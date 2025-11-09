//
//  TimeOfDay.swift
//  Reverie Weaver
//
//  Created by Antheia Li on 10/25/25.
//


//
// TimeAdaptiveText.swift
// Reverie Weaver
//
// Time-adaptive text system that works with your existing Color+Extensions
// Drop this file into your project - no conflicts!
//

import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - TIME-ADAPTIVE TEXT (No conflicts with existing code!)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extension View {
    /// Time-adaptive text that fixes readability across all gradients
    /// Works with your existing Color extensions
    func timeAdaptiveText(
        colorScheme: ColorScheme,
        style: TimeAdaptiveTextStyle = .primary
    ) -> some View {
        let hour = Calendar.current.component(.hour, from: Date())
        let period = TimeOfDay(hour: hour)
        
        let config = style.configuration(for: colorScheme, period: period)
        
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
        if colorScheme == .dark {
            return darkModeConfig()
        } else {
            return lightModeConfig(for: period)
        }
    }
    
    // MARK: - Dark Mode
    
    private func darkModeConfig() -> TimeAdaptiveTextConfiguration {
        switch self {
        case .primary:
            return TimeAdaptiveTextConfiguration(
                color: .white.opacity(0.95),
                shadowColor: Color.white.opacity(0.2),
                shadowRadius: 1.5, shadowX: 0, shadowY: 0.8
            )
        case .secondary:
            return TimeAdaptiveTextConfiguration(
                color: .white.opacity(0.85),
                shadowColor: Color.white.opacity(0.15),
                shadowRadius: 1.0, shadowX: 0, shadowY: 0.5
            )
        case .subtle:
            return TimeAdaptiveTextConfiguration(
                color: .white.opacity(0.75),
                shadowColor: Color.white.opacity(0.12),
                shadowRadius: 1.0, shadowX: 0, shadowY: 0.4
            )
        case .accent:
            return TimeAdaptiveTextConfiguration(
                color: TimeAdaptiveColor.hex("F9D8B5"),
                shadowColor: TimeAdaptiveColor.hex("CBA4F7").opacity(0.3),
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
            return TimeAdaptiveTextConfiguration(
                color: .white.opacity(0.95),
                shadowColor: Color.white.opacity(0.2),
                shadowRadius: 1.5, shadowX: 0, shadowY: 0.8
            )
        case .dawn:
            return TimeAdaptiveTextConfiguration(
                color: .white.opacity(0.95),
                shadowColor: Color.black.opacity(0.2),
                shadowRadius: 1.5, shadowX: 0, shadowY: 0.8
            )
        case .earlyMorning, .lateMorning, .earlyAfternoon, .lateAfternoon:
            return TimeAdaptiveTextConfiguration(
                color: .black.opacity(0.90),
                shadowColor: Color.black.opacity(0.05),
                shadowRadius: 0.5, shadowX: 0, shadowY: 0.3
            )
        case .goldenHour:
            return TimeAdaptiveTextConfiguration(
                color: TimeAdaptiveColor.hex("3D2E2E"),
                shadowColor: Color.white.opacity(0.25),
                shadowRadius: 1.5, shadowX: 0, shadowY: 0.8
            )
        case .dusk:
            return TimeAdaptiveTextConfiguration(
                color: .white,
                shadowColor: Color.black.opacity(0.35),
                shadowRadius: 2.0, shadowX: 0, shadowY: 1.0
            )
        }
    }
    
    // MARK: - Secondary Text Configurations
    
    private func secondaryLightConfig(for period: TimeOfDay) -> TimeAdaptiveTextConfiguration {
        switch period {
        case .deepNight, .evening:
            return TimeAdaptiveTextConfiguration(
                color: .white.opacity(0.88),
                shadowColor: Color.white.opacity(0.15),
                shadowRadius: 1.0, shadowX: 0, shadowY: 0.5
            )
        case .dawn:
            return TimeAdaptiveTextConfiguration(
                color: .white.opacity(0.90),
                shadowColor: Color.black.opacity(0.15),
                shadowRadius: 1.0, shadowX: 0, shadowY: 0.5
            )
        case .earlyMorning, .lateMorning, .earlyAfternoon, .lateAfternoon:
            return TimeAdaptiveTextConfiguration(
                color: .black.opacity(0.75),
                shadowColor: Color.black.opacity(0.03),
                shadowRadius: 0.5, shadowX: 0, shadowY: 0.2
            )
        case .goldenHour:
            return TimeAdaptiveTextConfiguration(
                color: TimeAdaptiveColor.hex("4A3535"),
                shadowColor: Color.white.opacity(0.2),
                shadowRadius: 1.2, shadowX: 0, shadowY: 0.6
            )
        case .dusk:
            return TimeAdaptiveTextConfiguration(
                color: .white.opacity(0.95),
                shadowColor: Color.black.opacity(0.3),
                shadowRadius: 1.8, shadowX: 0, shadowY: 0.9
            )
        }
    }
    
    // MARK: - Subtle Text Configurations (CRITICAL - Fixes your readability!)
    
    private func subtleLightConfig(for period: TimeOfDay) -> TimeAdaptiveTextConfiguration {
        switch period {
        case .deepNight, .evening:
            return TimeAdaptiveTextConfiguration(
                color: .white.opacity(0.80),  // Much better than 0.6!
                shadowColor: Color.white.opacity(0.12),
                shadowRadius: 1.0, shadowX: 0, shadowY: 0.4
            )
        case .dawn:
            return TimeAdaptiveTextConfiguration(
                color: .white.opacity(0.85),
                shadowColor: Color.black.opacity(0.12),
                shadowRadius: 1.0, shadowX: 0, shadowY: 0.4
            )
        case .earlyMorning, .lateMorning, .earlyAfternoon, .lateAfternoon:
            return TimeAdaptiveTextConfiguration(
                color: Color.gray.opacity(0.85),
                shadowColor: Color.black.opacity(0.02),
                shadowRadius: 0.3, shadowX: 0, shadowY: 0.1
            )
        case .goldenHour:
            return TimeAdaptiveTextConfiguration(
                color: TimeAdaptiveColor.hex("5A4545").opacity(0.90),
                shadowColor: Color.white.opacity(0.15),
                shadowRadius: 1.0, shadowX: 0, shadowY: 0.4
            )
        case .dusk:
            return TimeAdaptiveTextConfiguration(
                color: .white.opacity(0.88),
                shadowColor: Color.black.opacity(0.25),
                shadowRadius: 1.6, shadowX: 0, shadowY: 0.7
            )
        }
    }
    
    // MARK: - Accent Text Configurations
    
    private func accentLightConfig(for period: TimeOfDay) -> TimeAdaptiveTextConfiguration {
        switch period {
        case .deepNight:
            return TimeAdaptiveTextConfiguration(
                color: TimeAdaptiveColor.hex("A8DADC"),
                shadowColor: TimeAdaptiveColor.hex("415A77").opacity(0.3),
                shadowRadius: 1.5, shadowX: 0, shadowY: 0.8
            )
        case .dawn:
            return TimeAdaptiveTextConfiguration(
                color: TimeAdaptiveColor.hex("FFD5C2"),
                shadowColor: TimeAdaptiveColor.hex("73628A").opacity(0.3),
                shadowRadius: 1.5, shadowX: 0, shadowY: 0.8
            )
        case .earlyMorning, .lateMorning:
            return TimeAdaptiveTextConfiguration(
                color: TimeAdaptiveColor.hex("7B68A6"),
                shadowColor: TimeAdaptiveColor.hex("E3F2FD").opacity(0.2),
                shadowRadius: 1.0, shadowX: 0, shadowY: 0.5
            )
        case .earlyAfternoon, .lateAfternoon:
            return TimeAdaptiveTextConfiguration(
                color: TimeAdaptiveColor.hex("9B7EBD"),
                shadowColor: Color.black.opacity(0.05),
                shadowRadius: 1.0, shadowX: 0, shadowY: 0.5
            )
        case .goldenHour:
            return TimeAdaptiveTextConfiguration(
                color: TimeAdaptiveColor.hex("8B4789"),
                shadowColor: TimeAdaptiveColor.hex("FFD4A3").opacity(0.3),
                shadowRadius: 1.5, shadowX: 0, shadowY: 0.8
            )
        case .dusk:
            return TimeAdaptiveTextConfiguration(
                color: TimeAdaptiveColor.hex("FFF4C2"),
                shadowColor: Color.black.opacity(0.3),
                shadowRadius: 2.0, shadowX: 0, shadowY: 1.0
            )
        case .evening:
            return TimeAdaptiveTextConfiguration(
                color: TimeAdaptiveColor.hex("9DB7D8"),
                shadowColor: TimeAdaptiveColor.hex("293F5C").opacity(0.3),
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
     .font(.system(size: 36, weight: .bold))
     .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
 
 // Section Header
 Text("Constellations")
     .font(.system(size: 15, weight: .semibold))
     .fontDesign(.serif)
     .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
 
 // Subtitle
 Text("Apprentice Weaver")
     .font(.system(size: 16, weight: .regular))
     .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
 
 // Small Label (YOUR MAIN ISSUE - FIXES THE GRAY TEXT!)
 Text("2/8")
     .font(.system(size: 11, weight: .medium))
     .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
 
 // Hint Text
 Text("Tap unlocked constellations to read their stories")
     .font(.system(size: 10, weight: .regular))
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
            // Your ReverieWeaverBackground would go here
            Rectangle()
                .fill(LinearGradient(
                    colors: [Color.blue, Color.purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            
            VStack(spacing: 20) {
                Text("Primary Text")
                    .font(.system(size: 24, weight: .bold))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                
                Text("Secondary Text")
                    .font(.system(size: 16, weight: .regular))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                
                Text("Subtle Text - 2/8")
                    .font(.system(size: 11, weight: .medium))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                
                Text("Accent Text")
                    .font(.system(size: 14, weight: .semibold))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .accent)
            }
            .padding()
        }
        .ignoresSafeArea()
    }
}
#endif
