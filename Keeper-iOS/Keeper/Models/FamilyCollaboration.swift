import Foundation

// MARK: - Family Collaboration Models
// Philosophy: "We keep the family's peace of mind" - together

// MARK: - Family Member
struct FamilyMember: Identifiable, Codable, Equatable {
    let id: UUID
    let familyId: UUID
    let userId: UUID
    let role: FamilyRole
    let displayName: String
    let joinedAt: Date
    let isActive: Bool
    let notificationPreferences: NotificationPreferences
    
    init(
        id: UUID = UUID(),
        familyId: UUID,
        userId: UUID,
        role: FamilyRole,
        displayName: String,
        joinedAt: Date = Date(),
        isActive: Bool = true,
        notificationPreferences: NotificationPreferences = NotificationPreferences()
    ) {
        self.id = id
        self.familyId = familyId
        self.userId = userId
        self.role = role
        self.displayName = displayName
        self.joinedAt = joinedAt
        self.isActive = isActive
        self.notificationPreferences = notificationPreferences
    }
}

// MARK: - Family Role
enum FamilyRole: String, Codable, CaseIterable {
    case mom = "Mom"
    case dad = "Dad"
    case partner = "Partner"
    case guardian = "Guardian"
    case caregiver = "Caregiver"
    case grandparent = "Grandparent"
    
    var icon: String {
        switch self {
        case .mom: return "person.fill"
        case .dad: return "person.fill"
        case .partner: return "person.2.fill"
        case .guardian: return "figure.2"
        case .caregiver: return "figure.and.child.holdinghands"
        case .grandparent: return "figure.2"
        }
    }
    
    var emoji: String {
        switch self {
        case .mom: return "👩"
        case .dad: return "👨"
        case .partner: return "🧑"
        case .guardian: return "👤"
        case .caregiver: return "👶"
        case .grandparent: return "👵"
        }
    }
    
    var canInviteOthers: Bool {
        switch self {
        case .mom, .dad, .partner, .guardian: return true
        case .caregiver, .grandparent: return false
        }
    }
}

// MARK: - Notification Preferences
struct NotificationPreferences: Codable, Equatable {
    var silentMode: Bool // No sound/vibration except emergencies
    var feedNotifications: Bool
    var sleepNotifications: Bool
    var diaperNotifications: Bool
    var medicationNotifications: Bool // Always on for safety
    var appreciationNudges: Bool
    var handOffReports: Bool
    
    init(
        silentMode: Bool = false,
        feedNotifications: Bool = true,
        sleepNotifications: Bool = true,
        diaperNotifications: Bool = false, // Less urgent
        medicationNotifications: Bool = true, // Critical
        appreciationNudges: Bool = true,
        handOffReports: Bool = true
    ) {
        self.silentMode = silentMode
        self.feedNotifications = feedNotifications
        self.sleepNotifications = sleepNotifications
        self.diaperNotifications = diaperNotifications
        self.medicationNotifications = medicationNotifications
        self.appreciationNudges = appreciationNudges
        self.handOffReports = handOffReports
    }
}

// MARK: - Family Invite
struct FamilyInvite: Identifiable, Codable {
    let id: UUID
    let familyId: UUID
    let invitedBy: UUID
    let invitedByName: String
    let role: FamilyRole
    let email: String?
    let code: String // 6-digit code for joining
    let expiresAt: Date
    let createdAt: Date
    var acceptedAt: Date?
    var status: InviteStatus
    
    init(
        id: UUID = UUID(),
        familyId: UUID,
        invitedBy: UUID,
        invitedByName: String,
        role: FamilyRole,
        email: String? = nil,
        code: String = String(format: "%06d", Int.random(in: 0...999999)),
        expiresAt: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date())!,
        createdAt: Date = Date(),
        acceptedAt: Date? = nil,
        status: InviteStatus = .pending
    ) {
        self.id = id
        self.familyId = familyId
        self.invitedBy = invitedBy
        self.invitedByName = invitedByName
        self.role = role
        self.email = email
        self.code = code
        self.expiresAt = expiresAt
        self.createdAt = createdAt
        self.acceptedAt = acceptedAt
        self.status = status
    }
    
    var isExpired: Bool {
        Date() > expiresAt
    }
    
    var isValid: Bool {
        status == .pending && !isExpired
    }
}

enum InviteStatus: String, Codable {
    case pending = "pending"
    case accepted = "accepted"
    case declined = "declined"
    case expired = "expired"
}

