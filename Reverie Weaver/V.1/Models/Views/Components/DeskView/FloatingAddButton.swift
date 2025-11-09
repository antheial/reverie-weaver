//
// FloatingAddButton.swift
// ReverieWeaver
//
// Updated to match app aesthetic with glassmorphic design

import SwiftUI

struct FloatingAddButton: View {
    @Binding var isExpanded: Bool
    let onQuickAdd: () -> Void
    let onBrowseLibrary: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 12) {
            // Expanded options - matching app aesthetic
            if isExpanded {
                // Browse Library Button
                Button(action: onBrowseLibrary) {
                    HStack(spacing: 8) {
                        Image(systemName: "books.vertical.fill")
                            .font(.system(size: 15))
                        Text("Browse Library")
                            .font(.system(size: 13, weight: .medium))
                            .fontDesign(.serif)
                    }
                    .foregroundStyle(Color.dynamicLabel)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.5))
                            .shadow(color: Color.shadowColor, radius: 6, y: 2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.white.opacity(0.4), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
                
                // Quick Add Button
                Button(action: onQuickAdd) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 15))
                        Text("Quick Add")
                            .font(.system(size: 13, weight: .medium))
                            .fontDesign(.serif)
                    }
                    .foregroundStyle(Color.dynamicLabel)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.5))
                            .shadow(color: Color.shadowColor, radius: 6, y: 2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.white.opacity(0.4), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
            
            // Main FAB button - matching app colors
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            } label: {
                Image(systemName: isExpanded ? "xmark" : "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.sageGreen, Color.dustyBlue.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color.shadowColor, radius: 6, y: 2)
                    )
                    .rotationEffect(.degrees(isExpanded ? 45 : 0))
            }
            .buttonStyle(.plain)
        }
    }
}
