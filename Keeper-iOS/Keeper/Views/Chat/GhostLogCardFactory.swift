import SwiftUI

// MARK: - Ghost Log Card Factory
// Reference: Lifecycle Orchestration - "Ghost Log Component Factory"
// The UI component must be smart enough to render different "Cards" based on the data type

struct GhostLogCardFactory: View {
    let log: Log
    let onConfirm: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        switch log.stageContext {
        case .prenatal:
            PrenatalLogCard(log: log, onConfirm: onConfirm, onEdit: onEdit)
        case .infant:
            GhostLogCard(log: log, onConfirm: onConfirm, onEdit: onEdit)
        case .earlyEd:
            ToddlerLogCard(log: log, onConfirm: onConfirm, onEdit: onEdit)
        }
    }
}

// MARK: - Pre-Natal Log Card (Symptom Card)
// Focus on severity & doctor notes
struct PrenatalLogCard: View {
    let log: Log
    let onConfirm: () -> Void
    let onEdit: () -> Void
    
    private var data: LogData? { log.structuredData }
    private var hasWarning: Bool { data?.hasWarning ?? false }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with pregnancy-specific styling
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(hasWarning ? Color.sunsetCoral.opacity(0.2) : Color.pink.opacity(0.2))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: prenatalIcon)
                        .font(.system(size: 22))
                        .foregroundColor(hasWarning ? .sunsetCoral : .pink)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(prenatalTitle)
                        .font(.system(size: KeeperConstants.UI.baseTextSize, weight: .bold))
                        .foregroundColor(hasWarning ? .sunsetCoral : .starlightCream)
                    
                    if let severity = extractSeverity() {
                        SeverityIndicator(level: severity)
                    }
                }
                
                Spacer()
                
                if hasWarning {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.sunsetCoral)
                        .symbolEffect(.pulse)
                }
            }
            
            // Symptom details
            if let notes = data?.notes, !notes.isEmpty {
                Text(notes)
                    .font(.system(size: KeeperConstants.UI.smallTextSize))
                    .foregroundColor(.dimStar)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.deepSlate.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            // Warning for prenatal concerns
            if let warning = data?.warning {
                HStack(spacing: 8) {
                    Image(systemName: "heart.text.square.fill")
                        .foregroundColor(.sunsetCoral)
                    
                    Text(warning)
                        .font(.system(size: KeeperConstants.UI.smallTextSize, weight: .medium))
                        .foregroundColor(.sunsetCoral)
                }
                .padding(12)
                .background(Color.warningBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Doctor note prompt
            if !log.isConfirmed {
                HStack(spacing: 8) {
                    Image(systemName: "stethoscope")
                        .foregroundColor(.dimStar)
                    Text("Consider noting this for your next appointment")
                        .font(.system(size: 12))
                        .foregroundColor(.dimStar)
                }
            }
            
            // Action buttons
            if !log.isConfirmed {
                actionButtons
            }
        }
        .padding(KeeperConstants.UI.padding)
        .background(
            RoundedRectangle(cornerRadius: KeeperConstants.UI.cardRadius)
                .fill(hasWarning ? Color.warningBackground : Color(hex: "3D1A3D").opacity(0.3))
        )
        .overlay(
            RoundedRectangle(cornerRadius: KeeperConstants.UI.cardRadius)
                .stroke(
                    hasWarning ? Color.sunsetCoral.opacity(0.5) : Color.pink.opacity(0.3),
                    style: log.isConfirmed ? StrokeStyle(lineWidth: 1) : StrokeStyle(lineWidth: 2, dash: [8, 4])
                )
        )
    }
    
    private var prenatalIcon: String {
        switch data?.event {
        case "symptom": return "heart.text.square.fill"
        case "appointment": return "calendar.badge.clock"
        case "medication": return "pill.fill"
        case "kickcount": return "figure.wave"
        default: return "heart.fill"
        }
    }
    
    private var prenatalTitle: String {
        switch data?.event {
        case "symptom": return "Symptom"
        case "appointment": return "Appointment"
        case "medication": return "Medication"
        case "kickcount": return "Kick Count"
        default: return "Note"
        }
    }
    
    private func extractSeverity() -> Int? {
        // Try to extract severity from notes or amount
        if let amount = data?.amount {
            return min(max(Int(amount), 1), 10)
        }
        return nil
    }
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button(action: onConfirm) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .bold))
                    Text("Log It")
                        .font(.system(size: KeeperConstants.UI.baseTextSize, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: KeeperConstants.UI.minTouchTarget)
                .background(Color.pink)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.system(size: 20))
                    .foregroundColor(.dimStar)
                    .frame(width: KeeperConstants.UI.minTouchTarget, height: KeeperConstants.UI.minTouchTarget)
                    .background(Color.deepSlate)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }
}

