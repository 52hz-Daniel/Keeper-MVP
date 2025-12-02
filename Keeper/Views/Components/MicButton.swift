import SwiftUI

// MARK: - Mic Button (FAB)
// Reference: MPID "Component: The "Big Mic" Button"
// The Microphone icon is a Floating Action Button, not a small icon inside text box.
// Reference: Brand Strategy "Primary 'Mic' Action Button (The 'Thumb Zone' Hero)"

struct MicButton: View {
    let isRecording: Bool
    let action: () -> Void
    
    @State private var pulseAnimation = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Pulse animation ring (when recording)
                if isRecording {
                    Circle()
                        .stroke(Color.moonlightLavender.opacity(0.3), lineWidth: 3)
                        .frame(width: 72, height: 72)
                        .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                        .opacity(pulseAnimation ? 0 : 1)
                        .animation(
                            .easeInOut(duration: 1.0).repeatForever(autoreverses: false),
                            value: pulseAnimation
                        )
                }
                
                // Main button
                Circle()
                    .fill(Color.moonlightLavender)
                    .frame(
                        width: KeeperConstants.UI.largeButtonSize,
                        height: KeeperConstants.UI.largeButtonSize
                    )
                    .shadow(
                        color: Color.moonlightLavender.opacity(0.4),
                        radius: isRecording ? 12 : 6,
                        x: 0,
                        y: 4
                    )
                
                // Mic icon
                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .frame(
            width: KeeperConstants.UI.largeButtonSize + 16,
            height: KeeperConstants.UI.largeButtonSize + 16
        )
        .accessibilityIdentifier("micButton")
        .accessibilityLabel(isRecording ? "Stop recording" : "Start recording")
        .onChange(of: isRecording) { _, newValue in
            pulseAnimation = newValue
        }
    }
}

// MARK: - Large Mic Button (for empty state)
struct LargeMicButton: View {
    let isRecording: Bool
    let action: () -> Void
    
    @State private var pulseAnimation = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Outer glow
                Circle()
                    .fill(Color.moonlightLavender.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                // Middle ring (pulse when recording)
                Circle()
                    .fill(Color.moonlightLavender.opacity(0.2))
                    .frame(width: 96, height: 96)
                    .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                    .animation(
                        isRecording ?
                            .easeInOut(duration: 0.8).repeatForever(autoreverses: true) :
                            .default,
                        value: pulseAnimation
                    )
                
                // Main button
                Circle()
                    .fill(Color.moonlightLavender)
                    .frame(width: 80, height: 80)
                    .shadow(
                        color: Color.moonlightLavender.opacity(0.5),
                        radius: 16,
                        x: 0,
                        y: 8
                    )
                
                // Icon
                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .accessibilityIdentifier("largeMicButton")
        .onChange(of: isRecording) { _, newValue in
            pulseAnimation = newValue
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.midnightSlate
            .ignoresSafeArea()
        
        VStack(spacing: 40) {
            MicButton(isRecording: false, action: {})
            MicButton(isRecording: true, action: {})
            
            Divider()
            
            LargeMicButton(isRecording: false, action: {})
            LargeMicButton(isRecording: true, action: {})
        }
    }
}

