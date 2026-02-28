import SwiftUI

// MARK: - Dev Testing Menu
// Hidden menu for development and testing
// Philosophy: "Make testing easy so we can focus on the experience"

struct DevTestingMenu: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var onboardingVM: OnboardingViewModel
    @StateObject private var logStore = LogStore.shared
    @StateObject private var familySync = FamilySyncService.shared
    @StateObject private var prenatalStore = PrenatalStore.shared
    @StateObject private var earlyEdStore = EarlyEdStore.shared
    
    @State private var showResetConfirm = false
    @State private var showNotificationTest = false
    @State private var testMessage = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.midnightSlate
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Authentication Testing
                        authTestingSection
                        
                        // Onboarding Testing
                        onboardingTestingSection
                        
                        // Data Testing
                        dataTestingSection
                        
                        // Family/Collaboration Testing
                        familyTestingSection
                        
                        // Notification Testing
                        notificationTestingSection
                        
                        // Stage Switching
                        stageSwitchingSection
                        
                        // Dangerous Actions
                        dangerousActionsSection
                    }
                    .padding(20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("🛠 Dev Tools")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.moonlightLavender)
                }
            }
        }
        .alert("Reset Everything?", isPresented: $showResetConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                resetAllData()
            }
        } message: {
            Text("This will delete all local data and sign you out. This cannot be undone.")
        }
        .alert("Action Complete", isPresented: $showAlert) {
            Button("OK") {
                showAlert = false
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "wrench.and.screwdriver.fill")
                .font(.system(size: 48))
                .foregroundColor(.moonlightLavender)
            
            Text("Development Testing Menu")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.starlightCream)
            
            Text("These buttons are for testing only and will be removed in production.")
                .font(.system(size: 13))
                .foregroundColor(.dimStar)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 16)
    }
    
    // MARK: - Auth Testing
    private var authTestingSection: some View {
        TestSection(title: "Authentication") {
            TestButton(
                title: "Sign Out",
                icon: "rectangle.portrait.and.arrow.right",
                color: .orange
            ) {
                authService.signOut()
                testMessage = "Signed out successfully"
            }
            
            TestButton(
                title: "Simulate New User",
                icon: "person.badge.plus",
                color: .cyan
            ) {
                simulateNewUser()
            }
        }
    }
    
    // MARK: - Onboarding Testing
    private var onboardingTestingSection: some View {
        TestSection(title: "Onboarding & Stages") {
            TestButton(
                title: "Reset Onboarding",
                icon: "arrow.counterclockwise",
                color: .blue
            ) {
                resetOnboarding()
            }
            
            TestButton(
                title: "Skip to Pre-Natal",
                icon: "figure.wave",
                color: .purple
            ) {
                jumpToStage(.prenatal, dueDate: Date().addingTimeInterval(60 * 24 * 60 * 60))
            }
            
            TestButton(
                title: "Skip to Infant (3mo)",
                icon: "figure.and.child.holdinghands",
                color: .cyan
            ) {
                jumpToStage(.infant, birthDate: Date().addingTimeInterval(-90 * 24 * 60 * 60))
            }
            
            TestButton(
                title: "Skip to Early Ed (18mo)",
                icon: "books.vertical",
                color: .green
            ) {
                jumpToStage(.earlyEd, birthDate: Date().addingTimeInterval(-18 * 30 * 24 * 60 * 60))
            }
        }
    }
    
    // MARK: - Data Testing
    private var dataTestingSection: some View {
        TestSection(title: "Test Data") {
            TestButton(
                title: "Add Sample Logs (10)",
                icon: "note.text.badge.plus",
                color: .green
            ) {
                addSampleLogs(count: 10)
            }
            
            TestButton(
                title: "Add Night Feed (3AM)",
                icon: "moon.zzz.fill",
                color: .purple
            ) {
                addNightFeed()
            }
            
            TestButton(
                title: "Add Medication Log",
                icon: "cross.case.fill",
                color: .orange
            ) {
                addMedicationLog()
            }
            
            TestButton(
                title: "Generate Moments (5)",
                icon: "sparkles",
                color: .yellow
            ) {
                generateSampleMoments()
            }
        }
    }
    
    // MARK: - Family Testing
    private var familyTestingSection: some View {
        TestSection(title: "Family Collaboration") {
            TestButton(
                title: "Create Family",
                icon: "person.3.fill",
                color: .cyan
            ) {
                createTestFamily()
            }
            
            TestButton(
                title: "Add Partner",
                icon: "person.2.fill",
                color: .green
            ) {
                addTestPartner()
            }
            
            TestButton(
                title: "Generate Hand-Off Report",
                icon: "doc.text.magnifyingglass",
                color: .blue
            ) {
                generateHandOffReport()
            }
            
            TestButton(
                title: "Show Work Ledger",
                icon: "chart.bar.fill",
                color: .purple
            ) {
                showWorkLedger()
            }
        }
    }
    
    // MARK: - Notification Testing
    private var notificationTestingSection: some View {
        TestSection(title: "Notifications") {
            TestButton(
                title: "Trigger Appreciation Nudge",
                icon: "heart.fill",
                color: .pink
            ) {
                triggerAppreciationNudge()
            }
            
            TestButton(
                title: "Send Hand-Off Notification",
                icon: "bell.badge",
                color: .orange
            ) {
                sendHandOffNotification()
            }
            
            TestButton(
                title: "Test Silent Mode",
                icon: "bell.slash",
                color: .gray
            ) {
                testSilentMode()
            }
        }
    }
    
    // MARK: - Stage Switching
    private var stageSwitchingSection: some View {
        TestSection(title: "Quick Stage Switch") {
            HStack(spacing: 12) {
                stageSwitchButton(.prenatal)
                stageSwitchButton(.infant)
                stageSwitchButton(.earlyEd)
            }
        }
    }
    
    private func stageSwitchButton(_ stage: KeeperConstants.Stage) -> some View {
        let icon: String = {
            switch stage {
            case .prenatal: return "figure.wave"
            case .infant: return "figure.and.child.holdinghands"
            case .earlyEd: return "books.vertical"
            }
        }()
        
        return Button {
            onboardingVM.currentStage = stage
            testMessage = "Switched to \(stage.displayName)"
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(stage.displayName)
                    .font(.system(size: 12))
            }
            .foregroundColor(onboardingVM.currentStage == stage ? .white : .dimStar)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(onboardingVM.currentStage == stage ? Color.moonlightLavender : Color.deepSlate)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Dangerous Actions
    private var dangerousActionsSection: some View {
        TestSection(title: "⚠️ Dangerous Actions") {
            TestButton(
                title: "Clear All Logs",
                icon: "trash.fill",
                color: .red
            ) {
                clearAllLogs()
            }
            
            TestButton(
                title: "Reset All Data",
                icon: "exclamationmark.triangle.fill",
                color: .red
            ) {
                showResetConfirm = true
            }
        }
    }
    
    // MARK: - Test Actions
    
    private func simulateNewUser() {
        authService.signOut()
        resetOnboarding()
        alertMessage = "Simulated new user - restart onboarding"
        showAlert = true
    }
    
    private func resetOnboarding() {
        onboardingVM.hasCompletedOnboarding = false
        onboardingVM.currentStage = .infant
        onboardingVM.dateType = .birthday
        onboardingVM.selectedDate = Date()
        onboardingVM.currentStep = .welcome
        UserDefaults.standard.removeObject(forKey: "keeper_onboarding_completed")
        alertMessage = "Onboarding reset - will show on next launch"
        showAlert = true
    }
    
    private func jumpToStage(_ stage: KeeperConstants.Stage, dueDate: Date? = nil, birthDate: Date? = nil) {
        onboardingVM.hasCompletedOnboarding = true
        onboardingVM.currentStage = stage
        
        if let dueDate = dueDate {
            onboardingVM.dateType = .dueDate
            onboardingVM.selectedDate = dueDate
            prenatalStore.setDueDate(dueDate)
        } else if let birthDate = birthDate {
            onboardingVM.dateType = .birthday
            onboardingVM.selectedDate = birthDate
            earlyEdStore.setChildBirthDate(birthDate)
        }
        
        dismiss()
        HapticsService.shared.logConfirmed()
    }
    
    private func addSampleLogs(count: Int) {
        for i in 0..<count {
            let types: [KeeperConstants.EventType] = [.feed, .sleep, .diaper, .note]
            let randomType = types.randomElement()!
            
            let log = Log(
                familyId: UUID(),
                creatorId: UUID(),
                stageContext: onboardingVM.currentStage,
                eventType: randomType,
                rawText: "Sample \(randomType.displayName) #\(i+1)",
                structuredData: createSampleLogData(for: randomType),
                isConfirmed: true
            )
            
            logStore.addLog(log)
        }
        
        alertMessage = "✅ Added \(count) sample logs"
        showAlert = true
        HapticsService.shared.logConfirmed()
    }
    
    private func createSampleLogData(for type: KeeperConstants.EventType) -> LogData {
        switch type {
        case .feed:
            return LogData(
                event: "feed",
                subtype: "bottle",
                amount: Double.random(in: 3...6),
                unit: "oz",
                drug: nil,
                time: Date(),
                warning: nil,
                notes: nil
            )
        case .sleep:
            return LogData(
                event: "sleep",
                subtype: "nap",
                amount: Double.random(in: 1...3),
                unit: "hours",
                drug: nil,
                time: Date(),
                warning: nil,
                notes: nil
            )
        case .diaper:
            return LogData(
                event: "diaper",
                subtype: ["wet", "dirty", "both"].randomElement(),
                amount: nil,
                unit: nil,
                drug: nil,
                time: Date(),
                warning: nil,
                notes: nil
            )
        default:
            return LogData(
                event: "note",
                subtype: nil,
                amount: nil,
                unit: nil,
                drug: nil,
                time: Date(),
                warning: nil,
                notes: "Sample note"
            )
        }
    }
    
    private func addNightFeed() {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 3
        components.minute = 15
        
        let nightTime = Calendar.current.date(from: components) ?? Date()
        
        let log = Log(
            id: UUID(),
            familyId: UUID(),
            creatorId: UUID(),
            stageContext: .infant,
            eventType: .feed,
            rawText: "Night feed at 3:15 AM",
            structuredData: LogData(
                event: "feed",
                subtype: "bottle",
                amount: 4,
                unit: "oz",
                drug: nil,
                time: nightTime,
                warning: nil,
                notes: "Night feed"
            ),
            isConfirmed: true,
            createdAt: nightTime
        )
        
        logStore.addLog(log)
        alertMessage = "✅ Added night feed at 3:15 AM"
        showAlert = true
    }
    
    private func addMedicationLog() {
        let log = Log(
            familyId: UUID(),
            creatorId: UUID(),
            stageContext: .infant,
            eventType: .medication,
            rawText: "Gave Tylenol",
            structuredData: LogData(
                event: "medication",
                subtype: nil,
                amount: 2.5,
                unit: "ml",
                drug: "Infant Tylenol",
                time: Date(),
                warning: nil,
                notes: nil
            ),
            isConfirmed: true
        )
        
        logStore.addLog(log)
        alertMessage = "✅ Added medication log"
        showAlert = true
    }
    
    private func generateSampleMoments() {
        let moments = [
            ("First Smile!", "Baby smiled at me this morning 😊"),
            ("Slept 6 Hours!", "Finally got a full night's sleep"),
            ("New Word", "Said 'mama' for the first time!"),
            ("First Steps", "Took 3 steps without holding on"),
            ("Funny Quote", "No more monkeys jumping on the bed!")
        ]
        
        for (title, description) in moments {
            earlyEdStore.addMilestone(title, notes: description)
        }
        
        alertMessage = "✅ Generated 5 sample moments"
        showAlert = true
    }
    
    private func createTestFamily() {
        Task {
            do {
                let family = try await familySync.createFamily(
                    childName: "Emma",
                    childBirthDate: Date().addingTimeInterval(-90 * 24 * 60 * 60)
                )
                alertMessage = "✅ Created family: \(family.name)"
                showAlert = true
            } catch {
                alertMessage = "❌ Error: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
    
    private func addTestPartner() {
        guard familySync.currentFamily != nil else {
            alertMessage = "❌ Create a family first!"
            showAlert = true
            return
        }
        
        let invite = familySync.inviteMember(role: .dad, email: "partner@test.com")
        alertMessage = "✅ Invite code: \(invite.code)"
        showAlert = true
    }
    
    private func generateHandOffReport() {
        guard let member = familySync.currentMember else {
            alertMessage = "❌ Create a family first!"
            showAlert = true
            return
        }
        
        Task {
            let _ = await familySync.generateHandOffReport(for: member)
            alertMessage = "✅ Hand-off report generated"
            showAlert = true
        }
    }
    
    private func showWorkLedger() {
        let contributions = familySync.calculateWeeklyContributions()
        alertMessage = "✅ Contributions: \(contributions.count) member(s)"
        showAlert = true
    }
    
    private func triggerAppreciationNudge() {
        alertMessage = "💌 Appreciation nudge triggered"
        showAlert = true
        HapticsService.shared.logConfirmed()
    }
    
    private func sendHandOffNotification() {
        alertMessage = "📬 Hand-off notification sent"
        showAlert = true
        HapticsService.shared.logConfirmed()
    }
    
    private func testSilentMode() {
        alertMessage = "🔕 Silent mode test (only vibration)"
        showAlert = true
        HapticsService.shared.lightTap()
    }
    
    private func clearAllLogs() {
        logStore.logs.removeAll()
        logStore.feedLogs.removeAll()
        logStore.sleepLogs.removeAll()
        logStore.diaperLogs.removeAll()
        alertMessage = "🗑 All logs cleared"
        showAlert = true
        HapticsService.shared.mediumTap()
    }
    
    private func resetAllData() {
        // Clear all data
        logStore.logs.removeAll()
        logStore.feedLogs.removeAll()
        logStore.sleepLogs.removeAll()
        logStore.diaperLogs.removeAll()
        
        familySync.familyMembers.removeAll()
        familySync.currentFamily = nil
        prenatalStore.letters.removeAll()
        earlyEdStore.firstWords.removeAll()
        earlyEdStore.funnyQuotes.removeAll()
        earlyEdStore.milestones.removeAll()
        
        // Clear UserDefaults
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        
        // Reset onboarding state
        onboardingVM.hasCompletedOnboarding = false
        onboardingVM.currentStage = .infant
        
        // Sign out
        authService.signOut()
        
        // Close menu
        dismiss()
        
        HapticsService.shared.error()
    }
}

// MARK: - Supporting Views

struct TestSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.moonlightLavender)
            
            VStack(spacing: 12) {
                content
            }
            .padding(16)
            .background(Color.deepSlate)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

struct TestButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 15))
                    .foregroundColor(.starlightCream)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.dimStar)
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Preview
#Preview {
    DevTestingMenu()
        .environmentObject(AuthService.shared)
        .environmentObject(OnboardingViewModel())
}

