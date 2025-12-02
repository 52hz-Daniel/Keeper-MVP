import Foundation

// MARK: - Safety Service
// Reference: MPID Safety Guardrails
// CRITICAL: These are HARD-CODED rules. The AI is for parsing, CODE is for safety.
// Rule: Never bypass these checks. They are the "Brake" of the application.

final class SafetyService {
    
    // MARK: - Singleton
    static let shared = SafetyService()
    private init() {}
    
    // MARK: - Main Safety Check
    
    /// Check safety for any log data
    /// - Parameters:
    ///   - logData: The parsed log data from AI
    ///   - childAgeInMonths: The child's age in months
    ///   - stage: Current lifecycle stage
    /// - Returns: SafetyCheckResult indicating if the data is safe
    func checkSafety(
        logData: LogData,
        childAgeInMonths: Int,
        stage: KeeperConstants.Stage = .infant
    ) -> SafetyCheckResult {
        
        // Medical events require extra scrutiny
        if logData.isMedication {
            return checkMedication(
                drug: logData.drug ?? "",
                amount: logData.amount ?? 0,
                unit: logData.unit ?? "ml",
                ageInMonths: childAgeInMonths
            )
        }
        
        // Check for pre-natal warnings
        if stage == .prenatal {
            if let warning = checkPrenatalSymptom(logData) {
                return warning
            }
        }
        
        // Check for toddler behavioral concerns
        if stage == .earlyEd {
            if let warning = checkToddlerBehavior(logData) {
                return warning
            }
        }
        
        return .safe
    }
    
    // MARK: - Medication Checks (CRITICAL)
    
    /// Check medication safety
    /// RULE: Hard-coded limits. No AI involvement.
    func checkMedication(
        drug: String,
        amount: Double,
        unit: String,
        ageInMonths: Int
    ) -> SafetyCheckResult {
        
        let drugLower = drug.lowercased()
        let medication = KnownMedication.identify(from: drugLower)
        
        // Normalize to ml
        let amountInMl = normalizeToMl(amount: amount, unit: unit)
        
        // Check for missing dosage
        if amount == 0 || amount.isNaN {
            return .warning(
                "⚠️ Dosage not specified. Please add the amount given.",
                suggestion: "Add dosage (e.g., 2.5ml)"
            )
        }
        
        // RULE: Tylenol/Acetaminophen checks
        if let med = medication, med == .tylenol || med == .acetaminophen {
            return checkTylenol(amountInMl: amountInMl, ageInMonths: ageInMonths)
        }
        
        // RULE: Ibuprofen/Motrin checks (BLOCKED under 6 months)
        if let med = medication, med.isNSAID {
            return checkIbuprofen(amountInMl: amountInMl, ageInMonths: ageInMonths)
        }
        
        // RULE: Benadryl checks
        if let med = medication, med == .benadryl || med == .diphenhydramine {
            return checkBenadryl(amountInMl: amountInMl, ageInMonths: ageInMonths)
        }
        
        // Unknown medication - flag for review
        if medication == nil && !drugLower.isEmpty {
            return .warning(
                "⚠️ Unknown medication: '\(drug)'. Please verify dosage is correct.",
                suggestion: nil
            )
        }
        
        return .safe
    }
    
    // MARK: - Specific Drug Checks
    
    /// Tylenol (Acetaminophen) safety check
    private func checkTylenol(amountInMl: Double, ageInMonths: Int) -> SafetyCheckResult {
        let maxDose = KeeperConstants.Safety.maxTylenolDose // 15ml
        let standardRange = KeeperConstants.Safety.standardTylenolRange // 1.25-5.0ml
        
        // DANGER: Way too high
        if amountInMl > maxDose {
            return .danger(
                "⛔ DANGER: \(Int(amountInMl))ml is an extremely high dose of Tylenol. " +
                "Standard infant dose is \(standardRange.lowerBound)-\(standardRange.upperBound)ml. " +
                "Please verify this is correct."
            )
        }
        
        // WARNING: Higher than typical
        if amountInMl > standardRange.upperBound {
            return .warning(
                "⚠️ High Dosage Detected (\(Int(amountInMl))ml). " +
                "Standard infant dose is usually \(standardRange.lowerBound)-\(standardRange.upperBound)ml depending on weight.",
                suggestion: "Correct to \(standardRange.upperBound)ml"
            )
        }
        
        return .safe
    }
    
