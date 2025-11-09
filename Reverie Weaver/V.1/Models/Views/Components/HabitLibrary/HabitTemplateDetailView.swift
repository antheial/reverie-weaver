//
// HabitTemplateDetailView.swift
// Reverie Weaver
//
// Adaptive version — matches DeskView and ReverieWeaverBackground styling
//

import SwiftUI

struct HabitTemplateDetailView: View {
    let template: HabitTemplate
    let onAddHabit: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @StateObject private var localization = LocalizationManager.shared
    @State private var showAddSuccess = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: - Adaptive Time-Based Background
                ReverieWeaverBackground()
                    .overlay(
                        Color.black.opacity(0.02)
                            .blendMode(.softLight)
                            .ignoresSafeArea()
                    )
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        
                        // MARK: - Hero Section
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [
                                                template.category.color.opacity(0.65),
                                                template.category.color.opacity(0.2),
                                                Color.clear
                                            ],
                                            center: .center,
                                            startRadius: 0,
                                            endRadius: 80
                                        )
                                    )
                                    .frame(width: 120, height: 120)
                                
                                Image(systemName: template.icon)
                                    .font(.system(size: 38))
                                    .foregroundStyle(template.category.color)
                            }
                            
                            VStack(spacing: 8) {
                                Text(template.name)
                                    .font(.system(size: 18, weight: .bold))
                                    .fontDesign(.serif)
                                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                                    .multilineTextAlignment(.center)
                                
                                HStack(spacing: 12) {
                                    HStack(spacing: 4) {
                                        Image(systemName: template.category.icon)
                                            .font(.system(size: 11))
                                        Text(localization.localize("category.\(template.category.rawValue.replacingOccurrences(of: " ", with: ""))"))
                                            .font(.system(size: 12, weight: .medium))
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
                                        .font(.system(size: 12, weight: .regular))
                                        .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                                }
                            }
                        }
                        .padding(.top, 12)
                        
                        // MARK: - Description
                        VStack(alignment: .leading, spacing: 12) {
                            Text(localization.localize("library.description"))
                                .font(.system(size: 13, weight: .semibold))
                                .fontDesign(.serif)
                                .textCase(.uppercase)
                                .tracking(0.5)
                                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                            
                            Text(template.description)
                                .font(.system(size: 12, weight: .regular))
                                .lineSpacing(4)
                                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                                .adaptiveTextScrim(colorScheme: colorScheme)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .reverieCardStyle(colorScheme: colorScheme)
                        
                        // MARK: - Frequency
                        HStack {
                            Image(systemName: "calendar")
                                .font(.system(size: 14))
                                .foregroundStyle(template.category.color)
                            
                            Text(localization.localize("library.frequency"))
                                .font(.system(size: 12, weight: .medium))
                                .fontDesign(.serif)
                                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                            
                            Spacer()
                            
                            Text(template.suggestedFrequency)
                                .font(.system(size: 12, weight: .regular))
                                .fontDesign(.serif)
                                .timeAdaptiveText(colorScheme: colorScheme, style: .accent)
                        }
                        .padding(14)
                        .reverieCardStyle(colorScheme: colorScheme)
                        
                        // MARK: - Benefits
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 6) {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.terracottaRose)
                                
                                Text(localization.localize("library.benefits"))
                                    .font(.system(size: 12, weight: .medium))
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
                                            .font(.system(size: 12, weight: .regular))
                                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                                            .adaptiveTextScrim(colorScheme: colorScheme)
                                        
                                        Spacer(minLength: 0)
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .reverieCardStyle(colorScheme: colorScheme)
                        
                        // MARK: - Tips
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 6) {
                                Image(systemName: "lightbulb.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.paleMauve.opacity(1.0))
                                
                                Text(localization.localize("library.tips"))
                                    .font(.system(size: 12, weight: .semibold))
                                    .fontDesign(.serif)
                                    .textCase(.uppercase)
                                    .tracking(0.5)
                                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                            }
                            
                            Text(template.tips)
                                .font(.system(size: 12, weight: .regular))
                                .fontDesign(.serif)
                                .lineSpacing(4)
                                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                                .adaptiveTextScrim(colorScheme: colorScheme)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .reverieCardStyle(colorScheme: colorScheme)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 100)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.35))
                                .frame(width: 28, height: 28)
                                .shadow(color: Color.shadowColor, radius: 4, y: 2)
                            
                            Circle()
                                .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                                .frame(width: 28, height: 28)
                            
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .semibold))
                                .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                        }
                    }
                }
            }
            .overlay(alignment: .bottomTrailing) {
                // MARK: - Add Button (Restored Original Style)
                Button {
                    onAddHabit()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Add")
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
            }
        }
    }
}
