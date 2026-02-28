import Foundation
import SwiftUI

// MARK: - Log Store
// Centralized data store for all logs with local persistence
// Philosophy: "Keeper remembers" - We never lose a parent's data

@MainActor
final class LogStore: ObservableObject {
    static let shared = LogStore()
    
    // MARK: - Published Properties
    @Published var logs: [Log] = []
    @Published var feedLogs: [Log] = []
    @Published var sleepLogs: [Log] = []
    @Published var diaperLogs: [Log] = []
    @Published var currentFeedTimer: FeedTimer?
    @Published var currentSleepSession: SleepSession?
    
    // MARK: - Persistence
    private let defaults = UserDefaults.standard
    private let logsKey = "keeper_logs"
    private let feedTimerKey = "keeper_feed_timer"
    private let sleepSessionKey = "keeper_sleep_session"
    
    private init() {
        loadLogs()
        loadActiveTimers()
    }
    
    // MARK: - Today's Stats
    
    var todaysFeedCount: Int {
        feedLogs.filter { Calendar.current.isDateInToday($0.createdAt) }.count
    }
    
    var todaysSleepHours: Double {
        let todaySleepLogs = sleepLogs.filter { Calendar.current.isDateInToday($0.createdAt) }
        return todaySleepLogs.compactMap { $0.structuredData?.amount }.reduce(0, +)
    }
    
    var todaysDiaperCount: Int {
        diaperLogs.filter { Calendar.current.isDateInToday($0.createdAt) }.count
    }
    
    var lastFeedTime: Date? {
        feedLogs.first?.createdAt
    }
    
    var lastDiaperTime: Date? {
        diaperLogs.first?.createdAt
    }
    
