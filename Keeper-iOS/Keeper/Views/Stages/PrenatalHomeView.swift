import SwiftUI

// MARK: - Prenatal Home View
// Philosophy: "The Project Manager" - Calm preparation, emotional connection
// 
// Key Features:
// 1. Beautiful countdown - celebrate the anticipation
// 2. Kick counter - simple, reassuring
// 3. Contraction timer - for when it's time
// 4. Letters to baby - emotional keepsake (the rewarding part!)
// 5. Hospital bag - stress-free preparation
// 6. Self-care reminders - mom's wellbeing matters

struct PrenatalHomeView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var onboardingVM: OnboardingViewModel
    @StateObject private var prenatalStore = PrenatalStore.shared
    @StateObject private var viewModel = ChatViewModel()
    
    @State private var showVoiceInput = false
    @State private var showKickCounter = false
    @State private var showContractionTimer = false
    @State private var showLetterEditor = false
    @State private var showHospitalBag = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Unified dark theme
                Color.midnightSlate
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Week banner
                    pregnancyHeader
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            // Beautiful countdown
                            countdownCard
                            
                            // Letter to baby - emotional, rewarding
                            letterToBabyCard
                            
                            // Quick actions
                            quickActionsGrid
                            
                            // Weekly development info
                            weeklyDevelopmentCard
                            
                            // Self-care reminder
                            selfCareCard
                            
                            // Recent notes
                            if !prenatalStore.recentNotes.isEmpty {
                                recentNotesSection
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 140)
                    }
                }
                
                // Voice FAB
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        voiceFAB
                            .padding(.trailing, 24)
                            .padding(.bottom, 32)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showKickCounter) {
                KickCounterSheet()
            }
            .sheet(isPresented: $showContractionTimer) {
                ContractionTimerSheet()
            }
            .sheet(isPresented: $showLetterEditor) {
                LetterToBabySheet()
            }
            .sheet(isPresented: $showHospitalBag) {
                HospitalBagSheet()
            }
            .sheet(isPresented: $showVoiceInput) {
                ChatView()
                    .environmentObject(viewModel)
            }
        }
    }
    
    // MARK: - Pregnancy Header
    private var pregnancyHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Week \(prenatalStore.currentWeek)")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.starlightCream)
                
                Text(prenatalStore.trimesterText)
                    .font(.system(size: 15))
                    .foregroundColor(.dimStar)
            }
            
            Spacer()
            
            // Baby size indicator
            VStack(spacing: 4) {
                Text(prenatalStore.babySizeEmoji)
                    .font(.system(size: 32))
                Text(prenatalStore.babySizeName)
                    .font(.system(size: 11))
                    .foregroundColor(.dimStar)
            }
            .padding(12)
            .background(Color.deepSlate)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    // MARK: - Countdown Card
    private var countdownCard: some View {
        VStack(spacing: 16) {
            Text("\(prenatalStore.daysRemaining)")
                .font(.system(size: 72, weight: .bold))
                .foregroundColor(.moonlightLavender)
            
            Text("days until you meet your baby 💜")
                .font(.system(size: 16))
                .foregroundColor(.dimStar)
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.deepSlate)
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.moonlightLavender)
                        .frame(width: geometry.size.width * prenatalStore.progress, height: 8)
                }
            }
            .frame(height: 8)
            .padding(.horizontal, 20)
            
            Text("\(Int(prenatalStore.progress * 100))% of the journey complete")
                .font(.system(size: 14))
                .foregroundColor(.moonlightLavender)
        }
        .padding(24)
        .background(Color.deepSlate)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    // MARK: - Letter to Baby Card
    private var letterToBabyCard: some View {
        Button {
            showLetterEditor = true
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.pink.opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.pink)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Write to Your Baby")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.starlightCream)
                    
                    if prenatalStore.letters.isEmpty {
                        Text("Start your first letter - a gift they'll treasure forever 💌")
                            .font(.system(size: 14))
                            .foregroundColor(.dimStar)
                    } else {
                        Text("\(prenatalStore.letters.count) letter\(prenatalStore.letters.count == 1 ? "" : "s") saved")
                            .font(.system(size: 14))
                            .foregroundColor(.pink)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.dimStar)
            }
            .padding(20)
            .background(Color.pink.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    // MARK: - Quick Actions
    private var quickActionsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            PrenatalActionCard(
                icon: "figure.wave",
                title: "Kick Counter",
                subtitle: prenatalStore.lastKickCount > 0 ? "\(prenatalStore.lastKickCount) kicks" : "Count movements",
                color: .cyan
            ) {
                showKickCounter = true
            }
            
            PrenatalActionCard(
                icon: "timer",
                title: "Contractions",
                subtitle: prenatalStore.isNearDue ? "Ready when you are" : "For later",
                color: prenatalStore.isNearDue ? .orange : Color.dimStar.opacity(0.5)
            ) {
                showContractionTimer = true
            }
            
            PrenatalActionCard(
                icon: "bag.fill",
                title: "Hospital Bag",
                subtitle: "\(prenatalStore.packedItems)/\(prenatalStore.totalBagItems) packed",
                color: .green
            ) {
                showHospitalBag = true
            }
            
            PrenatalActionCard(
                icon: "heart.text.square",
                title: "Log Symptom",
                subtitle: "Quick voice note",
                color: .purple
            ) {
                showVoiceInput = true
            }
        }
    }
    
    // MARK: - Weekly Development Card
    private var weeklyDevelopmentCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.yellow)
                Text("This Week")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.starlightCream)
            }
            
            Text(prenatalStore.weeklyDevelopmentText)
                .font(.system(size: 15))
                .foregroundColor(.dimStar)
                .lineSpacing(4)
            
            // Fun fact
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                    .font(.system(size: 14))
                Text(prenatalStore.weeklyFunFact)
                    .font(.system(size: 13))
                    .foregroundColor(.yellow)
            }
            .padding(12)
            .background(Color.yellow.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(20)
        .background(Color.deepSlate)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Self Care Card
    private var selfCareCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "leaf.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.green)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Self-Care Reminder")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.starlightCream)
                
                Text(prenatalStore.selfCareReminder)
                    .font(.system(size: 13))
                    .foregroundColor(.dimStar)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color.green.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Recent Notes
    private var recentNotesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Notes")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.dimStar)
            
            ForEach(prenatalStore.recentNotes.prefix(3)) { note in
                HStack {
                    Text(note.text)
                        .font(.system(size: 14))
                        .foregroundColor(.starlightCream)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(note.timeAgo)
                        .font(.system(size: 12))
                        .foregroundColor(.dimStar)
                }
                .padding(12)
                .background(Color.deepSlate)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }
    
    // MARK: - Voice FAB
    private var voiceFAB: some View {
        Button {
            showVoiceInput = true
            HapticsService.shared.lightTap()
        } label: {
            ZStack {
                Circle()
                    .fill(Color.moonlightLavender.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .blur(radius: 10)
                
                Circle()
                    .fill(Color.moonlightLavender)
                    .frame(width: 64, height: 64)
                    .shadow(color: Color.moonlightLavender.opacity(0.5), radius: 12, y: 4)
                
                Image(systemName: "mic.fill")
                    .font(.system(size: 26))
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - Prenatal Action Card
struct PrenatalActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.starlightCream)
                
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.dimStar)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color.deepSlate)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

// MARK: - Kick Counter Sheet
struct KickCounterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var prenatalStore = PrenatalStore.shared
    
    @State private var kickCount = 0
    @State private var sessionStart: Date? = nil
    @State private var isActive = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.midnightSlate
                    .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    Text("Count 10 movements in 2 hours")
                        .font(.system(size: 16))
                        .foregroundColor(.dimStar)
                    
                    // Counter ring
                    ZStack {
                        Circle()
                            .stroke(Color.cyan.opacity(0.2), lineWidth: 12)
                            .frame(width: 200, height: 200)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(min(kickCount, 10)) / 10)
                            .stroke(Color.cyan, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                            .frame(width: 200, height: 200)
                            .rotationEffect(.degrees(-90))
                        
                        VStack(spacing: 8) {
                            Text("\(kickCount)")
                                .font(.system(size: 72, weight: .bold))
                                .foregroundColor(.starlightCream)
                            
                            Text("kicks")
                                .font(.system(size: 18))
                                .foregroundColor(.dimStar)
                        }
                    }
                    
                    // Goal reached message
                    if kickCount >= 10 {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Goal reached! Baby is active 🎉")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.green)
                        }
                        .padding(12)
                        .background(Color.green.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Spacer()
                    
                    // Kick button
                    Button {
                        if !isActive {
                            isActive = true
                            sessionStart = Date()
                        }
                        kickCount += 1
                        HapticsService.shared.lightTap()
                    } label: {
                        Text("👶 Tap for Kick")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 64)
                            .background(Color.cyan)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                    
                    HStack(spacing: 16) {
                        Button {
                            kickCount = 0
                            isActive = false
                        } label: {
                            Text("Reset")
                                .font(.system(size: 16))
                                .foregroundColor(.dimStar)
                        }
                        
                        Button {
                            prenatalStore.saveKickSession(count: kickCount)
                            dismiss()
                        } label: {
                            Text("Save")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.cyan)
                        }
                    }
                    .padding(.bottom, 24)
                }
                .padding(24)
            }
            .navigationTitle("Kick Counter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.dimStar)
                }
            }
        }
    }
}

