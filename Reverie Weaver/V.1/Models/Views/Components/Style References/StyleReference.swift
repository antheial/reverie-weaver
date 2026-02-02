//
// StyleReference.swift
//  Reverie Weaver
//
//  Created by Antheia Li on 10/22/25.
//

import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - TIME-ADAPTIVE CARD STYLING
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// In StyleReference.swift - Update reverieCardStyle

extension View {
    func reverieCardStyle(
        colorScheme: ColorScheme,
        cornerRadius: CGFloat = 16,
        shadowRadius: CGFloat? = nil,
        shadowYOffset: CGFloat? = nil,
        strokeWidth: CGFloat? = nil,
        borderOpacity: CGFloat? = nil,
        backgroundOpacity: CGFloat? = nil
    ) -> some View {
        let hour = Calendar.current.component(.hour, from: Date())
        let period = TimeOfDay(hour: hour)
        
        // Determine the "Effective" Color Scheme
        let isVisuallyDark = (period == .deepNight || period == .evening || period == .dusk)
        let effectiveScheme: ColorScheme = (colorScheme == .dark || isVisuallyDark) ? .dark : .light
        
        // Detect light backgrounds that need more visible borders
        let isLightBackground = (period == .dawn || period == .earlyMorning ||
                                 period == .lateMorning || period == .earlyAfternoon ||
                                 period == .lateAfternoon)
        
        let config = CardStyleConfiguration(period: period, colorScheme: colorScheme)

        return self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        Color.adaptiveSectionBackground(colorScheme: effectiveScheme)
                            .opacity(backgroundOpacity ?? config.backgroundOpacity)
                    )
                    .shadow(
                        color: config.shadowColor,
                        radius: shadowRadius ?? config.shadowRadius,
                        y: shadowYOffset ?? config.shadowYOffset
                    )
            )
            // Subtle border glow for dark/dusk periods
            .overlay(
                Group {
                    if isVisuallyDark {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(
                                Color.white.opacity(0.18),
                                lineWidth: 0.28
                            )
                            .shadow(color: Color.white.opacity(0.16), radius: 6, x: 0, y: 0)
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        // Enhanced border for light backgrounds
                        isLightBackground
                            ? Color.black.opacity(0.068)  // More visible gray border
                            : Color.adaptiveBorder(colorScheme: effectiveScheme)
                                .opacity(borderOpacity ?? config.borderOpacity),
                        lineWidth: strokeWidth ?? config.strokeWidth
                    )
            )
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - CARD CONFIGURATION
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
private struct CardStyleConfiguration {
    let backgroundOpacity: CGFloat
    let shadowColor: Color
    let shadowRadius: CGFloat
    let shadowYOffset: CGFloat
    let strokeWidth: CGFloat
    let borderOpacity: CGFloat

    init(period: TimeOfDay, colorScheme: ColorScheme) {
        // 1. Identify times that have dark backgrounds (Night/Evening/Dusk)
        // We force the dark card style during these times so we don't get
        // dark borders on dark backgrounds.
        let isVisuallyDark = (period == .deepNight || period == .evening || period == .dusk)
        
        // 2. Use Dark Theme if System is Dark OR if it's visually Night time
        let useDarkTheme = colorScheme == .dark || isVisuallyDark

        if useDarkTheme {
            // MARK: Dark Theme / Night Time Styling
            // Glassy, lighter opacity to pop against dark backgrounds
            self.backgroundOpacity = 0.36        // High visibility glass
            self.shadowColor = Color(hex: "0F0D0B").opacity(0.4)
            self.shadowRadius = 10
            self.shadowYOffset = 4
            self.strokeWidth = 0.8
            self.borderOpacity = 0.55
        } else {
            // MARK: Light Mode (Daytime) Styling
            switch period {
            case .deepNight, .evening, .dusk:
                self.backgroundOpacity = 0.38
                self.shadowColor = Color.black.opacity(0.18)
                self.shadowRadius = 8
                self.shadowYOffset = 3
                self.strokeWidth = 0.5
                self.borderOpacity = 0.38

            case .dawn:
                self.backgroundOpacity = 0.32
                self.shadowColor = Color.black.opacity(0.16)
                self.shadowRadius = 7
                self.shadowYOffset = 2.5
                self.strokeWidth = 0.55
                self.borderOpacity = 0.42

            case .earlyMorning, .lateMorning:
                self.backgroundOpacity = 0.38
                self.shadowColor = Color.black.opacity(0.18)
                self.shadowRadius = 5
                self.shadowYOffset = 2
                self.strokeWidth = 0.6
                self.borderOpacity = 0.48

            case .earlyAfternoon, .lateAfternoon:
                self.backgroundOpacity = 0.38
                self.shadowColor = Color.black.opacity(0.16)
                self.shadowRadius = 4
                self.shadowYOffset = 1.5
                self.strokeWidth = 0.65
                self.borderOpacity = 0.52

            case .goldenHour:
                self.backgroundOpacity = 0.38
                self.shadowColor = Color.orange.opacity(0.16)
                self.shadowRadius = 7
                self.shadowYOffset = 3
                self.strokeWidth = 0.7
                self.borderOpacity = 0.50
            }
        }
    }
}

/*
 ═══════════════════════════════════════════════════════════════
 USAGE EXAMPLES
 ═══════════════════════════════════════════════════════════════

 // Automatic time adaptation:
 VStack {
     Text("Quote")
         .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
 }
 .reverieCardStyle(colorScheme: colorScheme)

 // Both text AND card adapt to time of day!


 // Override specific card values if needed:
 .reverieCardStyle(
     colorScheme: colorScheme,
     shadowRadius: 12  // Custom, rest adapts
 )

 🌅 Dawn (5-7 AM)
    Cards: Gentle, awakening
    Text: Readable with soft contrast

 ☀️ Morning (7-12 PM)
    Cards: Crisp, well-defined
    Text: Clear, easy to read

 🌤️ Afternoon (12-5 PM)
    Cards: Brightest, sharpest
    Text: High contrast

 🌆 Golden Hour (5-7 PM)
    Cards: Warm orange-tinted shadows ✨
    Text: Rich, visible

 🌃 Dusk (7-9 PM)
    Cards: Dramatic purple-tinted shadows ✨
    Text: Strong contrast

 🌙 Night (9 PM-5 AM)
    Cards: Soft, dreamy
    Text: High readability


 ═══════════════════════════════════════════════════════════════
 VISUAL REFERENCE
 ═══════════════════════════════════════════════════════════════

 ┌─────────────────┬────────┬──────────┬──────────┬────────┐
 │ Time Period     │ BG Opa │ Shadow R │ Shadow Y │ Border │
 ├─────────────────┼────────┼──────────┼──────────┼────────┤
 │ Night           │ 0.35   │ 8        │ 3        │ 0.38   │
 │ Dawn            │ 0.32   │ 7        │ 2.5      │ 0.42   │
 │ Morning         │ 0.28   │ 5        │ 2        │ 0.48   │
 │ Afternoon       │ 0.25   │ 4        │ 1.5      │ 0.52   │
 │ Golden Hour 🌆  │ 0.33   │ 7 🟠     │ 3        │ 0.50   │
 │ Dusk 🌃         │ 0.38   │ 10 🟣    │ 4        │ 0.58   │
 │ Dark Mode       │ 0.25   │ 6        │ 2        │ 0.45   │
 └─────────────────┴────────┴──────────┴──────────┴────────┘

 🟠 = Orange-tinted shadow
 🟣 = Purple-tinted shadow

 */

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - TESTING
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

#if DEBUG
// Test different times using the debugHour from TimeOfDay.swift

#Preview("Golden Hour Cards") {
    TimeOfDay.debugHour = 18
    return TestCardView()
}

