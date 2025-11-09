//
//  HybridEditorialChallengeHeader.swift (INK-NEWSPAPER STYLE)
//  Reverie Weaver
//

import SwiftUI

// ================================================================
// HYBRID EDITORIAL CHALLENGE HEADER – INK-NEWSPAPER STYLE
// ================================================================

struct HybridEditorialChallengeHeader: View {
    let icon: String
    let title: String
    let categoryLabel: String
    let subtitle: String
    let tagline: String = "ADHD & Procrastinator-Friendly"
    let accentColor: Color
    
    @Environment(\.colorScheme) private var colorScheme
    
    // Richer neutral ink tone for headlines
    private var inkColor: Color {
        Color(.sRGB, white: colorScheme == .dark ? 0.85 : 0.15, opacity: 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            // MARK: - Dateline
            Text("FEATURED CHALLENGES · \(Date().formatted(.dateTime.month(.wide).day()))")
                .font(.custom("Georgia", size: 11))
                .tracking(1.1)
                .foregroundStyle(inkColor.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 6)
            
            // MARK: - Divider + Icon
            HStack(spacing: 0) {
                Rectangle()
                    .fill(inkColor.opacity(0.4))
                    .frame(width: 40, height: 1)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(inkColor)
                    .frame(width: 32, height: 32)
                
                Rectangle()
                    .fill(inkColor.opacity(0.4))
                    .frame(height: 1)
            }
            .padding(.bottom, 6)
            
            // MARK: - Category Capsule
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(inkColor.opacity(0.8))
                
                Text(categoryLabel.uppercased())
                    .font(.custom("Georgia", size: 10))
                    .tracking(1.0)
                    .foregroundStyle(inkColor.opacity(0.7))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(inkColor.opacity(colorScheme == .dark ? 0.08 : 0.05))
            )
            .overlay(
                Capsule()
                    .strokeBorder(inkColor.opacity(colorScheme == .dark ? 0.2 : 0.15), lineWidth: 0.5)
            )
            .padding(.bottom, 7)
            
            // MARK: - Title
            Text(title)
                .font(.custom("Georgia", size: 18))
                .fontWeight(.semibold)
                .foregroundStyle(inkColor)
                .tracking(0.5)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 5)
                .overlay(
                    NoiseOverlayView()
                        .opacity(0.05)
                        .blendMode(.multiply)
                        .allowsHitTesting(false)
                )
            
            // MARK: - Subtitle
            Text(subtitle)
                .font(.custom("Georgia", size: 12))
                .foregroundStyle(inkColor.opacity(0.85))
                .tracking(0.3)
                .lineSpacing(2)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 6)
                .overlay(
                    NoiseOverlayView()
                        .opacity(0.05)
                        .blendMode(.multiply)
                        .allowsHitTesting(false)
                )
            
            // MARK: - Tagline
            Text(tagline)
                .font(.custom("Georgia", size: 11))
                .fontWeight(.medium)
                .tracking(0.4)
                .frame(maxWidth: .infinity, alignment: .center)
                .foregroundStyle(inkColor.opacity(0.75))
                .overlay(
                    NoiseOverlayView()
                        .opacity(0.05)
                        .blendMode(.multiply)
                        .allowsHitTesting(false)
                )
        }
    }
}

// ================================================================
// PREVIEW (Light Mode)
// ================================================================

#Preview("Light Mode") {
    ZStack {
        ReverieWeaverBackground()
        HybridEditorialChallengeHeader(
            icon: "bolt.fill",
            title: "7-Day Mini Challenges",
            categoryLabel: "Small Sprints",
            subtitle: "Small sprints. Big clarity.",
            accentColor: Color(hex: "FFD18B")
        )
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }
    .preferredColorScheme(.light)
}
