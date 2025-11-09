//
//  HabitCard.swift
//  ReverieWeaver
//
//  Individual habit card component with consistent dark mode
//  Created by Antheia Li on 11/8/25.
//

import SwiftUI

// MARK: - Habit Card Component (Refined Glass Style)
struct HabitCard: View {
    let habit: Habit
    let isCompleted: Bool
    let onToggle: () -> Void

    @State private var showCompletionMessage = false
    @State private var justCompleted = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .center, spacing: ReverieSpacing.cardItemSpacing) {
            // Accent bar
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: habit.colorHex))
                .frame(width: 4)
                .opacity(isCompleted ? 0.4 : 1.0)

            // Content
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: ReverieSpacing.smallSpacing) {
                    // Only show icon if it's a valid SF Symbol name
                    if !habit.icon.isEmpty && habit.icon != "—" {
                        Image(systemName: habit.icon)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(Color(hex: habit.colorHex))
                            .frame(width: 28, height: 28)
                            .opacity(isCompleted ? 0.5 : 1.0)
                    }

                    Text(habit.name)
                        .font(.system(size: 12, weight: .regular))
                        .fontDesign(.serif)
                        .foregroundStyle(Color.dynamicLabel)
                        .strikethrough(isCompleted, color: Color.dynamicSecondaryLabel)
                        .opacity(isCompleted ? 0.6 : 1.0)
                }

                Text(habit.habitDescription)
                    .font(.system(size: 10, weight: .regular))
                    .adaptiveSecondaryText(colorScheme: colorScheme)
                    .lineLimit(1)
                    .opacity(isCompleted ? 0.5 : 1.0)

                if isCompleted {
                    Divider()
                        .padding(.top, 4)

                    if showCompletionMessage {
                        HStack(spacing: ReverieSpacing.tinySpacing) {
                            Text("✨")
                                .font(.system(size: 12))
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

            // Category icon (top-right)
            VStack {
                Image(systemName: habit.categoryIcon)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.dynamicSecondaryLabel)
                Spacer()
            }

            // Completion circle button
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
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 0)
        .padding(.trailing, 18)
        .padding(.vertical, 16)
        // 🪞 Updated unified background style
        .reverieCardStyle(colorScheme: colorScheme)
        .animation(.easeInOut(duration: 0.25), value: isCompleted)
    }
}
