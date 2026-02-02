//
// HybridCompletionToast.swift
// ReverieWeaver
//
// Hybrid toast: Clear messaging + Reverie aesthetic + Auto-dismiss
//    Uses SF Symbols for consistency
//    No progress bar (clean & minimal)
//    Matches app's design language
//    ENHANCED: Supports "Long Break Disabled" logic
//

import SwiftUI

struct HybridCompletionToast: View {
    let sessionType: TimerState
    let sessionCount: Int
    var isLongBreakEnabled: Bool = true
    
    let onStartBreak: () -> Void
    let onDismiss: () -> Void
    
    @State private var offset: CGFloat = -150
    @State private var opacity: Double = 0
    @State private var isVisible: Bool = true
    
    var body: some View {
        VStack {
            VStack(spacing: 0) {
                HStack(spacing: 14) {
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
                            .foregroundStyle(Color.primary)
                        
                        Text(subtitle)
                            .font(.system(size: 13, weight: .regular))
                            .fontDesign(.serif)
                            .foregroundStyle(Color.secondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer()
                    
                    Button(action: animateAndDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Color.secondary.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                
                if sessionType == .running {
                    Divider()
                        .opacity(0.2)
                    
                    HStack(spacing: 0) {
                        Button(action: animateAndDismiss) {
                            Text("Later")
                                .font(.system(size: 14, weight: .medium))
                                .fontDesign(.serif)
                                .foregroundStyle(Color.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .buttonStyle(.plain)
                        
                        Divider()
                            .frame(height: 40)
                            .opacity(0.2)
                        
                        // 'Start Break' Button
                        Button(action: {
                            animateAndDismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                onStartBreak()
                            }
                        }) {
                            HStack(spacing: 6) {
                                // Dynamic icon based on next break type
                                Image(systemName: isNextBreakLong ? "moon.stars.fill" : "cup.and.saucer.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                
                                Text(isNextBreakLong ? "Long Break" : "Short Break")
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
                                .white.opacity(0.6),
                                .white.opacity(0.2),
                                .white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .padding(.horizontal, 16)
            .padding(.top, 60)
            .offset(y: offset)
            .opacity(opacity)
            
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                offset = 0
                opacity = 1
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                if isVisible {
                    animateAndDismiss()
                }
            }
        }
    }
    
    // MARK: - Logic Helpers
    
    private func animateAndDismiss() {
        guard isVisible else { return }
        isVisible = false
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            offset = -200
            opacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            onDismiss()
        }
    }
    
    private var isNextBreakLong: Bool {
        return sessionCount > 0 && (sessionCount % 4 == 0)
    }
    
    // MARK: - Computed Properties (Styling)
    
    private var iconColor: Color {
        switch sessionType {
        case .running:      return Color.sageGreen
        case .shortBreak:   return Color.dustyBlue
        case .longBreak:    return Color.paleMauve
        default:            return Color.sageGreen
        }
    }
    
    private var iconSymbol: String {
        switch sessionType {
        case .running:      return "checkmark.circle.fill"
        case .shortBreak:   return "cup.and.saucer.fill"
        case .longBreak:    return "moon.stars.fill"
        default:            return "checkmark.circle.fill"
        }
    }
    
    private var title: String {
        switch sessionType {
        case .running:      return "Focus Session Complete"
        case .shortBreak:   return "Break Complete"
        case .longBreak:    return "Long Break Complete"
        default:            return "Session Complete"
        }
    }
    
    private var subtitle: String {
        switch sessionType {
        case .running:
            //  WORK SESSION COMPLETE
            // This toast appears immediately AFTER completing a work session
            // So we're prompting the user about the UPCOMING break
            if isNextBreakLong {
                if isLongBreakEnabled {
                    return "Well done. Time for a 15-minute rest."
                } else {
                    return "Cycle complete! Ready to continue flow?"
                }
            } else {
                return "Great work. Take a 5-minute break."
            }
            
        case .shortBreak:
            //    SHORT BREAK COMPLETE
            // This toast appears immediately AFTER completing a break
            // So we're prompting the user that they're ready to continue
            return "Refreshed? Ready to continue weaving."
            
        case .longBreak:
            //    LONG BREAK COMPLETE
            // This toast appears immediately AFTER completing a long break
            // So we're prompting the user that they're well-rested and ready
            return "Well rested. Begin your next cycle."
            
        default:
            return "Session recorded successfully."
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.black.opacity(0.1).ignoresSafeArea()
        
        HybridCompletionToast(
            sessionType: .running,
            sessionCount: 4,
            isLongBreakEnabled: true,
            onStartBreak: {},
            onDismiss: {}
        )
    }
}