#Preview("Dusk Cards") {
    TimeOfDay.debugHour = 20
    return TestCardView()
}

#Preview("Morning Cards") {
    TimeOfDay.debugHour = 9
    return TestCardView()
}

private struct TestCardView: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            ReverieWeaverBackground()

            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quote Card")
                        .font(.headline)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

                    Text("This card adapts its shadow and border to the time of day")
                        .font(.subheadline)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                }
                .padding()
                .reverieCardStyle(colorScheme: colorScheme)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Intention Card")
                        .font(.headline)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

                    Text("Notice the subtle shadow changes")
                        .font(.subheadline)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                }
                .padding()
                .reverieCardStyle(colorScheme: colorScheme)
            }
            .padding()
        }
    }
}
#endif

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - TEXT STYLES (Simplified Adaptive Versions)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extension View {
    func adaptivePrimaryText(
        colorScheme: ColorScheme,
        contrastBoost: Double = 0.05,
        glowIntensity: Double = 0.15
    ) -> some View {
        let textColor: Color = colorScheme == .dark
            ? .white.opacity(0.92 + contrastBoost)
            : .black.opacity(0.90)

        return self
            .foregroundStyle(textColor)
            .shadow(
                color: colorScheme == .dark
                    ? Color.white.opacity(glowIntensity * 0.4)
                    : Color.black.opacity(0.05),
                radius: colorScheme == .dark ? 1.5 : 0.8,
                y: colorScheme == .dark ? 0.8 : 0.4
            )
    }

    func adaptiveSecondaryText(
        colorScheme: ColorScheme,
        opacity: Double = 0.85
    ) -> some View {
        let textColor: Color = colorScheme == .dark
            ? Color.white.opacity(opacity * 0.9)
            : Color.black.opacity(opacity * 0.8)

        return self.foregroundStyle(textColor)
    }

    func adaptiveReadableText(
        colorScheme: ColorScheme,
        base: Color = .dynamicSecondaryLabel,
        glowIntensity: Double = 0.12
    ) -> some View {
        let textColor: Color = colorScheme == .dark
            ? base.opacity(0.88)
            : Color.black.opacity(0.85)

        return self
            .foregroundStyle(textColor)
            .shadow(
                color: colorScheme == .dark
                    ? Color.white.opacity(glowIntensity * 0.3)
                    : Color.black.opacity(glowIntensity * 0.6),
                radius: colorScheme == .dark ? 1 : 0.5,
                y: 0.3
            )
    }
}

