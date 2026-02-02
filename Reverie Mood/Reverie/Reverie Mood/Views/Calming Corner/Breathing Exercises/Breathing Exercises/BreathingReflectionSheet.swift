//
//  BreathingReflectionSheet.swift
//  Reverie Mood
//
//  Post-session reflection sheet with quick mood check and optional journal.
//  Records session statistics and mood improvement tracking.
//

import SwiftUI
import OSLog

private let breathingReflectionLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.reverie.mood", category: "BreathingReflection")

struct BreathingReflectionSheet: View {
    let exercise: BreathingExercise
    let sessionStats: SessionStats
    let preMood: BreathingMood?
    let cyclesTarget: Int
    let onComplete: (PostSessionMood?, String?) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var selectedMood: PostSessionMood?
    @State private var reflectionText: String = ""
    @State private var showContent = false
    @FocusState private var isTextFieldFocused: Bool

    private var exerciseStats: ExerciseStats {
        BreathingProgressManager.shared.getStats(for: exercise.id)
    }

    // Subtle warm tone for card backgrounds
    private var warmCardBackground: Color {
        ReverieColors.warmCardSurface(colorScheme)
    }

    var body: some View {
        ZStack {
            // Background
            ReverieBackground()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header with celebration
                    headerSection
                        .padding(.top, 28)

                    // Session summary
                    sessionSummarySection
                        .padding(.top, 24)

                    ReverieDivider(.ornamental)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 20)

                    // Mood check
                    moodCheckSection
                        .padding(.horizontal, 24)

                    // Optional reflection
                    reflectionSection
                        .padding(.horizontal, 24)
                        .padding(.top, 24)

                    // Complete button
                    completeButton
                        .padding(.horizontal, 24)
                        .padding(.top, 28)
                        .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                showContent = true
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 16) {
            // Celebration icon
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                exercise.color.opacity(0.3),
                                exercise.color.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 48))
                    .foregroundColor(ReverieColors.accentGold(colorScheme))
                    .scaleEffect(showContent ? 1.0 : 0.5)
                    .opacity(showContent ? 1.0 : 0)
            }

            VStack(spacing: 6) {
                Text(L("breathing_session.session_complete"))
                    .font(ReverieTypography.labelSmall)
                    .tracking(2)
                    .foregroundColor(ReverieColors.accentRed(colorScheme))

                Text(L("breathing_session.well_done"))
                    .font(.custom("Georgia-Italic", size: 18))
                    .foregroundColor(ReverieColors.textPrimary(colorScheme))
            }
        }
        .scaleEffect(showContent ? 1.0 : 0.95)
        .opacity(showContent ? 1.0 : 0)
    }

    // MARK: - Session Summary

    private var sessionSummarySection: some View {
        VStack(spacing: 16) {
            // Exercise name
            HStack(spacing: 12) {
                Image(systemName: exercise.icon)
                    .font(.system(size: 18))
                    .foregroundColor(exercise.color)

                Text(exercise.name)
                    .font(.custom("Georgia", size: 18))
                    .foregroundColor(ReverieColors.textPrimary(colorScheme))
            }

            // Stats row
            HStack(spacing: 24) {
                statItem(
                    value: sessionStats.durationFormatted,
                    label: "Duration",
                    icon: "clock"
                )

                Rectangle()
                    .fill(ReverieColors.border(colorScheme))
                    .frame(width: 1, height: 36)

                statItem(
                    value: "\(sessionStats.cyclesCompleted)",
                    label: "Cycles",
                    icon: "arrow.triangle.2.circlepath"
                )

                if exerciseStats.sessionsCompleted > 0 {
                    Rectangle()
                        .fill(ReverieColors.border(colorScheme))
                        .frame(width: 1, height: 36)

                    statItem(
                        value: "\(exerciseStats.sessionsCompleted + 1)",
                        label: "Total",
                        icon: "star"
                    )
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(warmCardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(ReverieColors.border(colorScheme).opacity(0.6), lineWidth: 1)
            )
        }
        .padding(.horizontal, 24)
    }

    private func statItem(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(ReverieColors.textTertiary(colorScheme))

                Text(value)
                    .font(.custom("Georgia-Bold", size: 16))
                    .foregroundColor(ReverieColors.textPrimary(colorScheme))
            }

            Text(label)
                .font(ReverieTypography.labelTiny)
                .foregroundColor(ReverieColors.textTertiary(colorScheme))
        }
    }

    // MARK: - Mood Check

    private var moodCheckSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(L("breathing_reflection.how_feel_now"))
                    .font(ReverieTypography.labelSmall)
                    .tracking(2)
                    .foregroundColor(ReverieColors.textTertiary(colorScheme))

                if let preMood = preMood {
                    Text(String(format: L("breathing_reflection.started_feeling"), preMood.rawValue.lowercased()))
                        .font(.custom("Georgia-Italic", size: 12))
                        .foregroundColor(ReverieColors.textTertiary(colorScheme).opacity(0.8))
                }
            }

            HStack(spacing: 12) {
                ForEach(PostSessionMood.allCases, id: \.rawValue) { mood in
                    postMoodButton(mood)
                }
            }
        }
    }

    private func postMoodButton(_ mood: PostSessionMood) -> some View {
        let isSelected = selectedMood == mood

        return Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                selectedMood = mood
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: mood.icon)
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .white : mood.color)

                Text(mood.rawValue)
                    .font(ReverieTypography.labelSmall)
                    .foregroundColor(isSelected ? .white : ReverieColors.textPrimary(colorScheme))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? mood.color : warmCardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? mood.color : ReverieColors.border(colorScheme).opacity(0.6), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Reflection

    private var reflectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L("breathing_reflection.reflection"))
                    .font(ReverieTypography.labelSmall)
                    .tracking(2)
                    .foregroundColor(ReverieColors.textTertiary(colorScheme))

                Spacer()

                Text(L("breathing_reflection.optional"))
                    .font(.custom("Georgia-Italic", size: 11))
                    .foregroundColor(ReverieColors.textTertiary(colorScheme).opacity(0.7))
            }

            ZStack(alignment: .topLeading) {
                if reflectionText.isEmpty {
                    Text(L("breathing_reflection.placeholder"))
                        .font(.custom("Georgia-Italic", size: 14))
                        .foregroundColor(ReverieColors.textTertiary(colorScheme).opacity(0.6))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                }

                TextEditor(text: $reflectionText)
                    .font(.custom("Georgia", size: 14))
                    .foregroundColor(ReverieColors.textPrimary(colorScheme))
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .focused($isTextFieldFocused)
            }
            .frame(height: 100)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(warmCardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isTextFieldFocused
                            ? ReverieColors.accentRed(colorScheme)
                            : ReverieColors.border(colorScheme).opacity(0.6),
                        lineWidth: 1
                    )
            )
        }
    }

    // MARK: - Complete Button

    private var completeButton: some View {
        VStack(spacing: 12) {
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                let reflection = reflectionText.trimmingCharacters(in: .whitespacesAndNewlines)
                onComplete(selectedMood, reflection.isEmpty ? nil : reflection)
                dismiss()
            } label: {
                Text(L("breathing_reflection.complete"))
                    .font(ReverieTypography.buttonPrimary)
                    .tracking(1.5)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(ReverieColors.accentRed(colorScheme))
                    )
            }

            // Skip option
            Button {
                onComplete(nil, nil)
                dismiss()
            } label: {
                Text(L("breathing_reflection.skip"))
                    .font(ReverieTypography.labelMedium)
                    .foregroundColor(ReverieColors.textTertiary(colorScheme))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    BreathingReflectionSheet(
        exercise: .boxBreathing,
        sessionStats: SessionStats(
            exerciseName: "Box Breathing",
            totalDuration: 180,
            cyclesCompleted: 5,
            startTime: Date().addingTimeInterval(-180),
            endTime: Date()
        ),
        preMood: .stressed,
        cyclesTarget: 5,
        onComplete: { mood, reflection in
            breathingReflectionLogger.debug("Mood: \(mood?.rawValue ?? "none"), Reflection: \(reflection ?? "none")")
        }
    )
}
