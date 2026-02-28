import Foundation
import SwiftUI
import Combine

// MARK: - Family Sync Service
// Real-time syncing and collaboration between family members
// Philosophy: "Reduce resentment, increase appreciation"

@MainActor
final class FamilySyncService: ObservableObject {
    static let shared = FamilySyncService()
    
    // MARK: - Published Properties
    @Published var currentFamily: Family?
    @Published var familyMembers: [FamilyMember] = []
    @Published var pendingInvites: [FamilyInvite] = []
    @Published var recentActivity: [FamilyActivity] = []
    @Published var unreadAppreciations: [AppreciationNote] = []
    @Published var currentHandOffReport: HandOffReport?
    @Published var weeklyContributions: [WorkContribution] = []
    @Published var isConnected: Bool = false
    
    // MARK: - Current User
    var currentMember: FamilyMember? {
        guard let userId = AuthService.shared.currentUser?.id else { return nil }
        return familyMembers.first { $0.userId == userId }
    }
    
    // MARK: - Services
    private let logStore = LogStore.shared
    private let supabase = SupabaseService.shared
    private let openAI = OpenAIService.shared
    private let haptics = HapticsService.shared
    
    // MARK: - Persistence
    private let defaults = UserDefaults.standard
    private let familyKey = "keeper_current_family"
    private let membersKey = "keeper_family_members"
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadLocalData()
        setupLogSyncObserver()
    }
    
    // MARK: - Family Management
    
    func createFamily(childName: String, childBirthDate: Date) async throws -> Family {
        guard let user = AuthService.shared.currentUser else {
            throw FamilySyncError.notAuthenticated
        }
        
        let family = Family(
            id: UUID(),
            name: "\(childName)'s Family",
            createdBy: user.id,
            childName: childName,
            childBirthDate: childBirthDate,
            subscriptionTier: .individual
        )
        
        // Create founder as first member
        let founder = FamilyMember(
            familyId: family.id,
            userId: user.id,
            role: .mom, // Can be changed later
            displayName: user.displayName ?? "Parent"
        )
        
        currentFamily = family
        familyMembers = [founder]
        
        saveLocalData()
        
        // Sync to backend
        // await supabase.createFamily(family, founder: founder)
        
        return family
    }
    
    func inviteMember(role: FamilyRole, email: String? = nil) -> FamilyInvite {
        guard let family = currentFamily,
              let currentUser = AuthService.shared.currentUser,
              let currentMember = currentMember,
              currentMember.role.canInviteOthers else {
            fatalError("Cannot invite members")
        }
        
        let invite = FamilyInvite(
            familyId: family.id,
            invitedBy: currentUser.id,
            invitedByName: currentMember.displayName,
            role: role,
            email: email
        )
        
        pendingInvites.append(invite)
        saveLocalData()
        
        return invite
    }
    
    func acceptInvite(code: String) async throws -> Family {
        guard let user = AuthService.shared.currentUser else {
            throw FamilySyncError.notAuthenticated
        }
        
        // Find invite by code (in real app, check backend)
        guard let invite = pendingInvites.first(where: { $0.code == code && $0.isValid }) else {
            throw FamilySyncError.invalidInviteCode
        }
        
        // Create member
        let newMember = FamilyMember(
            familyId: invite.familyId,
            userId: user.id,
            role: invite.role,
            displayName: user.displayName ?? "Caregiver"
        )
        
        familyMembers.append(newMember)
        
        // Load family info
        // In real app: currentFamily = try await supabase.getFamily(invite.familyId)
        
        // Create activity
        addActivity(
            memberId: newMember.userId,
            memberName: newMember.displayName,
            type: .joinedFamily,
            description: "\(newMember.displayName) joined the family"
        )
        
        saveLocalData()
        haptics.logConfirmed()
        
        return currentFamily!
    }
    
    // MARK: - Log Syncing
    
    private func setupLogSyncObserver() {
        // Observe log store changes and sync to family
        logStore.$logs
            .sink { [weak self] logs in
                self?.syncLogsToFamily(logs)
            }
            .store(in: &cancellables)
    }
    
    private func syncLogsToFamily(_ logs: [Log]) {
        guard let family = currentFamily,
              let currentMember = currentMember else { return }
        
        // In real app: sync to Supabase and trigger push notifications
        // For now, update local activity feed
        
        if let lastLog = logs.first {
            let activityType: FamilyActivity.ActivityType
            switch lastLog.eventType {
            case .feed: activityType = .loggedFeed
            case .sleep: activityType = .loggedSleep
            case .diaper: activityType = .loggedDiaper
            case .medication: activityType = .loggedMedication
            default: return
            }
            
            addActivity(
                memberId: currentMember.userId,
                memberName: currentMember.displayName,
                type: activityType,
                logId: lastLog.id,
                description: formatLogActivity(lastLog)
            )
            
            // Check if appreciation nudge should be triggered
            checkForAppreciationNudge(log: lastLog, member: currentMember)
        }
    }
    
    private func formatLogActivity(_ log: Log) -> String {
        guard let data = log.structuredData else {
            return log.eventType.displayName
        }
        
        switch log.eventType {
        case .feed:
            if let amount = data.amount, let unit = data.unit {
                return "Fed baby \(Int(amount))\(unit)"
            }
            return "Fed baby"
        case .sleep:
            if let amount = data.amount {
                return String(format: "Baby slept %.1fh", amount)
            }
            return "Baby went to sleep"
        case .diaper:
            return "Changed diaper (\(data.subtype ?? "change"))"
        case .medication:
            return "Gave \(data.drug ?? "medication")"
        default:
            return log.eventType.displayName
        }
    }
    
    // MARK: - Hand-Off Report Generation
    
    func generateHandOffReport(for member: FamilyMember) async -> HandOffReport {
        guard currentFamily != nil else {
            fatalError("No family loaded")
        }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let timeRange = DateInterval(start: startOfDay, end: now)
        
        // Get today's logs
        let todayLogs = logStore.logsForToday()
        
        // Calculate stats
        let feedLogs = todayLogs.filter { $0.eventType == .feed }
        let sleepLogs = todayLogs.filter { $0.eventType == .sleep }
        let diaperLogs = todayLogs.filter { $0.eventType == .diaper }
        
        let stats = HandOffStats(
            feedCount: feedLogs.count,
            totalFeedAmount: feedLogs.compactMap { $0.structuredData?.amount }.reduce(0, +),
            sleepDuration: sleepLogs.compactMap { $0.structuredData?.amount }.reduce(0, +),
            diaperCount: diaperLogs.count,
            lastFeedTime: feedLogs.first?.createdAt,
            lastSleepTime: sleepLogs.first?.createdAt,
            lastDiaperTime: diaperLogs.first?.createdAt
        )
        
        // Determine baby mood
        let mood = determineBabyMood(stats: stats, logs: todayLogs)
        
        // Generate AI summary
        let summary = await generateAISummary(stats: stats, logs: todayLogs)
        
        // Extract highlights
        let highlights = extractHighlights(logs: todayLogs)
        
        // Check for urgent items
        let urgentItems = checkUrgentItems(stats: stats)
        
        let report = HandOffReport(
            familyId: currentFamily!.id,
            generatedFor: member.userId,
            timeRange: timeRange,
            summary: summary,
            highlights: highlights,
            stats: stats,
            babyMood: mood,
            urgentItems: urgentItems
        )
        
        currentHandOffReport = report
        return report
    }
    
    private func determineBabyMood(stats: HandOffStats, logs: [Log]) -> BabyMood {
        // Simple heuristic - can be made more sophisticated
        let hoursSinceLastFeed = stats.lastFeedTime.map { Date().timeIntervalSince($0) / 3600 } ?? 100
        
        if hoursSinceLastFeed > 4 {
            return .needsAttention
        } else if stats.sleepDuration < 2 && hoursSinceLastFeed > 3 {
            return .fussy
        } else if stats.feedCount >= 6 && stats.sleepDuration >= 12 {
            return .great
        } else {
            return .good
        }
    }
    
    private func generateAISummary(stats: HandOffStats, logs: [Log]) async -> String {
        // In production: call OpenAI to generate natural summary
        // For now: template-based
        
        var summary = ""
        
        if stats.feedCount > 0 {
            summary += "\(currentFamily?.childName ?? "Baby") had \(stats.feedCount) feed\(stats.feedCount == 1 ? "" : "s") today"
            if let amount = stats.totalFeedAmount {
                summary += " (total \(Int(amount))oz)"
            }
            summary += ". "
        }
        
        if stats.sleepDuration > 0 {
            summary += String(format: "Slept for %.1f hours. ", stats.sleepDuration)
        }
        
        if let lastFeed = stats.lastFeedTime {
            let hoursSince = Date().timeIntervalSince(lastFeed) / 3600
            if hoursSince < 2 {
                summary += "Just fed recently, should be content. "
            } else if hoursSince > 3 {
                summary += "Getting close to next feeding time. "
            }
        }
        
        return summary.isEmpty ? "It's been a quiet day. Baby is doing well." : summary
    }
    
    private func extractHighlights(logs: [Log]) -> [String] {
        var highlights: [String] = []
        
        // Long sleep = highlight
        if let longestSleep = logs.filter({ $0.eventType == .sleep }).max(by: { ($0.structuredData?.amount ?? 0) < ($1.structuredData?.amount ?? 0) }),
           let duration = longestSleep.structuredData?.amount,
           duration >= 3 {
            highlights.append(String(format: "Longest nap: %.1f hours! 🌙", duration))
        }
        
        // Good feeding day
        let feedCount = logs.filter { $0.eventType == .feed }.count
        if feedCount >= 8 {
            highlights.append("Great feeding day with \(feedCount) feeds!")
        }
        
        return highlights
    }
    
    private func checkUrgentItems(stats: HandOffStats) -> [String] {
        var urgent: [String] = []
        
        // Check last feed time
        if let lastFeed = stats.lastFeedTime {
            let hoursSince = Date().timeIntervalSince(lastFeed) / 3600
            if hoursSince > 4 {
                urgent.append("⚠️ It's been \(Int(hoursSince)) hours since last feed")
            }
        }
        
        // Check diaper changes
        if let lastDiaper = stats.lastDiaperTime {
            let hoursSince = Date().timeIntervalSince(lastDiaper) / 3600
            if hoursSince > 3 {
                urgent.append("🧷 Last diaper change was \(Int(hoursSince)) hours ago")
            }
        }
        
        return urgent
    }
    
    // MARK: - Invisible Work Ledger
    
    func calculateWeeklyContributions() -> [WorkContribution] {
        let now = Date()
        let weekStart = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let weekRange = DateInterval(start: weekStart, end: now)
        
        var contributions: [WorkContribution] = []
        
        for member in familyMembers {
            let memberLogs = logStore.logs.filter { log in
                log.creatorId == member.userId &&
                weekRange.contains(log.createdAt)
            }
            
            var stats = ContributionStats()
            
            for log in memberLogs {
                switch log.eventType {
                case .feed:
                    stats.feedLogs += 1
                    // Check if night feed (12am-6am)
                    let hour = Calendar.current.component(.hour, from: log.createdAt)
                    if hour >= 0 && hour < 6 {
                        stats.nightFeeds += 1
                    }
                case .sleep:
                    stats.sleepLogs += 1
                case .diaper:
                    stats.diaperLogs += 1
                case .medication:
                    stats.medicationLogs += 1
                default:
                    stats.otherLogs += 1
                }
            }
            
            let contribution = WorkContribution(
                memberId: member.userId,
                memberName: member.displayName,
                week: weekRange,
                stats: stats
            )
            
            contributions.append(contribution)
        }
        
        weeklyContributions = contributions
        return contributions
    }
    
    // MARK: - Appreciation System
    
    private func checkForAppreciationNudge(log: Log, member: FamilyMember) {
        // Check if this is a night feed (12am-6am)
        let hour = Calendar.current.component(.hour, from: log.createdAt)
        if log.eventType == .feed && hour >= 0 && hour < 6 {
            // Schedule appreciation nudge for other family members in the morning
            scheduleAppreciationNudge(
                for: member,
                reason: "handled a night feed at \(formatTime(log.createdAt))"
            )
        }
        
        // Check for medication (always important)
        if log.eventType == .medication {
            scheduleAppreciationNudge(
                for: member,
                reason: "gave medication"
            )
        }
    }
    
    private func scheduleAppreciationNudge(for member: FamilyMember, reason: String) {
        // In production: schedule push notification for morning (8am)
        // For now: just log
        print("📬 Appreciation nudge: \(member.displayName) \(reason)")
    }
    
    func sendAppreciation(to: FamilyMember, message: String, relatedLog: UUID? = nil) {
        guard let fromMember = currentMember else { return }
        
        let _ = AppreciationNote(
            fromMember: fromMember.userId,
            fromName: fromMember.displayName,
            toMember: to.userId,
            toName: to.displayName,
            message: message,
            relatedLog: relatedLog
        )
        
        // In production: send push notification to recipient
        // For now: just log
        print("💌 Appreciation sent: \(message)")
        
        addActivity(
            memberId: fromMember.userId,
            memberName: fromMember.displayName,
            type: .sentAppreciation,
            description: "\(fromMember.displayName) thanked \(to.displayName)"
        )
        
        haptics.logConfirmed()
    }
    
    // MARK: - Smart Notifications
    
    func shouldSendNotification(for log: Log, to member: FamilyMember) -> Bool {
        let prefs = member.notificationPreferences
        
        // Medication is always sent (safety critical)
        if log.eventType == .medication {
            return true
        }
        
        // If silent mode, only critical notifications
        if prefs.silentMode {
            return false
        }
        
        // Check preferences for each type
        switch log.eventType {
        case .feed: return prefs.feedNotifications
        case .sleep: return prefs.sleepNotifications
        case .diaper: return prefs.diaperNotifications
        default: return false
        }
    }
    
    // MARK: - Activity Feed
    
    private func addActivity(
        memberId: UUID,
        memberName: String,
        type: FamilyActivity.ActivityType,
        logId: UUID? = nil,
        description: String
    ) {
        guard let family = currentFamily else { return }
        
        let activity = FamilyActivity(
            id: UUID(),
            familyId: family.id,
            memberId: memberId,
            memberName: memberName,
            activityType: type,
            logId: logId,
            description: description,
            timestamp: Date()
        )
        
        recentActivity.insert(activity, at: 0)
        
        // Keep only last 50 activities
        if recentActivity.count > 50 {
            recentActivity = Array(recentActivity.prefix(50))
        }
    }
    
    // MARK: - Helpers
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // MARK: - Persistence
    
    private func loadLocalData() {
        if let data = defaults.data(forKey: familyKey),
           let family = try? JSONDecoder().decode(Family.self, from: data) {
            currentFamily = family
        }
        
        if let data = defaults.data(forKey: membersKey),
           let members = try? JSONDecoder().decode([FamilyMember].self, from: data) {
            familyMembers = members
        }
    }
    
    private func saveLocalData() {
        if let family = currentFamily,
           let encoded = try? JSONEncoder().encode(family) {
            defaults.set(encoded, forKey: familyKey)
        }
        
        if let encoded = try? JSONEncoder().encode(familyMembers) {
            defaults.set(encoded, forKey: membersKey)
        }
    }
}

// MARK: - Errors

enum FamilySyncError: LocalizedError {
    case notAuthenticated
    case invalidInviteCode
    case familyNotFound
    case memberLimitReached
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be logged in to use family features"
        case .invalidInviteCode:
            return "Invalid or expired invite code"
        case .familyNotFound:
            return "Family not found"
        case .memberLimitReached:
            return "Family member limit reached (max 4 adults)"
        }
    }
}

