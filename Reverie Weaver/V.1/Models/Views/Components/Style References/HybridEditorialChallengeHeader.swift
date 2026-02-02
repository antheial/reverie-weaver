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
    let tagline: String = "Easy-Start Design"
    let accentColor: Color
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            // MARK: - Dateline
            Text("FEATURED CHALLENGES · \(Date().formatted(.dateTime.month(.wide).day()))")
                .font(.custom("Georgia", size: 12))
                .tracking(1.1)
                .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 6)
            
            // MARK: - Divider + Icon
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.dynamicSecondaryLabel.opacity(0.4))
                    .frame(height: 1)
                
                Spacer()
                    .frame(width: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    .frame(width: 32, height: 32)
                
                Spacer()
                    .frame(width: 40)
                
                Rectangle()
                    .fill(Color.dynamicSecondaryLabel.opacity(0.4))
                    .frame(height: 1)
            }
            .padding(.bottom, 6)
            
            // MARK: - Category Capsule
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                
                Text(categoryLabel.uppercased())
                    .font(.custom("Georgia", size: 10.5))
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
            .padding(.bottom, 7)
            
            // MARK: - Title
            Text(title)
                .font(.custom("Georgia", size: 18))
                .fontWeight(.semibold)
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
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
                .font(.custom("Georgia", size: 13))
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
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
                .font(.custom("Georgia", size: 12))
                .fontWeight(.medium)
                .tracking(0.4)
                .frame(maxWidth: .infinity, alignment: .center)
                .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
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