// MARK: - Contraction Timer Sheet
struct ContractionTimerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var prenatalStore = PrenatalStore.shared
    
    @State private var isContracting = false
    @State private var contractionStart: Date?
    @State private var contractions: [Contraction] = []
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var timerTick = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.midnightSlate
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Status
                    Text(isContracting ? "Contraction in progress..." : "Tap when a contraction starts")
                        .font(.system(size: 16))
                        .foregroundColor(.dimStar)
                    
                    // Timer display
                    if isContracting, let start = contractionStart {
                        Text(formatDuration(Date().timeIntervalSince(start)))
                            .font(.system(size: 64, weight: .bold, design: .monospaced))
                            .foregroundColor(.orange)
                            .id(timerTick)
                    } else {
                        Text("00:00")
                            .font(.system(size: 64, weight: .bold, design: .monospaced))
                            .foregroundColor(.dimStar)
                    }
                    
                    // Main button
                    Button {
                        if isContracting {
                            // End contraction
                            if let start = contractionStart {
                                let duration = Date().timeIntervalSince(start)
                                let lastEnd = contractions.last?.endTime
                                let interval = lastEnd.map { start.timeIntervalSince($0) }
                                contractions.append(Contraction(
                                    startTime: start,
                                    endTime: Date(),
                                    duration: duration,
                                    intervalFromPrevious: interval
                                ))
                            }
                            isContracting = false
                            contractionStart = nil
                        } else {
                            // Start contraction
                            isContracting = true
                            contractionStart = Date()
                        }
                        HapticsService.shared.mediumTap()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(isContracting ? Color.orange : Color.deepSlate)
                                .frame(width: 150, height: 150)
                            
                            Text(isContracting ? "STOP" : "START")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(isContracting ? .white : .orange)
                        }
                    }
                    
                    // Stats
                    if !contractions.isEmpty {
                        VStack(spacing: 12) {
                            HStack(spacing: 32) {
                                VStack {
                                    Text("\(contractions.count)")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.starlightCream)
                                    Text("Total")
                                        .font(.system(size: 12))
                                        .foregroundColor(.dimStar)
                                }
                                
                                VStack {
                                    Text(formatDuration(averageDuration))
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.starlightCream)
                                    Text("Avg Duration")
                                        .font(.system(size: 12))
                                        .foregroundColor(.dimStar)
                                }
                                
                                VStack {
                                    Text(formatDuration(averageInterval))
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.starlightCream)
                                    Text("Avg Interval")
                                        .font(.system(size: 12))
                                        .foregroundColor(.dimStar)
                                }
                            }
                        }
                        .padding(20)
                        .background(Color.deepSlate)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    
                    // When to go guidance
                    VStack(spacing: 8) {
                        Text("📞 Call your provider when:")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.starlightCream)
                        Text("Contractions are 5 min apart, lasting 1 min, for 1 hour")
                            .font(.system(size: 13))
                            .foregroundColor(.dimStar)
                            .multilineTextAlignment(.center)
                    }
                    .padding(16)
                    .background(Color.orange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("Contraction Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.dimStar)
                }
            }
            .onReceive(timer) { _ in
                if isContracting {
                    timerTick.toggle()
                }
            }
        }
    }
    
    private var averageDuration: TimeInterval {
        guard !contractions.isEmpty else { return 0 }
        return contractions.map(\.duration).reduce(0, +) / Double(contractions.count)
    }
    
    private var averageInterval: TimeInterval {
        let intervals = contractions.compactMap(\.intervalFromPrevious)
        guard !intervals.isEmpty else { return 0 }
        return intervals.reduce(0, +) / Double(intervals.count)
    }
    
    private func formatDuration(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct Contraction: Identifiable {
    let id = UUID()
    let startTime: Date
    let endTime: Date
    let duration: TimeInterval
    let intervalFromPrevious: TimeInterval?
}

// MARK: - Letter to Baby Sheet
struct LetterToBabySheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var prenatalStore = PrenatalStore.shared
    
    @State private var letterText = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.midnightSlate
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Dear Baby,")
                            .font(.system(size: 24, weight: .bold, design: .serif))
                            .foregroundColor(.pink)
                        
                        Text("Week \(prenatalStore.currentWeek)")
                            .font(.system(size: 14))
                            .foregroundColor(.dimStar)
                    }
                    
                    // Text editor
                    TextEditor(text: $letterText)
                        .font(.system(size: 16, design: .serif))
                        .foregroundColor(.starlightCream)
                        .scrollContentBackground(.hidden)
                        .focused($isFocused)
                        .frame(maxHeight: .infinity)
                        .padding(16)
                        .background(Color.deepSlate)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // Prompts
                    if letterText.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Ideas to write about:")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.dimStar)
                            
                            ForEach(letterPrompts, id: \.self) { prompt in
                                Button {
                                    letterText = prompt + " "
                                    isFocused = true
                                } label: {
                                    Text("• \(prompt)")
                                        .font(.system(size: 13))
                                        .foregroundColor(.pink)
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.pink.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // Save button
                    Button {
                        if !letterText.isEmpty {
                            prenatalStore.saveLetter(letterText, week: prenatalStore.currentWeek)
                            dismiss()
                        }
                    } label: {
                        Text("Save Letter 💌")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(letterText.isEmpty ? Color.dimStar : Color.pink)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(letterText.isEmpty)
                }
                .padding(24)
            }
            .navigationTitle("Letter to Baby")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.dimStar)
                }
            }
        }
    }
    
    private var letterPrompts: [String] {
        [
            "How I felt when I found out about you...",
            "What I dream about for your future...",
            "The first thing I want to show you...",
            "How your \(["dad", "other parent"].randomElement()!) reacted..."
        ]
    }
}

