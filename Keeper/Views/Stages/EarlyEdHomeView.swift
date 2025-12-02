import SwiftUI

// MARK: - Early Education Home View
// Philosophy: "The Pattern Keeper" - Celebrate growth, capture joy
// 
// CRITICAL SIMPLIFICATION:
// - NO complex development tracking (that's what pediatricians are for)
// - NO vocabulary counters with anxiety-inducing numbers
// - NO activity scheduling
//
// INSTEAD:
// - Celebrate moments and milestones
// - Capture the little joys (first words, funny quotes, milestones)
// - Surface happy memories at the right times
// - Help parents feel GOOD about the journey

struct EarlyEdHomeView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var momentsService = MomentsService.shared
    @StateObject private var earlyEdStore = EarlyEdStore.shared
    @StateObject private var viewModel = ChatViewModel()
    
    @State private var showVoiceInput = false
    @State private var showNewWordSheet = false
    @State private var showFunnyQuoteSheet = false
    @State private var showMilestoneSheet = false
    @State private var showMemoryBook = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Unified dark theme - consistent experience
                Color.midnightSlate
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Child header
                    childHeader
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            // Today's highlight
                            if let highlight = earlyEdStore.todaysHighlight {
                                todaysHighlightCard(highlight)
                            }
                            
                            // Quick capture section
                            momentCaptureSection
                            
                            // First words collection (joyful, not tracked)
                            if !earlyEdStore.firstWords.isEmpty {
                                firstWordsSection
                            }
                            
                            // Funny quotes (the best part of toddlerhood!)
                            if !earlyEdStore.funnyQuotes.isEmpty {
                                funnyQuotesSection
                            }
                            
                            // Memory book teaser
                            memoryBookCard
                            
                            // Recent moments
                            recentMomentsSection
                            
                            // Gentle encouragement
                            encouragementCard
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
            .sheet(isPresented: $showVoiceInput) {
                ChatView()
                    .environmentObject(viewModel)
            }
            .sheet(isPresented: $showNewWordSheet) {
                NewWordSheet()
            }
            .sheet(isPresented: $showFunnyQuoteSheet) {
                FunnyQuoteSheet()
            }
            .sheet(isPresented: $showMilestoneSheet) {
                MilestoneSheet()
            }
            .sheet(isPresented: $showMemoryBook) {
                MemoryBookView()
            }
        }
    }
    
    // MARK: - Child Header
    private var childHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(earlyEdStore.childName)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.starlightCream)
                
                Text(earlyEdStore.ageDescription)
                    .font(.system(size: 15))
                    .foregroundColor(.dimStar)
            }
            
            Spacer()
            
            // Fun emoji based on recent activity
            ZStack {
                Circle()
                    .fill(Color.yellow.opacity(0.15))
                    .frame(width: 56, height: 56)
                
                Text(earlyEdStore.moodEmoji)
                    .font(.system(size: 28))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    // MARK: - Today's Highlight
    private func todaysHighlightCard(_ highlight: EarlyEdHighlight) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.yellow)
                Text("Today's Moment")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.dimStar)
            }
            
            Text(highlight.text)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.starlightCream)
            
            if let detail = highlight.detail {
                Text(detail)
                    .font(.system(size: 14))
                    .foregroundColor(.dimStar)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.yellow.opacity(0.1), Color.deepSlate],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    // MARK: - Moment Capture Section
    private var momentCaptureSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Capture a Moment")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.starlightCream)
            
            HStack(spacing: 12) {
                CaptureButton(
                    icon: "text.bubble.fill",
                    label: "New Word!",
                    color: .cyan
                ) {
                    showNewWordSheet = true
                }
                
                CaptureButton(
                    icon: "quote.bubble.fill",
                    label: "Funny Quote",
                    color: .pink
                ) {
                    showFunnyQuoteSheet = true
                }
                
                CaptureButton(
                    icon: "star.fill",
                    label: "Milestone",
                    color: .yellow
                ) {
                    showMilestoneSheet = true
                }
            }
        }
    }
    
    // MARK: - First Words Section
    private var firstWordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("First Words")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.starlightCream)
                
                Spacer()
                
                Text("\(earlyEdStore.firstWords.count) words! 🎉")
                    .font(.system(size: 13))
                    .foregroundColor(.cyan)
            }
            
            // Word cloud (simple, joyful)
            FlowLayout(spacing: 8) {
                ForEach(earlyEdStore.firstWords.prefix(12)) { word in
                    Text(word.word)
                        .font(.system(size: 14))
                        .foregroundColor(.starlightCream)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.cyan.opacity(0.15))
                        .clipShape(Capsule())
                }
                
                if earlyEdStore.firstWords.count > 12 {
                    Button {
                        showMemoryBook = true
                    } label: {
                        Text("+\(earlyEdStore.firstWords.count - 12) more")
                            .font(.system(size: 13))
                            .foregroundColor(.cyan)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.deepSlate)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Funny Quotes Section
    private var funnyQuotesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("😂 Things They've Said")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.starlightCream)
                
                Spacer()
                
                Button {
                    showMemoryBook = true
                } label: {
                    Text("See All")
                        .font(.system(size: 13))
                        .foregroundColor(.pink)
                }
            }
            
            if let latestQuote = earlyEdStore.funnyQuotes.first {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\"\(latestQuote.quote)\"")
                        .font(.system(size: 16, design: .serif))
                        .italic()
                        .foregroundColor(.starlightCream)
                    
                    Text("— \(latestQuote.context ?? earlyEdStore.childName), \(latestQuote.timeAgo)")
                        .font(.system(size: 12))
                        .foregroundColor(.dimStar)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.pink.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(16)
        .background(Color.deepSlate)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Memory Book Card
    private var memoryBookCard: some View {
        Button {
            showMemoryBook = true
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.moonlightLavender.opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: "book.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.moonlightLavender)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Memory Book")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.starlightCream)
                    
                    Text("\(earlyEdStore.totalMemories) precious moments saved")
                        .font(.system(size: 14))
                        .foregroundColor(.dimStar)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.dimStar)
            }
            .padding(20)
            .background(Color.deepSlate)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    // MARK: - Recent Moments
    private var recentMomentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.dimStar)
            
            let recentItems = earlyEdStore.recentMoments
            
            if recentItems.isEmpty {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.moonlightLavender.opacity(0.1))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: 24))
                            .foregroundColor(.moonlightLavender)
                    }
                    
                    Text("Start capturing moments!")
                        .font(.system(size: 15))
                        .foregroundColor(.dimStar)
                }
                .frame(maxWidth: .infinity)
                .padding(32)
            } else {
                VStack(spacing: 8) {
                    ForEach(recentItems.prefix(3)) { item in
                        RecentMomentRow(moment: item)
                    }
                }
            }
        }
    }
    
    // MARK: - Encouragement Card
    private var encouragementCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "heart.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.green)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("You're doing amazing 💚")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.starlightCream)
                
                Text("Every moment you capture is a gift for the future.")
                    .font(.system(size: 13))
                    .foregroundColor(.dimStar)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color.green.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
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