    /// Ibuprofen (Motrin/Advil) safety check
    private func checkIbuprofen(amountInMl: Double, ageInMonths: Int) -> SafetyCheckResult {
        let minAge = KeeperConstants.Safety.minIbuprofenAge // 6 months
        let maxDose = KeeperConstants.Safety.maxIbuprofenDose // 7.5ml
        
        // BLOCK: Too young for Ibuprofen
        if ageInMonths < minAge {
            return .danger(
                "⛔ DANGER: Ibuprofen is NOT safe for infants under \(minAge) months old. " +
                "Baby is \(ageInMonths) months old. Use Tylenol (Acetaminophen) instead."
            )
        }
        
        // DANGER: Way too high
        if amountInMl > maxDose * 2 {
            return .danger(
                "⛔ DANGER: \(Int(amountInMl))ml is an extremely high dose of Ibuprofen. " +
                "Maximum infant dose is typically \(maxDose)ml."
            )
        }
        
        // WARNING: Higher than typical
        if amountInMl > maxDose {
            return .warning(
                "⚠️ High Dosage Detected (\(Int(amountInMl))ml). " +
                "Standard infant Ibuprofen dose is usually 2.5-\(maxDose)ml depending on weight.",
                suggestion: "Correct to \(maxDose)ml"
            )
        }
        
        return .safe
    }
    
    /// Benadryl (Diphenhydramine) safety check
    private func checkBenadryl(amountInMl: Double, ageInMonths: Int) -> SafetyCheckResult {
        // BLOCK: Too young for Benadryl
        if ageInMonths < 24 { // Under 2 years
            return .danger(
                "⛔ DANGER: Benadryl is NOT recommended for children under 2 years old. " +
                "Consult your pediatrician before giving any antihistamines."
            )
        }
        
        // WARNING: Check dosage for 2-5 year olds
        if ageInMonths < 60 && amountInMl > 5.0 {
            return .warning(
                "⚠️ High Dosage for age (\(Int(amountInMl))ml). " +
                "For children 2-5 years, typical dose is 2.5-5ml.",
                suggestion: "Correct to 5ml"
            )
        }
        
        return .safe
    }
    
    // MARK: - Pre-Natal Symptom Checks
    
    /// Check for concerning pre-natal symptoms
    private func checkPrenatalSymptom(_ logData: LogData) -> SafetyCheckResult? {
        guard let notes = logData.notes?.lowercased() else { return nil }
        
        // Keywords for immediate concern
        let bleedingKeywords = ["bleeding", "blood", "spotting", "hemorrhage"]
        let movementKeywords = ["no movement", "not moving", "stopped moving", "less movement", "reduced movement"]
        let painKeywords = ["severe pain", "sharp pain", "intense pain", "unbearable pain"]
        let preeclampsiaKeywords = ["headache", "vision", "blurry", "seeing spots", "swelling"]
        let contractionKeywords = ["contractions", "contracting"]
        
        // Check for bleeding
        if bleedingKeywords.contains(where: notes.contains) {
            return .danger(PrenatalWarning.bleeding.alertMessage)
        }
        
        // Check for reduced movement
        if movementKeywords.contains(where: notes.contains) {
            return .warning(PrenatalWarning.reducedMovement.alertMessage)
        }
        
        // Check for severe pain
        if painKeywords.contains(where: notes.contains) {
            return .danger(PrenatalWarning.severePain.alertMessage)
        }
        
        // Check for preeclampsia indicators
        let hasHeadache = notes.contains("headache")
        let hasVision = preeclampsiaKeywords.dropFirst().contains(where: notes.contains)
        if hasHeadache && hasVision {
            return .warning(PrenatalWarning.headacheVision.alertMessage)
        }
        
        // Check for frequent contractions
        if contractionKeywords.contains(where: notes.contains) {
            // Simple heuristic - actual frequency would need more context
            return .warning(PrenatalWarning.contractions.alertMessage)
        }
        
        return nil
    }
    
    // MARK: - Toddler Behavior Checks
    
    /// Check for concerning toddler behaviors
    private func checkToddlerBehavior(_ logData: LogData) -> SafetyCheckResult? {
        guard logData.event == "behavior" else { return nil }
        guard let notes = logData.notes?.lowercased() else { return nil }
        
        // Keywords for behavioral concerns
        let harmKeywords = ["hitting", "biting", "scratching", "hurting", "aggressive"]
        let regressionKeywords = ["stopped talking", "stopped walking", "regression", "lost skill"]
        
        // Check for repeated aggression patterns
        if harmKeywords.contains(where: notes.contains) {
            return .warning(ToddlerWarning.possibleHarm.alertMessage)
        }
        
        // Check for developmental regression
        if regressionKeywords.contains(where: notes.contains) {
            return .warning(ToddlerWarning.developmentalRegression.alertMessage)
        }
        
        return nil
    }
    
    // MARK: - Utility Functions
    
    /// Normalize medication amount to ml
    private func normalizeToMl(amount: Double, unit: String) -> Double {
        switch unit.lowercased() {
        case "ml", "milliliter", "milliliters":
            return amount
        case "tsp", "teaspoon", "teaspoons":
            return amount * 5.0
        case "tbsp", "tablespoon", "tablespoons":
            return amount * 15.0
        case "cc":
            return amount // cc = ml
        default:
            return amount // Assume ml if unknown
        }
    }
}

// MARK: - Extension for String matching
private extension String {
    func containsAny(_ keywords: [String]) -> Bool {
        keywords.contains { self.contains($0) }
    }
}

