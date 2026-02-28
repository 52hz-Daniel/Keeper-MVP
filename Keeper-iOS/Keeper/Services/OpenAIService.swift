import Foundation

// MARK: - OpenAI Service
// Reference: MPID AI Implementation Guidelines

final class OpenAIService {
    
    // MARK: - Singleton
    static let shared = OpenAIService()
    private init() {}
    
    // MARK: - Configuration
    private var apiKey: String {
        Config.OpenAI.apiKey
    }
    
    private var baseURL: String {
        Config.OpenAI.baseURL + "/chat/completions"
    }
    
    private var model: String {
        Config.OpenAI.model
    }
    
    // MARK: - Parse Log
    
    /// Parse natural language input into structured log data
    /// - Parameters:
    ///   - text: The user's natural language input
    ///   - stage: Current lifecycle stage for context
    /// - Returns: Parsed AI response
    func parseLog(
        text: String,
        stage: KeeperConstants.Stage = .infant
    ) async throws -> AIParseResponse {
        
        // If no API key or it's placeholder, return mock data for development
        guard !apiKey.isEmpty && !apiKey.hasPrefix("sk-your") else {
            return mockParse(text: text)
        }
        
        let systemPrompt = KeeperConstants.systemPrompt(for: stage)
        
        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": text]
            ],
            "response_format": ["type": "json_object"],
            "max_tokens": KeeperConstants.AI.maxTokens,
            "temperature": KeeperConstants.AI.temperature
        ]
        
        guard let url = URL(string: baseURL) else {
            throw OpenAIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw OpenAIError.apiError(statusCode: httpResponse.statusCode)
        }
        
        let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        
        guard let content = openAIResponse.choices.first?.message.content else {
            throw OpenAIError.noContent
        }
        
        guard let jsonData = content.data(using: .utf8) else {
            throw OpenAIError.invalidJSON
        }
        
        let parsed = try JSONDecoder().decode(AIParseResponse.self, from: jsonData)
        return parsed
    }
    
    // MARK: - Mock Parser (Development)
    
    /// Mock parser for development without API key
    /// Reference: MPID "Mocking: If OpenAI API fails, fallback to a local mock parser"
    private func mockParse(text: String) -> AIParseResponse {
        let lowercased = text.lowercased()
        
        // Simple keyword matching for mock
        if lowercased.contains("tylenol") || lowercased.contains("medicine") || lowercased.contains("medication") {
            let amount = extractNumber(from: text)
            return AIParseResponse(
                event: "medication",
                subtype: nil,
                amount: amount,
                unit: "ml",
                drug: "Tylenol",
                time: ISO8601DateFormatter().string(from: Date()),
                warning: amount == nil ? "missing_dosage" : nil,
                notes: nil,
                error: nil
            )
        }
        
        if lowercased.contains("ate") || lowercased.contains("fed") || lowercased.contains("formula") || lowercased.contains("milk") || lowercased.contains("oz") {
            let amount = extractNumber(from: text) ?? 4
            return AIParseResponse(
                event: "feed",
                subtype: lowercased.contains("breast") ? "breast" : "formula",
                amount: amount,
                unit: "oz",
                drug: nil,
                time: ISO8601DateFormatter().string(from: Date()),
                warning: nil,
                notes: nil,
                error: nil
            )
        }
        
        if lowercased.contains("slept") || lowercased.contains("sleep") || lowercased.contains("nap") {
            let amount = extractNumber(from: text) ?? 2
            return AIParseResponse(
                event: "sleep",
                subtype: lowercased.contains("nap") ? "nap" : "night",
                amount: amount,
                unit: "hours",
                drug: nil,
                time: ISO8601DateFormatter().string(from: Date()),
                warning: nil,
                notes: nil,
                error: nil
            )
        }
        
        if lowercased.contains("diaper") || lowercased.contains("poop") || lowercased.contains("pee") || lowercased.contains("wet") {
            let subtype: String
            if lowercased.contains("poop") || lowercased.contains("dirty") {
                subtype = "dirty"
            } else if lowercased.contains("wet") || lowercased.contains("pee") {
                subtype = "wet"
            } else {
                subtype = "mixed"
            }
            
            return AIParseResponse(
                event: "diaper",
                subtype: subtype,
                amount: nil,
                unit: nil,
                drug: nil,
                time: ISO8601DateFormatter().string(from: Date()),
                warning: nil,
                notes: nil,
                error: nil
            )
        }
        
        // Default to note
        return AIParseResponse(
            event: "note",
            subtype: nil,
            amount: nil,
            unit: nil,
            drug: nil,
            time: ISO8601DateFormatter().string(from: Date()),
            warning: nil,
            notes: text,
            error: nil
        )
    }
    
    /// Extract a number from text
    private func extractNumber(from text: String) -> Double? {
        let pattern = #"(\d+\.?\d*)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else {
            return nil
        }
        return Double(text[range])
    }
}

// MARK: - OpenAI Response Models

struct OpenAIResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
    }
    
    struct Message: Codable {
        let content: String?
    }
}

// MARK: - OpenAI Errors

enum OpenAIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case apiError(statusCode: Int)
    case noContent
    case invalidJSON
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .apiError(let statusCode):
            return "API error: \(statusCode)"
        case .noContent:
            return "No content in response"
        case .invalidJSON:
            return "Invalid JSON response"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

