//
// HybridCompletionToast.swift
// ReverieWeaver
//
// Hybrid toast: Clear messaging + Reverie aesthetic + Auto-dismiss
// ✅ Uses SF Symbols for consistency
// ✅ No progress bar (clean & minimal)
// ✅ Matches app's design language
//

import SwiftUI

struct HybridCompletionToast: View {
    let sessionType: TimerState  // ✅ FIXED: Removed PomodoroTimerManager. prefix
    let sessionCount: Int
    let onStartBreak: () -> Void
    let onDismiss: () -> Void
    
    @State private var offset: CGFloat = -200
    @State private var opacity: Double = 0
    
    var body: some View {
        VStack {
            // Toast card at top
            VStack(spacing: 0) {
                // Main content
                HStack(spacing: 14) {
                    // Icon with subtle animation
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        iconColor.opacity(0.2),
                                        iconColor.opacity(0.1),
                                        iconColor.opacity(0.05)
                                    ],
                                    center: .center,
                                    startRadius: 10,
                                    endRadius: 22
                                )
                            )
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: iconSymbol)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(iconColor)
                    }
                    
                    // Text content
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 15, weight: .semibold))
                            .fontDesign(.serif)
                            .foregroundStyle(Color.dynamicLabel)
                        
                        Text(subtitle)
                            .font(.system(size: 13, weight: .regular))
                            .fontDesign(.serif)
                            .foregroundStyle(Color.dynamicSecondaryLabel)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    // Close button
                    Button(action: dismissToast) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Color.dynamicSecondaryLabel.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                
                // Action buttons (only for work session completion)
                if sessionType == .running {
                    Divider()
                        .opacity(0.2)
                    
                    HStack(spacing: 0) {
                        Button(action: dismissToast) {
                            Text("Later")
                                .font(.system(size: 14, weight: .medium))
                                .fontDesign(.serif)
                                .foregroundStyle(Color.dynamicSecondaryLabel)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .buttonStyle(.plain)
                        
                        Divider()
                            .frame(height: 40)
                            .opacity(0.2)
                        
                        Button(action: {
                            onStartBreak()
                        }) {
                            HStack(spacing: 7) {
                                Image(systemName: sessionCount % 4 == 0 ? "moon.stars.fill" : "cup.and.saucer.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                
                                Text(sessionCount % 4 == 0 ? "Long Break" : "Short Break")
                                    .font(.system(size: 14, weight: .semibold))
                                    .fontDesign(.serif)
                            }
                            .foregroundStyle(iconColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(.ultraThinMaterial)
                    .shadow(color: Color.black.opacity(0.12), radius: 24, y: 12)
                    .shadow(color: iconColor.opacity(0.15), radius: 12, y: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.6),
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .padding(.horizontal, 16)
            .padding(.top, 60) // Below status bar
            .offset(y: offset)
            .opacity(opacity)
            
            Spacer()
        }
        .onAppear {
            // Slide in from top
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                offset = 0
                opacity = 1
            }
            
            // Auto-dismiss after 6 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                dismissToast()
            }
        }
    }
    
    private func dismissToast() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            offset = -200
            opacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            onDismiss()
        }
    }
    
    // MARK: - Computed Properties
    
    private var iconColor: Color {
        switch sessionType {
        case .running:
            return Color.sageGreen
        case .shortBreak:
            return Color.dustyBlue
        case .longBreak:
            return Color.paleMauve
        default:
            return Color.sageGreen
        }
    }
    
    private var iconSymbol: String {
        switch sessionType {
        case .running:
            return "checkmark.circle.fill"
        case .shortBreak:
            return "cup.and.saucer.fill"
        case .longBreak:
            return "moon.stars.fill"
        default:
            return "checkmark.circle.fill"
        }
    }
    
    private var title: String {
        switch sessionType {
        case .running:
            return "Focus Session Complete"
        case .shortBreak:
            return "Break Complete"
        case .longBreak:
            return "Long Break Complete"
        default:
            return "Session Complete"
        }
    }
    
    private var subtitle: String {
        switch sessionType {
        case .running:
            let isLongBreak = sessionCount % 4 == 0
            return isLongBreak
                ? "Well done. Time for a 15-minute rest."
                : "Great work. Take a 5-minute break."
        case .shortBreak:
            return "Refreshed? Ready to continue weaving."
        case .longBreak:
            return "Well rested. Begin your next cycle."
        default:
            return "Well done."
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.gray.opacity(0.2).ignoresSafeArea()
        
        HybridCompletionToast(
            sessionType: .running,
            sessionCount: 3,
            onStartBreak: {
                print("Start break tapped")
            },
            onDismiss: {
                print("Dismiss tapped")
            }
        )
    }
}