// MARK: - Hospital Bag Sheet
struct HospitalBagSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var prenatalStore = PrenatalStore.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.midnightSlate
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Progress
                        VStack(spacing: 12) {
                            Text("\(prenatalStore.packedItems) of \(prenatalStore.totalBagItems)")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.green)
                            
                            ProgressView(value: Double(prenatalStore.packedItems), total: Double(prenatalStore.totalBagItems))
                                .tint(.green)
                            
                            Text(prenatalStore.packedItems == prenatalStore.totalBagItems ?
                                 "You're all set! 🎉" : "No rush - you've got time 💛")
                                .font(.system(size: 14))
                                .foregroundColor(.dimStar)
                        }
                        .padding(20)
                        .background(Color.deepSlate)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        // Categories
                        ForEach(BagCategory.allCases, id: \.self) { category in
                            BagCategorySection(
                                category: category,
                                items: $prenatalStore.bagItems
                            )
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Hospital Bag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.moonlightLavender)
                }
            }
        }
    }
}

struct BagCategorySection: View {
    let category: BagCategory
    @Binding var items: [BagItem]
    
    var categoryItems: [BagItem] {
        items.filter { $0.category == category }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: category.icon)
                    .foregroundColor(.green)
                Text(category.rawValue)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.starlightCream)
            }
            
            ForEach(categoryItems) { item in
                Button {
                    if let index = items.firstIndex(where: { $0.id == item.id }) {
                        items[index].isPacked.toggle()
                        HapticsService.shared.lightTap()
                    }
                } label: {
                    HStack {
                        Image(systemName: item.isPacked ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(item.isPacked ? .green : .dimStar)
                        
                        Text(item.name)
                            .font(.system(size: 15))
                            .foregroundColor(item.isPacked ? .dimStar : .starlightCream)
                            .strikethrough(item.isPacked)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(16)
        .background(Color.deepSlate)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Preview
#Preview {
    PrenatalHomeView()
        .environmentObject(AuthService.shared)
}













