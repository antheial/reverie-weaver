//
//  ReveriePalette.swift
//  Reverie Mood
//
//  Created by Antheia Li on 12/23/25.
//


import SwiftUI

// MARK: - Reverie Design System
// A vintage editorial aesthetic inspired by newspapers, tape recorders, and analog equipment

// MARK: - Color Palette

struct ReveriePalette {
    
    // MARK: - Light Mode (Morning Edition)
    
    struct Light {
        // Backgrounds
        static let background = Color(hex: "F5DFC4")      // Warmer cream (5% more warmth)
        static let surface = Color(hex: "FFF9F0")         // Warm ivory (card surfaces)
        static let surfaceElevated = Color(hex: "FDF8F3") // Paper white
        static let surfaceRecessed = Color(hex: "F2EDE6") // Inset areas
        static let warmCardSurface = Color(hex: "FDF6EC") // Subtle warm cream for interactive cards
        
        // Text Hierarchy
        static let textPrimary = Color(hex: "1C1917")     // Near black (stone-900)
        static let textSecondary = Color(hex: "57534E")   // Warm gray (stone-600)
        static let textTertiary = Color(hex: "A8A29E")    // Light gray (stone-400)
        static let textPlaceholder = Color(hex: "D6D3D1") // Placeholder (stone-300)
        
        // Primary Accent
        static let accentRed = Color(hex: "91222C")       // Vintage red (primary action)
        static let accentRedHover = Color(hex: "7F1D24")  // Darker on press
        static let accentRedLight = Color(hex: "91222C").opacity(0.12) // Subtle backgrounds
        
        // Secondary Accents
        static let accentGold = Color(hex: "D3A345")      // Mustard gold
        static let accentTeal = Color(hex: "7397A3")      // Dusty teal
        static let accentSage = Color(hex: "B6BEB1")      // Muted sage
        static let accentBrown = Color(hex: "704D3B")     // Warm chocolate
        static let accentSepia = Color(hex: "A67C52")     // Nostalgic sepia
        
        // UI Elements
        static let border = Color(hex: "E7E5E4")          // Light border (stone-200)
        static let borderStrong = Color(hex: "D6D3D1")    // Stronger border (stone-300)
        static let borderFocus = Color(hex: "91222C")     // Focus ring
        static let divider = Color(hex: "1C1917").opacity(0.08)
        
        // Semantic Colors
        static let success = Color(hex: "3D6B4F")         // Muted green
        static let warning = Color(hex: "B45309")         // Amber
        static let error = Color(hex: "91222C")           // Same as accent red
        static let info = Color(hex: "7397A3")            // Teal
        
        // Component Specific - Flip Calendar
        static let flipCardBg = Color(hex: "1C1917")      // Dark flip cards
        static let flipCardText = Color(hex: "F5F5F4")    // Light text on flip
        static let flipCardSplit = Color(hex: "000000")   // Split line
        static let flipCardShine = Color.white.opacity(0.1)
        
        // Component Specific - Tape Deck
        static let tapedeckCasing = Color(hex: "D8D4CB")  // Champagne metal outer
        static let tapedeckInner = Color(hex: "E8E6DF")   // Inner panel cream
        static let tapedeckReel = Color(hex: "DCDCDC")    // Silver reel
        static let tapedeckReelInner = Color(hex: "BFBFBF") // Reel detail
        static let tapedeckWindow = Color(hex: "C0BCB4")  // Tape window
        static let tapedeckWood = Color(hex: "5C4033")    // Wood accent strip
        static let tapedeckButton = Color(hex: "E0E0E0")  // Button surface
        static let tapedeckButtonPressed = Color(hex: "CCCCCC")
        static let tapedeckLedGreen = Color(hex: "22C55E") // LED indicator
        static let tapedeckRecordRed = Color(hex: "DC2626") // Record button
        
        // Component Specific - Affect Grid
        static let gridBackground = Color(hex: "F2F0E4")  // Warm paper
        static let gridLine = Color(hex: "1C1917").opacity(0.1)
        static let gridAxisLabel = Color(hex: "1C1917").opacity(0.6)
        
        // Component Specific - Mini Player
        static let vuMeterBg = Color(hex: "FDFBF6")       // Warm white
        static let vuNeedle = Color(hex: "91222C")        // Red needle
        static let progressTrack = Color(hex: "333333")   // Dark track
        static let progressFill = Color(hex: "91222C").opacity(0.2)
    }
    
    // MARK: - Dark Mode (Evening Edition)
    
    struct Dark {
        // Backgrounds
        static let background = Color(hex: "1C1917")      // Warm charcoal
        static let surface = Color(hex: "292524")         // Elevated surface (stone-800)
        static let surfaceElevated = Color(hex: "3D3836") // Card (stone-700 adjusted)
        static let surfaceRecessed = Color(hex: "1A1816") // Inset areas
        static let warmCardSurface = Color(hex: "1A1816") // Same as surfaceRecessed in dark mode
        
