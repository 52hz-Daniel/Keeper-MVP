import Foundation

// MARK: - Insight Service
// Reference: Keeper Expansion - "Behavioral Pattern Matching"
// The "Pattern Recognition Engine" - Analyzes logs over time to find patterns

final class InsightService {
    
    // MARK: - Singleton
    static let shared = InsightService()
    private init() {}
    
    // MARK: - Pattern Analysis
    
    /// Analyze behavior patterns from a collection of logs
    func analyzeBehaviorPatterns(logs: [Log]) -> [BehaviorInsight] {
        var insights: [BehaviorInsight] = []
        
        // Filter behavior logs
        let behaviorLogs = logs.filter { $0.eventType == .note || $0.eventType == .milestone }
        
        // Analyze triggers
        let triggerInsight = analyzeTriggers(behaviorLogs)
        if let insight = triggerInsight {
            insights.append(insight)
        }
        
        // Analyze time patterns
        let timeInsight = analyzeTimePatterns(logs)
        if let insight = timeInsight {
            insights.append(insight)
        }
        
        return insights
    }
    
    /// Analyze vocabulary growth for toddlers
    func analyzeVocabularyGrowth(logs: [Log]) -> VocabularyInsight? {
        let vocabularyLogs = logs.filter {
            $0.structuredData?.event == "vocabulary" ||
            $0.structuredData?.subtype == "speech"
        }
        
        guard !vocabularyLogs.isEmpty else { return nil }
        
        // Count unique words
        var words: Set<String> = []
        for log in vocabularyLogs {
            if let notes = log.structuredData?.notes {
                // Simple word extraction
                let extractedWords = notes.lowercased()
                    .components(separatedBy: CharacterSet.alphanumerics.inverted)
                    .filter { !$0.isEmpty && $0.count > 1 }
                words.formUnion(extractedWords)
            }
        }
        
        return VocabularyInsight(
            totalWords: words.count,
            recentWords: Array(words.prefix(10)),
            lastUpdated: vocabularyLogs.first?.createdAt ?? Date()
        )
    }
    
    /// Analyze sleep patterns
    func analyzeSleepPatterns(logs: [Log]) -> SleepInsight? {
        let sleepLogs = logs.filter { $0.eventType == .sleep }
        
        guard sleepLogs.count >= 3 else { return nil }
        
        // Calculate average sleep duration
        let durations = sleepLogs.compactMap { $0.structuredData?.amount }
        let averageDuration = durations.reduce(0, +) / Double(durations.count)
        
        // Find common sleep times
        let sleepTimes = sleepLogs.compactMap { $0.structuredData?.time }
        let hourCounts = sleepTimes.reduce(into: [Int: Int]()) { counts, date in
            let hour = Calendar.current.component(.hour, from: date)
            counts[hour, default: 0] += 1
        }
        let commonHour = hourCounts.max(by: { $0.value < $1.value })?.key
        
        return SleepInsight(
            averageDurationHours: averageDuration,
            mostCommonSleepHour: commonHour,
            totalSleepLogs: sleepLogs.count
        )
    }
    
    /// Analyze feeding patterns
    func analyzeFeedingPatterns(logs: [Log]) -> FeedingInsight? {
        let feedLogs = logs.filter { $0.eventType == .feed }
        
        guard feedLogs.count >= 3 else { return nil }
        
        // Calculate daily intake
        let today = Calendar.current.startOfDay(for: Date())
        let todayLogs = feedLogs.filter {
            Calendar.current.isDate($0.createdAt, inSameDayAs: today)
        }
        
        let todayIntake = todayLogs.compactMap { $0.structuredData?.amount }.reduce(0, +)
        
        // Average feeding interval
        let sortedLogs = feedLogs.sorted { $0.createdAt > $1.createdAt }
        var intervals: [TimeInterval] = []
        for i in 0..<(sortedLogs.count - 1) {
            let interval = sortedLogs[i].createdAt.timeIntervalSince(sortedLogs[i + 1].createdAt)
            intervals.append(interval)
        }
        let averageInterval = intervals.isEmpty ? 0 : intervals.reduce(0, +) / Double(intervals.count)
        
        return FeedingInsight(
            todayIntakeOz: todayIntake,
            averageIntervalHours: averageInterval / 3600,
            totalFeedLogs: feedLogs.count
        )
    }
    
