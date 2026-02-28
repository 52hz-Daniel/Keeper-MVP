import Foundation

// MARK: - Supabase Service
// Backend integration with Supabase
// Reference: MPID "Backend / DB: Supabase (PostgreSQL)"

final class SupabaseService {
    
    // MARK: - Singleton
    static let shared = SupabaseService()
    
    // MARK: - Properties
    private let baseURL: URL
    private let apiKey: String
    private let session: URLSession
    
    // MARK: - Current User (for RLS)
    var currentUserId: UUID?
    var currentFamilyId: UUID?
    
    private init() {
        self.baseURL = URL(string: Config.Supabase.url)!
        self.apiKey = Config.Supabase.anonKey
        
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = [
            "apikey": apiKey,
            "Authorization": "Bearer \(apiKey)",
            "Content-Type": "application/json",
            "Prefer": "return=representation"
        ]
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Logs CRUD
    
    /// Fetch logs for the current family
    /// Reference: MPID "All queries filter by family_id"
    func fetchLogs(familyId: UUID, limit: Int = 50) async throws -> [SupabaseLog] {
        let endpoint = baseURL.appendingPathComponent("rest/v1/logs")
        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "family_id", value: "eq.\(familyId.uuidString)"),
            URLQueryItem(name: "order", value: "created_at.desc"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SupabaseError.fetchFailed
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode([SupabaseLog].self, from: data)
    }
    
    /// Create a new log
    /// Reference: MPID Ghost Log - only save after user confirms
    func createLog(_ log: SupabaseLog) async throws -> SupabaseLog {
        let endpoint = baseURL.appendingPathComponent("rest/v1/logs")
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(log)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 201 else {
            throw SupabaseError.createFailed
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        
        let logs = try decoder.decode([SupabaseLog].self, from: data)
        guard let createdLog = logs.first else {
            throw SupabaseError.createFailed
        }
        
        return createdLog
    }
    
    /// Update an existing log
    func updateLog(_ log: SupabaseLog) async throws -> SupabaseLog {
        let endpoint = baseURL.appendingPathComponent("rest/v1/logs")
        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "id", value: "eq.\(log.id.uuidString)")
        ]
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "PATCH"
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(log)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SupabaseError.updateFailed
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        
        let logs = try decoder.decode([SupabaseLog].self, from: data)
        guard let updatedLog = logs.first else {
            throw SupabaseError.updateFailed
        }
        
        return updatedLog
    }
    
    // MARK: - Family
    
    /// Create a new family
    func createFamily(inviteCode: String) async throws -> SupabaseFamily {
        let endpoint = baseURL.appendingPathComponent("rest/v1/families")
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        
        let body = ["invite_code": inviteCode]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 201 else {
            throw SupabaseError.createFailed
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        
        let families = try decoder.decode([SupabaseFamily].self, from: data)
        guard let family = families.first else {
            throw SupabaseError.createFailed
        }
        
        return family
    }
    
    /// Join a family with invite code
    func joinFamily(inviteCode: String) async throws -> SupabaseFamily? {
        let endpoint = baseURL.appendingPathComponent("rest/v1/families")
        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "invite_code", value: "eq.\(inviteCode)")
        ]
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SupabaseError.fetchFailed
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        
        let families = try decoder.decode([SupabaseFamily].self, from: data)
        return families.first
    }
    
    // MARK: - Health Check
    
    /// Check if Supabase is reachable
    func healthCheck() async -> Bool {
        let endpoint = baseURL.appendingPathComponent("rest/v1/")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "HEAD"
        
        do {
            let (_, response) = try await session.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }
}

// MARK: - Supabase Models (matching database schema)

struct SupabaseLog: Codable, Identifiable {
    let id: UUID
    let familyId: UUID
    let creatorId: UUID
    let stageContext: String?
    let eventType: String
    let rawText: String?
    let structuredData: [String: AnyCodable]?
    var isConfirmed: Bool
    let createdAt: Date
    var clientUpdatedAt: Date?
    var lastModifiedBy: UUID?
    
    init(from log: Log) {
        self.id = log.id
        self.familyId = log.familyId
        self.creatorId = log.creatorId
        self.stageContext = log.stageContext.rawValue
        self.eventType = log.eventType.rawValue
        self.rawText = log.rawText
        self.isConfirmed = log.isConfirmed
        self.createdAt = log.createdAt
        self.clientUpdatedAt = log.clientUpdatedAt
        self.lastModifiedBy = log.lastModifiedBy
        
        // Convert LogData to dictionary
        if let data = log.structuredData {
            var dict: [String: AnyCodable] = [:]
            dict["event"] = AnyCodable(data.event)
            if let subtype = data.subtype { dict["subtype"] = AnyCodable(subtype) }
            if let amount = data.amount { dict["amount"] = AnyCodable(amount) }
            if let unit = data.unit { dict["unit"] = AnyCodable(unit) }
            if let drug = data.drug { dict["drug"] = AnyCodable(drug) }
            if let warning = data.warning { dict["warning"] = AnyCodable(warning) }
            if let notes = data.notes { dict["notes"] = AnyCodable(notes) }
            self.structuredData = dict
        } else {
            self.structuredData = nil
        }
    }
}

struct SupabaseFamily: Codable, Identifiable {
    let id: UUID
    let inviteCode: String
    let createdAt: Date
}

struct SupabaseProfile: Codable, Identifiable {
    let id: UUID
    var email: String?
    var familyId: UUID?
    var role: String?
    let createdAt: Date
}

// MARK: - AnyCodable Helper
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
}

// MARK: - Supabase Errors
enum SupabaseError: Error, LocalizedError {
    case fetchFailed
    case createFailed
    case updateFailed
    case deleteFailed
    case notAuthenticated
    
    var errorDescription: String? {
        switch self {
        case .fetchFailed:
            return "Failed to fetch data from server"
        case .createFailed:
            return "Failed to create record"
        case .updateFailed:
            return "Failed to update record"
        case .deleteFailed:
            return "Failed to delete record"
        case .notAuthenticated:
            return "User not authenticated"
        }
    }
}

