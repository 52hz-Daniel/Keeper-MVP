import SwiftUI

// MARK: - Milestone Gift View
// A beautiful, emotional presentation of collected memories
// Philosophy: "Capture happiness... over time... provide it back as a gift"

struct MilestoneGiftView: View {
    let gift: MemoryGift
    var onDismiss: () -> Void
    
    @State private var currentMomentIndex = 0
    @State private var showMoments = false
    @State private var animateIn = false
    
    var body: some View {
        ZStack {
            // Background
            Color.midnightSlate
                .ignoresSafeArea()
            
            // Stars animation
            StarsBackground()
            
            VStack(spacing: 0) {
                // Close button
                HStack {
                    Spacer()
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.dimStar)
                            .padding(12)
                            .background(Color.deepSlate)
                            .clipShape(Circle())
                    }
                }
                .padding()
                
                if !showMoments {
                    // Gift opening view
                    giftOpeningView
                } else {
                    // Moments carousel
                    momentsCarouselView
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateIn = true
            }
        }
    }
    
    // MARK: - Gift Opening View
    private var giftOpeningView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Animated gift icon
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.moonlightLavender.opacity(0.4), Color.clear],
                            center: .center,
                            startRadius: 40,
                            endRadius: animateIn ? 120 : 80
                        )
                    )
                    .frame(width: 200, height: 200)
                
                // Gift icon
                ZStack {
                    Circle()
                        .fill(Color.moonlightLavender.opacity(0.2))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "gift.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.moonlightLavender)
                }
                .scaleEffect(animateIn ? 1.0 : 0.5)
            }
            
            // Celebration message
            VStack(spacing: 16) {
                Text(gift.milestone.type.celebrationTitle)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.starlightCream)
                    .multilineTextAlignment(.center)
                    .opacity(animateIn ? 1 : 0)
                
                Text(gift.milestone.type.giftMessage)
                    .font(.system(size: 16))
                    .foregroundColor(.dimStar)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 32)
                    .opacity(animateIn ? 1 : 0)
            }
            
            Spacer()
            
            // Open button
            Button {
                withAnimation(.spring()) {
                    showMoments = true
                }
                HapticsService.shared.logConfirmed()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                    Text("Open Your Memories")
                }
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(Color.moonlightLavender)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
            .opacity(animateIn ? 1 : 0)
        }
    }
    
    // MARK: - Moments Carousel View
    private var momentsCarouselView: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("Your Memories")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.starlightCream)
                
                Text("\(gift.moments.count) moments from your journey")
                    .font(.system(size: 15))
                    .foregroundColor(.dimStar)
            }
            .padding(.top, 20)
            
            // Moments carousel
            TabView(selection: $currentMomentIndex) {
                ForEach(Array(gift.moments.enumerated()), id: \.element.id) { index, moment in
                    MomentDetailCard(moment: moment)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .frame(height: 400)
            
            // Navigation dots
            HStack(spacing: 8) {
                ForEach(0..<gift.moments.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentMomentIndex ? Color.moonlightLavender : Color.dimStar.opacity(0.5))
                        .frame(width: 8, height: 8)
                }
            }
            
            Spacer()
            
            // Done button
            Button {
                onDismiss()
            } label: {
                Text("Keep These Memories 💛")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.starlightCream)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.deepSlate)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Moment Detail Card
struct MomentDetailCard: View {
    let moment: Moment
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            ZStack {
                Circle()
                    .fill(moment.displayColor.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Image(systemName: moment.displayIcon)
                    .font(.system(size: 36))
                    .foregroundColor(moment.displayColor)
            }
            
            // Content
            VStack(spacing: 12) {
                Text(moment.title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.starlightCream)
                    .multilineTextAlignment(.center)
                
                Text(moment.description)
                    .font(.system(size: 16))
                    .foregroundColor(.dimStar)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 20)
                
                Text(moment.type.celebrationMessage)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(moment.displayColor)
                    .padding(.top, 8)
            }
            
            // Date
            Text(moment.capturedAt.formatted(date: .abbreviated, time: .omitted))
                .font(.system(size: 13))
                .foregroundColor(.dimStar.opacity(0.7))
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(Color.deepSlate)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal, 24)
    }
}

// MARK: - Stars Background
struct StarsBackground: View {
    @State private var animateStars = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<20, id: \.self) { i in
                    Circle()
                        .fill(Color.white.opacity(Double.random(in: 0.1...0.4)))
                        .frame(width: CGFloat.random(in: 2...4))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                        .opacity(animateStars ? 1 : 0.3)
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    animateStars = true
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    MilestoneGiftView(
        gift: MemoryGift(
            familyId: UUID(),
            milestone: Milestone(
                type: .oneMonth,
                childAgeInDays: 30
            ),
            moments: [
                Moment(
                    familyId: UUID(),
                    type: .firstSmile,
                    title: "First Real Smile! 😊",
                    description: "She smiled right at me after her morning feed."
                ),
                Moment(
                    familyId: UUID(),
                    type: .sleepThrough,
                    title: "A Full Night! 🌙",
                    description: "Baby slept 6 hours straight!"
                )
            ]
        )
    ) {
        // Dismiss
    }
}

