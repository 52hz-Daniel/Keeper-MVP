import SwiftUI

// MARK: - Insights Dashboard View
// Reference: Keeper Expansion - "Pattern Recognition Engine"
// The "Digital Memory Keeper" - Shows patterns and milestones

struct InsightsDashboardView: View {
    @EnvironmentObject var chatViewModel: ChatViewModel
    @State private var selectedTab: InsightTab = .overview
    
    private let insightService = InsightService.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.midnightSlate
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Tab Selector
                        tabSelector
                        
                        // Content based on selected tab
                        switch selectedTab {
                        case .overview:
                            overviewContent
                        case .patterns:
                            patternsContent
                        case .milestones:
                            milestonesContent
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.midnightSlate, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
    
    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 8) {
            ForEach(InsightTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    Text(tab.title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(selectedTab == tab ? .white : .dimStar)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(selectedTab == tab ? Color.moonlightLavender : Color.clear)
                        )
                }
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(Color.deepSlate)
        )
    }
    
    // MARK: - Overview Content
    private var overviewContent: some View {
        VStack(spacing: 20) {
            // Today's Summary Card
            InsightsTodaySummaryCard()
            
            // Quick Stats Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                StatCard(
                    title: "Logs Today",
                    value: "12",
                    icon: "list.bullet.clipboard",
                    color: .moonlightLavender
                )
                
                StatCard(
                    title: "Sleep Total",
                    value: "14h",
                    icon: "moon.fill",
                    color: .cyan
                )
                
                StatCard(
                    title: "Feedings",
                    value: "6",
                    icon: "cup.and.saucer.fill",
                    color: .orange
                )
                
                StatCard(
                    title: "Diapers",
                    value: "8",
                    icon: "drop.fill",
                    color: .blue
                )
            }
            
            // Stage-specific insight
            StageInsightCard(stage: chatViewModel.currentStage)
        }
    }
    
    // MARK: - Patterns Content
    private var patternsContent: some View {
        VStack(spacing: 20) {
            // Sleep Pattern Card
            PatternCard(
                title: "Sleep Pattern",
                icon: "moon.stars.fill",
                iconColor: .cyan,
                content: {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Average sleep: 2.5 hours per nap")
                            .font(.system(size: 16))
                            .foregroundColor(.starlightCream)
                        
                        Text("Most naps start around 1:00 PM")
                            .font(.system(size: 14))
                            .foregroundColor(.dimStar)
                        
                        // Simple bar chart representation
                        HStack(alignment: .bottom, spacing: 4) {
                            ForEach(0..<7, id: \.self) { day in
                                VStack(spacing: 4) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.cyan.opacity(0.7))
                                        .frame(width: 30, height: CGFloat.random(in: 30...80))
                                    
                                    Text(dayAbbreviation(day))
                                        .font(.system(size: 10))
                                        .foregroundColor(.dimStar)
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                }
            )
            
            // Feeding Pattern Card
            PatternCard(
                title: "Feeding Pattern",
                icon: "cup.and.saucer.fill",
                iconColor: .orange,
                content: {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Average intake: 24oz per day")
                            .font(.system(size: 16))
                            .foregroundColor(.starlightCream)
                        
                        Text("Feeds every 2-3 hours")
                            .font(.system(size: 14))
                            .foregroundColor(.dimStar)
                    }
                }
            )
            
            // Behavior Pattern (for toddlers)
            if chatViewModel.currentStage == .earlyEd {
                PatternCard(
                    title: "Behavior Insights",
                    icon: "brain.head.profile",
                    iconColor: .yellow,
                    content: {
                        VStack(alignment: .leading, spacing: 12) {
                            InsightRow(
                                emoji: "📱",
                                text: "70% of tantrums occur after screen time"
                            )
                            
                            InsightRow(
                                emoji: "😴",
                                text: "Crankiness peaks around 5 PM"
                            )
                            
                            InsightRow(
                                emoji: "💡",
                                text: "Suggestion: Start wind-down routine at 4:30 PM"
                            )
                        }
                    }
                )
            }
        }
    }
    
    // MARK: - Milestones Content
    private var milestonesContent: some View {
        VStack(spacing: 20) {
            // Vocabulary Cloud (for toddlers)
            if chatViewModel.currentStage == .earlyEd {
                VocabularyCloudCard()
            }
            
            // Recent Milestones
            VStack(alignment: .leading, spacing: 16) {
                Text("Recent Milestones")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.starlightCream)
                
                MilestoneRow(
                    date: "Nov 28",
                    title: "First Steps!",
                    icon: "figure.walk",
                    color: .yellow
                )
                
                MilestoneRow(
                    date: "Nov 15",
                    title: "Said 'Mama'",
                    icon: "text.bubble.fill",
                    color: .cyan
                )
                
                MilestoneRow(
                    date: "Nov 10",
                    title: "Slept through the night",
                    icon: "moon.stars.fill",
                    color: .moonlightLavender
                )
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.deepSlate)
            )
            
            // Generate Yearbook Button
            Button {
                // TODO: Generate yearbook
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "book.fill")
                        .font(.system(size: 20))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Generate Yearbook")
                            .font(.system(size: 16, weight: .semibold))
                        
                        Text("Your first year in data")
                            .font(.system(size: 12))
                            .opacity(0.7)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .opacity(0.5)
                }
                .foregroundColor(.white)
                .padding(16)
                .background(
                    LinearGradient(
                        colors: [.moonlightLavender, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }
    
    // MARK: - Helpers
    
    private func dayAbbreviation(_ index: Int) -> String {
        let days = ["M", "T", "W", "T", "F", "S", "S"]
        return days[index % 7]
    }
}

// MARK: - Insight Tab
enum InsightTab: CaseIterable {
    case overview
    case patterns
    case milestones
    
    var title: String {
        switch self {
        case .overview: return "Overview"
        case .patterns: return "Patterns"
        case .milestones: return "Milestones"
        }
    }
}

// MARK: - Today's Insights Summary Card
struct InsightsTodaySummaryCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's Summary")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.starlightCream)
                
                Spacer()
                
                Text(Date(), style: .date)
                    .font(.system(size: 14))
                    .foregroundColor(.dimStar)
            }
            
            Divider()
                .background(Color.slateGray)
            
            Text("Baby had a good day! 3 naps totaling 4.5 hours, 5 feedings, and was happy most of the day.")
                .font(.system(size: 15))
                .foregroundColor(.dimStar)
                .lineSpacing(4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.deepSlate)
        )
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.starlightCream)
            
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.dimStar)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.deepSlate)
        )
    }
}

