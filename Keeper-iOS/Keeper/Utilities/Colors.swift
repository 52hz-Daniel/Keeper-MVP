import SwiftUI

// MARK: - Keeper Brand Colors
// Design Philosophy: "Nocturnal Softness"
// We are designing for the night. The aesthetic is deep, cool, and bioluminescent.

extension Color {
    // MARK: - Backgrounds
    /// The main canvas. Deep, restful, infinite. (#0F172A)
    static let midnightSlate = Color(hex: "0F172A")
    
    /// Card backgrounds, elevated surfaces. (#1E293B)
    static let deepSlate = Color(hex: "1E293B")
    
    /// Subtle borders and dividers. (#334155)
    static let slateGray = Color(hex: "334155")
    
    // MARK: - Brand Colors
    /// Primary brand color. The "Mic" button, active states, the "AI" voice. (#818CF8)
    /// It glows against the dark background.
    static let moonlightLavender = Color(hex: "818CF8")
    
    /// Primary text. Softened white to prevent eye burn. (#F1F5F9)
    static let starlightCream = Color(hex: "F1F5F9")
    
    /// Secondary text. (#94A3B8)
    static let dimStar = Color(hex: "94A3B8")
    
    // MARK: - Safety Colors
    /// Medical warnings. Urgent but warm, unlike "Traffic Light Red" which feels judgmental. (#FB7185)
    static let sunsetCoral = Color(hex: "FB7185")
    
    /// Danger/Block state. (#EF4444)
    static let dangerRed = Color(hex: "EF4444")
    
    /// Success/Confirm state. (#22C55E)
    static let safeGreen = Color(hex: "22C55E")
    
    // MARK: - Ghost Log States
    /// Draft card background (pending confirmation). (#312E81) with opacity
    static let ghostDraft = Color(hex: "312E81").opacity(0.3)
    
    /// Draft card border. (#818CF8) with opacity
    static let ghostBorder = Color(hex: "818CF8").opacity(0.5)
    
    /// Warning card background. (#7F1D1D) with opacity
    static let warningBackground = Color(hex: "7F1D1D").opacity(0.3)
    
    // MARK: - Hex Initializer
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Theme Presets for Lifecycle Stages
enum LifecycleTheme {
    case dawn      // Pre-Natal: Sage/Cream
    case midnight  // Infant: Indigo/Dark (default)
    case daylight  // Early Ed: Primary Colors
    
    var backgroundColor: Color {
        switch self {
        case .dawn:
            return Color(hex: "F5F5F4") // Warm cream
        case .midnight:
            return Color.midnightSlate
        case .daylight:
            return Color(hex: "FAFAF9") // Bright white
        }
    }
    
    var primaryColor: Color {
        switch self {
        case .dawn:
            return Color(hex: "84CC16") // Sage green
        case .midnight:
            return Color.moonlightLavender
        case .daylight:
            return Color(hex: "3B82F6") // Bright blue
        }
    }
    
    var textColor: Color {
        switch self {
        case .dawn:
            return Color(hex: "292524") // Dark text
        case .midnight:
            return Color.starlightCream
        case .daylight:
            return Color(hex: "1C1917") // Dark text
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // Brand Colors
        HStack(spacing: 10) {
            ColorSwatch(color: .midnightSlate, name: "Midnight Slate")
            ColorSwatch(color: .deepSlate, name: "Deep Slate")
            ColorSwatch(color: .moonlightLavender, name: "Moonlight Lavender")
        }
        
        HStack(spacing: 10) {
            ColorSwatch(color: .starlightCream, name: "Starlight Cream")
            ColorSwatch(color: .sunsetCoral, name: "Sunset Coral")
            ColorSwatch(color: .safeGreen, name: "Safe Green")
        }
    }
    .padding()
    .background(Color.midnightSlate)
}

struct ColorSwatch: View {
    let color: Color
    let name: String
    
    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(width: 60, height: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            Text(name)
                .font(.caption2)
                .foregroundColor(.starlightCream)
        }
    }
}

