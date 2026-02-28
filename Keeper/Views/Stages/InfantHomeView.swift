import SwiftUI

// MARK: - Infant Home View
// Philosophy: "We design for the night. Parents are at 40% capacity."
// This is NOT a data entry app - it's a cognitive offloading tool.
// Keep it SIMPLE. Keep it DARK. Keep it KIND.

struct InfantHomeView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var momentsService = MomentsService.shared
    @StateObject private var logStore = LogStore.shared
    @StateObject private var viewModel = ChatViewModel()
    
    @State private var showVoiceInput = false
    @State private var showFeedSheet = false
    @State private var showSleepSheet = false
    @State private var showDiaperSheet = false
    @State private var showHistorySheet = false
    
    // Timer update trigger
    @State private var timerTick = false
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Deep midnight background - easy on tired eyes
                Color.midnightSlate
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Minimal header with baby info
                    babyHeader
                    
                    // Main content
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            // Active timer if running
                            if logStore.currentFeedTimer != nil || logStore.currentSleepSession != nil {
                                activeTimerCard
                            }
                            
                            // Daily Highlight (if exists)
                            if let highlight = momentsService.getDailyHighlight() {
                                DailyHighlightCard(moment: highlight)
                            }
                            
                            // Quick Actions - ONE TAP logging
                            quickActionsSection
                            
                            // Today at a glance - minimal stats
                            todayGlance
                            
                            // Self-care reminder
                            selfCareReminder
                            
                            // Recent activity
                            recentActivitySection
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 140)
                    }
                }
                
                // Voice input FAB - the star of the show
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
            .sheet(isPresented: $showVoiceInput) {
                ChatView()
                    .environmentObject(viewModel)
            }
            .sheet(isPresented: $showFeedSheet) {
                FeedLogSheet()
            }
            .sheet(isPresented: $showSleepSheet) {
                SleepLogSheet()
            }
            .sheet(isPresented: $showDiaperSheet) {
                DiaperLogSheet()
            }
            .onReceive(timer) { _ in
                timerTick.toggle()
            }
        }
    }
    
    // MARK: - Baby Header
    private var babyHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Emma")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.starlightCream)
                
                Text(babyAgeString)
                    .font(.system(size: 15))
                    .foregroundColor(.dimStar)
            }
            
            Spacer()
            
            // Sleeping/Awake indicator
            if logStore.currentSleepSession != nil {
                sleepingIndicator
            } else {
                awakeIndicator
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private var sleepingIndicator: some View {
        HStack(spacing: 6) {
            Image(systemName: "moon.zzz.fill")
                .foregroundColor(.purple)
            Text("Sleeping")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.purple)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.purple.opacity(0.2))
        .clipShape(Capsule())
    }
    
    private var awakeIndicator: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.green)
                .frame(width: 8, height: 8)
            Text("Awake")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.dimStar)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.deepSlate)
        .clipShape(Capsule())
    }
    
    private var babyAgeString: String {
        "3 weeks old • Growing strong 💪"
    }
    
    // MARK: - Active Timer Card
    private var activeTimerCard: some View {
        VStack(spacing: 16) {
            if let feedTimer = logStore.currentFeedTimer {
                // Feed timer active
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "drop.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Feeding...")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.starlightCream)
                        
                        Text(feedTimer.elapsedFormatted)
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundColor(.blue)
                            .id(timerTick) // Force update
                        
                        if let side = feedTimer.side {
                            Text("\(side.rawValue.capitalized) side")
                                .font(.system(size: 13))
                                .foregroundColor(.dimStar)
                        }
                    }
                    
                    Spacer()
                    
                    Button {
                        logStore.completeFeedTimer()
                    } label: {
                        Text("Done")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .clipShape(Capsule())
                    }
                }
                .padding(20)
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            
            if let sleepSession = logStore.currentSleepSession {
                // Sleep session active
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.purple.opacity(0.2))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "moon.zzz.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.purple)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sleeping...")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.starlightCream)
                        
                        Text(sleepSession.elapsedFormatted)
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundColor(.purple)
                            .id(timerTick) // Force update
                    }
                    
                    Spacer()
                    
                    Button {
                        logStore.endSleepSession()
                    } label: {
                        Text("Wake")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.purple)
                            .clipShape(Capsule())
                    }
                }
                .padding(20)
                .background(Color.purple.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
        }
    }
    
    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Log")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.starlightCream)
            
            HStack(spacing: 12) {
                QuickLogButton(
                    icon: "drop.fill",
                    label: "Feed",
                    color: .blue,
                    lastTime: logStore.timeSinceLastFeed
                ) {
                    showFeedSheet = true
                }
                
                QuickLogButton(
                    icon: "moon.zzz.fill",
                    label: "Sleep",
                    color: .purple,
                    lastTime: logStore.awakeTime
                ) {
                    if logStore.currentSleepSession == nil {
                        logStore.startSleepSession()
                    } else {
                        showSleepSheet = true
                    }
                }
                
                QuickLogButton(
                    icon: "heart.fill",
                    label: "Diaper",
                    color: .green,
                    lastTime: logStore.lastDiaperTime.map { formatTimeAgo($0) } ?? "No logs"
                ) {
                    showDiaperSheet = true
                }
            }
        }
    }
    
    // MARK: - Today At a Glance
    private var todayGlance: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Today")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.starlightCream)
                Spacer()
            }
            
            HStack(spacing: 0) {
                GlanceItem(value: "\(logStore.todaysFeedCount)", label: "Feeds", color: .blue)
                GlanceItem(value: String(format: "%.1fh", logStore.todaysSleepHours), label: "Sleep", color: .purple)
                GlanceItem(value: "\(logStore.todaysDiaperCount)", label: "Diapers", color: .green)
            }
        }
        .padding(20)
        .background(Color.deepSlate)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    // MARK: - Self Care Reminder
    private var selfCareReminder: some View {
        let logsToday = logStore.logsForToday().count
        
        return Group {
            if logsToday > 8 {
                RestReminderCard(
                    message: "You've logged \(logsToday) times today. Remember to rest when baby rests. 💜"
                )
            } else if logsToday > 0 {
                // Gentle encouragement
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.15))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.green)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("You're doing great 💪")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.starlightCream)
                        
                        Text("\(logsToday) logs today. Keeper has your back.")
                            .font(.system(size: 13))
                            .foregroundColor(.dimStar)
                    }
                    
                    Spacer()
                }
                .padding(16)
                .background(Color.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }
    
    // MARK: - Recent Activity
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.dimStar)
                Spacer()
            }
            
            let recentLogs = logStore.recentLogs(limit: 5)
            
            if recentLogs.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 32))
                        .foregroundColor(.dimStar.opacity(0.5))
                    Text("No logs yet today")
                        .font(.system(size: 14))
                        .foregroundColor(.dimStar)
                }
                .frame(maxWidth: .infinity)
                .padding(32)
            } else {
                VStack(spacing: 8) {
                    ForEach(recentLogs) { log in
                        RecentLogItem(
                            icon: log.eventType.icon,
                            text: formatLogText(log),
                            time: formatTimeAgo(log.createdAt),
                            color: colorForEventType(log.eventType)
                        )
                    }
                }
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
                // Glow effect
                Circle()
                    .fill(Color.moonlightLavender.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .blur(radius: 10)
                
                // Main button
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
    
    // MARK: - Helpers
    
    private func formatTimeAgo(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let minutes = Int(interval) / 60
        let hours = minutes / 60
        
        if hours > 0 {
            return "\(hours)h ago"
        } else if minutes > 0 {
            return "\(minutes)m ago"
        } else {
            return "Just now"
        }
    }
    
    private func formatLogText(_ log: Log) -> String {
        guard let data = log.structuredData else {
            return log.eventType.displayName
        }
        
        switch log.eventType {
        case .feed:
            if let amount = data.amount, let unit = data.unit {
                return "Fed \(Int(amount))\(unit)"
            }
            return "Fed"
        case .sleep:
            if let amount = data.amount {
                return String(format: "Slept %.1fh", amount)
            }
            return "Slept"
        case .diaper:
            return "Diaper (\(data.subtype ?? "change"))"
        default:
            return log.eventType.displayName
        }
    }
    
    private func colorForEventType(_ type: KeeperConstants.EventType) -> Color {
        switch type {
        case .feed: return .blue
        case .sleep: return .purple
        case .diaper: return .green
        case .medication: return .orange
        default: return .moonlightLavender
        }
    }
}

// MARK: - Quick Log Button
struct QuickLogButton: View {
    let icon: String
    let label: String
    let color: Color
    let lastTime: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(color)
                }
                
                VStack(spacing: 2) {
                    Text(label)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.starlightCream)
                    
                    Text(lastTime)
                        .font(.system(size: 12))
                        .foregroundColor(.dimStar)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.deepSlate)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

