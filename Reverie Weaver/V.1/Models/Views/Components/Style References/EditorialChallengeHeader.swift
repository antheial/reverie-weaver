//
//  EditorialChallengeHeader.swift (INK-NEWSPAPER STYLE)
//  Reverie Weaver
//

import SwiftUI

struct OpenEditorialSection: View {
    let icon: String
    let iconColor: Color
    let title: String
    let content: String
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            // MARK: - Divider + Icon
            HStack(spacing: 0) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    .frame(width: 32, height: 32)
                
                Rectangle()
                    .fill(Color.dynamicSecondaryLabel.opacity(0.3))
                    .frame(height: 1)
            }
            .padding(.bottom, 5)
            
            // MARK: - Title
            Text(title)
                .font(.custom("Georgia", size: 14))
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
            
            // MARK: - Content
            Text(content)
                .font(.custom("Georgia", size: 13))
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
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
