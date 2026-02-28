import Foundation
import SwiftUI

// MARK: - Early Ed Store
// Data store for early education stage features
// Philosophy: Celebrate moments, capture joy, make parents feel rewarded

@MainActor
final class EarlyEdStore: ObservableObject {
    static let shared = EarlyEdStore()
    
    // MARK: - Published Properties
    @Published var childName: String = "Oliver"
    @Published var childBirthDate: Date
    @Published var firstWords: [FirstWord] = []
    @Published var funnyQuotes: [FunnyQuote] = []
    @Published var milestones: [ToddlerMilestone] = []
    
    // MARK: - Persistence
    private let defaults = UserDefaults.standard
    private let childNameKey = "keeper_child_name"
    private let birthDateKey = "keeper_child_birthdate"
    private let wordsKey = "keeper_first_words"
    private let quotesKey = "keeper_funny_quotes"
    private let milestonesKey = "keeper_toddler_milestones"
    
    private init() {
        // Default birth date 18 months ago
        childBirthDate = defaults.object(forKey: birthDateKey) as? Date ??
            Calendar.current.date(byAdding: .month, value: -18, to: Date())!
        
        childName = defaults.string(forKey: childNameKey) ?? "Oliver"
        loadData()
    }
    
    // MARK: - Computed Properties
    
    var ageDescription: String {
        let months = Calendar.current.dateComponents([.month], from: childBirthDate, to: Date()).month ?? 0
        if months >= 24 {
            let years = months / 12
            return "\(years) years old • Learning every day!"
        } else {
            return "\(months) months of wonder ✨"
        }
    }
    
    var moodEmoji: String {
        // Return different emojis based on recent activity
        if funnyQuotes.last?.createdAt.timeIntervalSinceNow ?? -1000 > -3600 {
            return "😂"
        } else if firstWords.last?.createdAt.timeIntervalSinceNow ?? -1000 > -3600 {
            return "🗣️"
        } else if milestones.last?.createdAt.timeIntervalSinceNow ?? -1000 > -3600 {
            return "⭐"
        }
        return "🌟"
    }
    
    var totalMemories: Int {
        firstWords.count + funnyQuotes.count + milestones.count
    }
    
    var todaysHighlight: EarlyEdHighlight? {
        // Check for recent activity to highlight
        if let lastWord = firstWords.last, Calendar.current.isDateInToday(lastWord.createdAt) {
            return EarlyEdHighlight(
                text: "New word: \"\(lastWord.word)\"! 🎉",
                detail: lastWord.context
            )
        }
        
        if let lastQuote = funnyQuotes.last, Calendar.current.isDateInToday(lastQuote.createdAt) {
            return EarlyEdHighlight(
                text: "😂 \"\(lastQuote.quote)\"",
                detail: nil
            )
        }
        
        if let lastMilestone = milestones.last, Calendar.current.isDateInToday(lastMilestone.createdAt) {
            return EarlyEdHighlight(
                text: "Milestone: \(lastMilestone.title) ⭐",
                detail: lastMilestone.notes
            )
        }
        
        // Show word count celebration
        if firstWords.count > 0 && firstWords.count % 10 == 0 {
            return EarlyEdHighlight(
                text: "\(firstWords.count) words! Amazing! 🎉",
                detail: "They're becoming such a great communicator!"
            )
        }
        
        return nil
    }
    
    var recentMoments: [EarlyEdMoment] {
        var moments: [EarlyEdMoment] = []
        
        // Add recent words
        for word in firstWords.prefix(3) {
            moments.append(EarlyEdMoment(
                id: word.id,
                type: .word,
                displayText: "New word: \"\(word.word)\"",
                createdAt: word.createdAt
            ))
        }
        
        // Add recent quotes
        for quote in funnyQuotes.prefix(3) {
            moments.append(EarlyEdMoment(
                id: quote.id,
                type: .quote,
                displayText: "\"\(quote.quote)\"",
                createdAt: quote.createdAt
            ))
        }
        
        // Add recent milestones
        for milestone in milestones.prefix(3) {
            moments.append(EarlyEdMoment(
                id: milestone.id,
                type: .milestone,
                displayText: milestone.title,
                createdAt: milestone.createdAt
            ))
        }
        
        return moments.sorted { $0.createdAt > $1.createdAt }
    }
    
