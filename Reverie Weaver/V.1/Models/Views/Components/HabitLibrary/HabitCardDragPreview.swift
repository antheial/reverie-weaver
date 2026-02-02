//
//  HabitCardDragPreview.swift
//  Reverie Weaver
//
//  Created by Antheia Li on 12/10/25.
//
import SwiftUI


struct HabitCardDragPreview: View {
    let habit: Habit
    let isCompleted: Bool
    let themeWeekProgress: ThemeWeekProgress?
    let completedTier: CompletionTier?
    var overrideTitle: String? = nil
    var overrideSubtitle: String? = nil
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var displayName: String {
        if let override = overrideTitle { return override }
        if habit.isThemeWeek, let progress = themeWeekProgress {
            return habit.displayName(themeWeekProgress: [progress])
        }
        return habit.name
    }
    
    private var displayDescription: String {
        if let override = overrideSubtitle { return override }
        if habit.isThemeWeek, let progress = themeWeekProgress {
            return habit.displayDescription(themeWeekProgress: [progress])
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
                    if !habit.icon.isEmpty && habit.icon != "—" {
                        Image(systemName: habit.icon)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(Color(hex: habit.colorHex))
                            .frame(width: 28, height: 28)
                            .opacity(isCompleted ? 0.7 : 1.0)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(displayName)
                                .font(.system(size: 12.5, weight: .regular))
                                .fontDesign(.serif)
                                .foregroundStyle(colorScheme == .dark ? .white : .black)
                                .strikethrough(isCompleted, color: Color.dynamicSecondaryLabel)
                                .opacity(isCompleted ? 0.7 : 1.0)
                            
                            if habit.isThemeWeek {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color.dynamicSecondaryLabel)
                            }
                            
                            if isCompleted, let tier = completedTier {
                                Image(systemName: tierIcon(for: tier))
                                    .font(.system(size: 11))
                                    .foregroundStyle(tierColor(for: tier))
                            }
                        }
                        
                        if habit.isThemeWeek, let progress = themeWeekProgress {
                            Text("Day \(progress.currentDayNumber) of 7")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Color(hex: habit.colorHex).opacity(0.8))
                        }
                    }
                }

                Text(displayDescription)
                    .font(.system(size: 11.5, weight: .regular))
                    .foregroundStyle(Color.dynamicSecondaryLabel)
                    .lineLimit(2)
                    .opacity(isCompleted ? 0.6 : 1.0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: ReverieSpacing.smallSpacing)

            VStack {
                Image(systemName: habit.categoryIcon)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.dynamicSecondaryLabel.opacity(0.7))
                Spacer()
            }
            
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
        .padding(.leading, 0)
        .padding(.trailing, 18)
        .padding(.vertical, 16)
        .frame(width: UIScreen.main.bounds.width - 48)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    colorScheme == .dark
                        ? Color.white.opacity(0.08)
                        : Color.white.opacity(0.65)
                )
                .shadow(
                    color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08),
                    radius: 8,
                    y: 4
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    colorScheme == .dark
                        ? Color.white.opacity(0.12)
                        : Color.black.opacity(0.06),
                    lineWidth: 0.5
                )
        )
        .scaleEffect(1.02)
    }
    
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