// MARK: - Severity Indicator
struct SeverityIndicator: View {
    let level: Int // 1-10
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { i in
                Circle()
                    .fill(i <= normalizedLevel ? severityColor : Color.slateGray)
                    .frame(width: 8, height: 8)
            }
            
            Text("Severity: \(level)/10")
                .font(.system(size: 12))
                .foregroundColor(.dimStar)
                .padding(.leading, 4)
        }
    }
    
    private var normalizedLevel: Int {
        (level + 1) / 2 // Convert 1-10 to 1-5
    }
    
    private var severityColor: Color {
        switch level {
        case 1...3: return .safeGreen
        case 4...6: return .yellow
        case 7...8: return .orange
        default: return .sunsetCoral
        }
    }
}

// MARK: - Toddler Log Card (Insight Card)
// Focus on behavior triggers & photos
struct ToddlerLogCard: View {
    let log: Log
    let onConfirm: () -> Void
    let onEdit: () -> Void
    
    private var data: LogData? { log.structuredData }
    private var hasWarning: Bool { data?.hasWarning ?? false }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with toddler-specific styling
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(toddlerColor.opacity(0.2))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: toddlerIcon)
                        .font(.system(size: 22))
                        .foregroundColor(toddlerColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(toddlerTitle)
                        .font(.system(size: KeeperConstants.UI.baseTextSize, weight: .bold))
                        .foregroundColor(.starlightCream)
                    
                    if let subtype = data?.subtype {
                        Text(subtype.capitalized)
                            .font(.system(size: KeeperConstants.UI.smallTextSize))
                            .foregroundColor(.dimStar)
                    }
                }
                
                Spacer()
                
                // Time badge
                Text(formattedTime)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.dimStar)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.deepSlate)
                    .clipShape(Capsule())
            }
            
            // Behavior trigger analysis
            if isBehaviorLog, let notes = data?.notes {
                BehaviorTriggerView(notes: notes)
            }
            
            // Milestone celebration
            if isMilestoneLog {
                MilestoneCelebration(data: data)
            }
            
            // Standard notes
            if !isBehaviorLog && !isMilestoneLog, let notes = data?.notes, !notes.isEmpty {
                Text(notes)
                    .font(.system(size: KeeperConstants.UI.smallTextSize))
                    .foregroundColor(.dimStar)
            }
            
            // Warning
            if let warning = data?.warning {
                HStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.sunsetCoral)
                    
                    Text(warning)
                        .font(.system(size: KeeperConstants.UI.smallTextSize, weight: .medium))
                        .foregroundColor(.sunsetCoral)
                }
                .padding(12)
                .background(Color.warningBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Action buttons
            if !log.isConfirmed {
                actionButtons
            } else {
                confirmedIndicator
            }
        }
        .padding(KeeperConstants.UI.padding)
        .background(
            RoundedRectangle(cornerRadius: KeeperConstants.UI.cardRadius)
                .fill(Color.deepSlate)
        )
        .overlay(
            RoundedRectangle(cornerRadius: KeeperConstants.UI.cardRadius)
                .stroke(
                    log.isConfirmed ? Color.slateGray.opacity(0.5) : toddlerColor.opacity(0.3),
                    style: log.isConfirmed ? StrokeStyle(lineWidth: 1) : StrokeStyle(lineWidth: 2, dash: [8, 4])
                )
        )
    }
    
    private var isBehaviorLog: Bool {
        data?.event == "behavior"
    }
    
    private var isMilestoneLog: Bool {
        data?.event == "milestone"
    }
    
    private var toddlerIcon: String {
        switch data?.event {
        case "behavior": return "brain.head.profile"
        case "milestone": return "star.fill"
        case "vocabulary": return "text.bubble.fill"
        case "sleep": return "moon.zzz.fill"
        case "feed": return "fork.knife"
        default: return "figure.child"
        }
    }
    
    private var toddlerTitle: String {
        switch data?.event {
        case "behavior": return "Behavior"
        case "milestone": return "Milestone!"
        case "vocabulary": return "New Word"
        case "sleep": return "Sleep"
        case "feed": return "Meal"
        default: return "Note"
        }
    }
    
    private var toddlerColor: Color {
        switch data?.event {
        case "behavior": return .orange
        case "milestone": return .yellow
        case "vocabulary": return .cyan
        default: return .moonlightLavender
        }
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: data?.time ?? log.createdAt)
    }
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button(action: onConfirm) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .bold))
                    Text("Save")
                        .font(.system(size: KeeperConstants.UI.baseTextSize, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: KeeperConstants.UI.minTouchTarget)
                .background(toddlerColor)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.system(size: 20))
                    .foregroundColor(.dimStar)
                    .frame(width: KeeperConstants.UI.minTouchTarget, height: KeeperConstants.UI.minTouchTarget)
                    .background(Color.deepSlate)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.slateGray, lineWidth: 1)
                    )
            }
        }
    }
    
    private var confirmedIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(.safeGreen)
            
            Text("Saved to Memory")
                .font(.system(size: 12))
                .foregroundColor(.dimStar)
        }
    }
}