// MARK: - Glance Item
struct GlanceItem: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(color)
            
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.dimStar)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Recent Log Item
struct RecentLogItem: View {
    let icon: String
    let text: String
    let time: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.starlightCream)
            
            Spacer()
            
            Text(time)
                .font(.system(size: 12))
                .foregroundColor(.dimStar)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Feed Log Sheet
struct FeedLogSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var logStore = LogStore.shared
    
    @State private var feedType: FeedType = .bottle
    @State private var amount: Double = 4
    @State private var side: BreastSide = .left
    @State private var showTimer = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.midnightSlate
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Feed Type Selector
                    HStack(spacing: 12) {
                        ForEach(FeedType.allCases, id: \.self) { type in
                            Button {
                                feedType = type
                            } label: {
                                Text(type.rawValue)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(feedType == type ? .white : .dimStar)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(feedType == type ? Color.moonlightLavender : Color.deepSlate)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    
                    if feedType == .breast {
                        // Side selector
                        HStack(spacing: 24) {
                            SideButton(side: .left, isSelected: side == .left) {
                                side = .left
                            }
                            SideButton(side: .right, isSelected: side == .right) {
                                side = .right
                            }
                        }
                        
                        // Timer option
                        Button {
                            logStore.startFeedTimer(type: .breast, side: side)
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "timer")
                                Text("Start Timer")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    } else {
                        // Amount picker
                        VStack(spacing: 8) {
                            Text("\(Int(amount)) oz")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.starlightCream)
                            
                            Slider(value: $amount, in: 1...10, step: 0.5)
                                .tint(.blue)
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    Spacer()
                    
                    // Log button
                    Button {
                        if feedType == .breast {
                            logStore.quickLogFeed(type: .breast, side: side)
                        } else {
                            logStore.quickLogFeed(type: feedType, amount: amount)
                        }
                        dismiss()
                    } label: {
                        Text("Log Feed")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.safeGreen)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.bottom, 24)
                }
                .padding(24)
            }
            .navigationTitle("Log Feed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.dimStar)
                }
            }
        }
    }
}

