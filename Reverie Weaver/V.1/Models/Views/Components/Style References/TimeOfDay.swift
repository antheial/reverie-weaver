//
//  TimeOfDay.swift
//  Reverie Weaver
//
//  Created by Antheia Li on 10/25/25.
//

import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - TIME-ADAPTIVE TEXT (Enhanced for Maximum Harmony!)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// ✨ ENHANCED: Text colors now harmonize beautifully with each time period:
//
//   • Deep Night/Evening: Warm cream-whites on dark blue backgrounds
//   • Dawn: Peachy-cream on lavender/rose twilight backgrounds
//   • Daytime: Rich warm browns on bright cream backgrounds
//   • Golden Hour: Deep chocolate-browns on amber backgrounds
//   • Dusk: BRONZY PEACH-GOLD on coral/mauve sunset (FIXED! 🎨)
//
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extension View {
    /// Time-adaptive text that provides optimal readability across all time-based gradients
    /// Each time period has carefully chosen warm/cool tones that harmonize with backgrounds
    func timeAdaptiveText(
        colorScheme: ColorScheme,
        style: TimeAdaptiveTextStyle = .primary,
        isCompleted: Bool = false  // Add this parameter
    ) -> some View {
        let hour = Calendar.current.component(.hour, from: Date())
        let period = TimeOfDay(hour: hour)
        
        var config = style.configuration(for: colorScheme, period: period)
        
        // Reduce opacity for completed items
        if isCompleted {
            config = TimeAdaptiveTextConfiguration(
                color: config.color.opacity(0.5),  // Adjust this value to taste
                shadowColor: config.shadowColor.opacity(0.5),
                shadowRadius: config.shadowRadius * 0.7,
                shadowX: config.shadowX,
                shadowY: config.shadowY
            )
        }
        
        return self
            .foregroundStyle(config.color)
            .shadow(
                color: config.shadowColor,
                radius: config.shadowRadius,
                x: config.shadowX,
                y: config.shadowY
            )
    }
}
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Time Period System
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

enum TimeOfDay {
    case deepNight      // 0-5 AM
    case dawn           // 5-7 AM
    case earlyMorning   // 7-9 AM
    case lateMorning    // 9-12 AM
    case earlyAfternoon // 12-3 PM
    case lateAfternoon  // 3-5 PM
    case goldenHour     // 5-7 PM
    case dusk           // 7-9 PM
    case evening        // 9-12 AM
    
    #if DEBUG
    static var debugHour: Int? = nil
    #endif
    
    init(hour: Int = Calendar.current.component(.hour, from: Date())) {
        #if DEBUG
        let testHour = Self.debugHour ?? hour
        #else
        let testHour = hour
        #endif
        
        switch testHour {
        case 0..<5:   self = .deepNight
        case 5..<7:   self = .dawn
        case 7..<9:   self = .earlyMorning
        case 9..<12:  self = .lateMorning
        case 12..<15: self = .earlyAfternoon
        case 15..<17: self = .lateAfternoon
        case 17..<19: self = .goldenHour
        case 19..<21: self = .dusk
        default:      self = .evening
        }
    }
    
    var luminance: Double {
        switch self {
        case .deepNight:      return 0.20
        case .dawn:           return 0.55
        case .earlyMorning:   return 0.95
        case .lateMorning:    return 0.98
        case .earlyAfternoon: return 0.99
        case .lateAfternoon:  return 0.95
        case .goldenHour:     return 0.70
        case .dusk:           return 0.55
        case .evening:        return 0.30
        }
    }
    
