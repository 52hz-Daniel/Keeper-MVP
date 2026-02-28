import UIKit

// MARK: - Haptics Service
// Reference: Brand Strategy - "Haptic Reassurance"
// Every "Save" action must have a subtle haptic "thud."
// The parent needs physical confirmation that the memory is safe.

final class HapticsService {
    
    // MARK: - Singleton
    static let shared = HapticsService()
    private init() {}
    
    // MARK: - Feedback Generators
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()
    
    // MARK: - Prepare (call before expected feedback)
    
    func prepare() {
        impactLight.prepare()
        impactMedium.prepare()
        notificationGenerator.prepare()
    }
    
    // MARK: - Standard Haptics
    
    /// Light tap for button presses
    func lightTap() {
        impactLight.impactOccurred()
    }
    
    /// Medium tap for confirmations
    func mediumTap() {
        impactMedium.impactOccurred()
    }
    
    /// Heavy tap for important actions
    func heavyTap() {
        impactHeavy.impactOccurred()
    }
    
    /// Selection changed (scrolling, picker)
    func selection() {
        selectionGenerator.selectionChanged()
    }
    
    // MARK: - Keeper-Specific Haptics
    
    /// Success feedback - Log confirmed
    /// Reference: "Success: Light vibration when a log is Confirmed."
    func logConfirmed() {
        notificationGenerator.notificationOccurred(.success)
    }
    
    /// Warning feedback - Safety guardrail triggered
    /// Reference: "Warning: Heavy/Double vibration if Safety Guardrail is triggered."
    func safetyWarning() {
        // Double heavy vibration for warnings
        impactHeavy.impactOccurred()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.impactHeavy.impactOccurred()
        }
    }
    
    /// Danger feedback - Critical safety alert
    func safetyDanger() {
        // Triple heavy vibration for danger
        notificationGenerator.notificationOccurred(.error)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.impactHeavy.impactOccurred()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.impactHeavy.impactOccurred()
        }
    }
    
    /// Recording started
    func recordingStarted() {
        impactMedium.impactOccurred()
    }
    
    /// Recording stopped
    func recordingStopped() {
        impactLight.impactOccurred()
    }
    
    /// Message sent
    func messageSent() {
        impactLight.impactOccurred()
    }
    
    /// Error feedback
    func error() {
        notificationGenerator.notificationOccurred(.error)
    }
    
    // MARK: - Haptic for Safety Result
    
    func feedback(for result: SafetyCheckResult) {
        switch result.action {
        case .none:
            break // No haptic for safe
        case .warn:
            safetyWarning()
        case .block:
            safetyDanger()
        }
    }
}