struct SideButton: View {
    let side: BreastSide
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.moonlightLavender : Color.deepSlate)
                        .frame(width: 70, height: 70)
                    
                    Text(side == .left ? "L" : "R")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(isSelected ? .white : .dimStar)
                }
                
                Text(side == .left ? "Left" : "Right")
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? .starlightCream : .dimStar)
            }
        }
    }
}

// MARK: - Sleep Log Sheet
struct SleepLogSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var logStore = LogStore.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.midnightSlate
                    .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    if let session = logStore.currentSleepSession {
                        // Show current sleep session
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.purple.opacity(0.2))
                                    .frame(width: 120, height: 120)
                                
                                Image(systemName: "moon.zzz.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(.purple)
                            }
                            
                            Text("Sleeping...")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.starlightCream)
                            
                            Text(session.elapsedFormatted)
                                .font(.system(size: 40, weight: .bold, design: .monospaced))
                                .foregroundColor(.purple)
                        }
                        
                        Spacer()
                        
                        Button {
                            logStore.endSleepSession()
                            dismiss()
                        } label: {
                            Text("Wake Up")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(Color.yellow)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    } else {
                        // Start sleep session
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.yellow.opacity(0.2))
                                    .frame(width: 120, height: 120)
                                
                                Image(systemName: "sun.max.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(.yellow)
                            }
                            
                            Text("Baby is awake")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.starlightCream)
                        }
                        
                        Spacer()
                        
                        Button {
                            logStore.startSleepSession()
                            dismiss()
                        } label: {
                            Text("Start Sleep")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(Color.purple)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }
                .padding(24)
                .padding(.bottom, 24)
            }
            .navigationTitle("Sleep")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.dimStar)
                }
            }
        }
    }
}

// MARK: - Diaper Log Sheet
struct DiaperLogSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var logStore = LogStore.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.midnightSlate
                    .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    Text("What type?")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.starlightCream)
                    
                    HStack(spacing: 20) {
                        DiaperOptionCard(
                            title: "Wet",
                            icon: "drop.fill",
                            color: .blue
                        ) {
                            logStore.quickLogDiaper(type: .wet)
                            dismiss()
                        }
                        
                        DiaperOptionCard(
                            title: "Dirty",
                            icon: "leaf.fill",
                            color: .brown
                        ) {
                            logStore.quickLogDiaper(type: .dirty)
                            dismiss()
                        }
                        
                        DiaperOptionCard(
                            title: "Both",
                            icon: "circle.grid.2x2.fill",
                            color: .green
                        ) {
                            logStore.quickLogDiaper(type: .both)
                            dismiss()
                        }
                    }
                    
                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("Log Diaper")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.dimStar)
                }
            }
        }
    }
}

struct DiaperOptionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: icon)
                        .font(.system(size: 28))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.starlightCream)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(Color.deepSlate)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

// MARK: - Preview
#Preview {
    InfantHomeView()
        .environmentObject(AuthService.shared)
}
