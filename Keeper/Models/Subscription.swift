import Foundation

// MARK: - Subscription Model
// Reference: User requirement - 14-day free trial, premium vs free tiers

struct Subscription: Codable {
    let id: UUID
    let userId: UUID
    var tier: SubscriptionTier
    var status: SubscriptionStatus
    let trialStartDate: Date?
    let trialEndDate: Date?
    var subscriptionStartDate: Date?
    var subscriptionEndDate: Date?
    var autoRenew: Bool
    var paymentMethodAdded: Bool
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        tier: SubscriptionTier = .free,
        status: SubscriptionStatus = .trial,
        trialStartDate: Date? = Date(),
        autoRenew: Bool = false,
        paymentMethodAdded: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.tier = tier
        self.status = status
        self.trialStartDate = trialStartDate
        self.trialEndDate = trialStartDate?.addingTimeInterval(14 * 24 * 60 * 60) // 14 days
        self.subscriptionStartDate = nil
        self.subscriptionEndDate = nil
        self.autoRenew = autoRenew
        self.paymentMethodAdded = paymentMethodAdded
    }
    
    // MARK: - Computed Properties
    
    var isTrialActive: Bool {
        guard status == .trial, let endDate = trialEndDate else { return false }
        return Date() < endDate
    }
    
    var trialDaysRemaining: Int {
        guard let endDate = trialEndDate else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
        return max(0, days)
    }
    
    var isPremium: Bool {
        return isTrialActive || status == .active
    }
    
    var shouldPromptForSubscription: Bool {
        // Prompt when trial is ending (3 days or less)
        return isTrialActive && trialDaysRemaining <= 3
    }
    
    var trialExpired: Bool {
        guard let endDate = trialEndDate else { return false }
        return Date() >= endDate && status == .trial
    }
}

// MARK: - Subscription Tier
enum SubscriptionTier: String, Codable, CaseIterable {
    case free = "free"
    case premium = "premium"
    
    var displayName: String {
        switch self {
        case .free: return "Free"
        case .premium: return "Premium"
        }
    }
    
    var monthlyPrice: Double {
        switch self {
        case .free: return 0
        case .premium: return 9.99
        }
    }
    
    var yearlyPrice: Double {
        switch self {
        case .free: return 0
        case .premium: return 99.00 // ~$8.25/mo
        }
    }
}

// MARK: - Subscription Status
enum SubscriptionStatus: String, Codable {
    case none = "none"           // Never had subscription
    case trial = "trial"         // In 14-day trial
    case active = "active"       // Paying subscriber
    case cancelled = "cancelled" // Cancelled but may still have access until period ends
    case expired = "expired"     // Trial or subscription expired
}

// MARK: - Premium Features
enum PremiumFeature: String, CaseIterable {
    case voiceLogging = "voice_logging"
    case aiParsing = "ai_parsing"
    case patternInsights = "pattern_insights"
    case unlimitedLogs = "unlimited_logs"
    case exportData = "export_data"
    case partnerSync = "partner_sync"
    case advancedMilestones = "advanced_milestones"
    case customReminders = "custom_reminders"
    
    var displayName: String {
        switch self {
        case .voiceLogging: return "Voice Logging"
        case .aiParsing: return "AI-Powered Parsing"
        case .patternInsights: return "Pattern Insights"
        case .unlimitedLogs: return "Unlimited Logs"
        case .exportData: return "Export Your Data"
        case .partnerSync: return "Partner Sync"
        case .advancedMilestones: return "Advanced Milestones"
        case .customReminders: return "Custom Reminders"
        }
    }
    
    var description: String {
        switch self {
        case .voiceLogging: return "Log hands-free with your voice"
        case .aiParsing: return "AI understands natural language"
        case .patternInsights: return "Discover sleep & feeding patterns"
        case .unlimitedLogs: return "No limits on daily logs"
        case .exportData: return "Download your data anytime"
        case .partnerSync: return "Real-time sync with partner"
        case .advancedMilestones: return "Detailed development tracking"
        case .customReminders: return "Set personalized reminders"
        }
    }
    
    var icon: String {
        switch self {
        case .voiceLogging: return "mic.fill"
        case .aiParsing: return "brain"
        case .patternInsights: return "chart.line.uptrend.xyaxis"
        case .unlimitedLogs: return "infinity"
        case .exportData: return "square.and.arrow.up"
        case .partnerSync: return "person.2.fill"
        case .advancedMilestones: return "star.fill"
        case .customReminders: return "bell.fill"
        }
    }
}

// MARK: - Free Tier Limits
enum FreeTierLimits {
    static let dailyLogs = 10
    static let historyDays = 7 // Can only view last 7 days
    static let exportEnabled = false
    static let voiceEnabled = false
    static let insightsEnabled = false
}

