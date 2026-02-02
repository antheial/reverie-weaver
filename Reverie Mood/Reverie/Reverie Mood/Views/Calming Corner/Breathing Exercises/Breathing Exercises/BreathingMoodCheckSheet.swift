//
//  BreathingMoodCheckSheet.swift
//  Reverie Mood
//
//  Pre-exercise mood check and cycle selection sheet.
//  Combines mood selection with customizable session length.
//

import SwiftUI
import OSLog

private let breathingMoodCheckLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.reverie.mood", category: "BreathingMoodCheck")

struct BreathingMoodCheckSheet: View {
    let exercise: BreathingExercise
    let onStart: (BreathingMood?, Int) -> Void
    let onCancel: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var selectedMood: BreathingMood?
    @State private var selectedCycles: Int = 5
    @State private var showRecommendation = false

    private let cycleOptions = [3, 5, 7, 10]

    private var progressManager: BreathingProgressManager {
        BreathingProgressManager.shared
    }

    private var isRecommended: Bool {
        guard let mood = selectedMood else { return false }
        return progressManager.isRecommended(exerciseId: exercise.id, for: mood)
    }

    private var recommendedExerciseName: String? {
        guard let mood = selectedMood, !isRecommended else { return nil }
        let recommendedId = progressManager.getRecommendedExercise(for: mood)
        // Map ID to name
        switch recommendedId {
        case "478": return "4-7-8 Breathing"
        case "box": return "Box Breathing"
        case "calm": return "Calm Breathing"
        case "triangle": return "Triangle Breathing"
        case "extended": return "Extended Exhale"
        case "coherent": return "Coherent Breathing"
        case "kapalabhati": return "Kapalabhati"
        default: return nil
        }
    }

    var body: some View {
        ZStack {
            ReverieBackground()

            VStack(spacing: 0) {
                // Header
                headerSection
                    .padding(.top, 20)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 28) {
                        // Exercise info
                        exerciseInfoSection

                        ReverieDivider(.solid)
                            .padding(.horizontal, 24)

                        // Mood check section
                        moodCheckSection

                        // Recommendation hint (if applicable)
                        if let recommendedName = recommendedExerciseName, selectedMood != nil {
                            recommendationHint(recommendedName)
                        }

                        ReverieDivider(.solid)
                            .padding(.horizontal, 24)

                        // Cycle selection
                        cycleSelectionSection

                        // Start button
                        startButton
                            .padding(.top, 8)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text(L("breathing_session.prepare"))
                    .font(ReverieTypography.labelSmall)
                    .tracking(2)
                    .foregroundColor(ReverieColors.textTertiary(colorScheme))

                Spacer()

                Button {
                    onCancel()
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(ReverieColors.textTertiary(colorScheme))
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(warmCardBackground)
                        )
                        .overlay(
                            Circle()
                                .stroke(ReverieColors.border(colorScheme).opacity(0.4), lineWidth: 1)
                        )
                }
            }

            ReverieDivider(.solid)
                .padding(.top, 8)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Exercise Info

    private var exerciseInfoSection: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(warmCardBackground)
                    .frame(width: 56, height: 56)

                RoundedRectangle(cornerRadius: 12)
                    .stroke(ReverieColors.border(colorScheme).opacity(0.6), lineWidth: 1)
                    .frame(width: 56, height: 56)

                Image(systemName: exercise.icon)
                    .font(.system(size: 24))
                    .foregroundColor(exercise.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.custom("Georgia", size: 20))
                    .foregroundColor(ReverieColors.textPrimary(colorScheme))

                HStack(spacing: 12) {
                    Label(exercise.duration, systemImage: "clock")
                    Label(exercise.difficulty, systemImage: "chart.bar")
                }
                .font(ReverieTypography.labelSmall)
                .foregroundColor(ReverieColors.textTertiary(colorScheme))
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }

    // MARK: - Mood Check

    private var moodCheckSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(L("breathing_session.how_feeling"))
                    .font(ReverieTypography.labelSmall)
                    .tracking(2)
                    .foregroundColor(ReverieColors.textTertiary(colorScheme))

