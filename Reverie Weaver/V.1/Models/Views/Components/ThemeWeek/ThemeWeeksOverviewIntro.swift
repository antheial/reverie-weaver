//
//  ThemeWeeksOverviewIntro.swift
//  Reverie Weaver
//
//  Created by Antheia Li on 11/16/25.
//
//
// Landing page for Theme Week Programs
// Browse and select gentle daily rhythm programs
//

import SwiftUI
import SwiftData

struct ThemeWeeksOverviewIntro: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Query private var themeWeekProgress: [ThemeWeekProgress]
    
    @State private var selectedProgram: ThemeWeekProgram?
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                ReverieWeaverBackground()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        heroSection
                        philosophicalQuote
                        programsSection
                        philosophySection
                    }
                    .padding(.bottom, 100)
                    .padding(.top, 60)
                }
                            HStack {
                                Spacer()
                                closeButton
                            }
                            .padding(.horizontal)
                            .padding(.top, 10)
                        }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedProgram) { program in
                ThemeWeekDetailView(program: program)
            }
        }
    }
}

// MARK: - View Sections

private extension ThemeWeeksOverviewIntro {
    
    // MARK: Hero Section
    var heroSection: some View {
        HybridEditorialChallengeHeader(
            icon: "moon.stars.fill",
            title: "Theme Week Programs",
            categoryLabel: "Gentle Rhythm",
            subtitle: "One focus per day. Three ways to win.",
            accentColor: Color(hex: "C8B8DB")
        )
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }
    
    // MARK: Philosophical Quote
    var philosophicalQuote: some View {
        VStack(spacing: 12) {
            // Decorative divider
            HStack(spacing: 12) {
                Rectangle()
                    .fill(Color.dynamicSecondaryLabel.opacity(0.2))
                    .frame(height: 0.5)
                    .frame(maxWidth: .infinity)
                
                Image(systemName: "sparkle")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "C8B8DB").opacity(0.6))
                
                Rectangle()
                    .fill(Color.dynamicSecondaryLabel.opacity(0.2))
                    .frame(height: 0.5)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 40)
            
            // The quote
            Text("Progress doesn't always mean pushing harder — sometimes it means creating space for gentleness, rhythm, and permission to start small.")
                .font(.custom("Georgia", size: 14))
                .fontWeight(.light)
                .italic()
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                .padding(.horizontal, 32)
            
            // Attribution
            Text("— REVERIE WEAVER PHILOSOPHY")
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.2)
                .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                .opacity(0.6)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: Programs Section
    var programsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("CHOOSE A PROGRAM")
                .font(.system(size: 12, weight: .semibold))
                .tracking(1)
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                .padding(.horizontal, 24)
            
            VStack(spacing: 12) {
                ForEach(ThemeWeekData.programs, id: \.id) { program in
                    ThemeWeekProgramCard(
                        program: program,
                        isActive: isProgramActive(program),
                        colorScheme: colorScheme
                    ) {
                        selectedProgram = program
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
    }
    
    // MARK: Close Button
    var closeButton: some View {
        GlassCloseButton {
            dismiss()
        }
    }
}

// MARK: - Helper Functions

private extension ThemeWeeksOverviewIntro {
    func isProgramActive(_ program: ThemeWeekProgram) -> Bool {
        themeWeekProgress.contains { progress in
            progress.programTag == program.tag && !progress.isCompleted && !progress.isPaused && !progress.isArchived
        }
    }
}

// MARK: - Theme Week Program Card

private struct ThemeWeekProgramCard: View {
    let program: ThemeWeekProgram
    let isActive: Bool
    let colorScheme: ColorScheme
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: program.colorHex).opacity(0.15))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Circle()
                                    .strokeBorder(Color(hex: program.colorHex).opacity(0.3), lineWidth: 1)
                            )
                        
                        Image(systemName: program.icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(Color(hex: program.colorHex))
                    }
                    
                    // Title and status
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text(program.title)
                                .font(.system(size: 14, weight: .semibold))
                                .fontDesign(.serif)
                                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                            
                            if isActive {
                                Text("Active")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.sageGreen)
                                    .cornerRadius(6)
                            }
                        }
                        
                        Text(program.subtitle)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color(hex: program.colorHex))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.dynamicSecondaryLabel.opacity(0.5))
                }
                
                // Description
                Text(program.description)
                    .font(.system(size: 12))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Micro-wins indicator (typography aligned with habit count row)
                HStack(spacing: 4) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 11))
                    Text("3-tier micro-wins system")
                        .font(.system(size: 11, weight: .medium))
                    
                    Spacer()
                    
                    Text("7 days")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(Color.dynamicSecondaryLabel.opacity(0.7))
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .reverieCardStyle(colorScheme: colorScheme)
        }
        .buttonStyle(.plain)
    }
}

// MARK: Philosophy Section

var philosophySection: some View {
    OpenEditorialSection(
        icon: "leaf.fill",
        iconColor: Color(hex: "B8D4C8"),
        title: "The Philosophy",
        content: "These 7-day programs offer gentle daily themes with three tiers of completion. Perfect for when everything feels overwhelming. Each habit has Seed (minimum), Sprout (intended), and Bloom (exceptional) options. Any tier counts as success."
    )
    .padding(.horizontal, 24)
}

// MARK: - Preview

#Preview {
    ThemeWeeksOverviewIntro()
        .modelContainer(for: [ThemeWeekProgress.self], inMemory: true)
}
