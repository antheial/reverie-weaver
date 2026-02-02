import SwiftUI
import UIKit

extension Color {
    
    // MARK: - System Dynamic Colors
    // These automatically adapt to light/dark mode
    
    static let dynamicBackground = Color(UIColor.systemBackground)
    static let dynamicSecondaryBackground = Color(UIColor.secondarySystemBackground)
    static let dynamicTertiaryBackground = Color(UIColor.tertiarySystemBackground)
    
    static let dynamicLabel = Color(UIColor.label)
    static let dynamicSecondaryLabel = Color(UIColor.secondaryLabel)
    static let dynamicTertiaryLabel = Color(UIColor.tertiaryLabel)
    
    static let dynamicSystemBackground = Color(UIColor.systemBackground)
    static let dynamicSeparator = Color(UIColor.separator)
    
    // MARK: - Card & UI Elements
    // Custom backgrounds and borders for cards
    
    static let habitCardBackground = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(white: 0.15, alpha: 1.0) // Dark gray in dark mode
            : UIColor.white // White in light mode
    })
    
    static let habitCardBorder = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(white: 0.3, alpha: 1.0) // Lighter gray border in dark
            : UIColor(white: 0.9, alpha: 1.0) // Light gray border in light
    })
    
    static let shadowColor = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor.clear // No shadow in dark mode
            : UIColor.black.withAlphaComponent(0.1) // Subtle shadow in light
    })
    
    // MARK: - 🌊 Glassmorphic Card Backgrounds
    // Simple semi-transparent white glass - background handles dark mode!
    // No need for complex adaptive logic - just pure glassmorphism
    
    static var cardBackground: Color {
        Color.white.opacity(0.30)
    }
    
    static var cardBackgroundElevated: Color {
        Color.white.opacity(0.65)
    }
    
    static var inputBackground: Color {
        Color.white.opacity(0.45)
    }
    
    // MARK: - 🎨 Adaptive Borders for Glass Cards
    // Whisper-thin borders that barely define the edges
    
    static var cardBorder: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(white: 0.5, alpha: 0.12) // Nearly invisible border
                : UIColor(white: 1.0, alpha: 0.3) // Soft white border
        })
    }
    
    // MARK: - 💫 Adaptive Shadows for Glass Cards
    // Refined shadows that add depth without heaviness
    
    static var cardShadow: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(white: 0.0, alpha: 0.3) // Softer shadow in dark
                : UIColor(white: 0.0, alpha: 0.08) // Subtle shadow in light
        })
    }
    
    // MARK: - 🌫️ Specific Component Backgrounds
    // Delicate, barely-there backgrounds
    
    static var streakBackground: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(white: 0.35, alpha: 0.18)
                : UIColor(white: 1.0, alpha: 0.35)
        })
    }
    
    static var progressBackground: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(white: 0.35, alpha: 0.12)
                : UIColor(white: 1.0, alpha: 0.2)
        })
    }
    
    // MARK: - Completion Indicators
    // Fixed colors for completed habits - EASY TO READ in dark mode!
    
    static let completedHabitIndicator = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.4, green: 0.8, blue: 0.4, alpha: 1.0) // Soft green in dark mode  
            : UIColor(red: 0.2, green: 0.7, blue: 0.3, alpha: 1.0) // Darker green in light mode
    })
    
    static let completionGlow = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.2, green: 0.4, blue: 0.2, alpha: 0.3) // Subtle green glow in dark  
            : UIColor(red: 0.8, green: 0.95, blue: 0.8, alpha: 1.0) // Light green background in light
    })
    
    // MARK: - Timeline Colors
    // For The Loom timeline view
    
    static let timelineDotComplete = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor.systemGreen // iOS green in dark mode  
            : UIColor(red: 0.2, green: 0.7, blue: 0.3, alpha: 1.0)
    })
    
    static let timelineDotIncomplete = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(white: 0.4, alpha: 1.0) // Medium gray in dark  
            : UIColor(white: 0.8, alpha: 1.0) // Light gray in light
    })
    
    // MARK: - Text Colors for Completed Items
    // Makes text readable on completion backgrounds
    
    static let completedText = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor.white // White text in dark mode  
            : UIColor.black // Black text in light mode
    })
    
    // MARK: - Daily Breakdown Colors
    // For Archive view daily summaries
    
    static let breakdownCategoryBackground = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(white: 0.2, alpha: 1.0) // Dark gray background  
            : UIColor(white: 0.95, alpha: 1.0) // Off-white in light
    })
    
    static let breakdownText = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(white: 0.95, alpha: 1.0) // Near-white in dark  
            : UIColor(white: 0.2, alpha: 1.0) // Near-black in light
    })
    
    // MARK: - 🎨 Hex Color Helper
    
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
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    // MARK: - Custom Colors
    
    static let sageGreen = Color(hex: "8BA888")
    static let dustyBlue = Color(hex: "9EADC8")
    static let terracottaRose = Color(hex: "E8927C")
    static let paleMauve = Color(hex: "D4A5C4")
    static let softLavender = Color(hex: "B5A8D4")
    static let sunriseOrange = Color(hex: "E8A87C")

    static let inkPrimary = Color(hex: "2B2B2B")
    static let inkSecondary = Color(hex: "4A4742")
    static let inkAccent = Color(hex: "A67B5B")


    
    // MARK: - Adaptive Section Backgrounds

        static func adaptiveSectionBackground(colorScheme: ColorScheme) -> Color {
            colorScheme == .dark
                ? Color.white.opacity(0.04)
                : Color.white.opacity(0.35)
        }
    
    // MARK: - Adaptive Borders
    
    static func adaptiveBorder(colorScheme: ColorScheme) -> Color {
            colorScheme == .dark
                ? Color.white.opacity(0.12)
                : Color.white.opacity(0.35)
        }
    
    // MARK: - Category Colors
    
    // MARK: - Time Adaptive Colors
    // These provide colors that adapt to both color scheme and time of day
    // Used for foreground styling where the timeAdaptiveText view modifier isn't suitable

    /// Returns a time-adaptive secondary color for text and icons
    /// This matches the secondary style from TimeAdaptiveTextStyle
    static func timeAdaptiveSecondary(colorScheme: ColorScheme) -> Color {
        let hour = Calendar.current.component(.hour, from: Date())
        let period = TimeOfDay(hour: hour)

        // If system is dark mode OR time period is visually dark, use light colors
        if colorScheme == .dark || period.isVisuallyDark {
            return Color(hex: "C8C0B8").opacity(0.75) // Soft grey-beige for dark backgrounds
        }

        // Light mode with light backgrounds - use dark text
        switch period {
        case .earlyMorning, .lateMorning, .earlyAfternoon, .lateAfternoon:
            return Color(hex: "5A4F45").opacity(0.78) // Warm grey-brown
        case .goldenHour:
            return Color(hex: "4A3528") // Deep chocolate
        default:
            return Color(hex: "5A4F45").opacity(0.78) // Warm grey-brown
        }
    }

    /// Returns a time-adaptive primary color for text and icons
    /// This matches the primary style from TimeAdaptiveTextStyle
    static func timeAdaptivePrimary(colorScheme: ColorScheme) -> Color {
        let hour = Calendar.current.component(.hour, from: Date())
        let period = TimeOfDay(hour: hour)

        // If system is dark mode OR time period is visually dark, use light colors
        if colorScheme == .dark || period.isVisuallyDark {
            return Color(hex: "E8E3DB").opacity(0.88) // Warm paper white for dark backgrounds
        }

        // Light mode with light backgrounds - use dark text
        switch period {
        case .earlyMorning, .lateMorning, .earlyAfternoon, .lateAfternoon:
            return Color(hex: "2A2520").opacity(0.92) // Warm dark brown
        case .goldenHour:
            return Color(hex: "3D2520") // Deep warm brown
        default:
            return Color(hex: "2A2520").opacity(0.92) // Warm dark brown
        }
    }

    static func categoryColor(for category: String, in colorScheme: ColorScheme) -> Color {
        let baseColors: [String: (light: Color, dark: Color)] = [
            "Health": (Color.green, Color.green.opacity(0.8)),
            "Creativity": (Color.purple, Color.purple.opacity(0.8)),
            "Productivity": (Color.blue, Color.blue.opacity(0.8)),
            "Mindfulness": (Color.cyan, Color.cyan.opacity(0.8)),
            "Social": (Color.orange, Color.orange.opacity(0.8)),
            "Learning": (Color.indigo, Color.indigo.opacity(0.8)),
            "Fitness": (Color.red, Color.red.opacity(0.8)),
            "Finance": (Color.mint, Color.mint.opacity(0.8))
        ]
        
        let colors = baseColors[category] ?? (Color.gray, Color.gray.opacity(0.8))
        return colorScheme == .dark ? colors.dark : colors.light
    }
}