    // MARK: - Actions
    
    func setChildName(_ name: String) {
        childName = name
        defaults.set(name, forKey: childNameKey)
    }
    
    func setChildBirthDate(_ date: Date) {
        childBirthDate = date
        defaults.set(date, forKey: birthDateKey)
    }
    
    func addFirstWord(_ word: String, context: String?) {
        let newWord = FirstWord(word: word.capitalized, context: context)
        firstWords.insert(newWord, at: 0)
        saveWords()
        HapticsService.shared.logConfirmed()
    }
    
    func addFunnyQuote(_ quote: String, context: String?) {
        let newQuote = FunnyQuote(quote: quote, context: context)
        funnyQuotes.insert(newQuote, at: 0)
        saveQuotes()
        HapticsService.shared.logConfirmed()
    }
    
    func addMilestone(_ title: String, notes: String?) {
        let newMilestone = ToddlerMilestone(title: title, notes: notes)
        milestones.insert(newMilestone, at: 0)
        saveMilestones()
        HapticsService.shared.logConfirmed()
    }
    
    // MARK: - Persistence
    
    private func loadData() {
        // Words
        if let data = defaults.data(forKey: wordsKey),
           let decoded = try? JSONDecoder().decode([FirstWord].self, from: data) {
            firstWords = decoded
        }
        
        // Quotes
        if let data = defaults.data(forKey: quotesKey),
           let decoded = try? JSONDecoder().decode([FunnyQuote].self, from: data) {
            funnyQuotes = decoded
        }
        
        // Milestones
        if let data = defaults.data(forKey: milestonesKey),
           let decoded = try? JSONDecoder().decode([ToddlerMilestone].self, from: data) {
            milestones = decoded
        }
    }
    
    private func saveWords() {
        if let encoded = try? JSONEncoder().encode(firstWords) {
            defaults.set(encoded, forKey: wordsKey)
        }
    }
    
    private func saveQuotes() {
        if let encoded = try? JSONEncoder().encode(funnyQuotes) {
            defaults.set(encoded, forKey: quotesKey)
        }
    }
    
    private func saveMilestones() {
        if let encoded = try? JSONEncoder().encode(milestones) {
            defaults.set(encoded, forKey: milestonesKey)
        }
    }
}

// MARK: - Supporting Types

struct FirstWord: Identifiable, Codable {
    let id: UUID
    let word: String
    let context: String?
    let createdAt: Date
    
    init(id: UUID = UUID(), word: String, context: String?, createdAt: Date = Date()) {
        self.id = id
        self.word = word
        self.context = context
        self.createdAt = createdAt
    }
}

struct FunnyQuote: Identifiable, Codable {
    let id: UUID
    let quote: String
    let context: String?
    let createdAt: Date
    
    init(id: UUID = UUID(), quote: String, context: String?, createdAt: Date = Date()) {
        self.id = id
        self.quote = quote
        self.context = context
        self.createdAt = createdAt
    }
    
    var timeAgo: String {
        let interval = Date().timeIntervalSince(createdAt)
        let hours = Int(interval) / 3600
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

struct ToddlerMilestone: Identifiable, Codable {
    let id: UUID
    let title: String
    let notes: String?
    let createdAt: Date
    
    init(id: UUID = UUID(), title: String, notes: String?, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.notes = notes
        self.createdAt = createdAt
    }
}

struct EarlyEdHighlight {
    let text: String
    let detail: String?
}

struct EarlyEdMoment: Identifiable {
    let id: UUID
    let type: MomentType
    let displayText: String
    let createdAt: Date
    
    enum MomentType {
        case word, quote, milestone
    }
    
    var icon: String {
        switch type {
        case .word: return "text.bubble.fill"
        case .quote: return "quote.bubble.fill"
        case .milestone: return "star.fill"
        }
    }
    
    var color: Color {
        switch type {
        case .word: return .cyan
        case .quote: return .pink
        case .milestone: return .yellow
        }
    }
    
    var timeAgo: String {
        let interval = Date().timeIntervalSince(createdAt)
        let hours = Int(interval) / 3600
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

