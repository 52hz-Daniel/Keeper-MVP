import SwiftUI

// MARK: - Subscription Prompt View
// Smart prompting based on usage patterns and trial status
// Shows at key moments to maximize conversion

struct SubscriptionPromptView: View {
    @StateObject private var authService = AuthService.shared
    @Environment(\.dismiss) private var dismiss
    
    let promptType: PromptType
    let onSubscribe: () -> Void
    let onDismiss: () -> Void
    
    enum PromptType {
        case trialEnding
        case trialExpired
        case featureGated
        case valueThreshold // After significant usage
        
        var title: String {
            switch self {
            case .trialEnding: return "Your Trial is Ending Soon"
            case .trialExpired: return "Your Trial Has Ended"
            case .featureGated: return "Premium Feature"
            case .valueThreshold: return "You're Loving Keeper! 🎉"
            }
        }
        
        var subtitle: String {
            switch self {
            case .trialEnding: return "Keep all your premium features"
            case .trialExpired: return "Upgrade to continue using premium features"
            case .featureGated: return "Unlock this feature with Premium"
            case .valueThreshold: return "Upgrade to unlock the full experience"
            }
        }
        
        var icon: String {
            switch self {
            case .trialEnding: return "clock.badge.exclamationmark"
            case .trialExpired: return "lock.fill"
            case .featureGated: return "crown.fill"
            case .valueThreshold: return "heart.fill"
            }
        }
        
        var iconColor: Color {
            switch self {
            case .trialEnding: return .orange
            case .trialExpired: return .red
            case .featureGated: return .yellow
            case .valueThreshold: return .pink
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Handle
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.slateGray)
                .frame(width: 40, height: 6)
                .padding(.top, 8)
            
            // Icon
            ZStack {
                Circle()
                    .fill(promptType.iconColor.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: promptType.icon)
                    .font(.system(size: 36))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [promptType.iconColor, promptType.iconColor.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            
            // Text
            VStack(spacing: 8) {
                Text(promptType.title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.starlightCream)
                
                Text(promptType.subtitle)
                    .font(.system(size: 16))
                    .foregroundColor(.dimStar)
                    .multilineTextAlignment(.center)
            }
            
            // Features Preview
            VStack(alignment: .leading, spacing: 12) {
                PremiumFeaturePreview(icon: "mic.fill", title: "Voice Logging", subtitle: "Log hands-free at 3 AM")
                PremiumFeaturePreview(icon: "chart.line.uptrend.xyaxis", title: "Pattern Insights", subtitle: "Discover sleep & feeding patterns")
                PremiumFeaturePreview(icon: "person.2.fill", title: "Partner Sync", subtitle: "Real-time updates with your partner")
            }
            .padding(16)
            .background(Color.deepSlate)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            // Trial remaining (if applicable)
            if promptType == .trialEnding,
               let days = authService.currentUser?.subscription?.trialDaysRemaining {
                HStack(spacing: 8) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.orange)
                    Text("\(days) days left in your trial")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.1))
                .clipShape(Capsule())
            }
            
            // Actions
            VStack(spacing: 12) {
                Button(action: onSubscribe) {
                    HStack(spacing: 8) {
                        Text("Upgrade to Premium")
                            .font(.system(size: 18, weight: .bold))
                        Text("$9.99/mo")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [.moonlightLavender, .moonlightLavender.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                
                Button(action: onDismiss) {
                    Text(promptType == .trialExpired ? "Continue with Free" : "Maybe Later")
                        .font(.system(size: 16))
                        .foregroundColor(.dimStar)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .background(Color.midnightSlate)
    }
}

// MARK: - Premium Feature Preview
struct PremiumFeaturePreview: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.moonlightLavender)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.starlightCream)
                
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.dimStar)
            }
            
            Spacer()
        }
    }
}

// MARK: - Feature Gate View
// Shows when user tries to access a premium feature
struct FeatureGateView: View {
    let feature: PremiumFeature
    let onUpgrade: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.moonlightLavender.opacity(0.2))
                    .frame(width: 100, height: 100)
                
                Image(systemName: feature.icon)
                    .font(.system(size: 44))
                    .foregroundColor(.moonlightLavender)
            }
            
            VStack(spacing: 8) {
                Text(feature.displayName)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.starlightCream)
                
                Text(feature.description)
                    .font(.system(size: 16))
                    .foregroundColor(.dimStar)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            
            // Premium badge
            HStack(spacing: 8) {
                Image(systemName: "crown.fill")
                    .foregroundStyle(
                        LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                Text("Premium Feature")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.yellow)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.yellow.opacity(0.1))
            .clipShape(Capsule())
            
            Spacer()
            
            // Actions
            VStack(spacing: 12) {
                Button(action: onUpgrade) {
                    Text("Upgrade to Premium")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.moonlightLavender)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                
                Button(action: onCancel) {
                    Text("Not Now")
                        .font(.system(size: 16))
                        .foregroundColor(.dimStar)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Color.midnightSlate)
    }
}

// MARK: - Account Creation Prompt
// Shows after user has confirmed several logs (value threshold)
struct AccountCreationPromptView: View {
    @StateObject private var authService = AuthService.shared
    @Environment(\.dismiss) private var dismiss
    
    let logsCount: Int
    let onCreateAccount: () -> Void
    let onSkip: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Handle
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.slateGray)
                .frame(width: 40, height: 6)
                .padding(.top, 8)
            
            Spacer()
            
            // Celebration
            VStack(spacing: 16) {
                Text("🎉")
                    .font(.system(size: 60))
                
                Text("You've logged \(logsCount) entries!")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.starlightCream)
                
                Text("Create a free account to sync your data and never lose it.")
                    .font(.system(size: 16))
                    .foregroundColor(.dimStar)
                    .multilineTextAlignment(.center)
            }
            
            // Benefits
            VStack(alignment: .leading, spacing: 12) {
                BenefitRow(icon: "icloud.fill", text: "Sync across all devices")
                BenefitRow(icon: "lock.shield.fill", text: "Secure cloud backup")
                BenefitRow(icon: "person.2.fill", text: "Invite your partner")
                BenefitRow(icon: "gift.fill", text: "14-day Premium trial included")
            }
            .padding(20)
            .background(Color.deepSlate)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            Spacer()
            
            // Actions
            VStack(spacing: 12) {
                Button(action: onCreateAccount) {
                    Text("Create Free Account")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.midnightSlate)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.safeGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                
                Button(action: onSkip) {
                    Text("Continue as Guest")
                        .font(.system(size: 16))
                        .foregroundColor(.dimStar)
                }
            }
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 24)
        .background(Color.midnightSlate)
    }
}

struct BenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.moonlightLavender)
                .frame(width: 28)
            
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.starlightCream)
            
            Spacer()
        }
    }
}

// MARK: - Preview
#Preview("Trial Ending") {
    SubscriptionPromptView(
        promptType: .trialEnding,
        onSubscribe: {},
        onDismiss: {}
    )
}

#Preview("Feature Gate") {
    FeatureGateView(
        feature: .voiceLogging,
        onUpgrade: {},
        onCancel: {}
    )
}

#Preview("Account Creation") {
    AccountCreationPromptView(
        logsCount: 10,
        onCreateAccount: {},
        onSkip: {}
    )
}

