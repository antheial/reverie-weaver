//
// FloatingAddButton.swift
// ReverieWeaver
//
//

import SwiftUI

struct FloatingAddButton: View {
    @Binding var isExpanded: Bool
    let onQuickAdd: () -> Void
    let onBrowseLibrary: () -> Void
    let onExpandToggle: () -> Void  // New callback for expansion state changes
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 14) {
            // Expanded options
            if isExpanded {
                // 1. Browse Library
                OptionButton(
                    icon: "books.vertical.fill",
                    label: "Browse Library",
                    delay: 0.05,
                    action: onBrowseLibrary
                )
                
                // 2. Create Custom (Renamed from Quick Add for clarity)
                OptionButton(
                    icon: "plus.circle.fill",
                    label: "Create New",
                    delay: 0.0,
                    action: onQuickAdd
                )
            }
            
            // Main FAB
            Button {
                // Haptic feedback on toggle
                ReverieHaptics.lightFeedback()
                
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
                
                // Notify parent about expansion state change
                onExpandToggle()
            } label: {
                ZStack {
                    // Subtle glow in background
                    Circle()
                        .fill(Color.sageGreen.opacity(0.3))
                        .frame(width: 54, height: 54)
                        .blur(radius: 4)
                    
                    // Main circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.sageGreen, Color.dustyBlue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                        .shadow(color: Color.shadowColor.opacity(0.3), radius: 4, y: 3)
                        .overlay(
                            Circle()
                                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                        .rotationEffect(.degrees(isExpanded ? 135 : 0))
                }
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }
}

// MARK: - Sub-Button Component

private struct OptionButton: View {
    let icon: String
    let label: String
    let delay: Double
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button {
            // Haptic feedback on option tap
            ReverieHaptics.lightFeedback()
            action()
        } label: {
            HStack(spacing: 12) {
                Text(label)
                    .font(.system(size: 14, weight: .semibold))
                    .fontDesign(.serif)
                    .foregroundStyle(Color.dynamicLabel)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(Color.dynamicLabel)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Color.black.opacity(0.1), radius: 4, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Color.white.opacity(0.4), lineWidth: 0.5)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .transition(
            .asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.8)),
                removal: .opacity.combined(with: .scale(scale: 0.6))
            )
        )
    }
}

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
