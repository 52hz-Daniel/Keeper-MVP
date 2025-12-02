import Foundation
import AuthenticationServices

// MARK: - Auth Service
// Handles user authentication, account creation, and session management

@MainActor
final class AuthService: ObservableObject {
    
    // MARK: - Singleton
    static let shared = AuthService()
    
    // MARK: - Published Properties
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Persistence Keys
    private let userKey = "keeper_current_user"
    private let defaults = UserDefaults.standard
    
    private init() {
        loadUser()
    }
    
    // MARK: - Session Management
    
    /// Load user from persistent storage
    private func loadUser() {
        if let data = defaults.data(forKey: userKey),
           let user = try? JSONDecoder().decode(User.self, from: data) {
            self.currentUser = user
            self.isAuthenticated = !user.isAnonymous
            
            // Increment session count
            var updatedUser = user
            updatedUser.incrementSessions()
            self.currentUser = updatedUser
            saveUser()
            
            // Check trial status
            checkTrialStatus()
        } else {
            // Create anonymous user for guest mode
            createAnonymousUser()
        }
    }
    
    /// Save user to persistent storage
    private func saveUser() {
        if let user = currentUser,
           let data = try? JSONEncoder().encode(user) {
            defaults.set(data, forKey: userKey)
        }
    }
    
    /// Create anonymous user for guest experience
    func createAnonymousUser() {
        var user = User()
        // Start with 14-day premium trial
        user.startTrial()
        self.currentUser = user
        self.isAuthenticated = false
        saveUser()
    }
    
    // MARK: - Authentication
    
    /// Sign in with Apple
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Extract user info from credential
        let userId = credential.user
        let email = credential.email
        let fullName = credential.fullName
        
        let displayName = [fullName?.givenName, fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")
        
        // Create or update user
        var user = currentUser ?? User()
        user.email = email ?? user.email
        user.displayName = displayName.isEmpty ? user.displayName : displayName
        user.authProvider = .apple
        
        // If this is first sign-in, start trial
        if user.subscription == nil {
            user.startTrial()
        }
        
        self.currentUser = user
        self.isAuthenticated = true
        saveUser()
        
        // Sync with Supabase
        try await syncUserToBackend(user)
    }
    
    /// Sign in with Email
    func signInWithEmail(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // TODO: Implement Supabase email auth
        // For now, create local user
        var user = currentUser ?? User()
        user.email = email
        user.authProvider = .email
        
        if user.subscription == nil {
            user.startTrial()
        }
        
        self.currentUser = user
        self.isAuthenticated = true
        saveUser()
    }
    
    /// Create account with email
    func createAccount(email: String, password: String, displayName: String?) async throws {
        isLoading = true
        defer { isLoading = false }
        
        var user = currentUser ?? User()
        user.email = email
        user.displayName = displayName
        user.authProvider = .email
        
        // Start trial on account creation
        user.startTrial()
        
        self.currentUser = user
        self.isAuthenticated = true
        saveUser()
        
        // Sync with Supabase
        try await syncUserToBackend(user)
    }
    
    /// Sign out
    func signOut() {
        // Keep local data but mark as anonymous
        var user = currentUser ?? User()
        user.email = nil
        user.authProvider = nil
        
        self.currentUser = user
        self.isAuthenticated = false
        saveUser()
    }
    
    // MARK: - Usage Tracking
    
    /// Track log confirmation (for prompting account creation)
    func trackLogConfirmed() {
        currentUser?.incrementLogs()
        saveUser()
    }
    
    /// Mark account prompt as seen
    func markAccountPromptSeen() {
        currentUser?.hasSeenAccountPrompt = true
        saveUser()
    }
    
    /// Mark subscription prompt as seen
    func markSubscriptionPromptSeen() {
        currentUser?.hasSeenSubscriptionPrompt = true
        saveUser()
    }
    
    // MARK: - Trial & Subscription
    
    /// Check and update trial status
    private func checkTrialStatus() {
        guard var user = currentUser,
              let subscription = user.subscription else { return }
        
        if subscription.trialExpired && subscription.status == .trial {
            // Trial expired - downgrade to free if no payment method
            if !subscription.paymentMethodAdded {
                user.downgradeToFree()
            } else {
                // Convert to paid subscription
                user.upgradeToPremium()
            }
            self.currentUser = user
            saveUser()
        }
    }
    
    /// Upgrade to premium
    func upgradeToPremium(withPaymentMethod: Bool) async throws {
        guard var user = currentUser else { return }
        
        user.subscription?.paymentMethodAdded = withPaymentMethod
        user.subscription?.autoRenew = withPaymentMethod
        user.upgradeToPremium()
        
        self.currentUser = user
        saveUser()
        
        // Sync with backend
        try await syncUserToBackend(user)
    }
    
    /// Check if feature is available
    func canAccessFeature(_ feature: PremiumFeature) -> Bool {
        return currentUser?.isPremium ?? false
    }
    
    // MARK: - Backend Sync
    
    private func syncUserToBackend(_ user: User) async throws {
        // TODO: Sync with Supabase
        // For now, just log
        print("📤 Syncing user to backend: \(user.id)")
    }
    
    // MARK: - Child Info
    
    func updateChildInfo(name: String?, dueDate: Date?, birthDate: Date?) {
        currentUser?.childName = name
        currentUser?.childDueDate = dueDate
        currentUser?.childBirthDate = birthDate
        saveUser()
    }
    
    func updatePreferredStage(_ stage: KeeperConstants.Stage) {
        currentUser?.preferredStage = stage
        saveUser()
    }
}

// MARK: - Auth Errors
enum AuthError: Error, LocalizedError {
    case invalidCredentials
    case emailAlreadyExists
    case weakPassword
    case networkError
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials: return "Invalid email or password"
        case .emailAlreadyExists: return "An account with this email already exists"
        case .weakPassword: return "Password must be at least 8 characters"
        case .networkError: return "Network error. Please try again."
        case .unknownError: return "An error occurred. Please try again."
        }
    }
}