// MARK: - Capture Button
struct CaptureButton: View {
    let icon: String
    let label: String
    let color: Color
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
                
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.starlightCream)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.deepSlate)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

// MARK: - Recent Moment Row
struct RecentMomentRow: View {
    let moment: EarlyEdMoment
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: moment.icon)
                .font(.system(size: 14))
                .foregroundColor(moment.color)
                .frame(width: 24)
            
            Text(moment.displayText)
                .font(.system(size: 14))
                .foregroundColor(.starlightCream)
                .lineLimit(1)
            
            Spacer()
            
            Text(moment.timeAgo)
                .font(.system(size: 12))
                .foregroundColor(.dimStar)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - New Word Sheet
struct NewWordSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = EarlyEdStore.shared
    
    @State private var word = ""
    @State private var context = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.midnightSlate
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("🎉")
                            .font(.system(size: 48))
                        Text("New Word!")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.starlightCream)
                    }
                    
                    TextField("What word did they say?", text: $word)
                        .font(.system(size: 20))
                        .foregroundColor(.starlightCream)
                        .multilineTextAlignment(.center)
                        .padding(16)
                        .background(Color.deepSlate)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    TextField("Any context? (optional)", text: $context)
                        .font(.system(size: 16))
                        .foregroundColor(.starlightCream)
                        .padding(16)
                        .background(Color.deepSlate)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    Spacer()
                    
                    Button {
                        if !word.isEmpty {
                            store.addFirstWord(word, context: context.isEmpty ? nil : context)
                            dismiss()
                        }
                    } label: {
                        Text("Save Word ✨")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(word.isEmpty ? Color.dimStar : Color.cyan)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(word.isEmpty)
                }
                .padding(24)
            }
            .navigationTitle("New Word")
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

// MARK: - Funny Quote Sheet
struct FunnyQuoteSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = EarlyEdStore.shared
    
    @State private var quote = ""
    @State private var context = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.midnightSlate
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("😂")
                            .font(.system(size: 48))
                        Text("What did they say?")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.starlightCream)
                    }
                    
                    TextEditor(text: $quote)
                        .font(.system(size: 18, design: .serif))
                        .foregroundColor(.starlightCream)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 100)
                        .padding(16)
                        .background(Color.deepSlate)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    TextField("What were they doing? (optional)", text: $context)
                        .font(.system(size: 16))
                        .foregroundColor(.starlightCream)
                        .padding(16)
                        .background(Color.deepSlate)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    Spacer()
                    
                    Button {
                        if !quote.isEmpty {
                            store.addFunnyQuote(quote, context: context.isEmpty ? nil : context)
                            dismiss()
                        }
                    } label: {
                        Text("Save Quote 💬")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(quote.isEmpty ? Color.dimStar : Color.pink)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(quote.isEmpty)
                }
                .padding(24)
            }
            .navigationTitle("Funny Quote")
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

