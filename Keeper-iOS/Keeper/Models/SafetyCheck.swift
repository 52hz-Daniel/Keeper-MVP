import Foundation

// MARK: - Safety Check Result
// Reference: MPID Safety Guardrails
// CRITICAL: These are HARD-CODED rules, NOT AI suggestions

struct SafetyCheckResult: Equatable {
    let isSafe: Bool
    let action: SafetyAction
    let warning: String?
    let suggestion: String?
    
    static let safe = SafetyCheckResult(isSafe: true, action: .none, warning: nil, suggestion: nil)
    
    static func warning(_ message: String, suggestion: String? = nil) -> SafetyCheckResult {
        SafetyCheckResult(isSafe: false, action: .warn, warning: message, suggestion: suggestion)
    }
    
    static func danger(_ message: String) -> SafetyCheckResult {
        SafetyCheckResult(isSafe: false, action: .block, warning: message, suggestion: nil)
    }
}

// MARK: - Safety Action
enum SafetyAction: Equatable {
    case none       // Safe, proceed
    case warn       // Show warning, allow override
    case block      // Dangerous, require confirmation with long-press
}

// MARK: - Medication Info (for safety validation)
struct MedicationInfo {
    let name: String
    let amount: Double
    let unit: String
    let childAgeInMonths: Int
    
    // Normalized amount in ml
    var amountInMl: Double {
        switch unit.lowercased() {
        case "ml":
            return amount
        case "tsp", "teaspoon":
            return amount * 5.0 // 1 tsp ≈ 5ml
        case "tbsp", "tablespoon":
            return amount * 15.0 // 1 tbsp ≈ 15ml
        default:
            return amount
        }
    }
}

// MARK: - Known Medications (for validation)
enum KnownMedication: String, CaseIterable {
    case tylenol
    case acetaminophen
    case motrin
    case ibuprofen
    case advil
    case benadryl
    case diphenhydramine
    
    static func identify(from name: String) -> KnownMedication? {
        let lowercased = name.lowercased()
        return KnownMedication.allCases.first { medication in
            lowercased.contains(medication.rawValue)
        }
    }
    
    var genericName: String {
        switch self {
        case .tylenol, .acetaminophen:
            return "Acetaminophen"
        case .motrin, .ibuprofen, .advil:
            return "Ibuprofen"
        case .benadryl, .diphenhydramine:
            return "Diphenhydramine"
        }
    }
    
    var isNSAID: Bool {
        switch self {
        case .motrin, .ibuprofen, .advil:
            return true
        default:
            return false
        }
    }
}

// MARK: - Pre-Natal Safety Flags
enum PrenatalWarning: String {
    case reducedMovement = "reduced_fetal_movement"
    case bleeding = "vaginal_bleeding"
    case severePain = "severe_abdominal_pain"
    case headacheVision = "headache_with_vision_changes" // Preeclampsia indicator
    case contractions = "frequent_contractions"
    
    var alertMessage: String {
        switch self {
        case .reducedMovement:
            return "⚠️ Reduced fetal movement detected. Consider doing a kick count or contacting your provider."
        case .bleeding:
            return "🚨 Vaginal bleeding reported. Please contact your healthcare provider immediately."
        case .severePain:
            return "🚨 Severe abdominal pain reported. Please seek medical attention."
        case .headacheVision:
            return "⚠️ Headache with vision changes can be a sign of preeclampsia. Contact your provider."
        case .contractions:
            return "⚠️ Frequent contractions detected. If they're less than 5 minutes apart, contact your provider."
        }
    }
}

// MARK: - Toddler Safety Flags
enum ToddlerWarning {
    case possibleHarm
    case developmentalRegression
    case severeBehavior
    
    var alertMessage: String {
        switch self {
        case .possibleHarm:
            return "⚠️ This behavior pattern may indicate distress. Consider consulting with your pediatrician."
        case .developmentalRegression:
            return "⚠️ Regression in previously acquired skills noted. This can be normal, but consider a pediatric consultation."
        case .severeBehavior:
            return "⚠️ Repeated aggressive behavior logged. Consider discussing with your pediatrician or child psychologist."
        }
    }
}

