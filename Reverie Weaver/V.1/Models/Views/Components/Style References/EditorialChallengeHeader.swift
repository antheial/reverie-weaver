//
//  EditorialChallengeHeader.swift (INK-NEWSPAPER STYLE)
//  Reverie Weaver
//

import SwiftUI

// ================================================================
// OPEN EDITORIAL SECTION – INK-NEWSPAPER STYLE
// ================================================================

struct OpenEditorialSection: View {
    let icon: String
    let iconColor: Color
    let title: String
    let content: String
    
    @Environment(\.colorScheme) private var colorScheme
    
    // Slightly lighter neutral ink tone for body text
    private var inkColor: Color {
        Color(.sRGB, white: colorScheme == .dark ? 0.9 : 0.2, opacity: 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            // MARK: - Divider + Icon
            HStack(spacing: 0) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(inkColor)
                    .frame(width: 32, height: 32)
                
                Rectangle()
                    .fill(inkColor.opacity(0.3))
                    .frame(height: 1)
            }
            .padding(.bottom, 5)
            
            // MARK: - Title
            Text(title)
                .font(.custom("Georgia", size: 14))
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
            
            // MARK: - Content
            Text(content)
                .font(.custom("Georgia", size: 12))
                .foregroundStyle(inkColor.opacity(0.9))
                .tracking(0.2)
                .lineSpacing(5)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
                .fixedSize(horizontal: false, vertical: true)
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
        VStack(spacing: 20) {
            OpenEditorialSection(
                icon: "star.fill",
                iconColor: Color(hex: "FFD18B"),
                title: "The Philosophy",
                content: "These editorial sections are designed to provide gentle guidance and structured reflection — with the tone of printed ink and the warmth of thoughtful journaling."
            )
            .padding(.horizontal, 24)
        }
    }
    .preferredColorScheme(.light)
}
