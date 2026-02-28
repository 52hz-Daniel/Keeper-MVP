import Foundation
import SwiftUI

// MARK: - Prenatal Store
// Data store for prenatal stage features
// Philosophy: Support the journey with gentle preparation and emotional connection

@MainActor
final class PrenatalStore: ObservableObject {
    static let shared = PrenatalStore()
    
    // MARK: - Published Properties
    @Published var dueDate: Date
    @Published var letters: [LetterToBaby] = []
    @Published var kickSessions: [KickSession] = []
    @Published var notes: [PrenatalNote] = []
    @Published var bagItems: [BagItem] = BagItem.defaultItems
    
    // MARK: - Persistence
    private let defaults = UserDefaults.standard
    private let dueDateKey = "keeper_due_date"
    private let lettersKey = "keeper_letters"
    private let kickSessionsKey = "keeper_kick_sessions"
    private let notesKey = "keeper_prenatal_notes"
    private let bagItemsKey = "keeper_bag_items"
    
    private init() {
        // Default due date 12 weeks from now
        dueDate = defaults.object(forKey: dueDateKey) as? Date ??
            Calendar.current.date(byAdding: .weekOfYear, value: 12, to: Date())!
        loadData()
    }
    
    // MARK: - Computed Properties
    
    var currentWeek: Int {
        let fullTerm = 40 // weeks
        let weeksRemaining = Calendar.current.dateComponents([.weekOfYear], from: Date(), to: dueDate).weekOfYear ?? 0
        return max(1, min(fullTerm, fullTerm - weeksRemaining))
    }
    
    var daysRemaining: Int {
        max(0, Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0)
    }
    
    var progress: Double {
        let totalDays = 280.0 // 40 weeks
        let elapsed = totalDays - Double(daysRemaining)
        return min(1.0, max(0.0, elapsed / totalDays))
    }
    
    var trimesterText: String {
        switch currentWeek {
        case 1...13: return "1st Trimester"
        case 14...27: return "2nd Trimester"
        default: return "3rd Trimester"
        }
    }
    
    var isNearDue: Bool {
        daysRemaining <= 42 // 6 weeks
    }
    
    var lastKickCount: Int {
        kickSessions.last?.count ?? 0
    }
    
    var packedItems: Int {
        bagItems.filter(\.isPacked).count
    }
    
    var totalBagItems: Int {
        bagItems.count
    }
    
    var recentNotes: [PrenatalNote] {
        Array(notes.sorted { $0.createdAt > $1.createdAt }.prefix(5))
    }
    
    // MARK: - Baby Size Data
    
    var babySizeEmoji: String {
        let sizes: [Int: String] = [
            4: "🫐", 5: "🍓", 6: "🍒", 7: "🍇", 8: "🫒",
            9: "🍋", 10: "🍑", 11: "🥝", 12: "🍊", 13: "🍐",
            14: "🍋", 15: "🍎", 16: "🥑", 17: "🥔", 18: "🔔",
            19: "🥭", 20: "🍌", 21: "🥕", 22: "🥥", 23: "🍆",
            24: "🌽", 25: "🥬", 26: "🥦", 27: "🥒", 28: "🍆",
            29: "🎃", 30: "🥬", 31: "🥥", 32: "🍈", 33: "🍍",
            34: "🍈", 35: "🍈", 36: "🥬", 37: "🍉", 38: "🍉",
            39: "🍉", 40: "🎃"
        ]
        return sizes[currentWeek] ?? "👶"
    }
    
    var babySizeName: String {
        let names: [Int: String] = [
            4: "Poppy Seed", 5: "Strawberry", 6: "Cherry", 7: "Grape", 8: "Olive",
            9: "Lime", 10: "Peach", 11: "Kiwi", 12: "Orange", 13: "Pear",
            14: "Lemon", 15: "Apple", 16: "Avocado", 17: "Potato", 18: "Bell Pepper",
            19: "Mango", 20: "Banana", 21: "Carrot", 22: "Coconut", 23: "Eggplant",
            24: "Corn", 25: "Lettuce", 26: "Cauliflower", 27: "Cucumber", 28: "Eggplant",
            29: "Squash", 30: "Cabbage", 31: "Coconut", 32: "Melon", 33: "Pineapple",
            34: "Cantaloupe", 35: "Honeydew", 36: "Romaine", 37: "Watermelon", 38: "Watermelon",
            39: "Watermelon", 40: "Pumpkin"
        ]
        return names[currentWeek] ?? "Baby"
    }
    
    var weeklyDevelopmentText: String {
        let texts: [Int: String] = [
            28: "Your baby is now about 14 inches long and weighs around 2.5 pounds. Their eyes can blink and they're developing more fat under their skin.",
            29: "Baby's muscles and lungs continue to mature. They're getting stronger and more active!",
            30: "The brain is growing rapidly. Baby can now regulate their own body temperature better.",
            31: "All five senses are working now. Baby can see light, hear sounds, and even taste what you eat!",
            32: "Baby is practicing breathing movements. They're also sleeping and waking in regular cycles."
        ]
        return texts[currentWeek] ?? "Your baby continues to grow and develop. Every day brings new changes!"
    }
    
    var weeklyFunFact: String {
        let facts: [Int: String] = [
            28: "Your baby can dream now! REM sleep has begun.",
            29: "Baby has their own unique fingerprints already.",
            30: "Baby's brain is forming billions of neurons.",
            31: "Babies recognize their mother's voice from the womb.",
            32: "Your baby has toenails now!"
        ]
        return facts[currentWeek] ?? "Your baby is amazing and unique!"
    }
    