    var hasHighSaturation: Bool {
        self == .dusk || self == .goldenHour
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Text Style Configuration
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

enum TimeAdaptiveTextStyle {
    case primary     // Main titles, headers
    case secondary   // Subtitles, descriptions
    case subtle      // Hints, small labels (FIXES YOUR READABILITY ISSUE!)
    case accent      // Important highlights
    
    func configuration(for colorScheme: ColorScheme, period: TimeOfDay) -> TimeAdaptiveTextConfiguration {
            // 1. If System is Dark Mode, ALWAYS use Dark Mode text (White)
            if colorScheme == .dark {
                return darkModeConfig()
            }
            
            // 2. If System is Light Mode, check if the "Time" is visually dark
            if period.isVisuallyDark {
                // It is Light Mode, but it is Night Time in the app.
                // We must use light text (effectively Dark Mode text styles)
                return darkModeConfig()
            }
            
            // 3. Otherwise, use standard Light Mode text
            return lightModeConfig(for: period)
        }
    
    // MARK: - Dark Mode
    
    private func darkModeConfig() -> TimeAdaptiveTextConfiguration {
        switch self {
        case .primary:
            return TimeAdaptiveTextConfiguration(
                color: Color(hex: "E8E3DB").opacity(0.88),  // Warm paper white
                shadowColor: Color(hex: "4A3F35").opacity(0.25),
                shadowRadius: 2.0, shadowX: 0, shadowY: 1.0
            )
        case .secondary:
            return TimeAdaptiveTextConfiguration(
                color: Color(hex: "C8C0B8").opacity(0.75),  // Soft grey-beige
                shadowColor: Color(hex: "2A2520").opacity(0.2),
                shadowRadius: 1.5, shadowX: 0, shadowY: 0.8
            )
        case .subtle:
            return TimeAdaptiveTextConfiguration(
                color: Color(hex: "A89C92").opacity(0.58),  // Dusty warm grey
                shadowColor: Color(hex: "1C1816").opacity(0.15),
                shadowRadius: 1.2, shadowX: 0, shadowY: 0.6
            )
        case .accent:
            return TimeAdaptiveTextConfiguration(
                color: Color(hex: "D4B896").opacity(0.85),  // Soft golden
                shadowColor: Color(hex: "5C4A38").opacity(0.3),
                shadowRadius: 2.0, shadowX: 0, shadowY: 1.0
            )
        }
    }
    
    // MARK: - Light Mode (Time-Adaptive)
    
    private func lightModeConfig(for period: TimeOfDay) -> TimeAdaptiveTextConfiguration {
        switch self {
        case .primary:   return primaryLightConfig(for: period)
        case .secondary: return secondaryLightConfig(for: period)
        case .subtle:    return subtleLightConfig(for: period)
        case .accent:    return accentLightConfig(for: period)
        }
    }
    
    // MARK: - Primary Text Configurations
    
    private func primaryLightConfig(for period: TimeOfDay) -> TimeAdaptiveTextConfiguration {
        switch period {
        case .deepNight, .evening:
            // Deep night: Soft warm white for dark blue backgrounds
            return TimeAdaptiveTextConfiguration(
                color: TimeAdaptiveColor.hex("F5F0E8").opacity(0.95),  // Warm cream-white
                shadowColor: TimeAdaptiveColor.hex("0D1B2A").opacity(0.3),
                shadowRadius: 1.8, shadowX: 0, shadowY: 0.9
            )
        case .dawn:
            // Dawn: Peachy-cream for lavender/rose backgrounds
            return TimeAdaptiveTextConfiguration(
                color: TimeAdaptiveColor.hex("FFF8F0").opacity(0.96),  // Soft peach-white
                shadowColor: TimeAdaptiveColor.hex("73628A").opacity(0.25),
                shadowRadius: 1.5, shadowX: 0, shadowY: 0.8
            )
        case .earlyMorning, .lateMorning, .earlyAfternoon, .lateAfternoon:
            // Daytime: Rich dark text for bright backgrounds
            return TimeAdaptiveTextConfiguration(
                color: TimeAdaptiveColor.hex("2A2520").opacity(0.92),  // Warm dark brown
                shadowColor: Color.white.opacity(0.25),
                shadowRadius: 0.8, shadowX: 0, shadowY: 0.4
            )
        case .goldenHour:
            // Golden Hour: Deep burgundy-brown for warm amber backgrounds
            return TimeAdaptiveTextConfiguration(
                color: TimeAdaptiveColor.hex("3D2520"),  // Deep warm brown
                shadowColor: TimeAdaptiveColor.hex("FFD4A3").opacity(0.35),
                shadowRadius: 1.8, shadowX: 0, shadowY: 0.9
            )
        case .dusk:
            // DUSK FIX: Warm bronze-cream instead of pure white for coral/mauve backgrounds
            return TimeAdaptiveTextConfiguration(
                color: TimeAdaptiveColor.hex("FFF5E8").opacity(0.96),  // Warm peachy-bronze
                shadowColor: TimeAdaptiveColor.hex("5E3A52").opacity(0.4),  // Deep mauve shadow
                shadowRadius: 2.2, shadowX: 0, shadowY: 1.1
            )
        }
    }
    
    // MARK: - Secondary Text Configurations
    
    private func secondaryLightConfig(for period: TimeOfDay) -> TimeAdaptiveTextConfiguration {
        switch period {
        case .deepNight, .evening:
            // Deep night: Soft warm grey-white
            return TimeAdaptiveTextConfiguration(
                color: TimeAdaptiveColor.hex("E8E0D5").opacity(0.88),  // Warm grey-cream
                shadowColor: TimeAdaptiveColor.hex("1B263B").opacity(0.25),
                shadowRadius: 1.2, shadowX: 0, shadowY: 0.6
            )
        case .dawn:
            // Dawn: Rosy-cream for twilight
            return TimeAdaptiveTextConfiguration(
                color: TimeAdaptiveColor.hex("FFEEE8").opacity(0.90),  // Rose-cream
                shadowColor: TimeAdaptiveColor.hex("73628A").opacity(0.2),
                shadowRadius: 1.0, shadowX: 0, shadowY: 0.5
            )
        case .earlyMorning, .lateMorning, .earlyAfternoon, .lateAfternoon:
            // Daytime: Softer brown-grey
            return TimeAdaptiveTextConfiguration(
                color: TimeAdaptiveColor.hex("5A4F45").opacity(0.78),  // Warm grey-brown
                shadowColor: Color.white.opacity(0.15),
                shadowRadius: 0.6, shadowX: 0, shadowY: 0.3
            )
        case .goldenHour:
            // Golden Hour: Rich chocolate-brown
            return TimeAdaptiveTextConfiguration(
                color: TimeAdaptiveColor.hex("4A3528"),  // Deep chocolate
                shadowColor: TimeAdaptiveColor.hex("FFD4A3").opacity(0.28),
                shadowRadius: 1.4, shadowX: 0, shadowY: 0.7
            )
        case .dusk:
            // DUSK FIX: Peachy-gold instead of white for harmony
            return TimeAdaptiveTextConfiguration(
                color: TimeAdaptiveColor.hex("FFEBD8").opacity(0.92),  // Peachy-bronze
                shadowColor: TimeAdaptiveColor.hex("5E3A52").opacity(0.35),
                shadowRadius: 2.0, shadowX: 0, shadowY: 1.0
            )
        }
    }
    
    // MARK: - Subtle Text Configurations (CRITICAL - Fixes your readability!)
    
    private func subtleLightConfig(for period: TimeOfDay) -> TimeAdaptiveTextConfiguration {
        switch period {
        case .deepNight, .evening:
            // Deep night: Muted warm white
            return TimeAdaptiveTextConfiguration(
                color: TimeAdaptiveColor.hex("D8CFBF").opacity(0.82),  // Dusty cream
                shadowColor: TimeAdaptiveColor.hex("1B263B").opacity(0.2),
                shadowRadius: 1.0, shadowX: 0, shadowY: 0.5
            )
        case .dawn:
            // Dawn: Soft rose-beige
            return TimeAdaptiveTextConfiguration(
                color: TimeAdaptiveColor.hex("FFE8DC").opacity(0.85),  // Rose-beige
                shadowColor: TimeAdaptiveColor.hex("73628A").opacity(0.18),
                shadowRadius: 1.0, shadowX: 0, shadowY: 0.4
            )
        case .earlyMorning, .lateMorning, .earlyAfternoon, .lateAfternoon:
            // Daytime: Warm grey
            return TimeAdaptiveTextConfiguration(
                color: TimeAdaptiveColor.hex("75685D").opacity(0.72),  // Warm stone grey
                shadowColor: Color.white.opacity(0.12),
                shadowRadius: 0.5, shadowX: 0, shadowY: 0.2
            )
        case .goldenHour:
            // Golden Hour: Sepia-brown
            return TimeAdaptiveTextConfiguration(
                color: TimeAdaptiveColor.hex("5A3F32").opacity(0.88),  // Sepia brown
                shadowColor: TimeAdaptiveColor.hex("FFD4A3").opacity(0.22),
                shadowRadius: 1.2, shadowX: 0, shadowY: 0.5
            )
        case .dusk:
            // DUSK FIX: Golden-bronze for subtle text (your main readability issue!)
            return TimeAdaptiveTextConfiguration(
                color: TimeAdaptiveColor.hex("FFE0C2").opacity(0.88),  // Golden-bronze
                shadowColor: TimeAdaptiveColor.hex("5E3A52").opacity(0.3),
                shadowRadius: 1.8, shadowX: 0, shadowY: 0.8
            )
        }
    }
    
    // MARK: - Accent Text Configurations
    
    private func accentLightConfig(for period: TimeOfDay) -> TimeAdaptiveTextConfiguration {
        switch period {
        case .deepNight:
            // Deep night: Cool blue accent
            return TimeAdaptiveTextConfiguration(
                color: TimeAdaptiveColor.hex("B8D4E8"),  // Soft sky blue
                shadowColor: TimeAdaptiveColor.hex("0D1B2A").opacity(0.4),
                shadowRadius: 1.8, shadowX: 0, shadowY: 0.9
            )
        case .dawn:
            // Dawn: Rosy-peach accent
            return TimeAdaptiveTextConfiguration(
                color: TimeAdaptiveColor.hex("FFCDB8"),  // Rose-peach
                shadowColor: TimeAdaptiveColor.hex("73628A").opacity(0.35),
                shadowRadius: 1.5, shadowX: 0, shadowY: 0.8
            )
        case .earlyMorning, .lateMorning:
            // Morning: Vibrant purple accent
            return TimeAdaptiveTextConfiguration(
                color: TimeAdaptiveColor.hex("7B68A6"),  // Morning purple
                shadowColor: Color.white.opacity(0.3),
                shadowRadius: 1.2, shadowX: 0, shadowY: 0.6
            )
        case .earlyAfternoon, .lateAfternoon:
            // Afternoon: Deeper purple accent
            return TimeAdaptiveTextConfiguration(
                color: TimeAdaptiveColor.hex("8B6FA8"),  // Afternoon purple
                shadowColor: Color.white.opacity(0.2),
                shadowRadius: 1.0, shadowX: 0, shadowY: 0.5
            )
        case .goldenHour:
            // Golden Hour: Rich amber-bronze accent
            return TimeAdaptiveTextConfiguration(
                color: TimeAdaptiveColor.hex("B8762E"),  // Amber-bronze
                shadowColor: TimeAdaptiveColor.hex("FFD4A3").opacity(0.35),
                shadowRadius: 1.6, shadowX: 0, shadowY: 0.8
            )
        case .dusk:
            // DUSK FIX: Warm golden-yellow that harmonizes with sunset
            return TimeAdaptiveTextConfiguration(
                color: TimeAdaptiveColor.hex("FFE8A8"),  // Warm golden-yellow
                shadowColor: TimeAdaptiveColor.hex("5E3A52").opacity(0.38),
                shadowRadius: 2.2, shadowX: 0, shadowY: 1.1
            )
        case .evening:
            // Evening: Cool blue-grey accent
            return TimeAdaptiveTextConfiguration(
                color: TimeAdaptiveColor.hex("A8BDCC"),  // Cool blue-grey
                shadowColor: TimeAdaptiveColor.hex("1A1612").opacity(0.35),
                shadowRadius: 1.5, shadowX: 0, shadowY: 0.8
            )
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Configuration Data Structure
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct TimeAdaptiveTextConfiguration {
    let color: Color
    let shadowColor: Color
    let shadowRadius: CGFloat
    let shadowX: CGFloat
    let shadowY: CGFloat
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Color Helper (Separate from your existing Color extensions)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct TimeAdaptiveColor {
    /// Creates Color from hex string (internal helper to avoid conflicts)
    static func hex(_ hexString: String) -> Color {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        return Color(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Optional: Text Scrim Helper
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extension View {
    /// Adds subtle dark background for extra readability during dusk/golden hour
    func adaptiveTextScrim(
        colorScheme: ColorScheme,
        intensity: Double = 1.0
    ) -> some View {
        let hour = Calendar.current.component(.hour, from: Date())
        let period = TimeOfDay(hour: hour)
        
        let shouldApplyScrim = (colorScheme == .light && period.hasHighSaturation)
        
        return self.background(
            Group {
                if shouldApplyScrim {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.black.opacity(0.15 * intensity))
                        .blur(radius: 2)
                        .padding(-4)
                } else {
                    Color.clear
                }
            }
        )
    }
}

extension TimeOfDay {
    /// Determines if the background is visually dark for this time period
    /// regardless of the system Light/Dark mode setting.
    var isVisuallyDark: Bool {
        switch self {
        case .deepNight, .evening, .dusk, .dawn:
            // These times have dark/saturated backgrounds -> Need Light Text
            return true
        case .earlyMorning, .lateMorning, .earlyAfternoon, .lateAfternoon, .goldenHour:
            // These times have light/pastel backgrounds -> Need Dark Text
            return false
        }
    }

}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - USAGE EXAMPLES
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/*
 
 REPLACE THIS:
 -------------
 Text("2/8")
     .foregroundStyle(Color.dynamicSecondaryLabel.opacity(0.6))
 
 WITH THIS:
 ----------
 Text("2/8")
     .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
 
 
 COMPLETE EXAMPLES:
 ------------------
 
 // Page Title
 Text("Profile")
     .font(.system(size: 23, weight: .bold))
     .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
 
 // Section Header
 Text("Constellations")
     .font(.system(size: 16, weight: .semibold))
     .fontDesign(.serif)
     .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
 
 // Subtitle
 Text("Apprentice Weaver")
     .font(.system(size: 16, weight: .regular))
     .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
 
 // Small Label (YOUR MAIN ISSUE - FIXES THE GRAY TEXT!)
 Text("2/8")
     .font(.system(size: 12, weight: .medium))
     .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
 
 // Hint Text
 Text("Tap unlocked constellations to read their stories")
     .font(.system(size: 11, weight: .regular))
     .italic()
     .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
 
 // Description
 Text("Quietly discovered moments in your journey")
     .font(.system(size: 11, weight: .regular))
     .italic()
     .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
 
 // Optional: Add scrim for extra readability during dusk
 Text("Important text during dusk")
     .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
     .adaptiveTextScrim(colorScheme: colorScheme)
 
 */

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Testing Previews (Optional - for testing different times)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

#if DEBUG
#Preview("Deep Night - 3 AM") {
    TimeOfDay.debugHour = 3
    return TimeAdaptiveTextTestView()
}

#Preview("Dawn - 6 AM") {
    TimeOfDay.debugHour = 6
    return TimeAdaptiveTextTestView()
}

#Preview("Morning - 8 AM") {
    TimeOfDay.debugHour = 8
    return TimeAdaptiveTextTestView()
}

#Preview("Afternoon - 2 PM") {
    TimeOfDay.debugHour = 14
    return TimeAdaptiveTextTestView()
}

#Preview("Golden Hour - 6 PM") {
    TimeOfDay.debugHour = 18
    return TimeAdaptiveTextTestView()
}

#Preview("Dusk - 8 PM") {
    TimeOfDay.debugHour = 20
    return TimeAdaptiveTextTestView()
}

#Preview("Evening - 10 PM") {
    TimeOfDay.debugHour = 22
    return TimeAdaptiveTextTestView()
}

struct TimeAdaptiveTextTestView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(LinearGradient(
                    colors: [Color.blue, Color.purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            
            VStack(spacing: 20) {
                Text("Primary Text")
                    .font(.system(size: 23, weight: .bold))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                
                Text("Secondary Text")
                    .font(.system(size: 16, weight: .regular))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                
                Text("Subtle Text - 2/8")
                    .font(.system(size: 12, weight: .medium))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                
                Text("Accent Text")
                    .font(.system(size: 13, weight: .semibold))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .accent)
            }
            .padding()
        }
        .ignoresSafeArea()
    }
}
#endif