// MARK: - Stage Insight Card
struct StageInsightCard: View {
    let stage: KeeperConstants.Stage
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: stageIcon)
                .font(.system(size: 32))
                .foregroundColor(stageColor)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(stageTitle)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.starlightCream)
                
                Text(stageDescription)
                    .font(.system(size: 14))
                    .foregroundColor(.dimStar)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(stageColor.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(stageColor.opacity(0.3), lineWidth: 1)
                )
        )
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
    
    private var stageTitle: String {
        switch stage {
        case .prenatal: return "Pre-Natal Mode"
        case .infant: return "Infant Mode"
        case .earlyEd: return "Toddler Mode"
        }
    }
    
    private var stageDescription: String {
        switch stage {
        case .prenatal: return "Tracking symptoms and preparations"
        case .infant: return "Focused on survival metrics"
        case .earlyEd: return "Discovering patterns and milestones"
        }
    }
}

// MARK: - Pattern Card
struct PatternCard<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
                
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.starlightCream)
            }
            
            content()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.deepSlate)
        )
    }
}

// MARK: - Insight Row
struct InsightRow: View {
    let emoji: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(emoji)
                .font(.system(size: 20))
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.dimStar)
        }
    }
}

// MARK: - Vocabulary Cloud Card
struct VocabularyCloudCard: View {
    let words = ["apple", "mama", "dada", "ball", "dog", "cat", "milk", "more", "no", "yes"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "text.bubble.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.cyan)
                
                Text("Vocabulary Vault")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.starlightCream)
                
                Spacer()
                
                Text("\(words.count) words")
                    .font(.system(size: 14))
                    .foregroundColor(.dimStar)
            }
            
            // Word cloud
            FlowLayout(spacing: 8) {
                ForEach(words, id: \.self) { word in
                    Text(word)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.starlightCream)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.cyan.opacity(0.2))
                        )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.deepSlate)
        )
    }
}

// MARK: - Milestone Row
struct MilestoneRow: View {
    let date: String
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.starlightCream)
                
                Text(date)
                    .font(.system(size: 12))
                    .foregroundColor(.dimStar)
            }
            
            Spacer()
            
            Image(systemName: "star.fill")
                .font(.system(size: 14))
                .foregroundColor(.yellow)
        }
    }
}

// FlowLayout moved to Utilities/FlowLayout.swift

// MARK: - Preview
#Preview {
    InsightsDashboardView()
        .environmentObject(ChatViewModel())
}

