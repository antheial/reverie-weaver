//
//  TierSelectionSheet.swift
//  Reverie Weaver
//
//  Created by Antheia Li on 11/17/25.
//

import SwiftUI

struct TierSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    let themeWeekHabit: ThemeWeekHabit
    let dayNumber: Int
    let themeName: String
    let onSelectTier: (CompletionTier) -> Void
    let isVitalityProgram: Bool
    
    @State private var selectedTier: CompletionTier?
    @State private var expandedTier: CompletionTier? = nil

    // MARK: - Initializer
    
    init(
        themeWeekHabit: ThemeWeekHabit,
        dayNumber: Int,
        themeName: String,
        isVitalityProgram: Bool = false,
        onSelectTier: @escaping (CompletionTier) -> Void
    ) {
        self.themeWeekHabit = themeWeekHabit
        self.dayNumber = dayNumber
        self.themeName = themeName
        self.isVitalityProgram = isVitalityProgram
        self.onSelectTier = onSelectTier
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Match DeskView background
            ReverieWeaverBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Drag handle
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.adaptiveBorder(colorScheme: colorScheme).opacity(0.5))
                    .frame(width: 36, height: 5)
                    .padding(.top, 12)
                    .padding(.bottom, 20)
                    .accessibilityHidden(true)
                
                // MARK: Header
                VStack(spacing: 8) {
                    Text("Day \(dayNumber): \(themeName)")
                        .font(.system(size: 18, weight: .semibold))
                        .fontDesign(.serif)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    
                    Text("Which version did you complete?")
                        .font(.system(size: 13))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                }
                .padding(.bottom, 24)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Day \(dayNumber): \(themeName). Choose completion tier.")
                
                // MARK: Tier Options
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 12) {
                        tierButton(
                            tier: .seed,
                            icon: "leaf.fill",
                            title: "Seed",
                            description: themeWeekHabit.seedTier,
                            color: Color(hex: "B8D4C8")
                        )

                        tierButton(
                            tier: .sprout,
                            icon: "leaf.circle.fill",
                            title: "Sprout",
                            description: themeWeekHabit.sproutTier,
                            color: Color(hex: "9BB5CE")
                        )

                        tierButton(
                            tier: .bloom,
                            icon: "sparkles",
                            title: "Bloom",
                            description: themeWeekHabit.bloomTier,
                            color: Color(hex: "D4B896")
                        )

                        // Long press hint
                        if selectedTier == nil {
                            HStack(spacing: 4) {
                                Image(systemName: "hand.tap")
                                    .font(.system(size: 10))
                                Text("Hold to read more")
                                    .font(.system(size: 11))
                            }
                            .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                            .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .scrollDismissesKeyboard(.interactively)

                // MARK: Encouraging Message
                if let tier = selectedTier {
                    HStack(spacing: 8) {
                        Image(systemName: encouragementIcon(for: tier))
                            .font(.system(size: 13))
                            .foregroundStyle(encouragementColor(for: tier))
                        
                        Text(encouragementMessage(for: tier))
                            .font(.system(size: 12, weight: .regular))
                            .italic()
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 6)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
                // MARK: Vitality RPE Note
                if isVitalityProgram {
                    HStack(spacing: 6) {
                        Image(systemName: "gauge.medium")
                            .font(.system(size: 12))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                        Text("Log effort (RPE) in My Arc after completing")
                            .font(.system(size: 11, weight: .regular))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 4)
                }
                
                Spacer(minLength: 20)
                
                // MARK: Cancel Button
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                        .font(.system(size: 14, weight: .medium))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Cancel")
                .accessibilityHint("Dismiss tier selection")
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .presentationDetents([.medium, .large])  // Dynamic height for longer tier descriptions
        .presentationDragIndicator(.hidden)
        .onAppear {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred()
        }
    }
    
    // MARK: - Tier Button Component (Option 3: Long Press to Expand, Tap to Select)
    // Quick tap = select immediately (fast selection path)
    // Long press = expand to read more (for users who want details)

    @ViewBuilder
    private func tierButton(
        tier: CompletionTier,
        icon: String,
        title: String,
        description: String,
        color: Color
    ) -> some View {
        let isExpanded = expandedTier == tier

        VStack(spacing: 0) {
            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.15))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Circle()
                                    .strokeBorder(color.opacity(0.3), lineWidth: 1)
                            )
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(color)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 15, weight: .semibold))
                            .fontDesign(.serif)
                            .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

                        Text(description)
                            .font(.system(size: 12))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                            .lineLimit(isExpanded ? nil : 2)
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    // Show checkmark when selected, or hint icon when not expanded
                    if selectedTier == tier {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(color)
                    } else if !isExpanded {
                        // Subtle hint that long press reveals more
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 16))
                            .foregroundStyle(color.opacity(0.4))
                    }
                }
                .padding(16)

                // Expanded content: full description already shown via lineLimit(nil)
                // Add collapse chevron when expanded
                if isExpanded {
                    HStack {
                        Spacer()
                        Image(systemName: "chevron.up")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(color.opacity(0.6))
                        Spacer()
                    }
                    .padding(.bottom, 10)
                    .padding(.top, -6)
                }
            }
            .reverieCardStyle(colorScheme: colorScheme)
            .contentShape(Rectangle())
            // Quick tap = select immediately
            .onTapGesture {
                // If expanded, collapse instead of selecting
                if isExpanded {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        expandedTier = nil
                    }
                    ReverieHaptics.lightFeedback()
                } else {
                    // Quick select
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTier = tier
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        ReverieHaptics.successFeedback()
                        onSelectTier(tier)
                        dismiss()
                    }
                }
            }
            // Long press = expand to read full description
            .onLongPressGesture(minimumDuration: 0.4) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    if expandedTier == tier {
                        expandedTier = nil
                    } else {
                        expandedTier = tier
                    }
                }
                ReverieHaptics.mediumFeedback()
            }
            .accessibilityLabel("\(title) tier")
            .accessibilityHint("Tap to select, hold to read more. \(description)")
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isExpanded)
    }
    
    // MARK: - Encouragement Helpers
    
    private func encouragementMessage(for tier: CompletionTier) -> String {
        switch tier {
        case .seed:
            return "Starting small is still starting — proud of you! 🌱"
        case .sprout:
            return "You're building momentum — great work! 🌿"
        case .bloom:
            return "You went all in — amazing effort! ✨"
        }
    }
    
    private func encouragementIcon(for tier: CompletionTier) -> String {
        switch tier {
        case .seed:
            return "hand.thumbsup.fill"
        case .sprout:
            return "bolt.heart.fill"
        case .bloom:
            return "star.fill"
        }
    }
    
    private func encouragementColor(for tier: CompletionTier) -> Color {
        switch tier {
        case .seed:
            return Color(hex: "B8D4C8")
        case .sprout:
            return Color(hex: "9BB5CE")
        case .bloom:
            return Color(hex: "D4B896")
        }
    }
}

// MARK: - Preview

#Preview {
    TierSelectionSheet(
        themeWeekHabit: ThemeWeekHabit(
            name: "Morning Movement",
            icon: "figure.walk",
            colorHex: "B8D4C8",
            seedTier: "5-minute stretch in bed",
            sproutTier: "15-minute walk outside",
            bloomTier: "30+ minutes intentional exercise",
            dayNumber: 1,
            tag: "GentleRhythmW1"
        ),
        dayNumber: 1,
        themeName: "Movement",
        onSelectTier: { tier in
            print("Selected: \(tier)")
        }
    )
}