// MARK: - Milestone Sheet
struct MilestoneSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = EarlyEdStore.shared
    
    @State private var milestone = ""
    @State private var notes = ""
    
    let suggestions = [
        "First steps without holding on",
        "First full sentence",
        "Used the potty",
        "Dressed themselves",
        "Made a new friend",
        "Learned to count to 10",
        "Recognized letters",
        "Shared toys with others"
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.midnightSlate
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("⭐")
                            .font(.system(size: 48))
                        Text("What milestone?")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.starlightCream)
                    }
                    
                    TextField("Describe the milestone", text: $milestone)
                        .font(.system(size: 18))
                        .foregroundColor(.starlightCream)
                        .padding(16)
                        .background(Color.deepSlate)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Suggestions
                    if milestone.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Or pick one:")
                                .font(.system(size: 13))
                                .foregroundColor(.dimStar)
                            
                            FlowLayout(spacing: 8) {
                                ForEach(suggestions, id: \.self) { suggestion in
                                    Button {
                                        milestone = suggestion
                                    } label: {
                                        Text(suggestion)
                                            .font(.system(size: 13))
                                            .foregroundColor(.yellow)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.yellow.opacity(0.1))
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    }
                    
                    TextField("Any notes? (optional)", text: $notes)
                        .font(.system(size: 16))
                        .foregroundColor(.starlightCream)
                        .padding(16)
                        .background(Color.deepSlate)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    Spacer()
                    
                    Button {
                        if !milestone.isEmpty {
                            store.addMilestone(milestone, notes: notes.isEmpty ? nil : notes)
                            dismiss()
                        }
                    } label: {
                        Text("Save Milestone 🌟")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(milestone.isEmpty ? Color.dimStar : Color.yellow)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(milestone.isEmpty)
                }
                .padding(24)
            }
            .navigationTitle("New Milestone")
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

// MARK: - Memory Book View
struct MemoryBookView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = EarlyEdStore.shared
    
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.midnightSlate
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Tab picker
                    Picker("", selection: $selectedTab) {
                        Text("Words").tag(0)
                        Text("Quotes").tag(1)
                        Text("Milestones").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    
                    TabView(selection: $selectedTab) {
                        // Words
                        ScrollView {
                            if store.firstWords.isEmpty {
                                emptyState(icon: "text.bubble", message: "No words captured yet")
                            } else {
                                LazyVStack(spacing: 12) {
                                    ForEach(store.firstWords) { word in
                                        WordCard(word: word)
                                    }
                                }
                                .padding(20)
                            }
                        }
                        .tag(0)
                        
                        // Quotes
                        ScrollView {
                            if store.funnyQuotes.isEmpty {
                                emptyState(icon: "quote.bubble", message: "No quotes captured yet")
                            } else {
                                LazyVStack(spacing: 12) {
                                    ForEach(store.funnyQuotes) { quote in
                                        QuoteCard(quote: quote)
                                    }
                                }
                                .padding(20)
                            }
                        }
                        .tag(1)
                        
                        // Milestones
                        ScrollView {
                            if store.milestones.isEmpty {
                                emptyState(icon: "star", message: "No milestones captured yet")
                            } else {
                                LazyVStack(spacing: 12) {
                                    ForEach(store.milestones) { milestone in
                                        MilestoneCard(milestone: milestone)
                                    }
                                }
                                .padding(20)
                            }
                        }
                        .tag(2)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            .navigationTitle("Memory Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.moonlightLavender)
                }
            }
        }
    }
    
    private func emptyState(icon: String, message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.dimStar.opacity(0.5))
            Text(message)
                .font(.system(size: 16))
                .foregroundColor(.dimStar)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}

struct WordCard: View {
    let word: FirstWord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(word.word)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.cyan)
            
            if let context = word.context {
                Text(context)
                    .font(.system(size: 14))
                    .foregroundColor(.dimStar)
            }
            
            Text(word.createdAt.formatted(date: .abbreviated, time: .omitted))
                .font(.system(size: 12))
                .foregroundColor(.dimStar.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.deepSlate)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct QuoteCard: View {
    let quote: FunnyQuote
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\"\(quote.quote)\"")
                .font(.system(size: 16, design: .serif))
                .italic()
                .foregroundColor(.starlightCream)
            
            if let context = quote.context {
                Text("— \(context)")
                    .font(.system(size: 13))
                    .foregroundColor(.pink)
            }
            
            Text(quote.createdAt.formatted(date: .abbreviated, time: .omitted))
                .font(.system(size: 12))
                .foregroundColor(.dimStar.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.pink.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct MilestoneCard: View {
    let milestone: ToddlerMilestone
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text(milestone.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.starlightCream)
            }
            
            if let notes = milestone.notes {
                Text(notes)
                    .font(.system(size: 14))
                    .foregroundColor(.dimStar)
            }
            
            Text(milestone.createdAt.formatted(date: .abbreviated, time: .omitted))
                .font(.system(size: 12))
                .foregroundColor(.dimStar.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.yellow.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview
#Preview {
    EarlyEdHomeView()
        .environmentObject(AuthService.shared)
}