// MARK: - Hand-Off Report
// AI-generated summary of the day for the incoming parent
struct HandOffReport: Identifiable, Codable {
    let id: UUID
    let familyId: UUID
    let generatedFor: UUID // The parent receiving the report
    let generatedBy: UUID? // The parent who triggered it (optional)
    let timeRange: DateInterval
    let summary: String // AI-generated natural language summary
    let highlights: [String] // Key points
    let stats: HandOffStats
    let babyMood: BabyMood
    let urgentItems: [String] // Things that need immediate attention
    let generatedAt: Date
    
    init(
        id: UUID = UUID(),
        familyId: UUID,
        generatedFor: UUID,
        generatedBy: UUID? = nil,
        timeRange: DateInterval,
        summary: String,
        highlights: [String],
        stats: HandOffStats,
        babyMood: BabyMood,
        urgentItems: [String] = [],
        generatedAt: Date = Date()
    ) {
        self.id = id
        self.familyId = familyId
        self.generatedFor = generatedFor
        self.generatedBy = generatedBy
        self.timeRange = timeRange
        self.summary = summary
        self.highlights = highlights
        self.stats = stats
        self.babyMood = babyMood
        self.urgentItems = urgentItems
        self.generatedAt = generatedAt
    }
}

struct HandOffStats: Codable {
    let feedCount: Int
    let totalFeedAmount: Double?
    let sleepDuration: Double // in hours
    let diaperCount: Int
    let lastFeedTime: Date?
    let lastSleepTime: Date?
    let lastDiaperTime: Date?
}

enum BabyMood: String, Codable {
    case great = "Great"
    case good = "Good"
    case fussy = "Fussy"
    case needsAttention = "Needs Attention"
    
    var emoji: String {
        switch self {
        case .great: return "😊"
        case .good: return "🙂"
        case .fussy: return "😤"
        case .needsAttention: return "😰"
        }
    }
    
    var color: String {
        switch self {
        case .great: return "green"
        case .good: return "cyan"
        case .fussy: return "yellow"
        case .needsAttention: return "orange"
        }
    }
}

// MARK: - Invisible Work Ledger
// Track and celebrate everyone's contributions
struct WorkContribution: Codable {
    let memberId: UUID
    let memberName: String
    let week: DateInterval
    let stats: ContributionStats
    
    var totalActions: Int {
        stats.feedLogs + stats.sleepLogs + stats.diaperLogs + stats.medicationLogs + stats.otherLogs
    }
}

struct ContributionStats: Codable {
    var feedLogs: Int = 0
    var sleepLogs: Int = 0
    var diaperLogs: Int = 0
    var medicationLogs: Int = 0
    var otherLogs: Int = 0
    var nightFeeds: Int = 0 // 12am-6am
    var voiceNotes: Int = 0
    var milestones: Int = 0
}

// MARK: - Appreciation Note
struct AppreciationNote: Identifiable, Codable {
    let id: UUID
    let fromMember: UUID
    let fromName: String
    let toMember: UUID
    let toName: String
    let message: String
    let relatedLog: UUID? // The log that triggered the appreciation
    let createdAt: Date
    var isRead: Bool
    
    init(
        id: UUID = UUID(),
        fromMember: UUID,
        fromName: String,
        toMember: UUID,
        toName: String,
        message: String,
        relatedLog: UUID? = nil,
        createdAt: Date = Date(),
        isRead: Bool = false
    ) {
        self.id = id
        self.fromMember = fromMember
        self.fromName = fromName
        self.toMember = toMember
        self.toName = toName
        self.message = message
        self.relatedLog = relatedLog
        self.createdAt = createdAt
        self.isRead = isRead
    }
}

// MARK: - Family Activity
// For the activity feed showing what everyone is doing
struct FamilyActivity: Identifiable, Codable {
    let id: UUID
    let familyId: UUID
    let memberId: UUID
    let memberName: String
    let activityType: ActivityType
    let logId: UUID?
    let description: String
    let timestamp: Date
    
    enum ActivityType: String, Codable {
        case loggedFeed = "logged_feed"
        case loggedSleep = "logged_sleep"
        case loggedDiaper = "logged_diaper"
        case loggedMedication = "logged_medication"
        case joinedFamily = "joined_family"
        case sentAppreciation = "sent_appreciation"
        case capturedMoment = "captured_moment"
    }
}

