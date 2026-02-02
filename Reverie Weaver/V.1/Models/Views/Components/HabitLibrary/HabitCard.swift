//
//  HabitCard.swift
//  ReverieWeaver
//
//  Individual habit card component with Theme Week support
//

import SwiftUI

// MARK: - Habit Card Component
struct HabitCard: View {
    let habit: Habit
    let isCompleted: Bool
    let onToggle: () -> Void
    
    let themeWeekProgress: ThemeWeekProgress?
    let completedTier: CompletionTier?

    @State private var showCompletionMessage = false
    @State private var justCompleted = false
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.editMode) private var editMode
    
    var overrideTitle: String? = nil
    var overrideSubtitle: String? = nil
    
    private var isReorderMode: Bool {
        editMode?.wrappedValue == .active
    }
    
    // MARK: - Dynamic Display Properties
        
        private var displayName: String {
            if let override = overrideTitle {
                return override
            }

            // 2. Original Component Logic
            // Safety: Ensure progress exists and matches a real program
            if habit.isThemeWeek, let progress = themeWeekProgress {
                let progressArray = [progress]
                return habit.displayName(themeWeekProgress: progressArray)
            }
            return habit.name
        }
        
        private var displayDescription: String {
            if let override = overrideSubtitle {
                return override
            }

            // 2. Original Component Logic
            if habit.isThemeWeek, let progress = themeWeekProgress {
                let progressArray = [progress]
                return habit.displayDescription(themeWeekProgress: progressArray)
            }
            return habit.habitDescription
        }

    var body: some View {
        HStack(alignment: .center, spacing: ReverieSpacing.cardItemSpacing) {
            // Accent bar
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: habit.colorHex))
                .frame(width: 4)
                .opacity(isCompleted ? 0.5 : 1.0)

            // Content
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: ReverieSpacing.smallSpacing) {
                    // Icon
                    if !habit.icon.isEmpty && habit.icon != "—" {
                        Image(systemName: habit.icon)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(Color(hex: habit.colorHex))
                            .frame(width: 28, height: 28)
                            .opacity(isCompleted ? 0.7 : 1.0)
                    }

                    // Habit name & Badges
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(displayName)
                                .font(.system(size: 12.5, weight: .regular))
                                .fontDesign(.serif)
                                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                                .strikethrough(isCompleted, color: Color.dynamicSecondaryLabel)
                                .opacity(isCompleted ? 0.7 : 1.0)
                            
                            // Theme Week Lock
                            if habit.isThemeWeek {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 11))
                                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                            }
                            
                            // Completion Tier
                            if isCompleted, let tier = completedTier {
                                Image(systemName: tierIcon(for: tier))
                                    .font(.system(size: 11))
                                    .foregroundStyle(tierColor(for: tier))
                            }
                        }
                        
                        // Theme Week Day Indicator
                        if habit.isThemeWeek, let progress = themeWeekProgress {
                            Text("Day \(progress.currentDayNumber) of 7")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Color(hex: habit.colorHex).opacity(0.8))
                        }
                    }
                }

                // Description
                Text(displayDescription)
                    .font(.system(size: 11.5, weight: .regular))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    .lineLimit(2)
                    .opacity(isCompleted ? 0.6 : 1.0)

                // Completion Message (Animated)
                if isCompleted {
                    Divider()
                        .padding(.top, 4)
                        .opacity(0.5)

                    if showCompletionMessage {
                        HStack(spacing: ReverieSpacing.tinySpacing) {
                            Text("✨")
                                .font(.system(size: 13))
                            Text(habit.completionMessage)
                                .font(.system(size: 13, weight: .regular))
                                .fontDesign(.serif)
                                .italic()
                                .foregroundStyle(Color(hex: habit.colorHex))
                        }
                        .transition(ReverieAnimations.scaleAndFade)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: ReverieSpacing.smallSpacing)

            // Category Icon (Top Right)
            VStack {
                Image(systemName: habit.categoryIcon)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.dynamicSecondaryLabel.opacity(0.7))
                Spacer()
            }

            // Completion Button (hidden in reorder mode)
            if !isReorderMode {
                Button {
                    ReverieHaptics.lightFeedback()
                    withAnimation(.spring(
                        response: ReverieAnimations.springResponse,
                        dampingFraction: ReverieAnimations.springDamping
                    )) {
                        onToggle()
                        if !isCompleted {
                            justCompleted = true
                            showCompletionMessage = true
                            
                            // Auto-hide message after delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + ReverieAnimations.habitCompletionDuration) {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    showCompletionMessage = false
                                }
                            }
                        }
                    }
                } label: {
                    ZStack {
                        Circle()
                            .strokeBorder(
                                isCompleted ? Color(hex: habit.colorHex) : Color.habitCardBorder,
                                lineWidth: 2
                            )
                            .frame(width: ReverieSizes.completionCircle, height: ReverieSizes.completionCircle)
                        
                        if isCompleted {
                            Circle()
                                .fill(Color(hex: habit.colorHex))
                                .frame(width: ReverieSizes.completionCircle, height: ReverieSizes.completionCircle)
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .buttonStyle(.plain)
                .contentShape(Circle())
                .accessibilityLabel(isCompleted ? "Mark \(displayName) as incomplete" : "Complete \(displayName)")
                .accessibilityValue(isCompleted ? "Completed" : "Incomplete")
                .accessibilityHint("Double tap to toggle status")
            }
        }
        .padding(.leading, 0)
        .padding(.trailing, 18)
        .padding(.vertical, 16)
        .reverieCardStyle(colorScheme: colorScheme)
        .animation(isReorderMode ? .none : .easeInOut(duration: 0.25), value: isCompleted)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(displayName). \(displayDescription).")
        .accessibilityValue(isCompleted ? "Completed" : "Not completed")
    }
    
    // MARK: - Helpers
    
    private func tierIcon(for tier: CompletionTier) -> String {
        switch tier {
        case .seed: return "leaf.fill"
        case .sprout: return "leaf.circle.fill"
        case .bloom: return "sparkles"
        }
    }
    
    private func tierColor(for tier: CompletionTier) -> Color {
        switch tier {
        case .seed: return Color(hex: "B8D4C8")
        case .sprout: return Color(hex: "9BB5CE")
        case .bloom: return Color(hex: "D4B896")
        }
    }
}

// MARK: - Convenience Init
extension HabitCard {
    init(habit: Habit, isCompleted: Bool, onToggle: @escaping () -> Void) {
        self.habit = habit
        self.isCompleted = isCompleted
        self.onToggle = onToggle
        self.themeWeekProgress = nil
        self.completedTier = nil
    }
}
