import SwiftUI

// MARK: - Subscription View
// Premium upgrade flow with trial status and payment

struct SubscriptionView: View {
    @StateObject private var authService = AuthService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedPlan: PlanType = .monthly
    @State private var showPaymentSheet = false
    
    enum PlanType {
        case monthly
        case yearly
        
        var price: String {
            switch self {
            case .monthly: return "$9.99/mo"
            case .yearly: return "$99/yr"
            }
        }
        
        var savings: String? {
            switch self {
            case .monthly: return nil
            case .yearly: return "Save $20"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.midnightSlate
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Trial Status Banner
                        if let subscription = authService.currentUser?.subscription,
                           subscription.isTrialActive {
                            TrialStatusBanner(daysRemaining: subscription.trialDaysRemaining)
                        }
                        
                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.yellow, .orange],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Text("Keeper Premium")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.starlightCream)
                            
                            Text("Unlock the full power of Keeper")
                                .font(.system(size: 16))
                                .foregroundColor(.dimStar)
                        }
                        .padding(.top, 20)
                        
                        // Features List
                        VStack(spacing: 16) {
                            ForEach(PremiumFeature.allCases, id: \.rawValue) { feature in
                                FeatureRow(feature: feature)
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Plan Selection
                        VStack(spacing: 12) {
                            PlanCard(
                                title: "Monthly",
                                price: "$9.99",
                                period: "per month",
                                isSelected: selectedPlan == .monthly
                            ) {
                                selectedPlan = .monthly
                            }
                            
                            PlanCard(
                                title: "Yearly",
                                price: "$99",
                                period: "per year",
                                badge: "Save $20",
                                isSelected: selectedPlan == .yearly
                            ) {
                                selectedPlan = .yearly
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Subscribe Button
                        Button {
                            showPaymentSheet = true
                        } label: {
                            Text("Subscribe Now")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.midnightSlate)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    LinearGradient(
                                        colors: [.yellow, .orange],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .padding(.horizontal, 24)
                        
                        // Continue with Free
                        Button {
                            Task {
                                authService.currentUser?.downgradeToFree()
                                dismiss()
                            }
                        } label: {
                            Text("Continue with Free")
                                .font(.system(size: 16))
                                .foregroundColor(.dimStar)
                        }
                        
                        // Terms
                        Text("Cancel anytime. Subscription automatically renews unless cancelled 24 hours before the end of the current period.")
                            .font(.system(size: 11))
                            .foregroundColor(.dimStar)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.dimStar)
                    }
                }
            }
            .sheet(isPresented: $showPaymentSheet) {
                PaymentSheetView(plan: selectedPlan) {
                    Task {
                        try? await authService.upgradeToPremium(withPaymentMethod: true)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Trial Status Banner
struct TrialStatusBanner: View {
    let daysRemaining: Int
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: daysRemaining <= 3 ? "exclamationmark.triangle.fill" : "clock.fill")
                .foregroundColor(daysRemaining <= 3 ? .orange : .cyan)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Free Trial")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.starlightCream)
                
                Text("\(daysRemaining) days remaining")
                    .font(.system(size: 12))
                    .foregroundColor(.dimStar)
            }
            
            Spacer()
            
            if daysRemaining <= 3 {
                Text("Ending Soon!")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.orange)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(daysRemaining <= 3 ? Color.orange.opacity(0.1) : Color.cyan.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(daysRemaining <= 3 ? Color.orange.opacity(0.3) : Color.cyan.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, 24)
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let feature: PremiumFeature
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.moonlightLavender.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: feature.icon)
                    .font(.system(size: 18))
                    .foregroundColor(.moonlightLavender)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(feature.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.starlightCream)
                
                Text(feature.description)
                    .font(.system(size: 13))
                    .foregroundColor(.dimStar)
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.safeGreen)
        }
    }
}

// MARK: - Plan Card
struct PlanCard: View {
    let title: String
    let price: String
    let period: String
    var badge: String? = nil
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.starlightCream)
                        
                        if let badge = badge {
                            Text(badge)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.midnightSlate)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.safeGreen)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text("\(price) \(period)")
                        .font(.system(size: 14))
                        .foregroundColor(.dimStar)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.moonlightLavender : Color.slateGray, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.moonlightLavender)
                            .frame(width: 14, height: 14)
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.deepSlate)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.moonlightLavender : Color.slateGray.opacity(0.5), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
    }
}

// MARK: - Payment Sheet View
struct PaymentSheetView: View {
    let plan: SubscriptionView.PlanType
    let onComplete: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var cardNumber = ""
    @State private var expiry = ""
    @State private var cvv = ""
    @State private var isProcessing = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.midnightSlate
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Order Summary
                    VStack(spacing: 12) {
                        Text("Order Summary")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.starlightCream)
                        
                        HStack {
                            Text("Keeper Premium")
                            Spacer()
                            Text(plan.price)
                        }
                        .foregroundColor(.dimStar)
                        
                        Divider()
                            .background(Color.slateGray)
                        
                        HStack {
                            Text("Total")
                                .font(.system(size: 18, weight: .semibold))
                            Spacer()
                            Text(plan.price)
                                .font(.system(size: 18, weight: .bold))
                        }
                        .foregroundColor(.starlightCream)
                    }
                    .padding(20)
                    .background(Color.deepSlate)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // Card Input
                    VStack(spacing: 16) {
                        CustomTextField(
                            placeholder: "Card Number",
                            text: $cardNumber,
                            icon: "creditcard.fill",
                            keyboardType: .numberPad
                        )
                        
                        HStack(spacing: 12) {
                            CustomTextField(
                                placeholder: "MM/YY",
                                text: $expiry,
                                icon: "calendar",
                                keyboardType: .numberPad
                            )
                            
                            CustomTextField(
                                placeholder: "CVV",
                                text: $cvv,
                                icon: "lock.fill",
                                keyboardType: .numberPad
                            )
                        }
                    }
                    
                    Spacer()
                    
                    // Pay Button
                    Button {
                        isProcessing = true
                        // Simulate payment processing
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            isProcessing = false
                            onComplete()
                        }
                    } label: {
                        if isProcessing {
                            ProgressView()
                                .tint(.midnightSlate)
                        } else {
                            Text("Pay \(plan.price)")
                                .font(.system(size: 18, weight: .bold))
                        }
                    }
                    .foregroundColor(.midnightSlate)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.safeGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .disabled(isProcessing)
                }
                .padding(24)
            }
            .navigationTitle("Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.dimStar)
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    SubscriptionView()
}

