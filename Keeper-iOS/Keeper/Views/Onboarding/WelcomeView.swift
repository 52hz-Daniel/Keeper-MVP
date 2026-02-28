import SwiftUI

// MARK: - Welcome View
// Reference: Keeper Expansion - Zero-Onboarding Flow
// "On first launch, do NOT ask for Email/Password. Ask only for the anchor date."

struct WelcomeView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        Group {
            switch viewModel.currentStep {
            case .welcome:
                welcomeScreen
            case .dateSelection:
                dateSelectionScreen
            case .immersion, .complete:
                // Mark onboarding as complete to transition to main view
                Color.clear.onAppear {
                    viewModel.hasCompletedOnboarding = true
                }
            case .valueThreshold:
                valueThresholdScreen
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Welcome Screen
    private var welcomeScreen: some View {
        ZStack {
            Color.midnightSlate
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Logo
                VStack(spacing: 16) {
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.moonlightLavender, .moonlightLavender.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Keeper")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(.starlightCream)
                    
                    Text("remembers, so you can sleep.")
                        .font(.system(size: 18))
                        .foregroundColor(.dimStar)
                }
                
                Spacer()
                
                // Main Question
                VStack(spacing: 24) {
                    Text("To help you best, we need to know\nwhere you are in your journey.")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.starlightCream)
                        .multilineTextAlignment(.center)
                    
                    // Date Type Selection
                    HStack(spacing: 16) {
                        DateTypeButton(
                            title: "Expecting",
                            subtitle: "I'm pregnant",
                            icon: "heart.fill",
                            isSelected: viewModel.dateType == .dueDate
                        ) {
                            viewModel.selectDateType(.dueDate)
                            viewModel.currentStep = .dateSelection
                        }
                        
                        DateTypeButton(
                            title: "New Parent",
                            subtitle: "Baby is here",
                            icon: "moon.stars.fill",
                            isSelected: viewModel.dateType == .birthday
                        ) {
                            viewModel.selectDateType(.birthday)
                            viewModel.currentStep = .dateSelection
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Skip option
                Button {
                    viewModel.skipOnboarding()
                } label: {
                    Text("Skip for now")
                        .font(.system(size: 16))
                        .foregroundColor(.dimStar)
                }
                .padding(.bottom, 40)
            }
        }
    }
    
    // MARK: - Date Selection Screen
    private var dateSelectionScreen: some View {
        ZStack {
            Color.midnightSlate
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Title
                VStack(spacing: 12) {
                    Text(viewModel.dateType.prompt)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.starlightCream)
                    
                    Text("This helps us personalize your experience")
                        .font(.system(size: 16))
                        .foregroundColor(.dimStar)
                }
                
                // Date Picker with constraints
                if viewModel.dateType == .birthday {
                    DatePicker(
                        "",
                        selection: $viewModel.selectedDate,
                        in: ...Date(), // Birthday can't be in future
                        displayedComponents: .date
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .colorScheme(.dark)
                    .padding(.horizontal, 20)
                } else {
                    DatePicker(
                        "",
                        selection: $viewModel.selectedDate,
                        in: Date()..., // Due date must be in future
                        displayedComponents: .date
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .colorScheme(.dark)
                    .padding(.horizontal, 20)
                }
                
                // Stage Preview
                StagePreviewCard(stage: viewModel.calculatedStage)
                    .onChange(of: viewModel.selectedDate) { _, _ in
                        viewModel.calculateStage()
                    }
                
                Spacer()
                
                // Continue Button
                Button {
                    viewModel.confirmDate()
                } label: {
                    Text("Continue")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.moonlightLavender)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
    
    // MARK: - Value Threshold Screen
    // Reference: Keeper Expansion - "Value Threshold" Conversion
    private var valueThresholdScreen: some View {
        ZStack {
            Color.midnightSlate
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Success Icon
                ZStack {
                    Circle()
                        .fill(Color.safeGreen.opacity(0.2))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.safeGreen)
                }
                
                // Message
                VStack(spacing: 16) {
                    Text("You're doing great!")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.starlightCream)
                    
                    Text("Keeper has saved you mental load from\n\(viewModel.logsConfirmed) logs. Secure your family's data permanently.")
                        .font(.system(size: 16))
                        .foregroundColor(.dimStar)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                // Sign In Options
                VStack(spacing: 16) {
                    SignInButton(
                        title: "Continue with Apple",
                        icon: "apple.logo",
                        backgroundColor: .white,
                        foregroundColor: .black
                    ) {
                        // TODO: Implement Apple Sign In
                        viewModel.completeOnboarding()
                    }
                    
                    SignInButton(
                        title: "Continue with Google",
                        icon: "g.circle.fill",
                        backgroundColor: .white,
                        foregroundColor: .black
                    ) {
                        // TODO: Implement Google Sign In
                        viewModel.completeOnboarding()
                    }
                    
                    Button {
                        viewModel.completeOnboarding()
                    } label: {
                        Text("Maybe later")
                            .font(.system(size: 16))
                            .foregroundColor(.dimStar)
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Date Type Button
struct DateTypeButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(isSelected ? .moonlightLavender : .dimStar)
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.starlightCream)
                    
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.dimStar)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.deepSlate)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? Color.moonlightLavender : Color.slateGray,
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
    }
}

// MARK: - Stage Preview Card
struct StagePreviewCard: View {
    let stage: KeeperConstants.Stage
    
    var body: some View {
        HStack(spacing: 16) {
            // Stage Icon
            ZStack {
                Circle()
                    .fill(stageColor.opacity(0.2))
                    .frame(width: 48, height: 48)
                
                Image(systemName: stageIcon)
                    .font(.system(size: 22))
                    .foregroundColor(stageColor)
            }
            
            // Stage Info
            VStack(alignment: .leading, spacing: 4) {
                Text(stage.displayName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.starlightCream)
                
                Text("AI Persona: \(stage.aiPersona)")
                    .font(.system(size: 14))
                    .foregroundColor(.dimStar)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.deepSlate)
        )
        .padding(.horizontal, 24)
    }
    
    private var stageIcon: String {
        switch stage {
        case .prenatal: return "heart.fill"
        case .infant: return "moon.stars.fill"
        case .earlyEd: return "sun.max.fill"
        }
    }
    
    private var stageColor: Color {
        switch stage {
        case .prenatal: return .pink
        case .infant: return .moonlightLavender
        case .earlyEd: return .yellow
        }
    }
}

// MARK: - Sign In Button
struct SignInButton: View {
    let title: String
    let icon: String
    let backgroundColor: Color
    let foregroundColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundColor(foregroundColor)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Preview
#Preview {
    WelcomeView(viewModel: OnboardingViewModel())
}

