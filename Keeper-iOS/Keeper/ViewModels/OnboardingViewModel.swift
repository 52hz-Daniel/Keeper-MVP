import Foundation
import SwiftUI

// MARK: - Onboarding View Model
// Reference: Keeper Expansion - "Zero-Onboarding" Flow
// "Value must precede commitment" - Show chat interface before asking for signup

@MainActor
final class OnboardingViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentStep: OnboardingStep = .welcome
    @Published var selectedDate: Date = Date()
    @Published var dateType: DateType = .birthday
    @Published var hasCompletedOnboarding: Bool = false
    @Published var calculatedStage: KeeperConstants.Stage = .infant
    @Published var logsConfirmed: Int = 0
    @Published var childName: String?
    
    // Value Threshold - Ask for signup after 5 confirmed logs
    private let valueThreshold = 5
    
    // MARK: - Persistence
    private let defaults = UserDefaults.standard
    private let onboardingKey = "keeper_onboarding_completed"
    private let dateKey = "keeper_anchor_date"
    private let dateTypeKey = "keeper_date_type"
    private let logsConfirmedKey = "keeper_logs_confirmed"
    private let childNameKey = "keeper_child_name"
    
    init() {
        loadState()
    }
    
    // MARK: - Date Type
    enum DateType: String, CaseIterable {
        case dueDate = "due_date"
        case birthday = "birthday"
        
        var displayName: String {
            switch self {
            case .dueDate: return "Due Date"
            case .birthday: return "Birthday"
            }
        }
        
        var prompt: String {
            switch self {
            case .dueDate: return "When is your baby due?"
            case .birthday: return "When was your baby born?"
            }
        }
    }
    
    // MARK: - Onboarding Steps
    enum OnboardingStep {
        case welcome
        case dateSelection
        case immersion  // Go straight to chat
        case valueThreshold  // Ask for signup
        case complete
    }
    
    // MARK: - Stage Calculation
    // Reference: Lifecycle Orchestration - Stage Detection Logic
    func calculateStage() {
        let today = Date()
        
        switch dateType {
        case .dueDate:
            if selectedDate > today {
                calculatedStage = .prenatal
            } else {
                // Due date passed, assume baby is born
                let months = Calendar.current.dateComponents([.month], from: selectedDate, to: today).month ?? 0
                calculatedStage = months < 12 ? .infant : .earlyEd
            }
        case .birthday:
            let months = Calendar.current.dateComponents([.month], from: selectedDate, to: today).month ?? 0
            calculatedStage = months < 12 ? .infant : .earlyEd
        }
    }
    
    // MARK: - Actions
    
    func selectDateType(_ type: DateType) {
        dateType = type
        // Set reasonable default date
        if type == .dueDate {
            // Default to 3 months from now
            selectedDate = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
        } else {
            // Default to today (newborn)
            selectedDate = Date()
        }
    }
    
    func confirmDate() {
        calculateStage()
        saveState()
        currentStep = .immersion
    }
    
    func logConfirmed() {
        logsConfirmed += 1
        defaults.set(logsConfirmed, forKey: logsConfirmedKey)
        
        // Check if we've reached the value threshold
        if logsConfirmed >= valueThreshold && !hasCompletedOnboarding {
            currentStep = .valueThreshold
        }
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
        defaults.set(true, forKey: onboardingKey)
        currentStep = .complete
    }
    
    func skipOnboarding() {
        // Allow skipping but mark as incomplete
        currentStep = .immersion
    }
    
    // MARK: - Persistence
    
    private func loadState() {
        hasCompletedOnboarding = defaults.bool(forKey: onboardingKey)
        logsConfirmed = defaults.integer(forKey: logsConfirmedKey)
        childName = defaults.string(forKey: childNameKey)
        
        if let dateTypeString = defaults.string(forKey: dateTypeKey),
           let type = DateType(rawValue: dateTypeString) {
            dateType = type
        }
        
        if let savedDate = defaults.object(forKey: dateKey) as? Date {
            selectedDate = savedDate
            calculateStage()
            currentStep = hasCompletedOnboarding ? .complete : .immersion
        } else {
            currentStep = .welcome
        }
    }
    
    private func saveState() {
        defaults.set(selectedDate, forKey: dateKey)
        defaults.set(dateType.rawValue, forKey: dateTypeKey)
        if let name = childName {
            defaults.set(name, forKey: childNameKey)
        }
    }
    
    func updateChildName(_ name: String) {
        childName = name
        defaults.set(name, forKey: childNameKey)
    }
    
    func reset() {
        defaults.removeObject(forKey: onboardingKey)
        defaults.removeObject(forKey: dateKey)
        defaults.removeObject(forKey: dateTypeKey)
        defaults.removeObject(forKey: logsConfirmedKey)
        currentStep = .welcome
        hasCompletedOnboarding = false
        logsConfirmed = 0
    }
    
    // MARK: - Stage-Specific Prompts
    // Reference: Lifecycle Orchestration - Step 2: Immediate Immersion
    var immersionPrompt: String {
        switch calculatedStage {
        case .prenatal:
            return "I'm ready. Tell me a symptom you're feeling, or let's start a registry list."
        case .infant:
            return "I'm listening. Tell me when the baby last ate or slept."
        case .earlyEd:
            return "I'm here. Noticed any new words or behaviors today?"
        }
    }
    
    var stageDisplayName: String {
        calculatedStage.displayName
    }
    
    var aiPersona: String {
        calculatedStage.aiPersona
    }
    
    /// Current stage (alias for calculatedStage for easier access)
    var currentStage: KeeperConstants.Stage {
        get { calculatedStage }
        set { calculatedStage = newValue }
    }
}

