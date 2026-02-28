import SwiftUI
import AuthenticationServices

// MARK: - Account View
// Sign up / Sign in flow with Apple, Google, and Email options

struct AccountView: View {
    @StateObject private var authService = AuthService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var isSignUp = true
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var showError = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.midnightSlate
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: "shield.checkered")
                                .font(.system(size: 60))
                                .foregroundColor(.moonlightLavender)
                            
                            Text(isSignUp ? "Create Account" : "Welcome Back")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.starlightCream)
                            
                            Text(isSignUp ? "Start your 14-day free trial" : "Sign in to continue")
                                .font(.system(size: 16))
                                .foregroundColor(.dimStar)
                        }
                        .padding(.top, 40)
                        
                        // Trial Badge
                        if isSignUp {
                            TrialBadge()
                        }
                        
                        // Social Sign In Buttons
                        VStack(spacing: 12) {
                            SignInWithAppleButton(.signUp) { request in
                                request.requestedScopes = [.fullName, .email]
                            } onCompletion: { result in
                                handleAppleSignIn(result)
                            }
                            .signInWithAppleButtonStyle(.white)
                            .frame(height: 54)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            
                            Button {
                                // TODO: Google Sign In
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "g.circle.fill")
                                        .font(.system(size: 20))
                                    Text("Continue with Google")
                                        .font(.system(size: 17, weight: .semibold))
                                }
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Divider
                        HStack {
                            Rectangle()
                                .fill(Color.slateGray)
                                .frame(height: 1)
                            Text("or")
                                .font(.system(size: 14))
                                .foregroundColor(.dimStar)
                            Rectangle()
                                .fill(Color.slateGray)
                                .frame(height: 1)
                        }
                        .padding(.horizontal, 24)
                        
                        // Email Form
                        VStack(spacing: 16) {
                            if isSignUp {
                                CustomTextField(
                                    placeholder: "Your name",
                                    text: $displayName,
                                    icon: "person.fill"
                                )
                            }
                            
                            CustomTextField(
                                placeholder: "Email",
                                text: $email,
                                icon: "envelope.fill",
                                keyboardType: .emailAddress
                            )
                            
                            CustomTextField(
                                placeholder: "Password",
                                text: $password,
                                icon: "lock.fill",
                                isSecure: true
                            )
                            
                            Button {
                                Task {
                                    await handleEmailAuth()
                                }
                            } label: {
                                if authService.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text(isSignUp ? "Create Account" : "Sign In")
                                        .font(.system(size: 17, weight: .bold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.moonlightLavender)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .disabled(authService.isLoading)
                        }
                        .padding(.horizontal, 24)
                        
                        // Toggle Sign Up / Sign In
                        Button {
                            withAnimation {
                                isSignUp.toggle()
                            }
                        } label: {
                            Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                                .font(.system(size: 14))
                                .foregroundColor(.moonlightLavender)
                        }
                        
                        // Terms
                        Text("By continuing, you agree to our Terms of Service and Privacy Policy")
                            .font(.system(size: 12))
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
                    Button("Skip") {
                        dismiss()
                    }
                    .foregroundColor(.dimStar)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(authService.errorMessage ?? "An error occurred")
            }
        }
    }
    
    // MARK: - Handlers
    
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
                Task {
                    do {
                        try await authService.signInWithApple(credential: credential)
                        dismiss()
                    } catch {
                        authService.errorMessage = error.localizedDescription
                        showError = true
                    }
                }
            }
        case .failure(let error):
            authService.errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func handleEmailAuth() async {
        do {
            if isSignUp {
                try await authService.createAccount(
                    email: email,
                    password: password,
                    displayName: displayName.isEmpty ? nil : displayName
                )
            } else {
                try await authService.signInWithEmail(email: email, password: password)
            }
            dismiss()
        } catch {
            authService.errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Trial Badge
struct TrialBadge: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "gift.fill")
                .foregroundColor(.yellow)
            
            Text("14-day free Premium trial included!")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.starlightCream)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color.yellow.opacity(0.15))
                .overlay(
                    Capsule()
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Custom Text Field
struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.dimStar)
                .frame(width: 20)
            
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(.never)
            }
        }
        .font(.system(size: 16))
        .foregroundColor(.starlightCream)
        .padding(16)
        .background(Color.deepSlate)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview
#Preview {
    AccountView()
}

