import SwiftUI

// MARK: - Moment Card
// Displays precious moments in a warm, celebratory way
// Philosophy: "Capture the happiness in moments they usually ignore"

struct MomentCard: View {
    let moment: Moment
    var onFavorite: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(moment.displayColor.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: moment.displayIcon)
                    .font(.system(size: 22))
                    .foregroundColor(moment.displayColor)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(moment.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.starlightCream)
                
                Text(moment.description)
                    .font(.system(size: 14))
                    .foregroundColor(.dimStar)
                    .lineLimit(2)
                
                Text(moment.timeAgo)
                    .font(.system(size: 12))
                    .foregroundColor(.dimStar.opacity(0.7))
            }
            
            Spacer()
            
            // Favorite Button
            if let onFavorite = onFavorite {
                Button(action: onFavorite) {
                    Image(systemName: moment.isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 20))
                        .foregroundColor(moment.isFavorite ? .sunsetCoral : .dimStar)
                }
            }
        }
        .padding(16)
        .background(Color.deepSlate)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Memory Gift Card
// Celebrates milestone achievements with collected moments
struct MemoryGiftCard: View {
    let gift: MemoryGift
    var onOpen: () -> Void
    
    @State private var isGlowing = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Gift Icon with glow animation
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.moonlightLavender.opacity(0.5), Color.clear],
                            center: .center,
                            startRadius: 30,
                            endRadius: isGlowing ? 80 : 60
                        )
                    )
                    .frame(width: 120, height: 120)
                
                // Gift box
                ZStack {
                    Circle()
                        .fill(Color.moonlightLavender.opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "gift.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.moonlightLavender)
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    isGlowing = true
                }
            }
            
            // Message
            VStack(spacing: 8) {
                Text(gift.milestone.type.celebrationTitle)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.starlightCream)
                    .multilineTextAlignment(.center)
                
                Text(gift.milestone.type.giftMessage)
                    .font(.system(size: 15))
                    .foregroundColor(.dimStar)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 20)
            
            // Moment count
            Text("\(gift.moments.count) precious moments")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.moonlightLavender)
            
            // Open button
            Button(action: onOpen) {
                Text("Open Your Gift")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.moonlightLavender)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 30)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.deepSlate)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.moonlightLavender.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Daily Highlight Card
// Gentle reminder of a positive moment
struct DailyHighlightCard: View {
    let moment: Moment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.yellow)
                Text("A moment from your journey")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.dimStar)
            }
            
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(moment.displayColor.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: moment.displayIcon)
                        .font(.system(size: 18))
                        .foregroundColor(moment.displayColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(moment.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.starlightCream)
                    
                    Text(moment.type.celebrationMessage)
                        .font(.system(size: 13))
                        .foregroundColor(.dimStar)
                }
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [moment.displayColor.opacity(0.1), Color.deepSlate],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Gentle Prompt Card
// Non-intrusive invitation to capture a moment
struct GentlePromptCard: View {
    let prompt: String
    var onCapture: () -> Void
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.yellow.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "camera.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.yellow)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Capture a Moment")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.starlightCream)
                
                Text(prompt)
                    .font(.system(size: 13))
                    .foregroundColor(.dimStar)
            }
            
            Spacer()
            
            Button(action: onCapture) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.yellow.opacity(0.8))
            }
        }
        .padding(16)
        .background(Color.deepSlate)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Rest Reminder Card
// Gentle nudge to take care of themselves
struct RestReminderCard: View {
    let message: String
    var onDismiss: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.purple)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Rest Reminder 💜")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.starlightCream)
                
                Text(message)
                    .font(.system(size: 13))
                    .foregroundColor(.dimStar)
            }
            
            Spacer()
            
            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14))
                        .foregroundColor(.dimStar)
                }
            }
        }
        .padding(16)
        .background(Color.purple.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Preview
#Preview {
    ScrollView(showsIndicators: false) {
        VStack(spacing: 20) {
            MomentCard(
                moment: Moment(
                    familyId: UUID(),
                    type: .firstSmile,
                    title: "First Real Smile! 😊",
                    description: "She smiled right at me after her morning feed.",
                    isFavorite: true
                )
            ) {
                // Favorite action
            }
            
            DailyHighlightCard(
                moment: Moment(
                    familyId: UUID(),
                    type: .sleepThrough,
                    title: "A Full Night! 🌙",
                    description: "Baby slept 6 hours straight!"
                )
            )
            
            GentlePromptCard(prompt: "Any sweet moments to remember? 💛") {
                // Capture action
            }
            
            RestReminderCard(message: "You've been up for 3 hours. Try to rest when baby rests.")
        }
        .padding()
    }
    .background(Color.midnightSlate)
}

