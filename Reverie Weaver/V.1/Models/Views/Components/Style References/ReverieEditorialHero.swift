//
//  ReverieEditorialHero.swift
//  Reverie Weaver
//
//  A reusable hero section component that combines vintage newspaper
//  editorial aesthetics with soft, dreamy atmospheric elements.
//

import SwiftUI


struct ReverieEditorialHero: View {
    // Required parameters
    let icon: String
    let title: String
    let badgeText: String
    let tagline: String
    let description: String
    let accentColorHex: String
    
    var showDateline: Bool = true
    var datelinePrefix: String = "FEATURED PROGRAM"
    var iconSize: CGFloat = 42
    
    // Optional tier badge
    var tierBadge: (icon: String, text: String, colorHex: String)? = nil
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            
            // MARK: - Optional Dateline
            if showDateline {
                Text("\(datelinePrefix) · \(Date().formatted(.dateTime.month(.wide).day()))")
                    .font(.custom("Georgia", size: 11))
                    .tracking(1.1)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 8)
            }
            
            // MARK: - Simple Divider
            Rectangle()
                .fill(Color.dynamicSecondaryLabel.opacity(0.4))
                .frame(height: 1)
                .padding(.bottom, 7)
            
            // MARK: - Category Badge + Tier Badge (below divider)
            HStack(spacing: 8) {
                // Left: Duration badge
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .medium))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    
                    Text(badgeText.uppercased())
                        .font(.custom("Georgia", size: 11))
                        .tracking(1.0)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(Color.dynamicSecondaryLabel.opacity(colorScheme == .dark ? 0.08 : 0.05))
                )
                .overlay(
                    Capsule()
                        .strokeBorder(Color.dynamicSecondaryLabel.opacity(colorScheme == .dark ? 0.2 : 0.15), lineWidth: 0.5)
                )
                
                // Right: Tier badge (optional)
                if let tier = tierBadge {
                    HStack(spacing: 6) {
                        Image(systemName: tier.icon)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color(hex: tier.colorHex))
                        
                        Text(tier.text.uppercased())
                            .font(.custom("Georgia", size: 11))
                            .tracking(1.0)
                            .foregroundStyle(Color(hex: tier.colorHex))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(Color(hex: tier.colorHex).opacity(colorScheme == .dark ? 0.15 : 0.10))
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(Color(hex: tier.colorHex).opacity(0.3), lineWidth: 0.5)
                    )
                }
                
                Spacer()
            }
            .padding(.bottom, 16)
            
            // MARK: - Title + Orb (Orb on right of title)
            HStack(spacing: 12) {
                // Title
                Text(title)
                    .font(.system(size: 23, weight: .bold))
                    .fontDesign(.serif)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    .multilineTextAlignment(.center)
                    .overlay(
                        NoiseOverlayView()
                            .opacity(0.06)
                            .blendMode(.multiply)
                            .allowsHitTesting(false)
                    )
                
                // Icon with Dreamy Glow
                ZStack {
                    // Soft atmospheric glow (outermost)
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(hex: accentColorHex).opacity(0.12),
                                    Color(hex: accentColorHex).opacity(0.04),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 40
                            )
                        )
                        .frame(width: 80, height: 80)
                        .blur(radius: 12)
                    
                    // Middle halo (like light through frosted glass)
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(colorScheme == .dark ? 0.08 : 0.15),
                                    Color(hex: accentColorHex).opacity(0.08),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 30
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    // Inner circle with delicate border
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(hex: accentColorHex).opacity(colorScheme == .dark ? 0.15 : 0.08),
                                    Color(hex: accentColorHex).opacity(0.03)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 25
                            )
                        )
                        .frame(width: 50, height: 50)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    Color(hex: accentColorHex).opacity(0.3),
                                    lineWidth: 1.5
                                )
                        )
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    Color.white.opacity(colorScheme == .dark ? 0.1 : 0.3),
                                    lineWidth: 0.5
                                )
                                .padding(2)
                        )
                    
                    // Icon with noise texture
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(Color(hex: accentColorHex).opacity(0.9))
                        .overlay(
                            NoiseOverlayView()
                                .opacity(0.08)
                                .blendMode(.overlay)
                                .allowsHitTesting(false)
                        )
                }
                .frame(width: 50, height: 50)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 8)
            
            // MARK: - Tagline (Keeping previous font size)
            Text(tagline)
                .font(.system(size: 13, weight: .medium))
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                .multilineTextAlignment(.center)
                .overlay(
                    NoiseOverlayView()
                        .opacity(0.05)
                        .blendMode(.multiply)
                        .allowsHitTesting(false)
                )
                .padding(.bottom, 6)
            
            // MARK: - Description (Keeping previous font size)
            Text(description)
                .font(.system(size: 12, weight: .regular))
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                .lineSpacing(2)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .overlay(
                    NoiseOverlayView()
                        .opacity(0.05)
                        .blendMode(.multiply)
                        .allowsHitTesting(false)
                )
                .padding(.horizontal, 32)
        }
        .padding(.top, 16)
    }
}