// MARK: - 🌊 Glassmorphic Card Modifier

struct GlassmorphicCard: ViewModifier {
    let cornerRadius: CGFloat
    let padding: CGFloat
    let elevated: Bool
    
    init(cornerRadius: CGFloat = 24, padding: CGFloat = 16, elevated: Bool = false) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.elevated = elevated
    }
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(elevated ? Color.cardBackgroundElevated : Color.cardBackground)
                    .shadow(color: Color.cardShadow, radius: 8, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(Color.cardBorder, lineWidth: 1)
            )
    }
}

extension View {
    func glassmorphicCard(cornerRadius: CGFloat = 24, padding: CGFloat = 16, elevated: Bool = false) -> some View {
        modifier(GlassmorphicCard(cornerRadius: cornerRadius, padding: padding, elevated: elevated))
    }
}

// MARK: - Roman Numeral Helper

extension Int {
    /// Converts an integer to its Roman numeral representation (for chapters 0-12)
    var romanNumeral: String {
        switch self {
        case 0: return "0"
        case 1: return "I"
        case 2: return "II"
        case 3: return "III"
        case 4: return "IV"
        case 5: return "V"
        case 6: return "VI"
        case 7: return "VII"
        case 8: return "VIII"
        case 9: return "IX"
        case 10: return "X"
        case 11: return "XI"
        case 12: return "XII"
        default: return "\(self)"
        }
    }
}