                Text(L("breathing_session.optional_mood"))
                    .font(.custom("Georgia-Italic", size: 12))
                    .foregroundColor(ReverieColors.textTertiary(colorScheme).opacity(0.8))
            }

            // Mood grid - 2 columns
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(BreathingMood.allCases) { mood in
                    moodButton(mood)
                }
            }
        }
        .padding(.horizontal, 24)
    }

    // Subtle warm tone for card backgrounds
    private var warmCardBackground: Color {
        ReverieColors.warmCardSurface(colorScheme)
    }

    private func moodButton(_ mood: BreathingMood) -> some View {
        let isSelected = selectedMood == mood

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                if selectedMood == mood {
                    selectedMood = nil
                } else {
                    selectedMood = mood
                }
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: mood.icon)
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .white : mood.color)

                Text(mood.rawValue)
                    .font(ReverieTypography.labelMedium)
                    .foregroundColor(isSelected ? .white : ReverieColors.textPrimary(colorScheme))

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? mood.color : warmCardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? mood.color : ReverieColors.border(colorScheme).opacity(0.6), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Recommendation Hint

    private func recommendationHint(_ recommendedName: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 14))
                .foregroundColor(ReverieColors.accentGold(colorScheme))

            Text(String(format: L("breathing_hint.recommendation"), selectedMood?.rawValue.lowercased() ?? "this mood", recommendedName))
                .font(.custom("Georgia-Italic", size: 13))
                .foregroundColor(ReverieColors.textSecondary(colorScheme))
                .lineSpacing(4)

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(ReverieColors.accentGold(colorScheme).opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(ReverieColors.accentGold(colorScheme).opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 24)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Cycle Selection

    private var cycleSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(L("breathing_session.session_length"))
                    .font(ReverieTypography.labelSmall)
                    .tracking(2)
                    .foregroundColor(ReverieColors.textTertiary(colorScheme))

                Text(L("breathing_session.choose_cycles"))
                    .font(.custom("Georgia-Italic", size: 12))
                    .foregroundColor(ReverieColors.textTertiary(colorScheme).opacity(0.8))
            }

            HStack(spacing: 12) {
                ForEach(cycleOptions, id: \.self) { count in
                    cycleButton(count)
                }
            }

            // Duration estimate
            if let cycleDuration = estimatedCycleDuration {
                let totalSeconds = cycleDuration * Double(selectedCycles)
                let minutes = Int(totalSeconds) / 60
                let seconds = Int(totalSeconds) % 60

                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 11))
                    Text("≈ \(minutes):\(String(format: "%02d", seconds))")
                        .font(ReverieTypography.labelSmall)
                }
                .foregroundColor(ReverieColors.textTertiary(colorScheme))
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, 24)
    }

    private func cycleButton(_ count: Int) -> some View {
        let isSelected = selectedCycles == count
        let isDefault = count == 5

        return Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                selectedCycles = count
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            VStack(spacing: 4) {
                Text("\(count)")
                    .font(.custom("Georgia-Bold", size: 22))
                    .foregroundColor(isSelected ? .white : ReverieColors.textPrimary(colorScheme))

                Text(L("breathing_session.cycles"))
                    .font(ReverieTypography.labelTiny)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : ReverieColors.textTertiary(colorScheme))

                if isDefault && !isSelected {
                    Text(L("breathing_session.default"))
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(ReverieColors.accentRed(colorScheme))
                        .padding(.top, 2)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? ReverieColors.accentRed(colorScheme) : warmCardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? ReverieColors.accentRed(colorScheme) : ReverieColors.border(colorScheme).opacity(0.6), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var estimatedCycleDuration: Double? {
        let totalPhaseTime = exercise.phases.reduce(0.0) { $0 + $1.duration }
        return totalPhaseTime > 0 ? totalPhaseTime : nil
    }

    // MARK: - Start Button

    private var startButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onStart(selectedMood, selectedCycles)
            dismiss()
        } label: {
            HStack(spacing: 12) {
                Text(L("breathing_session.begin_session"))
                    .font(ReverieTypography.buttonPrimary)
                    .tracking(1.5)

                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(ReverieColors.accentRed(colorScheme))
            )
            .shadow(color: ReverieColors.accentRed(colorScheme).opacity(0.3), radius: 8, y: 4)
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Preview

#Preview {
    BreathingMoodCheckSheet(
        exercise: .boxBreathing,
        onStart: { mood, cycles in
            breathingMoodCheckLogger.debug("Starting with mood: \(mood?.rawValue ?? "none"), cycles: \(cycles)")
        },
        onCancel: {}
    )
}