        // Text Hierarchy
        static let textPrimary = Color(hex: "F5F5F4")     // Warm white (stone-100)
        static let textSecondary = Color(hex: "A8A29E")   // Medium gray (stone-400)
        static let textTertiary = Color(hex: "78716C")    // Dim gray (stone-500)
        static let textPlaceholder = Color(hex: "57534E") // Placeholder (stone-600)
        
        // Primary Accent (brighter for dark mode contrast)
        static let accentRed = Color(hex: "DC2626")       // Brighter red
        static let accentRedHover = Color(hex: "EF4444")  // Even brighter on hover
        static let accentRedLight = Color(hex: "DC2626").opacity(0.15)
        
        // Secondary Accents (adjusted for dark - vintage, muted tones)
        static let accentGold = Color(hex: "D4A574")      // Warmer brass/sepia
        static let accentTeal = Color(hex: "7CA9A3")      // Dusty sage-teal (vintage)
        static let accentSage = Color(hex: "99A88D")      // Muted sage green
        static let accentBrown = Color(hex: "D6D3D1")     // Neutralized to light
        static let accentSepia = Color(hex: "C9A77C")     // Warmer sepia
        
        // UI Elements
        static let border = Color(hex: "3D3836")          // Dark border
        static let borderStrong = Color(hex: "57534E")    // Stronger (stone-600)
        static let borderFocus = Color(hex: "DC2626")     // Focus ring
        static let divider = Color(hex: "F5F5F4").opacity(0.08)
        
        // Semantic Colors (vintage-appropriate for dark mode)
        static let success = Color(hex: "6B9080")         // Vintage forest green
        static let warning = Color(hex: "D4A574")         // Warm brass (matches gold)
        static let error = Color(hex: "DC2626")           // Muted red (less bright)
        static let info = Color(hex: "7CA9A3")            // Dusty teal (matches accent)
        
        // Component Specific - Flip Calendar
        static let flipCardBg = Color(hex: "0C0A09")      // Deeper black
        static let flipCardText = Color(hex: "F5F5F4")    // Light text
        static let flipCardSplit = Color(hex: "000000")
        static let flipCardShine = Color.white.opacity(0.05)
        
        // Component Specific - Tape Deck
        static let tapedeckCasing = Color(hex: "3D3836")  // Dark metal outer
        static let tapedeckInner = Color(hex: "292524")   // Dark inner panel
        static let tapedeckReel = Color(hex: "57534E")    // Dark reel
        static let tapedeckReelInner = Color(hex: "44403C")
        static let tapedeckWindow = Color(hex: "1C1917")  // Dark window
        static let tapedeckWood = Color(hex: "3D2817")    // Dark wood
        static let tapedeckButton = Color(hex: "44403C")
        static let tapedeckButtonPressed = Color(hex: "57534E")
        static let tapedeckLedGreen = Color(hex: "4ADE80")
        static let tapedeckRecordRed = Color(hex: "EF4444")
        
        // Component Specific - Affect Grid
        static let gridBackground = Color(hex: "292524")
        static let gridLine = Color(hex: "F5F5F4").opacity(0.1)
        static let gridAxisLabel = Color(hex: "F5F5F4").opacity(0.5)
        
        // Component Specific - Mini Player
        static let vuMeterBg = Color(hex: "1C1917")
        static let vuNeedle = Color(hex: "EF4444")
        static let progressTrack = Color(hex: "0C0A09")
        static let progressFill = Color(hex: "DC2626").opacity(0.3)
    }
}

// MARK: - Adaptive Color Accessor

struct ReverieColors {
    
    // MARK: - Backgrounds
    
    static func background(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? ReveriePalette.Dark.background : ReveriePalette.Light.background
    }
    
    static func surface(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? ReveriePalette.Dark.surface : ReveriePalette.Light.surface
    }
    
    static func surfaceElevated(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? ReveriePalette.Dark.surfaceElevated : ReveriePalette.Light.surfaceElevated
    }
    
    static func surfaceRecessed(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? ReveriePalette.Dark.surfaceRecessed : ReveriePalette.Light.surfaceRecessed
    }

    static func warmCardSurface(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? ReveriePalette.Dark.warmCardSurface : ReveriePalette.Light.warmCardSurface
    }

    // MARK: - Text
    
    static func textPrimary(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? ReveriePalette.Dark.textPrimary : ReveriePalette.Light.textPrimary
    }
    
    static func textSecondary(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? ReveriePalette.Dark.textSecondary : ReveriePalette.Light.textSecondary
    }
    
    static func textTertiary(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? ReveriePalette.Dark.textTertiary : ReveriePalette.Light.textTertiary
    }
    
    static func textPlaceholder(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? ReveriePalette.Dark.textPlaceholder : ReveriePalette.Light.textPlaceholder
    }
    
    // MARK: - Accents
    
    static func accentRed(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? ReveriePalette.Dark.accentRed : ReveriePalette.Light.accentRed
    }
    
    static func accentRedHover(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? ReveriePalette.Dark.accentRedHover : ReveriePalette.Light.accentRedHover
    }
    
    static func accentRedLight(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? ReveriePalette.Dark.accentRedLight : ReveriePalette.Light.accentRedLight
    }
    
