import Foundation

// MARK: - Configuration
// API Keys and environment configuration
// NOTE: In production, use Keychain or a secure secrets manager

enum Config {
    
    // MARK: - Supabase
    enum Supabase {
        static let url = "https://onjirlfjbvcvbsygcwya.supabase.co"
        static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9uamlybGZqYnZjdmJzeWdjd3lhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQwMTMxNDQsImV4cCI6MjA3OTU4OTE0NH0.GPgnLa2NO7T5aJA0PqG4mMUzpmFS4xED9ttMru8yjhE"
    }
    
    // MARK: - OpenAI
    enum OpenAI {
        static let apiKey = "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"
        static let model = "gpt-4o-mini"
        static let baseURL = "https://api.openai.com/v1"
    }
    
    // MARK: - App Settings
    enum App {
        static let bundleId = "com.keeper.app"
        static let appName = "Keeper"
    }
}