    // MARK: - Private Helpers
    
    private func analyzeTriggers(_ logs: [Log]) -> BehaviorInsight? {
        // Look for common trigger words in notes
        var triggerCounts: [String: Int] = [:]
        
        let triggerKeywords = [
            "screen", "ipad", "tv", "phone",
            "food", "hungry", "tired", "sleepy",
            "toy", "share", "sibling", "brother", "sister",
            "transition", "leaving", "goodbye"
        ]
        
        for log in logs {
            guard let notes = log.structuredData?.notes?.lowercased() else { continue }
            
            for trigger in triggerKeywords {
                if notes.contains(trigger) {
                    triggerCounts[trigger, default: 0] += 1
                }
            }
        }
        
        guard let topTrigger = triggerCounts.max(by: { $0.value < $1.value }),
              topTrigger.value >= 2 else { return nil }
        
        let percentage = Double(topTrigger.value) / Double(logs.count) * 100
        
        return BehaviorInsight(
            type: .trigger,
            title: "Pattern Detected",
            description: "\(Int(percentage))% of incidents involve '\(topTrigger.key)'",
            recommendation: "Consider strategies for managing \(topTrigger.key)-related situations",
            confidence: min(percentage / 100, 0.9)
        )
    }
    
    private func analyzeTimePatterns(_ logs: [Log]) -> BehaviorInsight? {
        // Find patterns based on time of day
        let hourCounts = logs.reduce(into: [Int: Int]()) { counts, log in
            let hour = Calendar.current.component(.hour, from: log.createdAt)
            counts[hour, default: 0] += 1
        }
        
        guard let peakHour = hourCounts.max(by: { $0.value < $1.value }),
              peakHour.value >= 3 else { return nil }
        
        let timeDescription: String
        switch peakHour.key {
        case 6...9: timeDescription = "morning"
        case 10...12: timeDescription = "late morning"
        case 13...15: timeDescription = "early afternoon"
        case 16...18: timeDescription = "late afternoon"
        case 19...21: timeDescription = "evening"
        default: timeDescription = "night"
        }
        
        return BehaviorInsight(
            type: .time,
            title: "Time Pattern",
            description: "Most activity logged in the \(timeDescription) (\(peakHour.key):00)",
            recommendation: "Plan calming activities before this time",
            confidence: 0.7
        )
    }
}

// MARK: - Insight Models

struct BehaviorInsight {
    enum InsightType {
        case trigger
        case time
        case pattern
        case milestone
    }
    
    let type: InsightType
    let title: String
    let description: String
    let recommendation: String
    let confidence: Double // 0-1
}

struct VocabularyInsight {
    let totalWords: Int
    let recentWords: [String]
    let lastUpdated: Date
    
    var assessment: String {
        // Basic CDC milestones comparison
        // 18 months: ~10-50 words
        // 24 months: ~200+ words
        // This is simplified - real assessment needs age context
        switch totalWords {
        case 0...10:
            return "Building vocabulary"
        case 11...50:
            return "Growing well!"
        case 51...200:
            return "Excellent progress!"
        default:
            return "Amazing vocabulary!"
        }
    }
}

struct SleepInsight {
    let averageDurationHours: Double
    let mostCommonSleepHour: Int?
    let totalSleepLogs: Int
    
    var sleepTimeDescription: String? {
        guard let hour = mostCommonSleepHour else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        var components = DateComponents()
        components.hour = hour
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return nil
    }
}

struct FeedingInsight {
    let todayIntakeOz: Double
    let averageIntervalHours: Double
    let totalFeedLogs: Int
    
    var intervalDescription: String {
        let hours = Int(averageIntervalHours)
        let minutes = Int((averageIntervalHours - Double(hours)) * 60)
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes) minutes"
    }
}

