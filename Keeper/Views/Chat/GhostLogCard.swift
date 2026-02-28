import SwiftUI

// MARK: - Ghost Log Card
// Reference: MPID "Component: The "Ghost Log" Card (The "Granola" Pattern)"
// This is the most important UI element. It distinguishes "Chat" from "Data."

struct GhostLogCard: View {
    let log: Log
    let onConfirm: () -> Void
    let onEdit: () -> Void
    
    private var data: LogData? { log.structuredData }
    private var hasWarning: Bool { data?.hasWarning ?? false }
    private var isMedical: Bool { log.eventType.isMedical }
    
    var body: some View {
        if log.isConfirmed {
            confirmedCard
        } else {
            draftCard
        }
    }
    
    // MARK: - Draft Card (Pending Confirmation)
    // Visual State 1: The Draft
    // Appearance: Looks like a "Ticket" or "Sticky Note" with dashed border
    private var draftCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with icon and type
            HStack(spacing: 12) {
                // Event icon
                ZStack {
                    Circle()
                        .fill(hasWarning ? Color.sunsetCoral.opacity(0.2) : Color.moonlightLavender.opacity(0.2))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: log.eventType.icon)
                        .font(.system(size: 22))
                        .foregroundColor(hasWarning ? .sunsetCoral : .moonlightLavender)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    // Event type headline
                    Text(log.eventType.displayName)
                        .font(.system(size: KeeperConstants.UI.baseTextSize, weight: .bold))
                        .foregroundColor(hasWarning ? .sunsetCoral : .starlightCream)
                    
                    // Details
                    if let amount = data?.displayAmount, !amount.isEmpty {
                        Text(amount)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(hasWarning ? .sunsetCoral : .starlightCream)
                    } else if let drug = data?.drug {
                        Text(drug)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(hasWarning ? .sunsetCoral : .starlightCream)
                    }
                }
                
                Spacer()
                
                // Warning icon if applicable
                if hasWarning {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.sunsetCoral)
                        .symbolEffect(.pulse)
                }
                
                // Time
                Text(formattedTime)
                    .font(.system(size: KeeperConstants.UI.smallTextSize))
                    .foregroundColor(.dimStar)
            }
            
            // Warning message if present
            if let warning = data?.warning {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.sunsetCoral)
                    
                    Text(warning)
                        .font(.system(size: KeeperConstants.UI.smallTextSize, weight: .medium))
                        .foregroundColor(.sunsetCoral)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .background(Color.warningBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Action buttons
            HStack(spacing: 12) {
                // Confirm button (Green, prominent)
                Button(action: onConfirm) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 18, weight: .bold))
                        Text("Confirm")
                            .font(.system(size: KeeperConstants.UI.baseTextSize, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: KeeperConstants.UI.minTouchTarget)
                    .background(Color.safeGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .accessibilityIdentifier("confirmButton")
                
                // Edit button (subtle)
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
                .accessibilityIdentifier("editButton")
            }
        }
        .padding(KeeperConstants.UI.padding)
        .background(
            RoundedRectangle(cornerRadius: KeeperConstants.UI.cardRadius)
                .fill(hasWarning ? Color.warningBackground : Color.ghostDraft)
        )
        .overlay(
            RoundedRectangle(cornerRadius: KeeperConstants.UI.cardRadius)
                .stroke(
                    hasWarning ? Color.sunsetCoral.opacity(0.5) : Color.ghostBorder,
                    style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                )
        )
        .accessibilityIdentifier("ghostLogCard")
    }
    
    // MARK: - Confirmed Card
    // Visual State 2: Confirmed (Saved)
    // Styling: Solid background, no dashed border, synced indicator
    private var confirmedCard: some View {
        HStack(spacing: 12) {
            // Event icon
            ZStack {
                Circle()
                    .fill(Color.moonlightLavender.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: log.eventType.icon)
                    .font(.system(size: 20))
                    .foregroundColor(.moonlightLavender)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(log.eventType.displayName)
                    .font(.system(size: KeeperConstants.UI.baseTextSize, weight: .semibold))
                    .foregroundColor(.starlightCream)
                
                if let amount = data?.displayAmount, !amount.isEmpty {
                    Text(amount)
                        .font(.system(size: KeeperConstants.UI.smallTextSize))
                        .foregroundColor(.dimStar)
                } else if let notes = data?.notes {
                    Text(notes)
                        .font(.system(size: KeeperConstants.UI.smallTextSize))
                        .foregroundColor(.dimStar)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Synced indicator
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.safeGreen)
                
                Text("Synced")
                    .font(.system(size: 12))
                    .foregroundColor(.dimStar)
            }
        }
        .padding(KeeperConstants.UI.padding)
        .background(
            RoundedRectangle(cornerRadius: KeeperConstants.UI.cardRadius)
                .fill(Color.deepSlate)
        )
        .overlay(
            RoundedRectangle(cornerRadius: KeeperConstants.UI.cardRadius)
                .stroke(Color.slateGray.opacity(0.5), lineWidth: 1)
        )
        .accessibilityIdentifier("confirmedLogCard")
    }
    
    // MARK: - Helpers
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: data?.time ?? log.createdAt)
    }
}

// MARK: - Preview
#Preview("Draft Card") {
    VStack(spacing: 20) {
        GhostLogCard(
            log: Log(
                familyId: UUID(),
                creatorId: UUID(),
                eventType: .feed,
                structuredData: LogData(
                    event: "feed",
                    subtype: "formula",
                    amount: 4,
                    unit: "oz",
                    drug: nil,
                    time: Date(),
                    warning: nil,
                    notes: nil
                ),
                isConfirmed: false
            ),
            onConfirm: {},
            onEdit: {}
        )
        
        GhostLogCard(
            log: Log(
                familyId: UUID(),
                creatorId: UUID(),
                eventType: .medication,
                structuredData: LogData(
                    event: "medication",
                    subtype: nil,
                    amount: 15,
                    unit: "ml",
                    drug: "Tylenol",
                    time: Date(),
                    warning: "⚠️ High Dosage Detected (15ml). Standard infant dose is usually 1.25-5ml.",
                    notes: nil
                ),
                isConfirmed: false
            ),
            onConfirm: {},
            onEdit: {}
        )
        
        GhostLogCard(
            log: Log(
                familyId: UUID(),
                creatorId: UUID(),
                eventType: .feed,
                structuredData: LogData(
                    event: "feed",
                    subtype: "formula",
                    amount: 4,
                    unit: "oz",
                    drug: nil,
                    time: Date(),
                    warning: nil,
                    notes: nil
                ),
                isConfirmed: true
            ),
            onConfirm: {},
            onEdit: {}
        )
    }
    .padding()
    .background(Color.midnightSlate)
}

