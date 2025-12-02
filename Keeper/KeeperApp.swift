import SwiftUI

// MARK: - Keeper App
// Main entry point for Keeper - The Family Operating System
// Handles: Stage selection, Auth flow, Subscription prompts

@main
struct KeeperApp: App {
    @StateObject private var authService = AuthService.shared
    @StateObject private var onboardingVM = OnboardingViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .environmentObject(onboardingVM)
                .preferredColorScheme(.dark) // Always dark mode for 3 AM test
        }
    }
}

// MARK: - Content View
// Orchestrates the main app flow
struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var onboardingVM: OnboardingViewModel
    @StateObject private var momentsService = MomentsService.shared
    
    @State private var showAccountView = false
    @State private var showSubscriptionView = false
    @State private var showSubscriptionPrompt = false
    @State private var subscriptionPromptType: SubscriptionPromptView.PromptType = .valueThreshold
    @State private var showAccountCreationPrompt = false
    @State private var showMilestoneGift = false
    @State private var currentMilestoneGift: MemoryGift?
    
    var body: some View {
        ZStack {
            // Main Content based on state
            mainContent
            
            // Subscription prompt overlay
            if showSubscriptionPrompt {
                subscriptionPromptOverlay
            }
            
            // Account creation prompt overlay
            if showAccountCreationPrompt {
                accountCreationPromptOverlay
            }
            
            // Milestone gift overlay (highest priority)
            if showMilestoneGift, let gift = currentMilestoneGift {
                MilestoneGiftView(gift: gift) {
                    withAnimation(.easeOut) {
                        showMilestoneGift = false
                        currentMilestoneGift = nil
                    }
                }
                .transition(.opacity)
            }
        }
        .sheet(isPresented: $showAccountView) {
            AccountView()
        }
        .sheet(isPresented: $showSubscriptionView) {
            SubscriptionView()
        }
        .onAppear {
            checkPromptsNeeded()
            checkForMilestoneGift()
        }
        .onChange(of: authService.currentUser?.logsConfirmed) { _, newValue in
            checkAccountPrompt(logsCount: newValue ?? 0)
        }
    }
    
    // MARK: - Main Content
    @ViewBuilder
    private var mainContent: some View {
        if !onboardingVM.hasCompletedOnboarding {
            // First time user - show welcome
            WelcomeView(viewModel: onboardingVM)
        } else {
            // Show stage-appropriate home view
            stageHomeView
        }
    }
    
    // MARK: - Stage Home Views
    @ViewBuilder
    private var stageHomeView: some View {
        switch onboardingVM.currentStage {
        case .prenatal:
            PrenatalHomeView()
                .environmentObject(authService)
                .overlay(alignment: .topTrailing) {
                    profileButton
                }
        case .infant:
            InfantHomeView()
                .environmentObject(authService)
                .overlay(alignment: .topTrailing) {
                    profileButton
                }
        case .earlyEd:
            EarlyEdHomeView()
                .environmentObject(authService)
                .overlay(alignment: .topTrailing) {
                    profileButton
                }
        }
    }
    
    // MARK: - Profile Button
    private var profileButton: some View {
        Menu {
            // Stage Switcher Section
            Menu {
                ForEach(KeeperConstants.Stage.allCases, id: \.self) { stage in
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            onboardingVM.currentStage = stage
                        }
                        HapticsService.shared.lightTap()
                    } label: {
                        if onboardingVM.currentStage == stage {
                            Label(stage.displayName, systemImage: "checkmark")
                        } else {
                            Text(stage.displayName)
                        }
                    }
                }
            } label: {
                Label("Change Stage", systemImage: "arrow.triangle.swap")
            }
            
            Divider()
            
            if authService.currentUser?.isAnonymous ?? true {
                Button {
                    showAccountView = true
                } label: {
                    Label("Create Account", systemImage: "person.badge.plus")
                }
            }
            
            Button {
                showSubscriptionView = true
            } label: {
                if authService.currentUser?.isPremium ?? false {
                    Label("Manage Subscription", systemImage: "crown.fill")
                } else {
                    Label("Upgrade to Premium", systemImage: "crown")
                }
            }
            
            Divider()
            
            Button {
                // Settings
            } label: {
                Label("Settings", systemImage: "gear")
            }
            
            if !(authService.currentUser?.isAnonymous ?? true) {
                Button(role: .destructive) {
                    authService.signOut()
                } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        } label: {
            ZStack {
                Circle()
                    .fill(Color.deepSlate)
                    .frame(width: 40, height: 40)
                
                if authService.currentUser?.isAnonymous ?? true {
                    Image(systemName: "person.circle")
                        .font(.system(size: 20))
                        .foregroundColor(.dimStar)
                } else {
                    Text(authService.currentUser?.displayName?.prefix(1).uppercased() ?? "U")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.starlightCream)
                }
                
                // Premium badge
                if authService.currentUser?.isPremium ?? false {
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Image(systemName: "crown.fill")
                                .font(.system(size: 6))
                                .foregroundColor(.black)
                        )
                        .offset(x: 14, y: -14)
                }
            }
        }
        .padding(.trailing, 16)
        .padding(.top, 8)
    }
    
    // MARK: - Subscription Prompt Overlay
    private var subscriptionPromptOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    // Don't dismiss on tap
                }
            
            VStack {
                Spacer()
                
                SubscriptionPromptView(
                    promptType: subscriptionPromptType,
                    onSubscribe: {
                        showSubscriptionPrompt = false
                        showSubscriptionView = true
                        authService.markSubscriptionPromptSeen()
                    },
                    onDismiss: {
                        showSubscriptionPrompt = false
                        authService.markSubscriptionPromptSeen()
                    }
                )
                .frame(height: 500)
                .clipShape(RoundedRectangle(cornerRadius: 24))
            }
            .transition(.move(edge: .bottom))
        }
    }
    
    // MARK: - Account Creation Prompt Overlay
    private var accountCreationPromptOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                AccountCreationPromptView(
                    logsCount: authService.currentUser?.logsConfirmed ?? 0,
                    onCreateAccount: {
                        showAccountCreationPrompt = false
                        showAccountView = true
                        authService.markAccountPromptSeen()
                    },
                    onSkip: {
                        showAccountCreationPrompt = false
                        authService.markAccountPromptSeen()
                    }
                )
                .frame(height: 500)
                .clipShape(RoundedRectangle(cornerRadius: 24))
            }
            .transition(.move(edge: .bottom))
        }
    }
    
    // MARK: - Prompt Logic
    private func checkPromptsNeeded() {
        guard let user = authService.currentUser else { return }
        
        // Check trial status
        if let subscription = user.subscription {
            if subscription.trialExpired && !user.hasSeenSubscriptionPrompt {
                subscriptionPromptType = .trialExpired
                withAnimation(.spring()) {
                    showSubscriptionPrompt = true
                }
                return
            }
            
            if subscription.shouldPromptForSubscription && !user.hasSeenSubscriptionPrompt {
                subscriptionPromptType = .trialEnding
                withAnimation(.spring()) {
                    showSubscriptionPrompt = true
                }
                return
            }
        }
    }
    
    private func checkAccountPrompt(logsCount: Int) {
        guard let user = authService.currentUser else { return }
        
        // Show account creation prompt after 5 logs if still anonymous
        if user.isAnonymous && logsCount >= 5 && !user.hasSeenAccountPrompt {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                withAnimation(.spring()) {
                    showAccountCreationPrompt = true
                }
            }
        }
    }
    
    // MARK: - Milestone Gift Check
    private func checkForMilestoneGift() {
        // Only check for infant and early ed stages
        guard onboardingVM.currentStage != .prenatal else { return }
        guard let user = authService.currentUser else { return }
        
        // Get the child's birth date from onboarding
        let childBirthDate = onboardingVM.selectedDate
        
        // Check for milestone gift
        if let gift = momentsService.checkForMilestoneGift(
            childBirthDate: childBirthDate,
            familyId: user.familyId ?? UUID()
        ) {
            // Delay to not overwhelm on app open
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                currentMilestoneGift = gift
                withAnimation(.easeIn(duration: 0.5)) {
                    showMilestoneGift = true
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ContentView()
        .environmentObject(AuthService.shared)
        .environmentObject(OnboardingViewModel())
}
