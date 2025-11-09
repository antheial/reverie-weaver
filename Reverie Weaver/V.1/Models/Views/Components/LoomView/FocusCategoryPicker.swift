//
//  FocusCategoryPicker.swift
//  Reverie Weaver
//
//  Enhanced to match app's glassmorphic aesthetic
//

import SwiftUI

struct FocusCategoryPicker: View {
    @Bindable var timerManager: PomodoroTimerManager
    let onStart: () -> Void
    let onCancel: () -> Void
    
    @State private var appeared = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with subtle gradient
            VStack(spacing: 10) {
                // Decorative top element
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.dynamicSecondaryLabel.opacity(0.3))
                    .frame(width: 40, height: 4)
                    .padding(.top, 12)
                
                VStack(spacing: 6) {
                    Text("What are you focusing on?")
                        .font(.system(size: 19, weight: .semibold))
                        .fontDesign(.serif)
                        .foregroundStyle(Color.dynamicLabel)
                    
                    Text("Help track where your energy flows")
                        .font(.system(size: 13, weight: .regular))
                        .fontDesign(.serif)
                        .foregroundStyle(Color.dynamicSecondaryLabel)
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Category options with glassmorphic design
                    VStack(spacing: 10) {
                        ForEach(FocusCategory.allCases.filter { $0 != .uncategorized }, id: \.self) { category in
                            Button {
                                // Haptic feedback
                                let impact = UIImpactFeedbackGenerator(style: .light)
                                impact.impactOccurred()
                                
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    timerManager.selectedCategory = category
                                }
                            } label: {
                                HStack(spacing: 14) {
                                    // Glossy icon background
                                    ZStack {
                                        // Outer glow
                                        Circle()
                                            .fill(
                                                RadialGradient(
                                                    colors: [
                                                        category.color.opacity(0.25),
                                                        category.color.opacity(0.1),
                                                        category.color.opacity(0.0)
                                                    ],
                                                    center: .center,
                                                    startRadius: 10,
                                                    endRadius: 24
                                                )
                                            )
                                            .frame(width: 48, height: 48)
                                        
                                        // Icon circle
                                        Circle()
                                            .fill(category.color.opacity(0.15))
                                            .frame(width: 42, height: 42)
                                            .overlay(
                                                Circle()
                                                    .strokeBorder(
                                                        LinearGradient(
                                                            colors: [
                                                                Color.white.opacity(0.3),
                                                                Color.white.opacity(0.1)
                                                            ],
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        ),
                                                        lineWidth: 1
                                                    )
                                            )
                                        
                                        Image(systemName: category.icon)
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundStyle(category.color)
                                    }
                                    
                                    // Text content
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(category.rawValue)
                                            .font(.system(size: 15, weight: .medium))
                                            .fontDesign(.serif)
                                            .foregroundStyle(Color.dynamicLabel)
                                        
                                        Text(category.description)
                                            .font(.system(size: 12, weight: .regular))
                                            .fontDesign(.serif)
                                            .foregroundStyle(Color.dynamicSecondaryLabel)
                                            .lineLimit(1)
                                    }
                                    
                                    Spacer()
                                    
                                    // Selection indicator with animation
                                    ZStack {
                                        if timerManager.selectedCategory == category {
                                            Circle()
                                                .fill(category.color.opacity(0.15))
                                                .frame(width: 28, height: 28)
                                                .transition(.scale.combined(with: .opacity))
                                            
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 24))
                                                .foregroundStyle(category.color)
                                                .transition(.scale.combined(with: .opacity))
                                        } else {
                                            Circle()
                                                .strokeBorder(Color.dynamicSecondaryLabel.opacity(0.25), lineWidth: 2)
                                                .frame(width: 24, height: 24)
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.ultraThinMaterial)
                                        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .strokeBorder(
                                                    timerManager.selectedCategory == category
                                                        ? LinearGradient(
                                                            colors: [
                                                                category.color.opacity(0.5),
                                                                category.color.opacity(0.3)
                                                            ],
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        )
                                                        : LinearGradient(
                                                            colors: [
                                                                Color.white.opacity(0.3),
                                                                Color.white.opacity(0.1)
                                                            ],
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        ),
                                                    lineWidth: 1.5
                                                )
                                        )
                                )
                                .scaleEffect(timerManager.selectedCategory == category ? 1.0 : 0.98)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Optional note with glassmorphic styling
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 6) {
                            Image(systemName: "note.text")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Color.dynamicSecondaryLabel)
                            
                            Text("Note (optional)")
                                .font(.system(size: 13, weight: .medium))
                                .fontDesign(.serif)
                                .foregroundStyle(Color.dynamicLabel)
                        }
                        
                        TextField("What will you work on?", text: $timerManager.sessionNote, axis: .vertical)
                            .font(.system(size: 14, weight: .regular))
                            .fontDesign(.serif)
                            .foregroundStyle(Color.dynamicLabel)
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(.ultraThinMaterial)
                                    .shadow(color: Color.black.opacity(0.03), radius: 4, y: 2)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .strokeBorder(
                                                LinearGradient(
                                                    colors: [
                                                        Color.white.opacity(0.2),
                                                        Color.white.opacity(0.1)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                            )
                            .lineLimit(2...4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
                .padding(.bottom, 20)
            }
            
            // Action buttons with enhanced styling
            HStack(spacing: 12) {
                // Cancel - LEFT SIDE
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    onCancel()
                } label: {
                    Text("Cancel")
                        .font(.system(size: 13, weight: .medium))
                        .fontDesign(.serif)
                        .foregroundStyle(Color.dynamicSecondaryLabel)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white.opacity(0.5))
                                .shadow(color: Color.black.opacity(0.06), radius: 8, y: 4)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                // Start Focus - RIGHT SIDE
                Button {
                    let impact = UINotificationFeedbackGenerator()
                    impact.notificationOccurred(.success)
                    onStart()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 14))
                        
                        Text("Start")
                            .font(.system(size: 13, weight: .medium))
                            .fontDesign(.serif)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        timerManager.selectedCategory.color,
                                        timerManager.selectedCategory.color.opacity(0.85)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: timerManager.selectedCategory.color.opacity(0.4), radius: 12, y: 6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.4),
                                                Color.white.opacity(0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.5
                                    )
                            )
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .background(
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .shadow(color: Color.black.opacity(0.1), radius: 20, y: -10)
            )
        }
        .background(Color.clear)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }
}

#Preview {
    FocusCategoryPicker(
        timerManager: PomodoroTimerManager(),
        onStart: { print("Start") },
        onCancel: { print("Cancel") }
    )
    .presentationDetents([.medium, .large])
}
