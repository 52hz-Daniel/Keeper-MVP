import Foundation
import SwiftUI

// MARK: - Moments Service
// Captures and surfaces precious moments from the chaos of parenting
// Philosophy: "Keeper remembers, so you can sleep" - and so you can look back and smile

@MainActor
final class MomentsService: ObservableObject {
    
    static let shared = MomentsService()
    
    @Published var moments: [Moment] = []
    @Published var pendingGift: MemoryGift?
    @Published var recentHighlight: Moment?
    
    private let defaults = UserDefaults.standard
    private let momentsKey = "keeper_moments"
    private let lastMilestoneCheck = "keeper_last_milestone_check"
    
    private init() {
        loadMoments()
    }
    
    // MARK: - Moment Detection
    // Automatically detect special moments from logs
    
    func analyzeLogForMoment(log: Log, childBirthDate: Date) -> Moment? {
        guard let data = log.structuredData else { return nil }
        
        // Check for parent wins (good sleep stretches)
        if log.eventType == .sleep, let amount = data.amount, let unit = data.unit {
            if unit == "hours" && amount >= 6 {
                return createMoment(
                    type: .sleepThrough,
                    title: "A Full Night's Rest! 🌙",
                    description: "Baby slept \(Int(amount)) hours straight. You both earned this!",
                    relatedLogId: log.id
                )
            }
        }
        
        // Check for first solids
        if log.eventType == .feed, data.subtype == "solid" {
            // Could check if this is the first solid log
            return createMoment(
                type: .firstSolid,
                title: "First Taste Adventure! 🥣",
                description: "A new flavor experience! What did they think?",
                relatedLogId: log.id
            )
        }
        
        // Check for milestones
        if log.eventType == .milestone {
            return createMoment(
                type: .milestone,
                title: data.notes ?? "New Milestone! ⭐",
                description: "Another step on this amazing journey.",
                relatedLogId: log.id
            )
        }
        
        // Check for sweet notes (user shared something heartfelt)
        if log.eventType == .note, let text = log.rawText {
            let sweetKeywords = ["smiled", "laughed", "first", "love", "cute", "adorable", "amazing", "wonderful"]
            let lowercaseText = text.lowercased()
            if sweetKeywords.contains(where: { lowercaseText.contains($0) }) {
                return createMoment(
                    type: .sweetNote,
                    title: "A Sweet Moment 💛",
                    description: text,
                    relatedLogId: log.id
                )
            }
        }
        
        return nil
    }
    
    // MARK: - Parent Win Detection
    // Surface moments that celebrate the parents, not just the baby
    
    func checkForParentWin(recentLogs: [Log]) -> Moment? {
        // Check for consistent sleep patterns
        let sleepLogs = recentLogs.filter { $0.eventType == .sleep }
        let recentSleepHours = sleepLogs.compactMap { $0.structuredData?.amount }.reduce(0, +)
        
        if recentSleepHours >= 12 { // Good sleep day
            return createMoment(
                type: .parentWin,
                title: "You're Crushing It! 💪",
                description: "Great sleep patterns today. You're doing an amazing job.",
                relatedLogId: nil
            )
        }
        
        return nil
    }
    
    // MARK: - Milestone Gift Generation
    
    func checkForMilestoneGift(childBirthDate: Date, familyId: UUID) -> MemoryGift? {
        let daysSinceBirth = Calendar.current.dateComponents([.day], from: childBirthDate, to: Date()).day ?? 0
        
        for milestoneType in MilestoneType.allCases {
            // Check if we've reached this milestone
            if daysSinceBirth >= milestoneType.daysRequired {
                // Check if we've already generated this gift
                let giftKey = "keeper_gift_\(milestoneType.rawValue)_\(familyId.uuidString)"
                if !defaults.bool(forKey: giftKey) {
                    // Generate the gift!
                    let milestone = Milestone(
                        type: milestoneType,
                        childAgeInDays: daysSinceBirth
                    )
                    
                    // Get moments from this period
                    let relevantMoments = moments.filter { moment in
                        moment.capturedAt <= Date() && moment.capturedAt >= childBirthDate
                    }.prefix(10) // Top 10 moments
                    
                    let gift = MemoryGift(
                        familyId: familyId,
                        milestone: milestone,
                        moments: Array(relevantMoments)
                    )
                    
                    // Mark as generated
                    defaults.set(true, forKey: giftKey)
                    
                    return gift
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Moment Management
    
    private func createMoment(
        type: MomentType,
        title: String,
        description: String,
        relatedLogId: UUID?,
        familyId: UUID = UUID()
    ) -> Moment {
        let moment = Moment(
            familyId: familyId,
            type: type,
            title: title,
            description: description,
            relatedLogId: relatedLogId
        )
        
        return moment
    }
    
    func saveMoment(_ moment: Moment) {
        moments.append(moment)
        recentHighlight = moment
        saveMoments()
        HapticsService.shared.logConfirmed()
    }
    
    func toggleFavorite(_ moment: Moment) {
        if let index = moments.firstIndex(where: { $0.id == moment.id }) {
            moments[index].isFavorite.toggle()
            saveMoments()
        }
    }
    
    // MARK: - Daily Highlight
    // Surface a positive moment to the parent
    
    func getDailyHighlight() -> Moment? {
        // Prioritize: Recent parent wins, then favorites, then any recent moment
        if let recentWin = moments.filter({ $0.type == .parentWin }).last {
            return recentWin
        }
        
        if let favorite = moments.filter({ $0.isFavorite }).randomElement() {
            return favorite
        }
        
        return moments.last
    }
    
    // MARK: - Gentle Prompts
    // Non-intrusive prompts to capture moments
    
    func getGentlePrompt(for stage: KeeperConstants.Stage) -> String {
        switch stage {
        case .prenatal:
            return "Feeling any movements today? 🤰"
        case .infant:
            return "Any sweet moments to remember? 💛"
        case .earlyEd:
            return "What made you smile today? 😊"
        }
    }
    
    // MARK: - Persistence
    
    private func loadMoments() {
        if let data = defaults.data(forKey: momentsKey),
           let decoded = try? JSONDecoder().decode([Moment].self, from: data) {
            moments = decoded
        }
    }
    
    private func saveMoments() {
        if let encoded = try? JSONEncoder().encode(moments) {
            defaults.set(encoded, forKey: momentsKey)
        }
    }
    
    func clearAll() {
        moments = []
        defaults.removeObject(forKey: momentsKey)
    }
}

// MARK: - Moment Card View Model
extension Moment {
    var displayIcon: String {
        type.icon
    }
    
    var displayColor: Color {
        switch type {
        case .firstSmile, .firstLaugh, .sweetNote:
            return .yellow
        case .sleepThrough, .parentWin:
            return .green
        case .firstWord, .firstStep:
            return .blue
        case .firstSolid:
            return .orange
        case .growthSpurt, .milestone:
            return .purple
        }
    }
    
    var timeAgo: String {
        let interval = Date().timeIntervalSince(capturedAt)
        let hours = Int(interval / 3600)
        let days = hours / 24
        
        if days > 0 {
            return "\(days)d ago"
        } else if hours > 0 {
            return "\(hours)h ago"
        } else {
            return "Just now"
        }
    }
}

