import Foundation

// MARK: - Family Model
// Reference: MPID Database Schema

struct Family: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let inviteCode: String
    let createdAt: Date
    let createdBy: UUID
    var childName: String?
    var childBirthDate: Date?
    var subscriptionTier: SubscriptionTier
    var subscriptionExpiry: Date?
    var memberCount: Int
    
    init(
        id: UUID = UUID(),
        name: String,
        inviteCode: String = Family.generateInviteCode(),
        createdAt: Date = Date(),
        createdBy: UUID,
        childName: String? = nil,
        childBirthDate: Date? = nil,
        subscriptionTier: SubscriptionTier = .individual,
        subscriptionExpiry: Date? = nil,
        memberCount: Int = 1
    ) {
        self.id = id
        self.name = name
        self.inviteCode = inviteCode
        self.createdAt = createdAt
        self.createdBy = createdBy
        self.childName = childName
        self.childBirthDate = childBirthDate
        self.subscriptionTier = subscriptionTier
        self.subscriptionExpiry = subscriptionExpiry
        self.memberCount = memberCount
    }
    
    /// Generate a 6-character invite code
    static func generateInviteCode() -> String {
        let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // Excluding confusable characters
        return String((0..<6).map { _ in characters.randomElement()! })
    }
}

// MARK: - Profile Model
struct Profile: Identifiable, Codable, Equatable {
    let id: UUID
    var email: String?
    var familyId: UUID?
    var role: FamilyRole?
    let createdAt: Date
    var displayName: String?
    
    // Baby/Child info (for stage calculation)
    var childDueDate: Date?
    var childBirthDate: Date?
    var childName: String?
    
    init(
        id: UUID = UUID(),
        email: String? = nil,
        familyId: UUID? = nil,
        role: FamilyRole? = nil,
        createdAt: Date = Date(),
        displayName: String? = nil,
        childDueDate: Date? = nil,
        childBirthDate: Date? = nil,
        childName: String? = nil
    ) {
        self.id = id
        self.email = email
        self.familyId = familyId
        self.role = role
        self.createdAt = createdAt
        self.displayName = displayName
        self.childDueDate = childDueDate
        self.childBirthDate = childBirthDate
        self.childName = childName
    }
    
    /// Calculate current lifecycle stage based on dates
    var currentStage: KeeperConstants.Stage {
        // If due date is in the future, we're in pre-natal
        if let dueDate = childDueDate, dueDate > Date() {
            return .prenatal
        }
        
        // If we have a birth date, calculate age
        if let birthDate = childBirthDate {
            let months = Calendar.current.dateComponents([.month], from: birthDate, to: Date()).month ?? 0
            return months < 12 ? .infant : .earlyEd
        }
        
        // Default to infant stage
        return .infant
    }
    
    /// Child's age in months (if birth date is set)
    var childAgeInMonths: Int? {
        guard let birthDate = childBirthDate else { return nil }
        return Calendar.current.dateComponents([.month], from: birthDate, to: Date()).month
    }
}


// MARK: - Partner Status (for sync indicators)
enum PartnerStatus {
    case online
    case logging
    case lastSeen(Date)
    case offline
    
    var displayText: String {
        switch self {
        case .online:
            return "Online"
        case .logging:
            return "Logging..."
        case .lastSeen(let date):
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .short
            return "Last seen \(formatter.localizedString(for: date, relativeTo: Date()))"
        case .offline:
            return "Offline"
        }
    }
    
    var isActive: Bool {
        switch self {
        case .online, .logging:
            return true
        default:
            return false
        }
    }
}

