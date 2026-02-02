//
//  StatCard.swift
//  Reverie Weaver
//
//  Created by Antheia Li on 10/25/25.
//
// Reusable stat card component for displaying metrics
// Used in ProfileView and other stat displays
//

import SwiftUI

struct StatCard: View {
    let value: String
    let label: String
    let color: Color
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .fontDesign(.serif)
                .foregroundStyle(color)
            
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(colorScheme == .dark ? 0.12 : 0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    color.opacity(colorScheme == .dark ? 0.25 : 0.15),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 12) {
        StatCard(
            value: "42",
            label: "Day Streak",
            color: .sageGreen
        )
        
        StatCard(
            value: "156",
            label: "Total Completions",
            color: .dustyBlue
        )
        
        StatCard(
            value: "12",
            label: "Achievements",
            color: .terracottaRose
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
