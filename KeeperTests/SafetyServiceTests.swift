import XCTest
@testable import Keeper

// MARK: - Safety Service Tests
// Reference: MPID "Testing Strategy (The 'Safety Net')"
// Mandatory: You must write tests for SafetyService covering 20+ scenarios

final class SafetyServiceTests: XCTestCase {
    
    var safetyService: SafetyService!
    
    override func setUp() {
        super.setUp()
        safetyService = SafetyService.shared
    }
    
    // MARK: - Tylenol Tests
    
    func testTylenol_SafeDose() {
        let result = safetyService.checkMedication(
            drug: "Tylenol",
            amount: 2.5,
            unit: "ml",
            ageInMonths: 6
        )
        XCTAssertTrue(result.isSafe)
        XCTAssertEqual(result.action, .none)
    }
    
    func testTylenol_HighDose_Warning() {
        let result = safetyService.checkMedication(
            drug: "Tylenol",
            amount: 10,
            unit: "ml",
            ageInMonths: 6
        )
        XCTAssertFalse(result.isSafe)
        XCTAssertEqual(result.action, .warn)
        XCTAssertNotNil(result.warning)
        XCTAssertTrue(result.warning!.contains("High Dosage"))
    }
    
    func testTylenol_ExtremelyHighDose_Danger() {
        let result = safetyService.checkMedication(
            drug: "Tylenol",
            amount: 50,
            unit: "ml",
            ageInMonths: 6
        )
        XCTAssertFalse(result.isSafe)
        XCTAssertEqual(result.action, .block)
        XCTAssertNotNil(result.warning)
        XCTAssertTrue(result.warning!.contains("DANGER"))
    }
    
    func testAcetaminophen_SameTylenol() {
        let result = safetyService.checkMedication(
            drug: "Acetaminophen",
            amount: 20,
            unit: "ml",
            ageInMonths: 6
        )
        XCTAssertFalse(result.isSafe)
        XCTAssertTrue(result.warning!.contains("DANGER"))
    }
    
    // MARK: - Ibuprofen Tests
    
    func testIbuprofen_Under6Months_Blocked() {
        let result = safetyService.checkMedication(
            drug: "Ibuprofen",
            amount: 2.5,
            unit: "ml",
            ageInMonths: 3
        )
        XCTAssertFalse(result.isSafe)
        XCTAssertEqual(result.action, .block)
        XCTAssertNotNil(result.warning)
        XCTAssertTrue(result.warning!.contains("NOT safe"))
        XCTAssertTrue(result.warning!.contains("under 6 months"))
    }
    
    func testMotrin_Under6Months_Blocked() {
        let result = safetyService.checkMedication(
            drug: "Motrin",
            amount: 2.5,
            unit: "ml",
            ageInMonths: 5
        )
        XCTAssertFalse(result.isSafe)
        XCTAssertEqual(result.action, .block)
    }
    
    func testAdvil_Under6Months_Blocked() {
        let result = safetyService.checkMedication(
            drug: "Advil",
            amount: 2.5,
            unit: "ml",
            ageInMonths: 4
        )
        XCTAssertFalse(result.isSafe)
        XCTAssertEqual(result.action, .block)
    }
    
    func testIbuprofen_Over6Months_SafeDose() {
        let result = safetyService.checkMedication(
            drug: "Ibuprofen",
            amount: 5,
            unit: "ml",
            ageInMonths: 8
        )
        XCTAssertTrue(result.isSafe)
    }
    
    func testIbuprofen_Over6Months_HighDose() {
        let result = safetyService.checkMedication(
            drug: "Ibuprofen",
            amount: 10,
            unit: "ml",
            ageInMonths: 12
        )
        XCTAssertFalse(result.isSafe)
        XCTAssertEqual(result.action, .warn)
    }
    
    func testIbuprofen_ExtremelyHighDose() {
        let result = safetyService.checkMedication(
            drug: "Ibuprofen",
            amount: 20,
            unit: "ml",
            ageInMonths: 12
        )
        XCTAssertFalse(result.isSafe)
        XCTAssertEqual(result.action, .block)
    }
    
    // MARK: - Benadryl Tests
    
    func testBenadryl_Under2Years_Blocked() {
        let result = safetyService.checkMedication(
            drug: "Benadryl",
            amount: 2.5,
            unit: "ml",
            ageInMonths: 18
        )
        XCTAssertFalse(result.isSafe)
        XCTAssertEqual(result.action, .block)
        XCTAssertTrue(result.warning!.contains("under 2 years"))
    }
    
    func testDiphenhydramine_Under2Years_Blocked() {
        let result = safetyService.checkMedication(
            drug: "Diphenhydramine",
            amount: 2.5,
            unit: "ml",
            ageInMonths: 12
        )
        XCTAssertFalse(result.isSafe)
        XCTAssertEqual(result.action, .block)
    }
    