extension View {
    func readableTintOverlay(colorScheme: ColorScheme) -> some View {
        self.background(
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    colorScheme == .dark
                        ? Color.black.opacity(0.2)
                        : Color.white.opacity(0.25)
                )
                .blur(radius: 1.5)
        )
    }
}

extension View {
    func reverieAccentText(colorScheme: ColorScheme) -> some View {
        self.foregroundStyle(
            LinearGradient(
                colors: colorScheme == .dark
                    ? [Color(hex: "CBA4F7"), Color(hex: "F9D8B5")]
                    : [Color(hex: "9B7EBD"), Color(hex: "E8927C")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .shadow(color: .white.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 1)
    }
}


// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// COLOR PALETTE
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct ReverieColors {

    // MARK: - Background Gradients

    // Dark Mode Background
    static let darkModePalette = [
        "1A1625",  // Deep purple-black
        "2D2438",  // Rich violet shadow
        "241B2F"   // Dark plum
    ]

    // Light Mode - Dawn (0-6 AM)
    static let dawnPalette = [
        "2D3561",  // Deep pre-dawn indigo
        "8B6F9E",  // Soft purple haze
        "D4A59A"   // First peachy glow
    ]

    // Light Mode - Morning (6-12 AM)
    static let morningPalette = [
        "FFF9E8",  // Warmer cream
        "E8F4FF",  // Softer blue
        "FFFBF0"   // Gentle warmth
    ]

    // Light Mode - Afternoon (12-5 PM)
    static let afternoonPalette = [
        "F8FCFF",  // Bright clear
        "FFFAF0",  // Warm cream
        "F0F7FF"   // Pale azure
    ]

    // Light Mode - Evening (5-9 PM)
    static let eveningPalette = [
        "E8927C",  // Vibrant coral
        "9B7EBD",  // Royal purple
        "5D7A9E"   // Deep twilight
    ]

    // Light Mode - Night (9 PM-12 AM)
    static let nightPalette = [
        "1B2845",  // Deep navy
        "2D3E5C",  // Midnight blue
        "3A4A63"   // Charcoal blue
    ]

    // MARK: - Accent Colors

    static let sparklesGradient = ["9B7EBD", "E8927C"]
    static let heartGradient = ["FF6B9D", "FFA07A"]
    static let boltGradient = ["FFB347", "FFCC33"]
    static let completeGradient = ["8FBC8F", "98D98E"]
    static let intentionGradient = ["9B7EBD", "7A9CC6"]

    // MARK: - Adaptive UI Colors

    // Section backgrounds
    static let darkSectionBackground = "Opacity: 0.04"
    static let lightSectionBackground = "Opacity: 0.02"

    // Borders
    static let darkBorder = "Opacity: 0.12"
    static let lightBorder = "Opacity: 0.08"
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// TYPOGRAPHY SCALE
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct ReverieTypography {

    // Page Title
    static let pageTitle = (size: 23.0, weight: Font.Weight.bold)

    // Section Headers
    static let sectionHeader = (size: 13.0, weight: Font.Weight.semibold)

    // Card Titles
    static let cardTitle = (size: 13.0, weight: Font.Weight.medium)

    // Body Text
    static let bodyText = (size: 12.0, weight: Font.Weight.regular)

    // Small Text
    static let smallText = (size: 11.0, weight: Font.Weight.regular)

    // Caption
    static let caption = (size: 12.0, weight: Font.Weight.regular)

    // Tiny Text
    static let tinyText = (size: 11.0, weight: Font.Weight.medium)

    // Badge Text
    static let badgeText = (size: 11.0, weight: Font.Weight.medium)

    // Icon Sizes
    static let iconSmall = 11.0
    static let iconMedium = 14.0
    static let iconLarge = 18.0
    static let iconXLarge = 24.0
    static let iconHero = 32.0
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// SPACING SYSTEM
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct ReverieSpacing {

    // Main Layout
    static let containerSpacing: CGFloat = 24      // Between major sections
    static let horizontalPadding: CGFloat = 20     // Page margins
    static let topPadding: CGFloat = 20            // Top margin
    static let bottomPadding: CGFloat = 40         // Bottom margin

    // Card Spacing
    static let cardPadding: CGFloat = 20           // Inside cards
    static let cardSpacing: CGFloat = 16           // Between elements in card
    static let cardItemSpacing: CGFloat = 12       // Between card items

    // Component Spacing
    static let componentSpacing: CGFloat = 14      // Between components
    static let smallSpacing: CGFloat = 10          // Small gaps
    static let tinySpacing: CGFloat = 6            // Tiny gaps
    static let microSpacing: CGFloat = 4           // Micro gaps

    // Button Spacing
    static let buttonPaddingHorizontal: CGFloat = 16
    static let buttonPaddingVertical: CGFloat = 12
    static let buttonSpacing: CGFloat = 10         // Between buttons
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// CORNER RADIUS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct ReverieRadius {
    static let card: CGFloat = 20                  // Main cards
    static let nestedCard: CGFloat = 14            // Cards within cards
    static let button: CGFloat = 12                // Buttons
    static let input: CGFloat = 12                 // Text inputs
    static let badge: CGFloat = 100                // Capsule/pill shapes
    static let icon: CGFloat = 42                  // Icon backgrounds
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// SHADOWS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct ReverieShadows {

    // Dark Mode
    static let darkCardShadow = (
        color: "black",
        opacity: 0.3,
        radius: 8.0,
        x: 0.0,
        y: 4.0
    )

    // Light Mode
    static let lightCardShadow = (
        color: "black",
        opacity: 0.04,
        radius: 12.0,
        x: 0.0,
        y: 6.0
    )

    // Small shadows (for badges, etc.)
    static let smallShadow = (
        opacity: 0.25,
        radius: 1.0,
        y: 0.5
    )
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ANIMATIONS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct ReverieAnimations {

    // Completion Message
    static let completionDisplayDuration = 1.5
    static let habitCompletionDuration = 2.0

    // Spring Animation
    static let springResponse = 0.4
    static let springDamping = 0.7

    // Transitions
    static let fadeInOut = AnyTransition.opacity
    static let scaleAndFade = AnyTransition.scale.combined(with: .opacity)
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// BACKGROUND TEXTURE SETTINGS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct ReverieTextures {

    // Paper Texture
    static let fiberCount = 320
    static let fiberLengthRange = (min: 8.0, max: 20.0)
    static let fiberOpacityRange = (min: 0.03, max: 0.08)
    static let fiberWidthRange = (min: 0.3, max: 0.7)

    static let speckCount = 180
    static let speckSizeRange = (min: 0.5, max: 1.5)
    static let speckOpacityRange = (min: 0.04, max: 0.10)

    static let variationCount = 25
    static let variationSizeRange = (min: 20.0, max: 45.0)
    static let variationOpacityRange = (min: 0.008, max: 0.018)

    // Grain Overlay
    static let grainCount = 2500
    static let grainSizeRange = (min: 0.3, max: 0.8)
    static let grainOpacityRange = (min: 0.02, max: 0.12)

    // Overall Opacity
    static let paperTextureOpacity = 0.45
    static let grainOverlayDarkOpacity = 0.15
    static let grainOverlayLightOpacity = 0.08
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// COMPONENT SIZES
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct ReverieSizes {

    // Icons
    static let categoryIconBackground: CGFloat = 42
    static let categoryIconSize: CGFloat = 18
    static let completionCheckmark: CGFloat = 24
    static let completionCircle: CGFloat = 24

    // Buttons
    static let skipButtonSize: CGFloat = 44

    // Badges
    static let badgePaddingHorizontal: CGFloat = 10
    static let badgePaddingVertical: CGFloat = 4

    // Habit Rows
    static let habitRowPadding: CGFloat = 14
    static let habitRowInnerSpacing: CGFloat = 14
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// OPACITY VALUES
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct ReverieOpacity {

    // Section Backgrounds
    static let darkSectionBg: Double = 0.04
    static let lightSectionBg: Double = 0.02

    // Nested Elements (within cards)
    static let darkNestedBg: Double = 0.03
    static let lightNestedBg: Double = 0.015

    // Input Fields
    static let darkInputBg: Double = 0.05
    static let lightInputBg: Double = 0.03

    // Borders
    static let darkBorder: Double = 0.12
    static let lightBorder: Double = 0.08
    static let nestedBorder: Double = 0.5

    // Category Badges
    static let darkBadge: Double = 0.08
    static let lightBadge: Double = 0.05

    // Icon Backgrounds
    static let iconBackground: Double = 0.15

    // Gradient Borders
    static let gradientBorder1: Double = 0.3
    static let gradientBorder2: Double = 0.2
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// HAPTIC FEEDBACK
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct ReverieHaptics {

    static func completionFeedback() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }

    static func lightFeedback() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }

    static func mediumFeedback() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }

    static func successFeedback() {
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)
    }
    
    static func errorFeedback() {
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.error)
    }
}

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

/*

🎨 DESIGN PRINCIPLES
====================

1. CLASSY & SOPHISTICATED
   - Minimal, refined aesthetics
   - Subtle backgrounds and borders
   - Elegant gradients
   - Premium paper texture

2. ADAPTIVE & RESPONSIVE
   - Seamless dark/light mode transitions
   - Colors adapt to time of day (light mode)
   - Components change based on color scheme

3. BREATHING ROOM
   - Generous spacing
   - No cramped layouts
   - Clear visual hierarchy
   - Elements have space to breathe

4. THOUGHTFUL INTERACTIONS
   - Haptic feedback
   - Smooth animations
   - Auto-disappearing messages
   - Clear state changes

5. REVERIE WEAVER ESSENCE
   - Contemplative and mindful
   - Premium journal feel
   - Organic paper textures
   - Warm, inviting gradients

*/