    static func accentGold(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? ReveriePalette.Dark.accentGold : ReveriePalette.Light.accentGold
    }
    
    static func accentTeal(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? ReveriePalette.Dark.accentTeal : ReveriePalette.Light.accentTeal
    }
    
    static func accentSage(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? ReveriePalette.Dark.accentSage : ReveriePalette.Light.accentSage
    }
    
    static func accentBrown(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? ReveriePalette.Dark.accentBrown : ReveriePalette.Light.accentBrown
    }
    
    static func accentSepia(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? ReveriePalette.Dark.accentSepia : ReveriePalette.Light.accentSepia
    }
    
    // MARK: - UI Elements
    
    static func border(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? ReveriePalette.Dark.border : ReveriePalette.Light.border
    }
    
    static func borderStrong(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? ReveriePalette.Dark.borderStrong : ReveriePalette.Light.borderStrong
    }
    
    static func borderFocus(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? ReveriePalette.Dark.borderFocus : ReveriePalette.Light.borderFocus
    }
    
    static func divider(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? ReveriePalette.Dark.divider : ReveriePalette.Light.divider
    }
    
    // MARK: - Semantic
    
    static func success(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? ReveriePalette.Dark.success : ReveriePalette.Light.success
    }
    
    static func warning(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? ReveriePalette.Dark.warning : ReveriePalette.Light.warning
    }
    
    static func error(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? ReveriePalette.Dark.error : ReveriePalette.Light.error
    }
    
    static func info(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? ReveriePalette.Dark.info : ReveriePalette.Light.info
    }
    
    // MARK: - Flip Calendar
    
    static func flipCardBg(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? ReveriePalette.Dark.flipCardBg : ReveriePalette.Light.flipCardBg
    }
    
    static func flipCardText(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? ReveriePalette.Dark.flipCardText : ReveriePalette.Light.flipCardText
    }
    
    static func flipCardShine(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? ReveriePalette.Dark.flipCardShine : ReveriePalette.Light.flipCardShine
    }
    
    // MARK: - Tape Deck
    
    static func tapedeckCasing(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? ReveriePalette.Dark.tapedeckCasing : ReveriePalette.Light.tapedeckCasing
    }
    
    static func tapedeckInner(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? ReveriePalette.Dark.tapedeckInner : ReveriePalette.Light.tapedeckInner
    }
    
    static func tapedeckReel(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? ReveriePalette.Dark.tapedeckReel : ReveriePalette.Light.tapedeckReel
    }
    
    static func tapedeckWindow(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? ReveriePalette.Dark.tapedeckWindow : ReveriePalette.Light.tapedeckWindow
    }
    
    static func tapedeckWood(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? ReveriePalette.Dark.tapedeckWood : ReveriePalette.Light.tapedeckWood
    }
    
    static func tapedeckButton(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? ReveriePalette.Dark.tapedeckButton : ReveriePalette.Light.tapedeckButton
    }
    
    static func tapedeckRecordRed(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? ReveriePalette.Dark.tapedeckRecordRed : ReveriePalette.Light.tapedeckRecordRed
    }
    
    // MARK: - Affect Grid
    
    static func gridBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? ReveriePalette.Dark.gridBackground : ReveriePalette.Light.gridBackground
    }
    
    static func gridLine(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? ReveriePalette.Dark.gridLine : ReveriePalette.Light.gridLine
    }
    
    static func gridAxisLabel(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? ReveriePalette.Dark.gridAxisLabel : ReveriePalette.Light.gridAxisLabel
    }
    
    // MARK: - Mini Player
    
    static func vuMeterBg(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? ReveriePalette.Dark.vuMeterBg : ReveriePalette.Light.vuMeterBg
    }
    
    static func vuNeedle(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? ReveriePalette.Dark.vuNeedle : ReveriePalette.Light.vuNeedle
    }
    
    static func progressTrack(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? ReveriePalette.Dark.progressTrack : ReveriePalette.Light.progressTrack
    }
    
    static func progressFill(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? ReveriePalette.Dark.progressFill : ReveriePalette.Light.progressFill
    }
}

// MARK: - Environment-Based Color Wrapper

/// A property wrapper that automatically resolves colors based on color scheme
/// Usage: @ReverieColor(\.textPrimary) var textColor
@propertyWrapper
struct ReverieColor: DynamicProperty {
    @Environment(\.colorScheme) private var colorScheme
    private let resolver: (ColorScheme) -> Color
    
    init(_ keyPath: KeyPath<ReverieColorResolver, (ColorScheme) -> Color>) {
        self.resolver = ReverieColorResolver()[keyPath: keyPath]
    }
    
    var wrappedValue: Color {
        resolver(colorScheme)
    }
}

@MainActor
struct ReverieColorResolver {
    let textPrimary: (ColorScheme) -> Color = ReverieColors.textPrimary
    let textSecondary: (ColorScheme) -> Color = ReverieColors.textSecondary
    let background: (ColorScheme) -> Color = ReverieColors.background
    let surface: (ColorScheme) -> Color = ReverieColors.surface
    let accentRed: (ColorScheme) -> Color = ReverieColors.accentRed
}
