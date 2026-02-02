//
//  PostExerciseReflection.swift
//  Reverie Mood
//
//  Post-exercise reflection with mood tracking and optional note
//

import SwiftUI
import OSLog

private let postExerciseLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.reverie.mood", category: "PostExerciseReflection")

struct PostExerciseReflection: View {
    let technique: GroundingTechnique
    let groundednessBefore: Int
    let onComplete: (Int, String?) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var groundednessAfter: Int? = nil
    @State private var reflectionNote: String = ""
    @State private var showCelebration = false
    @FocusState private var isNoteFieldFocused: Bool

    private let moodEmojis = ["😰", "😟", "😐", "🙂", "😊"]
    private let moodLabels = [
        "Very ungrounded",
        "Somewhat ungrounded",
        "Neutral",
        "Somewhat grounded",
        "Very grounded"
    ]

    private var improvement: Int {
        guard let after = groundednessAfter else { return 0 }
        return after - groundednessBefore
    }

    var body: some View {
        ZStack {
            // Warm background
            ReverieColors.background(colorScheme)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 12) {
                        // Completion icon
                        ZStack {
                            Circle()
                                .fill(ReverieColors.accent(colorScheme).opacity(0.15))
                                .frame(width: 80, height: 80)

                            Image(systemName: "checkmark")
                                .font(.system(size: 32, weight: .medium))
                                .foregroundColor(ReverieColors.accent(colorScheme))
                        }
                        .scaleEffect(showCelebration ? 1.0 : 0.8)
                        .opacity(showCelebration ? 1.0 : 0)

                        Text("Exercise Complete")
                            .font(.custom("Georgia", size: 24))
                            .tracking(-0.3)
                            .foregroundColor(ReverieColors.textPrimary(colorScheme))

                        Text(technique.title)
                            .font(.custom("Georgia-Italic", size: 15))
                            .foregroundColor(ReverieColors.textSecondary(colorScheme))
                    }
                    .padding(.top, 32)

                    // Before/After comparison
                    beforeAfterCard

                    // Mood check card
                    moodCheckCard

                    // Improvement or compassionate response badge
                    if let _ = groundednessAfter {
                        if improvement > 0 {
                            improvementBadge
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            // Compassionate messaging for no improvement or regression
                            compassionateBadge
                                .transition(.scale.combined(with: .opacity))
                        }
                    }

                    // Optional reflection note
                    reflectionNoteCard

                    // Save button
                    if groundednessAfter != nil {
                        saveButton
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    Spacer(minLength: 40)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                showCelebration = true
            }
        }
    }

    // MARK: - Before/After Card

    private var beforeAfterCard: some View {
        HStack(spacing: 0) {
            // Before
            VStack(spacing: 8) {
                Text("BEFORE")
                    .font(ReverieTypography.labelTiny)
                    .tracking(1.2)
                    .foregroundColor(ReverieColors.textTertiary(colorScheme))

                Text(moodEmojis[groundednessBefore - 1])
                    .font(.system(size: 36))

                Text("\(groundednessBefore)")
                    .font(.custom("Georgia", size: 20))
                    .foregroundColor(ReverieColors.textPrimary(colorScheme))
            }
            .frame(maxWidth: .infinity)

            // Divider
            Rectangle()
                .fill(ReverieColors.textPrimary(colorScheme).opacity(0.12))
                .frame(width: 1, height: 80)

            // After
            VStack(spacing: 8) {
                Text("AFTER")
                    .font(ReverieTypography.labelTiny)
                    .tracking(1.2)
                    .foregroundColor(ReverieColors.textTertiary(colorScheme))

                if let after = groundednessAfter {
                    Text(moodEmojis[after - 1])
                        .font(.system(size: 36))
                        .transition(.scale)

                    Text("\(after)")
                        .font(.custom("Georgia", size: 20))
                        .foregroundColor(ReverieColors.textPrimary(colorScheme))
                        .transition(.opacity)
                } else {
                    Text("?")
                        .font(.system(size: 36))
                        .foregroundColor(ReverieColors.textTertiary(colorScheme).opacity(0.4))
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 24)
        .background(
            ReverieCardSurface(
                cornerRadius: ReverieLayout.Radius.large,
                includeBorder: false,
                includeTexture: true
            )
        )
        .padding(.horizontal, 24)
    }

    // MARK: - Mood Check Card

    private var moodCheckCard: some View {
        VStack(spacing: 20) {
            Text("How do you feel now?")
                .font(.custom("Georgia", size: 18))
                .tracking(-0.2)
                .foregroundColor(ReverieColors.textPrimary(colorScheme))
                .multilineTextAlignment(.center)

            // Emoji scale
            HStack(spacing: 16) {
                ForEach(1...5, id: \.self) { level in
                    moodButton(level: level)
                }
            }
            .padding(.vertical, 8)

            // Label for selected mood
            if let selected = groundednessAfter {
                Text(moodLabels[selected - 1])
                    .font(.custom("Georgia-Italic", size: 13))
                    .foregroundColor(ReverieColors.textSecondary(colorScheme))
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .padding(28)
        .background(
            ReverieCardSurface(
                cornerRadius: ReverieLayout.Radius.large,
                includeBorder: false,
                includeTexture: true
            )
        )
        .padding(.horizontal, 24)
    }

    private func moodButton(level: Int) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                groundednessAfter = level
                ReverieHaptics.light()
            }
        }) {
            VStack(spacing: 6) {
                Text(moodEmojis[level - 1])
                    .font(.system(size: 32))

                Text("\(level)")
                    .font(.custom("Georgia", size: 11))
                    .foregroundColor(ReverieColors.textTertiary(colorScheme))
            }
            .frame(width: 52, height: 64)
            .background(
                RoundedRectangle(cornerRadius: ReverieLayout.Radius.small)
                    .fill(
                        groundednessAfter == level
                            ? ReverieColors.accent(colorScheme).opacity(0.15)
                            : ReverieColors.textPrimary(colorScheme).opacity(0.04)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: ReverieLayout.Radius.small)
                    .stroke(
                        groundednessAfter == level
                            ? ReverieColors.accent(colorScheme).opacity(0.4)
                            : Color.clear,
                        lineWidth: 2
                    )
            )
            .scaleEffect(groundednessAfter == level ? 1.05 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Improvement Badge

    private var improvementBadge: some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(ReverieColors.accent(colorScheme))

            VStack(alignment: .leading, spacing: 2) {
                Text("You improved by +\(improvement)")
                    .font(.custom("Georgia", size: 16))
                    .foregroundColor(ReverieColors.textPrimary(colorScheme))

                Text(improvementMessage)
                    .font(.custom("Georgia-Italic", size: 13))
                    .foregroundColor(ReverieColors.textSecondary(colorScheme))
            }

            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: ReverieLayout.Radius.medium)
                .fill(ReverieColors.accent(colorScheme).opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: ReverieLayout.Radius.medium)
                .stroke(ReverieColors.accent(colorScheme).opacity(0.25), lineWidth: 1)
        )
        .padding(.horizontal, 24)
    }

    private var improvementMessage: String {
        switch improvement {
        case 1:
            return "A step in the right direction"
        case 2:
            return "Noticeable improvement"
        case 3:
            return "Significant progress"
        case 4...:
            return "Amazing transformation"
        default:
            return "Keep going"
        }
    }

    // MARK: - Compassionate Badge (No Improvement or Regression)

    private var compassionateBadge: some View {
        HStack(spacing: 10) {
            Image(systemName: compassionateIcon)
                .font(.system(size: 24))
                .foregroundColor(compassionateColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(compassionateTitle)
                    .font(.custom("Georgia", size: 16))
                    .foregroundColor(ReverieColors.textPrimary(colorScheme))

                Text(compassionateMessage)
                    .font(.custom("Georgia-Italic", size: 13))
                    .foregroundColor(ReverieColors.textSecondary(colorScheme))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: ReverieLayout.Radius.medium)
                .fill(compassionateColor.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: ReverieLayout.Radius.medium)
                .stroke(compassionateColor.opacity(0.25), lineWidth: 1)
        )
        .padding(.horizontal, 24)
    }

    private var compassionateIcon: String {
        if improvement == 0 {
            return "equal.circle.fill"
        } else {
            return "heart.circle.fill"
        }
    }

    private var compassionateColor: Color {
        if improvement == 0 {
            return Color(hex: "90CAF9") // Soft blue - neutral
        } else {
            return Color(hex: "CE93D8") // Soft purple - gentle
        }
    }

    private var compassionateTitle: String {
        if improvement == 0 {
            return "You stayed steady"
        } else {
            return "You showed up"
        }
    }

    private var compassionateMessage: String {
        if improvement == 0 {
            return "Staying steady is its own kind of strength. You showed up for yourself, and that matters."
        } else {
            // Regression (felt worse)
            return "Sometimes feelings surface when we slow down. This is part of the process, not a failure. You did something brave by trying."
        }
    }

    // MARK: - Reflection Note Card

    private var reflectionNoteCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Any thoughts? (optional)")
                .font(.custom("Georgia-Italic", size: 14))
                .foregroundColor(ReverieColors.textSecondary(colorScheme))

            ZStack(alignment: .topLeading) {
                // Background
                RoundedRectangle(cornerRadius: ReverieLayout.Radius.medium)
                    .fill(ReverieColors.textPrimary(colorScheme).opacity(0.04))
                    .frame(height: 100)

                // Placeholder
                if reflectionNote.isEmpty && !isNoteFieldFocused {
                    Text("What did you notice? How do you feel?")
                        .font(.custom("Georgia-Italic", size: 14))
                        .foregroundColor(ReverieColors.textTertiary(colorScheme).opacity(0.6))
                        .padding(.horizontal, 14)
                        .padding(.top, 12)
                }

                // Text editor
                TextEditor(text: $reflectionNote)
                    .font(.custom("Georgia", size: 14))
                    .foregroundColor(ReverieColors.textPrimary(colorScheme))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .frame(height: 100)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .focused($isNoteFieldFocused)
            }
        }
        .padding(20)
        .background(
            ReverieCardSurface(
                cornerRadius: ReverieLayout.Radius.large,
                includeBorder: false,
                includeTexture: true
            )
        )
        .padding(.horizontal, 24)
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button(action: {
            guard let after = groundednessAfter else { return }
            ReverieHaptics.success()

            let note = reflectionNote.trimmingCharacters(in: .whitespacesAndNewlines)
            onComplete(after, note.isEmpty ? nil : note)
        }) {
            HStack(spacing: 8) {
                Text("Save & Finish")
                    .font(ReverieTypography.labelMedium)
                    .tracking(1.2)

                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(ReverieColors.textPrimary(colorScheme))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: ReverieLayout.Radius.medium)
                    .fill(ReverieColors.accent(colorScheme).opacity(0.15))
            )
            .overlay(
                RoundedRectangle(cornerRadius: ReverieLayout.Radius.medium)
                    .stroke(ReverieColors.accent(colorScheme).opacity(0.4), lineWidth: 1.5)
            )
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Preview
struct PostExerciseReflection_Previews: PreviewProvider {
    static var previews: some View {
        PostExerciseReflection(
            technique: .boxBreathing,
            groundednessBefore: 2,
            onComplete: { after, note in
                postExerciseLogger.debug("After: \(after), Note: \(note ?? "none")")
            }
        )
    }
}
