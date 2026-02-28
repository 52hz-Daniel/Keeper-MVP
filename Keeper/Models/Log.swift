import Foundation

// MARK: - Log Model
// Reference: MPID Database Schema

struct Log: Identifiable, Codable, Equatable {
    let id: UUID
    let familyId: UUID
    let creatorId: UUID
    let stageContext: KeeperConstants.Stage
    let eventType: KeeperConstants.EventType
    let rawText: String?
    let structuredData: LogData?
    var isConfirmed: Bool
    let createdAt: Date
    var clientUpdatedAt: Date?
    var lastModifiedBy: UUID?
    
    init(
        id: UUID = UUID(),
        familyId: UUID,
        creatorId: UUID,
        stageContext: KeeperConstants.Stage = .infant,
        eventType: KeeperConstants.EventType,
        rawText: String? = nil,
        structuredData: LogData? = nil,
        isConfirmed: Bool = false,
        createdAt: Date = Date(),
        clientUpdatedAt: Date? = nil,
        lastModifiedBy: UUID? = nil
    ) {
        self.id = id
        self.familyId = familyId
        self.creatorId = creatorId
        self.stageContext = stageContext
        self.eventType = eventType
        self.rawText = rawText
        self.structuredData = structuredData
        self.isConfirmed = isConfirmed
        self.createdAt = createdAt
        self.clientUpdatedAt = clientUpdatedAt
        self.lastModifiedBy = lastModifiedBy
    }
}

// MARK: - Structured Log Data (Parsed from AI)
struct LogData: Codable, Equatable {
    let event: String
    let subtype: String?
    let amount: Double?
    let unit: String?
    let drug: String?
    let time: Date?
    let warning: String?
    let notes: String?
    
    // Convenience computed properties
    var displayAmount: String {
        guard let amount = amount else { return "" }
        let unit = unit ?? ""
        return "\(Int(amount))\(unit)"
    }
    
    var hasWarning: Bool {
        warning != nil && !warning!.isEmpty
    }
    
    var isMedication: Bool {
        event == "medication"
    }
}

// MARK: - Chat Message (UI Model)
enum MessageRole {
    case user
    case ai
    case system
}

struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    let role: MessageRole
    let text: String?
    let log: Log?
    let timestamp: Date
    var isProcessing: Bool
    
    init(
        id: UUID = UUID(),
        role: MessageRole,
        text: String? = nil,
        log: Log? = nil,
        timestamp: Date = Date(),
        isProcessing: Bool = false
    ) {
        self.id = id
        self.role = role
        self.text = text
        self.log = log
        self.timestamp = timestamp
        self.isProcessing = isProcessing
    }
    
    // User message factory
    static func user(_ text: String) -> ChatMessage {
        ChatMessage(role: .user, text: text)
    }
    
    // AI Ghost Log factory
    static func ghostLog(_ log: Log) -> ChatMessage {
        ChatMessage(role: .ai, log: log)
    }
    
    // Processing indicator factory
    static func processing() -> ChatMessage {
        ChatMessage(role: .system, text: "Thinking...", isProcessing: true)
    }
}

// MARK: - AI Parse Response
struct AIParseResponse: Codable {
    let event: String
    let subtype: String?
    let amount: Double?
    let unit: String?
    let drug: String?
    let time: String?
    let warning: String?
    let notes: String?
    let error: String?
    
    func toLogData() -> LogData {
        let parsedTime: Date?
        if let timeString = time {
            let formatter = ISO8601DateFormatter()
            parsedTime = formatter.date(from: timeString)
        } else {
            parsedTime = Date()
        }
        
        return LogData(
            event: event,
            subtype: subtype,
            amount: amount,
            unit: unit,
            drug: drug,
            time: parsedTime,
            warning: warning,
            notes: notes
        )
    }
    
    func toEventType() -> KeeperConstants.EventType {
        KeeperConstants.EventType(rawValue: event) ?? .note
    }
}