    func testBenadryl_Over2Years_SafeDose() {
        let result = safetyService.checkMedication(
            drug: "Benadryl",
            amount: 5,
            unit: "ml",
            ageInMonths: 36
        )
        XCTAssertTrue(result.isSafe)
    }
    
    func testBenadryl_2to5Years_HighDose() {
        let result = safetyService.checkMedication(
            drug: "Benadryl",
            amount: 10,
            unit: "ml",
            ageInMonths: 36
        )
        XCTAssertFalse(result.isSafe)
        XCTAssertEqual(result.action, .warn)
    }
    
    // MARK: - Missing Dosage Tests
    
    func testMissingDosage_Warning() {
        let result = safetyService.checkMedication(
            drug: "Tylenol",
            amount: 0,
            unit: "ml",
            ageInMonths: 6
        )
        XCTAssertFalse(result.isSafe)
        XCTAssertEqual(result.action, .warn)
        XCTAssertTrue(result.warning!.contains("Dosage not specified"))
    }
    
    func testNaNDosage_Warning() {
        let result = safetyService.checkMedication(
            drug: "Tylenol",
            amount: Double.nan,
            unit: "ml",
            ageInMonths: 6
        )
        XCTAssertFalse(result.isSafe)
    }
    
    // MARK: - Unit Conversion Tests
    
    func testTeaspoonConversion() {
        // 1 tsp = 5ml, so 4 tsp = 20ml (very high)
        let result = safetyService.checkMedication(
            drug: "Tylenol",
            amount: 4,
            unit: "tsp",
            ageInMonths: 6
        )
        XCTAssertFalse(result.isSafe)
        XCTAssertEqual(result.action, .block) // 20ml is danger level
    }
    
    func testTablespoonConversion() {
        // 1 tbsp = 15ml (at danger level)
        let result = safetyService.checkMedication(
            drug: "Tylenol",
            amount: 1,
            unit: "tbsp",
            ageInMonths: 6
        )
        XCTAssertFalse(result.isSafe) // 15ml exceeds safe range
    }
    
    // MARK: - Unknown Medication Tests
    
    func testUnknownMedication_Warning() {
        let result = safetyService.checkMedication(
            drug: "SomeUnknownDrug",
            amount: 5,
            unit: "ml",
            ageInMonths: 6
        )
        XCTAssertFalse(result.isSafe)
        XCTAssertEqual(result.action, .warn)
        XCTAssertTrue(result.warning!.contains("Unknown medication"))
    }
    
    // MARK: - Edge Cases
    
    func testBoundaryAge_Ibuprofen_Exactly6Months() {
        let result = safetyService.checkMedication(
            drug: "Ibuprofen",
            amount: 5,
            unit: "ml",
            ageInMonths: 6 // Exactly 6 months - should be safe
        )
        XCTAssertTrue(result.isSafe)
    }
    
    func testBoundaryAge_Ibuprofen_JustUnder6Months() {
        let result = safetyService.checkMedication(
            drug: "Ibuprofen",
            amount: 5,
            unit: "ml",
            ageInMonths: 5 // Just under 6 months - should block
        )
        XCTAssertFalse(result.isSafe)
        XCTAssertEqual(result.action, .block)
    }
    
    func testCaseInsensitive_Tylenol() {
        let result1 = safetyService.checkMedication(drug: "TYLENOL", amount: 20, unit: "ml", ageInMonths: 6)
        let result2 = safetyService.checkMedication(drug: "tylenol", amount: 20, unit: "ml", ageInMonths: 6)
        let result3 = safetyService.checkMedication(drug: "TyLeNoL", amount: 20, unit: "ml", ageInMonths: 6)
        
        XCTAssertEqual(result1.action, result2.action)
        XCTAssertEqual(result2.action, result3.action)
    }
    
    func testPartialMatch_InfantsTylenol() {
        let result = safetyService.checkMedication(
            drug: "Infants' Tylenol Oral Suspension",
            amount: 20,
            unit: "ml",
            ageInMonths: 6
        )
        XCTAssertFalse(result.isSafe)
        XCTAssertEqual(result.action, .block)
    }
    
    // MARK: - Log Data Safety Check Tests
    
    func testLogDataSafetyCheck_MedicationWithWarning() {
        let logData = LogData(
            event: "medication",
            subtype: nil,
            amount: 20,
            unit: "ml",
            drug: "Tylenol",
            time: Date(),
            warning: nil,
            notes: nil
        )
        
        let result = safetyService.checkSafety(
            logData: logData,
            childAgeInMonths: 6,
            stage: .infant
        )
        
        XCTAssertFalse(result.isSafe)
    }
    
    func testLogDataSafetyCheck_NonMedication_Safe() {
        let logData = LogData(
            event: "feed",
            subtype: "formula",
            amount: 4,
            unit: "oz",
            drug: nil,
            time: Date(),
            warning: nil,
            notes: nil
        )
        
        let result = safetyService.checkSafety(
            logData: logData,
            childAgeInMonths: 6,
            stage: .infant
        )
        
        XCTAssertTrue(result.isSafe)
    }
}

