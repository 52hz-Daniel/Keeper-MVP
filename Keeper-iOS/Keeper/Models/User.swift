import Foundation

// MARK: - User Model
// Account management for Keeper

struct User: Codable, Identifiable {
    let id: UUID
    var email: String?
    var displayName: String?
    var avatarURL: String?
    var authProvider: AuthProvider?
    let createdAt: Date
    var lastLoginAt: Date?
    
    // Family relationship
    var familyId: UUID?
    var familyRole: FamilyRole?
    
    // Child info
    var childName: String?
    var childDueDate: Date?
    var childBirthDate: Date?
    var childPhotoURL: String?
    
    // Preferences
    var preferredStage: KeeperConstants.Stage?
    var notificationsEnabled: Bool
    var darkModePreference: DarkModePreference
    
    // Subscription
    var subscription: Subscription?
    
    // Usage tracking (for prompting account creation)
    var logsConfirmed: Int
    var sessionCount: Int
    var hasSeenAccountPrompt: Bool
    var hasSeenSubscriptionPrompt: Bool
    
    init(
        id: UUID = UUID(),
        email: String? = nil,
        displayName: String? = nil,
        authProvider: AuthProvider? = nil,
        familyId: UUID? = nil,
        familyRole: FamilyRole? = nil
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.authProvider = authProvider
        self.createdAt = Date()
        self.lastLoginAt = Date()
        self.familyId = familyId
        self.familyRole = familyRole
        self.notificationsEnabled = true
        self.darkModePreference = .system
        self.logsConfirmed = 0
        self.sessionCount = 1
        self.hasSeenAccountPrompt = false
        self.hasSeenSubscriptionPrompt = false
    }
    
    // MARK: - Computed Properties
    
    var isAnonymous: Bool {
        email == nil && authProvider == nil
    }
    
    var currentStage: KeeperConstants.Stage {
        if let preferred = preferredStage {
            return preferred
        }
        
        // Auto-calculate from dates
        if let dueDate = childDueDate, dueDate > Date() {
            return .prenatal
        }
        if let birthDate = childBirthDate {
            let months = Calendar.current.dateComponents([.month], from: birthDate, to: Date()).month ?? 0
            return months < 12 ? .infant : .earlyEd
        }
        return .infant
    }
    
    var childAgeInMonths: Int? {
        guard let birthDate = childBirthDate else { return nil }
        return Calendar.current.dateComponents([.month], from: birthDate, to: Date()).month
    }
    
    var shouldPromptForAccount: Bool {
        // Prompt after 5 confirmed logs if still anonymous
        return isAnonymous && logsConfirmed >= 5 && !hasSeenAccountPrompt
    }
    
    var isPremium: Bool {
        subscription?.isPremium ?? false
    }
    
    // MARK: - Mutating Functions
    
    mutating func incrementLogs() {
        logsConfirmed += 1
    }
    
    mutating func incrementSessions() {
        sessionCount += 1
        lastLoginAt = Date()
    }
    
    mutating func startTrial() {
        subscription = Subscription(userId: id, tier: .individual, status: .trial)
    }
    
    mutating func upgradeToPremium() {
        subscription?.tier = .individual
        subscription?.status = .active
        subscription?.subscriptionStartDate = Date()
    }
    
    mutating func downgradeToFree() {
        subscription?.tier = .free
        subscription?.status = .expired
    }
}

// MARK: - Auth Provider
enum AuthProvider: String, Codable {
    case apple = "apple"
    case google = "google"
    case email = "email"
    
    var displayName: String {
        switch self {
        case .apple: return "Apple"
        case .google: return "Google"
        case .email: return "Email"
        }
    }
    
    var icon: String {
        switch self {
        case .apple: return "apple.logo"
        case .google: return "g.circle.fill"
        case .email: return "envelope.fill"
        }
    }
}

// MARK: - Dark Mode Preference
enum DarkModePreference: String, Codable {
    case system = "system"
    case dark = "dark"
    case light = "light"
}

