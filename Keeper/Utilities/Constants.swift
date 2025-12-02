import Foundation
import SwiftUI

// MARK: - Keeper Constants
// Reference: MPID, Brand Strategy & Design Philosophy

enum KeeperConstants {
    
    // MARK: - App Info
    static let appName = "Keeper"
    static let tagline = "Keeper remembers, so you can sleep."
    static let aiPersona = "Family Chief of Staff"
    
    // MARK: - UI Standards (The "3:00 AM Test")
    enum UI {
        /// Minimum touch target size (Fat Finger Standard)
        static let minTouchTarget: CGFloat = 48
        
        /// Large button size (Mic, Confirm)
        static let largeButtonSize: CGFloat = 64
        
        /// Base text size (scaled up 10%)
        static let baseTextSize: CGFloat = 18
        
        /// Small text size
        static let smallTextSize: CGFloat = 14
        
        /// Large title size
        static let titleSize: CGFloat = 24
        
        /// Standard corner radius
        static let cornerRadius: CGFloat = 16
        
        /// Card corner radius
        static let cardRadius: CGFloat = 20
        
        /// Standard padding
        static let padding: CGFloat = 16
        
        /// Bottom safe area for thumb zone
        static let bottomSafeArea: CGFloat = 100
        
        /// Animation duration
        static let animationDuration: Double = 0.3
    }
    
    // MARK: - Safety Limits (HARD-CODED - NOT AI)
    enum Safety {
        /// Maximum Tylenol dose for infants (ml)
        static let maxTylenolDose: Double = 15.0
        
        /// Standard infant Tylenol dose range (ml)
        static let standardTylenolRange = 1.25...5.0
        
        /// Minimum age for Ibuprofen (months)
        static let minIbuprofenAge: Int = 6
        
        /// Maximum infant Ibuprofen dose (ml)
        static let maxIbuprofenDose: Double = 7.5
        
        /// High fever threshold (°F)
        static let highFeverThreshold: Double = 104.0
        
        /// Fever threshold (°F)
        static let feverThreshold: Double = 100.4
    }
    
    // MARK: - Lifecycle Stages
    enum Stage: String, CaseIterable, Codable {
        case prenatal = "prenatal"
        case infant = "infant"
        case earlyEd = "toddler"
        
        var displayName: String {
            switch self {
            case .prenatal: return "Pre-Natal"
            case .infant: return "Infant"
            case .earlyEd: return "Early Education"
            }
        }
        
        var aiPersona: String {
            switch self {
            case .prenatal: return "The Project Manager"
            case .infant: return "The Night Nurse"
            case .earlyEd: return "The Pattern Keeper"
            }
        }
        
        var theme: LifecycleTheme {
            switch self {
            case .prenatal: return .dawn
            case .infant: return .midnight
            case .earlyEd: return .daylight
            }
        }
    }
    
    // MARK: - Event Types
    enum EventType: String, CaseIterable, Identifiable, Codable {
        case feed = "feed"
        case sleep = "sleep"
        case diaper = "diaper"
        case medication = "medication"
        case symptom = "symptom"
        case milestone = "milestone"
        case note = "note"
        case growth = "growth"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .feed: return "Feed"
            case .sleep: return "Sleep"
            case .diaper: return "Diaper"
            case .medication: return "Medication"
            case .symptom: return "Symptom"
            case .milestone: return "Milestone"
            case .note: return "Note"
            case .growth: return "Growth"
            }
        }
        
        var icon: String {
            switch self {
            case .feed: return "cup.and.saucer.fill"
            case .sleep: return "moon.fill"
            case .diaper: return "humidity.fill"
            case .medication: return "pill.fill"
            case .symptom: return "heart.text.square.fill"
            case .milestone: return "star.fill"
            case .note: return "note.text"
            case .growth: return "chart.line.uptrend.xyaxis"
            }
        }
        
        var isMedical: Bool {
            switch self {
            case .medication, .symptom:
                return true
            default:
                return false
            }
        }
    }
    
    // MARK: - AI Configuration
    enum AI {
        static let model = "gpt-4o-mini"
        static let maxTokens = 500
        static let temperature = 0.3 // Low temperature for consistent parsing
        
        /// Audio retention period (hours)
        static let audioRetentionHours = 48
        
        /// Retry attempts for failed AI calls
        static let maxRetryAttempts = 3
        
        /// Retry delay (seconds)
        static let retryDelay: TimeInterval = 5 * 60 // 5 minutes
    }
    
    // MARK: - Notification Rules
    enum Notifications {
        /// Debounce period for notification triggers (seconds)
        static let debouncePeriod: TimeInterval = 60
        
        /// Significant fields that trigger partner notification
        static let significantFields = ["medication_amount", "time", "event_type"]
    }
}

// MARK: - System Prompts
extension KeeperConstants {
    
    static func systemPrompt(for stage: Stage, currentDate: Date = Date()) -> String {
        let dateFormatter = ISO8601DateFormatter()
        let dateString = dateFormatter.string(from: currentDate)
        
        let basePrompt = """
        You are Keeper, the Family Chief of Staff. Your job is to extract structured parenting data from natural language.
        Tone: Calm, Brief, Alert, Warm. (e.g., 'Logged.' not 'Great job mama!')
        Current Date: \(dateString)
        
        CRITICAL: You are a DATA LOGGER. You are NOT a doctor. Do not give medical advice.
        
        OUTPUT FORMAT (JSON):
        {
            "event": "feed|sleep|diaper|medication|symptom|milestone|note",
            "subtype": "formula|breast|wet|dirty|mixed|...",
            "amount": <number or null>,
            "unit": "oz|ml|min|hours",
            "drug": "<medication name if applicable>",
            "time": "ISO8601 timestamp",
            "warning": "missing_dosage|high_dose|null",
            "notes": "<any additional context>"
        }
        
        EXAMPLES:
        INPUT: 'He drank 4oz of milk.'
        OUTPUT: {"event": "feed", "subtype": "formula", "amount": 4, "unit": "oz", "time": "current_time"}
        
        INPUT: 'Gave him Tylenol.'
        OUTPUT: {"event": "medication", "drug": "Tylenol", "amount": null, "warning": "missing_dosage"}
        
        INPUT: 'She slept for 2 hours'
        OUTPUT: {"event": "sleep", "amount": 2, "unit": "hours", "time": "current_time"}
        
        """
        
        let stagePrompt: String
        switch stage {
        case .prenatal:
            stagePrompt = """
            STAGE: Pre-Natal
            PERSONA: The Project Manager - Vigilant, Medical, List-focused
            
            SPECIAL RULES:
            - If user mentions bleeding, severe pain, or reduced fetal movement, immediately flag with warning.
            - Focus on symptoms, preparations, and logistics.
            - Track kick counts, contractions, and symptoms carefully.
            """
        case .infant:
            stagePrompt = """
            STAGE: Infant (0-12 months)
            PERSONA: The Night Nurse - Brief, Efficient, Survival-focused
            
            SPECIAL RULES:
            - Optimize for SPEED. Parents are exhausted.
            - If medication seems high, flag it in warning field.
            - Track: feeds, diapers, sleep, medications precisely.
            """
        case .earlyEd:
            stagePrompt = """
            STAGE: Early Education (1-5 years)
            PERSONA: The Pattern Keeper - Analytical, Connecting dots, Educational
            
            SPECIAL RULES:
            - Look for behavioral patterns and triggers.
            - Track milestones, vocabulary, behaviors.
            - If behavior suggests physical harm or regression, suggest pediatrician consult.
            """
        }
        
        return basePrompt + stagePrompt
    }
}

