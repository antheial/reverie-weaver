//
// QuickActionPromptSheet.swift
// ReverieWeaver
//
// Celebratory sheet when user completes quick action 3 times
//

import SwiftUI

struct QuickActionPromptSheet: View {
    let microHabit: MicroHabit
    let onAddHabit: () -> Void
    let onDismiss: () -> Void
    
    @StateObject private var localization = LocalizationManager.shared
    @State private var showConfetti = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Celebration Header
                VStack(spacing: 20) {
                    // Confetti animation
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        microHabit.category.color.opacity(0.3),
                                        microHabit.category.color.opacity(0.1),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 60
                                )
                            )
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "star.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [microHabit.category.color, microHabit.category.color.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .rotationEffect(.degrees(showConfetti ? 360 : 0))
                            .scaleEffect(showConfetti ? 1.0 : 0.5)
                    }
                    .padding(.top, 32)
                    
                    VStack(spacing: 12) {
                        Text(localization.localize("quickAction.congratulations"))
                            .font(.system(size: 24, weight: .bold))
                            .fontDesign(.serif)
                            .foregroundStyle(Color.dynamicLabel)
                        
                        Text(localization.localize("quickAction.readyToAdd"))
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(Color.dynamicSecondaryLabel)
                            .multilineTextAlignment(.center)
                        
                        // Quick Action info
                        VStack(spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: microHabit.category.icon)
                                    .font(.system(size: 14))
                                    .foregroundStyle(microHabit.category.color)
                                
                                Text(microHabit.title)
                                    .font(.system(size: 15, weight: .medium))
                                    .fontDesign(.serif)
                                    .foregroundStyle(Color.dynamicLabel)
                            }
                            
                            // Progress dots
                            HStack(spacing: 6) {
                                ForEach(0..<3, id: \.self) { _ in
                                    Circle()
                                        .fill(microHabit.category.color)
                                        .frame(width: 8, height: 8)
                                }
                                
                                Text("3/3 " + localization.localize("quickAction.completions"))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(microHabit.category.color)
                            }
                        }
                        .padding(16)
                        .background(microHabit.category.color.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 24)
                    
                    Text(localization.localize("quickAction.suggestHabit"))
                        .font(.system(size: 14, weight: .regular))
                        .fontDesign(.serif)
                        .foregroundStyle(Color.dynamicSecondaryLabel)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.bottom, 32)
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button {
                        onAddHabit()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18))
                            Text(localization.localize("quickAction.addHabit"))
                                .font(.system(size: 16, weight: .semibold))
                                .fontDesign(.serif)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(microHabit.category.color)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        onDismiss()
                    } label: {
                        Text(localization.localize("quickAction.maybeLater"))
                            .font(.system(size: 15, weight: .medium))
                            .fontDesign(.serif)
                            .foregroundStyle(Color.dynamicSecondaryLabel)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.dynamicSecondaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .background(Color.dynamicBackground)
            
            // Confetti overlay
            ConfettiView(isActive: $showConfetti)
        }
        .presentationDetents([.height(520)])
        .presentationDragIndicator(.visible)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showConfetti = true
            }
            
            // Haptic feedback
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)
            
            // Stop confetti after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                showConfetti = false
            }
        }
    }
}