extension ReverieEditorialHero {
    /// Simplified initializer for 7-Day Challenges with Tier Badge
    init(
        icon: String,
        title: String,
        tagline: String,
        description: String,
        accentColorHex: String,
        tier: ChallengeTier? = nil,
        iconSize: CGFloat = 42
    ) {
        self.icon = icon
        self.title = title
        self.badgeText = "7-Day Challenge"
        self.tagline = tagline
        self.description = description
        self.accentColorHex = accentColorHex
        self.showDateline = true
        self.datelinePrefix = "FEATURED CHALLENGE"
        self.iconSize = iconSize
        
        // Convert tier to badge tuple
        if let tier = tier {
            self.tierBadge = (
                icon: tier.icon,
                text: tier.rawValue,
                colorHex: tier.color
            )
        } else {
            self.tierBadge = nil
        }
    }
    
    /// Custom initializer for Project 50 or other programs
    init(
        icon: String,
        title: String,
        badgeText: String,
        tagline: String,
        description: String,
        accentColorHex: String,
        datelinePrefix: String = "FEATURED PROGRAM",
        showDateline: Bool = true,
        iconSize: CGFloat = 42,
        tierBadge: (icon: String, text: String, colorHex: String)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.badgeText = badgeText
        self.tagline = tagline
        self.description = description
        self.accentColorHex = accentColorHex
        self.showDateline = showDateline
        self.datelinePrefix = datelinePrefix
        self.iconSize = iconSize
        self.tierBadge = tierBadge
    }
}

#Preview("Light Mode - 7-Day Challenge") {
    ScrollView {
        ZStack {
            ReverieWeaverBackground()
            
            VStack(spacing: 32) {
                ReverieEditorialHero(
                    icon: "bolt.fill",
                    title: "Focus Flow",
                    tagline: "Work with your brain, not against it",
                    description: "Train your attention in short, flexible bursts. Perfect for variable focus patterns.",
                    accentColorHex: "B8A4D5",
                    tier: .core
                )
                
                ReverieEditorialHero(
                    icon: "moon.stars.fill",
                    title: "Evening Ritual",
                    tagline: "Wind down with intention",
                    description: "Create a peaceful transition from day to night with gentle, restorative practices.",
                    accentColorHex: "A8B5C9",
                    tier: .foundation
                )
            }
            .padding(.horizontal, 24)
        }
    }
    .preferredColorScheme(.light)
}

#Preview("Dark Mode - 7-Day Challenge") {
    ScrollView {
        ZStack {
            ReverieWeaverBackground()
            
            VStack(spacing: 32) {
                ReverieEditorialHero(
                    icon: "bolt.fill",
                    title: "Focus Flow",
                    tagline: "Work with your brain, not against it",
                    description: "Train your attention in short, flexible bursts. Perfect for variable focus patterns.",
                    accentColorHex: "B8A4D5",
                    tier: .specialized
                )
                
                ReverieEditorialHero(
                    icon: "sparkles",
                    title: "Creative Spark",
                    tagline: "Nurture your creative spirit",
                    description: "Small daily practices to unlock your creative potential without pressure or judgment.",
                    accentColorHex: "E8B4A8",
                    tier: .program
                )
            }
            .padding(.horizontal, 24)
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Custom Badge - Project 50") {
    ScrollView {
        ZStack {
            ReverieWeaverBackground()
            
            ReverieEditorialHero(
                icon: "star.fill",
                title: "Morning Pages",
                badgeText: "Foundation · Project 50",
                tagline: "Write yourself clear",
                description: "Three pages of stream-of-consciousness writing to clear mental clutter and unlock clarity.",
                accentColorHex: "FFD18B",
                datelinePrefix: "PROJECT 50 FOUNDATION",
                showDateline: true,
                iconSize: 44
            )
            .padding(.horizontal, 24)
        }
    }
    .preferredColorScheme(.light)
}