    var selfCareReminder: String {
        let reminders = [
            "Take a moment to put your feet up today.",
            "Remember to stay hydrated - water is your friend!",
            "A short walk can help with circulation and mood.",
            "It's okay to take a nap. You're growing a human!",
            "Stretch gently to ease any back tension.",
            "Talk to your baby - they can hear you now!"
        ]
        return reminders.randomElement()!
    }
    
    // MARK: - Actions
    
    func setDueDate(_ date: Date) {
        dueDate = date
        defaults.set(date, forKey: dueDateKey)
    }
    
    func saveLetter(_ text: String, week: Int) {
        let letter = LetterToBaby(text: text, week: week)
        letters.append(letter)
        saveLetters()
        HapticsService.shared.logConfirmed()
    }
    
    func saveKickSession(count: Int) {
        let session = KickSession(count: count)
        kickSessions.append(session)
        saveKickSessions()
        HapticsService.shared.logConfirmed()
    }
    
    func addNote(_ text: String) {
        let note = PrenatalNote(text: text)
        notes.append(note)
        saveNotes()
    }
    
    // MARK: - Persistence
    
    private func loadData() {
        // Letters
        if let data = defaults.data(forKey: lettersKey),
           let decoded = try? JSONDecoder().decode([LetterToBaby].self, from: data) {
            letters = decoded
        }
        
        // Kick sessions
        if let data = defaults.data(forKey: kickSessionsKey),
           let decoded = try? JSONDecoder().decode([KickSession].self, from: data) {
            kickSessions = decoded
        }
        
        // Notes
        if let data = defaults.data(forKey: notesKey),
           let decoded = try? JSONDecoder().decode([PrenatalNote].self, from: data) {
            notes = decoded
        }
        
        // Bag items
        if let data = defaults.data(forKey: bagItemsKey),
           let decoded = try? JSONDecoder().decode([BagItem].self, from: data) {
            bagItems = decoded
        }
    }
    
    private func saveLetters() {
        if let encoded = try? JSONEncoder().encode(letters) {
            defaults.set(encoded, forKey: lettersKey)
        }
    }
    
    private func saveKickSessions() {
        if let encoded = try? JSONEncoder().encode(kickSessions) {
            defaults.set(encoded, forKey: kickSessionsKey)
        }
    }
    
    private func saveNotes() {
        if let encoded = try? JSONEncoder().encode(notes) {
            defaults.set(encoded, forKey: notesKey)
        }
    }
    
    func saveBagItems() {
        if let encoded = try? JSONEncoder().encode(bagItems) {
            defaults.set(encoded, forKey: bagItemsKey)
        }
    }
}

// MARK: - Supporting Types

struct LetterToBaby: Identifiable, Codable {
    let id: UUID
    let text: String
    let week: Int
    let createdAt: Date
    
    init(id: UUID = UUID(), text: String, week: Int, createdAt: Date = Date()) {
        self.id = id
        self.text = text
        self.week = week
        self.createdAt = createdAt
    }
}

struct KickSession: Identifiable, Codable {
    let id: UUID
    let count: Int
    let createdAt: Date
    
    init(id: UUID = UUID(), count: Int, createdAt: Date = Date()) {
        self.id = id
        self.count = count
        self.createdAt = createdAt
    }
}

struct PrenatalNote: Identifiable, Codable {
    let id: UUID
    let text: String
    let createdAt: Date
    
    init(id: UUID = UUID(), text: String, createdAt: Date = Date()) {
        self.id = id
        self.text = text
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

struct BagItem: Identifiable, Codable {
    let id: UUID
    let name: String
    let category: BagCategory
    var isPacked: Bool
    
    init(id: UUID = UUID(), name: String, category: BagCategory, isPacked: Bool = false) {
        self.id = id
        self.name = name
        self.category = category
        self.isPacked = isPacked
    }
    
    static let defaultItems: [BagItem] = [
        // For Mom
        BagItem(name: "ID & Insurance cards", category: .forMom),
        BagItem(name: "Birth plan (if you have one)", category: .forMom),
        BagItem(name: "Comfortable robe", category: .forMom),
        BagItem(name: "Nursing bras (2-3)", category: .forMom),
        BagItem(name: "Comfortable underwear", category: .forMom),
        BagItem(name: "Toiletries", category: .forMom),
        BagItem(name: "Hair ties", category: .forMom),
        BagItem(name: "Lip balm", category: .forMom),
        BagItem(name: "Phone charger", category: .forMom),
        BagItem(name: "Going home outfit", category: .forMom),
        BagItem(name: "Slippers", category: .forMom),
        
        // For Baby
        BagItem(name: "Onesies (2-3)", category: .forBaby),
        BagItem(name: "Swaddle blankets", category: .forBaby),
        BagItem(name: "Car seat (installed!)", category: .forBaby),
        BagItem(name: "Newborn diapers", category: .forBaby),
        BagItem(name: "Going home outfit", category: .forBaby),
        BagItem(name: "Hat & socks", category: .forBaby),
        BagItem(name: "Receiving blanket", category: .forBaby),
        
        // For Partner
        BagItem(name: "Snacks", category: .forPartner),
        BagItem(name: "Phone charger", category: .forPartner),
        BagItem(name: "Change of clothes", category: .forPartner),
        BagItem(name: "Toiletries", category: .forPartner),
        BagItem(name: "Camera", category: .forPartner),
        BagItem(name: "Entertainment (book, tablet)", category: .forPartner),
    ]
}

enum BagCategory: String, CaseIterable, Codable {
    case forMom = "For Mom"
    case forBaby = "For Baby"
    case forPartner = "For Partner"
    
    var icon: String {
        switch self {
        case .forMom: return "person.fill"
        case .forBaby: return "figure.child"
        case .forPartner: return "person.2.fill"
        }
    }
}