// MARK: - Behavior Trigger View
struct BehaviorTriggerView: View {
    let notes: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.triangle.branch")
                    .font(.system(size: 14))
                    .foregroundColor(.orange)
                
                Text("Trigger Analysis")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.orange)
            }
            
            Text(notes)
                .font(.system(size: KeeperConstants.UI.smallTextSize))
                .foregroundColor(.starlightCream)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

// MARK: - Milestone Celebration
struct MilestoneCelebration: View {
    let data: LogData?
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "party.popper.fill")
                .font(.system(size: 24))
                .foregroundColor(.yellow)
            
            VStack(alignment: .leading, spacing: 4) {
                if let notes = data?.notes {
                    Text(notes)
                        .font(.system(size: KeeperConstants.UI.baseTextSize, weight: .semibold))
                        .foregroundColor(.starlightCream)
                }
                
                Text("This moment is now saved forever!")
                    .font(.system(size: 12))
                    .foregroundColor(.dimStar)
            }
        }
        .padding(12)
        .background(
            LinearGradient(
                colors: [Color.yellow.opacity(0.1), Color.orange.opacity(0.1)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview
#Preview("Pre-Natal") {
    VStack(spacing: 20) {
        PrenatalLogCard(
            log: Log(
                familyId: UUID(),
                creatorId: UUID(),
                stageContext: .prenatal,
                eventType: .symptom,
                structuredData: LogData(
                    event: "symptom",
                    subtype: "nausea",
                    amount: 6,
                    unit: nil,
                    drug: nil,
                    time: Date(),
                    warning: nil,
                    notes: "Morning sickness, felt nauseous after breakfast"
                ),
                isConfirmed: false
            ),
            onConfirm: {},
            onEdit: {}
        )
    }
    .padding()
    .background(Color.midnightSlate)
}

#Preview("Toddler") {
    VStack(spacing: 20) {
        ToddlerLogCard(
            log: Log(
                familyId: UUID(),
                creatorId: UUID(),
                stageContext: .earlyEd,
                eventType: .milestone,
                structuredData: LogData(
                    event: "milestone",
                    subtype: "speech",
                    amount: nil,
                    unit: nil,
                    drug: nil,
                    time: Date(),
                    warning: nil,
                    notes: "Said 'apple' for the first time!"
                ),
                isConfirmed: false
            ),
            onConfirm: {},
            onEdit: {}
        )
    }
    .padding()
    .background(Color.midnightSlate)
}