    var timeSinceLastFeed: String {
        guard let lastFeed = lastFeedTime else { return "No feeds" }
        let interval = Date().timeIntervalSince(lastFeed)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m ago"
        } else {
            return "\(minutes)m ago"
        }
    }
    
    var awakeTime: String {
        if currentSleepSession != nil {
            return "Sleeping"
        }
        guard let lastSleepEnd = sleepLogs.first?.structuredData?.time else {
            return "Awake"
        }
        let interval = Date().timeIntervalSince(lastSleepEnd)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        return "\(hours)h \(minutes)m awake"
    }
    
    // MARK: - Add Log
    
    func addLog(_ log: Log) {
        logs.insert(log, at: 0)
        
        switch log.eventType {
        case .feed:
            feedLogs.insert(log, at: 0)
        case .sleep:
            sleepLogs.insert(log, at: 0)
        case .diaper:
            diaperLogs.insert(log, at: 0)
        default:
            break
        }
        
        saveLogs()
        HapticsService.shared.logConfirmed()
    }
    
    func updateLog(_ log: Log) {
        if let index = logs.firstIndex(where: { $0.id == log.id }) {
            logs[index] = log
        }
        
        // Update category-specific arrays
        switch log.eventType {
        case .feed:
            if let index = feedLogs.firstIndex(where: { $0.id == log.id }) {
                feedLogs[index] = log
            }
        case .sleep:
            if let index = sleepLogs.firstIndex(where: { $0.id == log.id }) {
                sleepLogs[index] = log
            }
        case .diaper:
            if let index = diaperLogs.firstIndex(where: { $0.id == log.id }) {
                diaperLogs[index] = log
            }
        default:
            break
        }
        
        saveLogs()
    }
    
    func deleteLog(_ log: Log) {
        logs.removeAll { $0.id == log.id }
        feedLogs.removeAll { $0.id == log.id }
        sleepLogs.removeAll { $0.id == log.id }
        diaperLogs.removeAll { $0.id == log.id }
        saveLogs()
    }
    
    // MARK: - Quick Log Methods
    
    func quickLogFeed(type: FeedType, amount: Double? = nil, duration: TimeInterval? = nil, side: BreastSide? = nil) {
        var subtype: String
        var unit: String = "oz"
        var displayAmount = amount
        
        switch type {
        case .breast:
            subtype = side == .left ? "breast_left" : "breast_right"
            unit = "min"
            if let duration = duration {
                displayAmount = duration / 60
            }
        case .bottle:
            subtype = "bottle"
        case .solid:
            subtype = "solid"
            unit = ""
        }
        
        let log = Log(
            familyId: UUID(),
            creatorId: UUID(),
            stageContext: .infant,
            eventType: .feed,
            rawText: nil,
            structuredData: LogData(
                event: "feed",
                subtype: subtype,
                amount: displayAmount,
                unit: displayAmount != nil ? unit : nil,
                drug: nil,
                time: Date(),
                warning: nil,
                notes: side?.rawValue
            ),
            isConfirmed: true
        )
        
        addLog(log)
    }
    
    func quickLogDiaper(type: DiaperLogType) {
        let log = Log(
            familyId: UUID(),
            creatorId: UUID(),
            stageContext: .infant,
            eventType: .diaper,
            rawText: nil,
            structuredData: LogData(
                event: "diaper",
                subtype: type.rawValue,
                amount: nil,
                unit: nil,
                drug: nil,
                time: Date(),
                warning: nil,
                notes: nil
            ),
            isConfirmed: true
        )
        
        addLog(log)
    }
    
    // MARK: - Feed Timer
    
    func startFeedTimer(type: FeedType, side: BreastSide? = nil) {
        currentFeedTimer = FeedTimer(
            startTime: Date(),
            type: type,
            side: side
        )
        saveFeedTimer()
    }
    
    func stopFeedTimer() -> FeedTimer? {
        guard let timer = currentFeedTimer else { return nil }
        currentFeedTimer = nil
        clearFeedTimer()
        return timer
    }
    
    func completeFeedTimer() {
        guard let timer = stopFeedTimer() else { return }
        let duration = Date().timeIntervalSince(timer.startTime)
        quickLogFeed(type: timer.type, duration: duration, side: timer.side)
    }
    
    // MARK: - Sleep Session
    
    func startSleepSession() {
        currentSleepSession = SleepSession(startTime: Date())
        saveSleepSession()
    }
    
    func endSleepSession() {
        guard let session = currentSleepSession else { return }
        let duration = Date().timeIntervalSince(session.startTime)
        let hours = duration / 3600
        
        let log = Log(
            familyId: UUID(),
            creatorId: UUID(),
            stageContext: .infant,
            eventType: .sleep,
            rawText: nil,
            structuredData: LogData(
                event: "sleep",
                subtype: hours >= 2 ? "night_sleep" : "nap",
                amount: hours,
                unit: "hours",
                drug: nil,
                time: Date(),
                warning: nil,
                notes: nil
            ),
            isConfirmed: true
        )
        
        addLog(log)
        currentSleepSession = nil
        clearSleepSession()
    }
    
    // MARK: - Persistence
    
    private func loadLogs() {
        if let data = defaults.data(forKey: logsKey),
           let decoded = try? JSONDecoder().decode([Log].self, from: data) {
            logs = decoded.sorted { $0.createdAt > $1.createdAt }
            feedLogs = logs.filter { $0.eventType == .feed }
            sleepLogs = logs.filter { $0.eventType == .sleep }
            diaperLogs = logs.filter { $0.eventType == .diaper }
        }
    }
    
    private func saveLogs() {
        if let encoded = try? JSONEncoder().encode(logs) {
            defaults.set(encoded, forKey: logsKey)
        }
    }
    
    private func loadActiveTimers() {
        if let data = defaults.data(forKey: feedTimerKey),
           let timer = try? JSONDecoder().decode(FeedTimer.self, from: data) {
            currentFeedTimer = timer
        }
        
        if let data = defaults.data(forKey: sleepSessionKey),
           let session = try? JSONDecoder().decode(SleepSession.self, from: data) {
            currentSleepSession = session
        }
    }
    
    private func saveFeedTimer() {
        if let timer = currentFeedTimer,
           let encoded = try? JSONEncoder().encode(timer) {
            defaults.set(encoded, forKey: feedTimerKey)
        }
    }
    
    private func clearFeedTimer() {
        defaults.removeObject(forKey: feedTimerKey)
    }
    
    private func saveSleepSession() {
        if let session = currentSleepSession,
           let encoded = try? JSONEncoder().encode(session) {
            defaults.set(encoded, forKey: sleepSessionKey)
        }
    }
    
    private func clearSleepSession() {
        defaults.removeObject(forKey: sleepSessionKey)
    }
    
    // MARK: - Recent Logs for Display
    
    func recentLogs(limit: Int = 5) -> [Log] {
        Array(logs.filter { $0.isConfirmed }.prefix(limit))
    }
    
    func logsForToday() -> [Log] {
        logs.filter { Calendar.current.isDateInToday($0.createdAt) }
    }
}

// MARK: - Supporting Types

struct FeedTimer: Codable {
    let startTime: Date
    let type: FeedType
    let side: BreastSide?
    
    var elapsed: TimeInterval {
        Date().timeIntervalSince(startTime)
    }
    
    var elapsedFormatted: String {
        let minutes = Int(elapsed) / 60
        let seconds = Int(elapsed) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct SleepSession: Codable {
    let startTime: Date
    
    var elapsed: TimeInterval {
        Date().timeIntervalSince(startTime)
    }
    
    var elapsedFormatted: String {
        let hours = Int(elapsed) / 3600
        let minutes = (Int(elapsed) % 3600) / 60
        return String(format: "%dh %dm", hours, minutes)
    }
}

enum DiaperLogType: String, Codable {
    case wet = "wet"
    case dirty = "dirty"
    case both = "both"
}

enum BreastSide: String, Codable {
    case left = "left"
    case right = "right"
}

enum FeedType: String, CaseIterable, Codable {
    case breast = "Breast"
    case bottle = "Bottle"
    case solid = "Solid"
}





