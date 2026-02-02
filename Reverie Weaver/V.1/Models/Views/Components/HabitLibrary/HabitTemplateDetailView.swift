//
// HabitTemplateDetailView.swift
// Reverie Weaver
//
//

import SwiftUI

struct HabitTemplateDetailView: View {
    let template: HabitTemplate
    let onAddHabit: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @StateObject private var localization = LocalizationManager.shared
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Adaptive Background
                ReverieWeaverBackground()
                    .overlay(
                        Color.black.opacity(0.02)
                            .blendMode(.softLight)
                            .ignoresSafeArea()
                    )
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        
                        // Hero Section
                        VStack(spacing: 16) {
                            // Breathing Orb Component
                            HabitHeroOrb(
                                color: template.category.color,
                                icon: template.icon
                        )
                            
                            VStack(spacing: 8) {
                                Text(template.name)
                                    .font(.system(size: 18, weight: .bold))
                                    .fontDesign(.serif)
                                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                                    .multilineTextAlignment(.center)
                                
                                HStack(spacing: 12) {
                                    HStack(spacing: 4) {
                                        Image(systemName: template.category.icon)
                                            .font(.system(size: 12))
                                        Text(localization.localize("category.\(template.category.rawValue.replacingOccurrences(of: " ", with: ""))"))
                                            .font(.system(size: 13, weight: .medium))
                                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                                    }
                                    .foregroundStyle(template.category.color)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(template.category.color.opacity(0.15))
                                    .clipShape(Capsule())
                                    
                                    Text("•")
                                        .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                                    
                                    Text(template.estimatedMinutes)
                                        .font(.system(size: 13, weight: .regular))
                                        .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                                }
                            }
                        }
                        
                        // Description
                        VStack(alignment: .leading, spacing: 12) {
                            Text(localization.localize("library.description"))
                                .font(.system(size: 12, weight: .semibold))
                                .fontDesign(.serif)
                                .textCase(.uppercase)
                                .tracking(0.5)
                                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                            
                            Text(template.description)
                                .font(.system(size: 12, weight: .regular))
                                .lineSpacing(4)
                                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .reverieCardStyle(colorScheme: colorScheme)
                        
                        // Frequency
                        HStack {
                            Image(systemName: "calendar")
                                .font(.system(size: 14))
                                .foregroundStyle(template.category.color)
                            
                            Text(localization.localize("library.frequency"))
                                .font(.system(size: 13, weight: .medium))
                                .fontDesign(.serif)
                                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                            
                            Spacer()
                            
                            Text(template.suggestedFrequency)
                                .font(.system(size: 13, weight: .regular))
                                .fontDesign(.serif)
                                .timeAdaptiveText(colorScheme: colorScheme, style: .accent)
                        }
                        .padding(14)
                        .reverieCardStyle(colorScheme: colorScheme)
                        
                        // Benefits
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 6) {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.terracottaRose)
                                
                                Text(localization.localize("library.benefits"))
                                    .font(.system(size: 13, weight: .medium))
                                    .fontDesign(.serif)
                                    .textCase(.uppercase)
                                    .tracking(0.5)
                                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                            }
                            
                            VStack(spacing: 10) {
                                ForEach(template.benefits, id: \.self) { benefit in
                                    HStack(alignment: .top, spacing: 10) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 14))
                                            .foregroundStyle(template.category.color)
                                        
                                        Text(benefit)
                                            .font(.system(size: 13, weight: .regular))
                                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                                        
                                        Spacer(minLength: 0)
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .reverieCardStyle(colorScheme: colorScheme)
                        
                        // Tips
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 6) {
                                Image(systemName: "lightbulb.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.paleMauve.opacity(1.0))
                                
                                Text(localization.localize("library.tips"))
                                    .font(.system(size: 13, weight: .semibold))
                                    .fontDesign(.serif)
                                    .textCase(.uppercase)
                                    .tracking(0.5)
                                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                            }
                            
                            Text(template.tips)
                                .font(.system(size: 13, weight: .regular))
                                .fontDesign(.serif)
                                .lineSpacing(4)
                                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .reverieCardStyle(colorScheme: colorScheme)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 100)
                    .padding(.top, 60)
                }
                
                // Floating Close Button (Top Right)
                HStack {
                    Spacer()
                    GlassCloseButton {
                        dismiss()
                    }
                    .accessibilityLabel("Close")
                    .accessibilityHint("Close habit template details")
                }
                .padding(.horizontal)
                .padding(.top, 10)
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .overlay(alignment: .bottomTrailing) {
                // Add Button
                Button {
                    onAddHabit()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                        Text(localization.localize("desk.habits.add"))
                            .font(.system(size: 14, weight: .semibold))
                            .fontDesign(.serif)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 10)
                    .background(Color.sageGreen)
                    .clipShape(Capsule())
                    .shadow(color: Color.shadowColor.opacity(0.25), radius: 6, y: 3)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 24)
                .padding(.bottom, 32)
                .accessibilityLabel("Add this habit")
            }
        }
    }
}

// MARK: - Subviews

fileprivate struct HabitHeroOrb: View {
    let color: Color
    let icon: String
    
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var isBreathing = false
    
    var body: some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: 100, height: 100)
                .blur(radius: 20)
                .opacity(isBreathing ? 0.3 : 0.15)
                .scaleEffect(isBreathing ? 1.2 : 0.95)
            
            Circle()
                .strokeBorder(
                    BorderGradient(color: color),
                    lineWidth: 8
                )
                .frame(width: 100, height: 100)
                .blur(radius: 3)
                .opacity(isBreathing ? 0.8 : 0.5)
                .scaleEffect(isBreathing ? 1.05 : 0.98)
            
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(color)
                .shadow(color: Color.white.opacity(0.5), radius: 10, x: 0, y: 0)
                .scaleEffect(isBreathing ? 1.02 : 0.98)
        }
        .onAppear {
            let isLowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
            let shouldAnimate = !isLowPower && !reduceMotion
            
            if shouldAnimate {
                withAnimation(
                    .easeInOut(duration: 5.0)
                    .repeatForever(autoreverses: true)
                ) {
                    isBreathing = true
                }
            }
        }
    }
    
    private func BorderGradient(color: Color) -> AngularGradient {
        AngularGradient(
            gradient: Gradient(colors: [
                color.opacity(0.3),
                color.opacity(0.8),
                color.opacity(0.3),
                color.opacity(0.8)
            ]),
            center: .center
        )
    }
}
