//
//  GuidedExerciseView.swift
//  Reverie Mood
//
//  Visual progress indicators for guided grounding exercises
//

import SwiftUI
import OSLog

private let guidedExerciseLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.reverie.mood", category: "GuidedExercise")

struct GuidedExerciseView: View {
    let technique: GroundingTechnique
    let groundednessBefore: Int
    let onComplete: () -> Void
    var onDismiss: (() -> Void)? // Optional dismiss callback

    @StateObject private var audioManager = GroundingAudioManager()
    @Environment(\.colorScheme) private var colorScheme
    @State private var hasCompleted = false
    @State private var showExitConfirmation = false

    var body: some View {
        ZStack {
            // Warm background
            ReverieColors.background(colorScheme)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Audio controls header
                audioControlsHeader
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 20)

                ScrollView {
                    VStack(spacing: 28) {
                        // Technique title
                        VStack(spacing: 8) {
                            Image(systemName: technique.icon)
                                .font(.system(size: 32))
                                .foregroundColor(ReverieColors.accent(colorScheme))

                            Text(technique.title)
                                .font(.custom("Georgia", size: 22))
                                .tracking(-0.3)
                                .foregroundColor(ReverieColors.textPrimary(colorScheme))
                                .multilineTextAlignment(.center)
                        }

                        // Technique-specific visual guide
                        techniqueVisualGuide
                            .padding(.horizontal, 24)

                        // Progress bar
                        progressBar
                            .padding(.horizontal, 24)
                            .padding(.bottom, 32)
                    }
                    .padding(.top, 12)
                }
            }
        }
        .onAppear {
            startExercise()
        }
        .onDisappear {
            audioManager.stop()
        }
    }

    // MARK: - Audio Controls Header

    private var audioControlsHeader: some View {
        HStack(spacing: 16) {
            // Exit button
            Button(action: {
                showExitConfirmation = true
                ReverieHaptics.light()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(ReverieColors.textSecondary(colorScheme))
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(ReverieColors.textPrimary(colorScheme).opacity(0.08))
                    )
            }
            .alert("Exit Exercise?", isPresented: $showExitConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Exit", role: .destructive) {
                    audioManager.stop()
                    if let onDismiss = onDismiss {
                        onDismiss()
                    }
                }
            } message: {
                Text("Your progress won't be saved if you exit now.")
            }

            // Mute toggle (uses built-in Apple voice guidance)
            Button(action: {
                audioManager.toggleMute()
                ReverieHaptics.light()
            }) {
                Image(systemName: audioManager.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(ReverieColors.textSecondary(colorScheme))
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(ReverieColors.textPrimary(colorScheme).opacity(0.08))
                    )
            }

            // Timer
            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .font(.system(size: 13))
                    .foregroundColor(ReverieColors.textTertiary(colorScheme))

                Text("\(audioManager.formattedElapsedTime) / \(audioManager.formattedTotalTime)")
                    .font(ReverieTypography.labelSmall)
                    .tracking(0.8)
                    .foregroundColor(ReverieColors.textSecondary(colorScheme))
                    .monospacedDigit()
            }

            Spacer()
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PROGRESS")
                .font(ReverieTypography.labelTiny)
                .tracking(1.2)
                .foregroundColor(ReverieColors.textTertiary(colorScheme))

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(ReverieColors.textPrimary(colorScheme).opacity(0.08))
                        .frame(height: 8)

                    // Progress fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(ReverieColors.accent(colorScheme).opacity(0.7))
                        .frame(width: geometry.size.width * audioManager.progressPercentage, height: 8)
                        .animation(.linear(duration: 1), value: audioManager.progressPercentage)
                }
            }
            .frame(height: 8)

            // Percentage
            Text("\(Int(audioManager.progressPercentage * 100))%")
                .font(ReverieTypography.labelSmall)
                .foregroundColor(ReverieColors.textSecondary(colorScheme))
                .monospacedDigit()
        }
    }

    // MARK: - Technique-Specific Visual Guides

    @ViewBuilder
    private var techniqueVisualGuide: some View {
        switch technique {
        case .fiveFourThreeTwoOne:
            fiveSensesVisual
        case .boxBreathing:
            breathingCircleVisual
        case .threeTrueThings:
            threeTruthsVisual
        case .gentleSelfSoothe:
            gentleSelfSootheVisual
        case .safePlace:
            safePlaceVisual
        case .selfCompassion:
            selfCompassionVisual
        case .categoriesGame, .progressiveMuscleRelaxation, .butterflyHug, .coldWaterReset, .groundingWalk, .shakeItOut, .alphabetGrounding, .orienting, .quickThreeTwoOne, .quickTenBreaths, .quickPalmsPress, .quickOneTruth:
            // Placeholder for new techniques - guided mode not yet implemented
            genericTechniqueVisual
        }
    }

    private var genericTechniqueVisual: some View {
        VStack(spacing: 16) {
            Image(systemName: technique.icon)
                .font(.system(size: 48))
                .foregroundColor(technique.color)

            Text(technique.title)
                .font(ReverieTypography.headlineSmall)
                .foregroundColor(ReverieColors.textPrimary(colorScheme))

            Text("Follow the audio guidance")
                .font(ReverieTypography.bodySmall)
                .foregroundColor(ReverieColors.textSecondary(colorScheme))
        }
        .padding(24)
        .background(
            ReverieCardSurface(
                cornerRadius: ReverieLayout.Radius.large,
                includeBorder: false,
                includeTexture: true
            )
        )
    }

    // MARK: - Five Senses Checklist

    private var fiveSensesVisual: some View {
        VStack(spacing: 20) {
            senseChecklistItem(emoji: "👁️", title: "5 things you see", step: 0)
            senseChecklistItem(emoji: "👂", title: "4 things you hear", step: 1)
            senseChecklistItem(emoji: "✋", title: "3 things you can touch", step: 2)
            senseChecklistItem(emoji: "👃", title: "2 things you smell", step: 3)
            senseChecklistItem(emoji: "👅", title: "1 thing you taste", step: 4)
        }
        .padding(24)
        .background(
            ReverieCardSurface(
                cornerRadius: ReverieLayout.Radius.large,
                includeBorder: false,
                includeTexture: true
            )
        )
    }

    private func senseChecklistItem(emoji: String, title: String, step: Int) -> some View {
        HStack(spacing: 14) {
            Text(emoji)
                .font(.system(size: 28))

            Text(title)
                .font(.custom("Georgia", size: 16))
                .foregroundColor(ReverieColors.textPrimary(colorScheme))

            Spacer()

            if audioManager.currentStep > step {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(ReverieColors.accent(colorScheme))
                    .transition(.scale.combined(with: .opacity))
            } else {
                Circle()
                    .stroke(ReverieColors.textTertiary(colorScheme).opacity(0.3), lineWidth: 2)
                    .frame(width: 22, height: 22)
            }
        }
        .opacity(audioManager.currentStep >= step ? 1.0 : 0.5)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: audioManager.currentStep)
    }

    // MARK: - Breathing Circle

    private var breathingCircleVisual: some View {
        VStack(spacing: 32) {
            ZStack {
                // Outer ring
                Circle()
                    .stroke(ReverieColors.accent(colorScheme).opacity(0.2), lineWidth: 2)
                    .frame(width: 200, height: 200)

                // Breathing circle
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                ReverieColors.accent(colorScheme).opacity(0.4),
                                ReverieColors.accent(colorScheme).opacity(0.2)
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 100
                        )
                    )
                    .frame(width: breathingCircleSize, height: breathingCircleSize)
                    .animation(.easeInOut(duration: 4), value: breathingCircleSize)

                // Phase label
                Text(breathingPhase)
                    .font(.custom("Georgia", size: 18))
                    .foregroundColor(ReverieColors.textPrimary(colorScheme))
            }

            // Instructions
            Text(breathingInstructions)
                .font(.custom("Georgia-Italic", size: 14))
                .foregroundColor(ReverieColors.textSecondary(colorScheme))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(32)
        .background(
            ReverieCardSurface(
                cornerRadius: ReverieLayout.Radius.large,
                includeBorder: false,
                includeTexture: true
            )
        )
    }

    private var breathingCircleSize: CGFloat {
        let cycleStep = audioManager.currentStep % 4
        switch cycleStep {
        case 0: return 80  // Inhale - expanding
        case 1: return 120 // Hold (full)
        case 2: return 80  // Exhale - contracting
        case 3: return 80  // Hold (empty)
        default: return 80
        }
    }

    private var breathingPhase: String {
        let cycleStep = audioManager.currentStep % 4
        switch cycleStep {
        case 0: return "Inhale"
        case 1: return "Hold"
        case 2: return "Exhale"
        case 3: return "Hold"
        default: return "Breathe"
        }
    }

    private var breathingInstructions: String {
        "Breathe in for 4, hold for 4,\nbreathe out for 4, hold for 4"
    }

    // MARK: - Three Truths Cards

    private var threeTruthsVisual: some View {
        VStack(spacing: 16) {
            ForEach(0..<3, id: \.self) { index in
                truthCard(number: index + 1, isActive: audioManager.currentStep > index)
            }
        }
        .padding(24)
        .background(
            ReverieCardSurface(
                cornerRadius: ReverieLayout.Radius.large,
                includeBorder: false,
                includeTexture: true
            )
        )
    }

    private func truthCard(number: Int, isActive: Bool) -> some View {
        HStack(spacing: 14) {
            Text("\(number)")
                .font(.custom("Georgia", size: 24))
                .foregroundColor(isActive ? ReverieColors.accent(colorScheme) : ReverieColors.textTertiary(colorScheme))
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(isActive ? ReverieColors.accent(colorScheme).opacity(0.15) : ReverieColors.textPrimary(colorScheme).opacity(0.05))
                )

            Text("One true thing about right now...")
                .font(.custom("Georgia-Italic", size: 15))
                .foregroundColor(isActive ? ReverieColors.textPrimary(colorScheme) : ReverieColors.textTertiary(colorScheme))
                .lineLimit(1)

            Spacer()

            if isActive {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(ReverieColors.accent(colorScheme))
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: ReverieLayout.Radius.medium)
                .fill(isActive ? ReverieColors.accent(colorScheme).opacity(0.06) : Color.clear)
        )
        .opacity(isActive ? 1.0 : 0.5)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isActive)
    }

    // MARK: - Gentle Self-Soothe Visual

    private var gentleSelfSootheVisual: some View {
        VStack(spacing: 24) {
            Image(systemName: "hands.sparkles.fill")
                .font(.system(size: 56))
                .foregroundColor(ReverieColors.accent(colorScheme).opacity(0.7))

            VStack(spacing: 16) {
                sootheStep(icon: "hand.point.up.left.fill", text: "Place hand on chest", step: 0)
                sootheStep(icon: "wind", text: "Feel the warmth of your touch", step: 1)
                sootheStep(icon: "heart.fill", text: "Breathe slowly and gently", step: 2)
                sootheStep(icon: "sparkles", text: "Notice sensations of comfort", step: 3)
            }

            Text("Physical touch signals safety to your nervous system")
                .font(.custom("Georgia-Italic", size: 13))
                .foregroundColor(ReverieColors.textSecondary(colorScheme))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(32)
        .background(
            ReverieCardSurface(
                cornerRadius: ReverieLayout.Radius.large,
                includeBorder: false,
                includeTexture: true
            )
        )
    }

    private func sootheStep(icon: String, text: String, step: Int) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(audioManager.currentStep > step ? ReverieColors.accent(colorScheme) : ReverieColors.textTertiary(colorScheme))
                .frame(width: 28)

            Text(text)
                .font(.custom("Georgia", size: 15))
                .foregroundColor(audioManager.currentStep > step ? ReverieColors.textPrimary(colorScheme) : ReverieColors.textTertiary(colorScheme))

            Spacer()

            if audioManager.currentStep > step {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(ReverieColors.accent(colorScheme))
                    .transition(.scale)
            }
        }
        .opacity(audioManager.currentStep >= step ? 1.0 : 0.5)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: audioManager.currentStep)
    }

    // MARK: - Safe Place Visual

    private var safePlaceVisual: some View {
        VStack(spacing: 24) {
            Image(systemName: "figure.mind.and.body")
                .font(.system(size: 56))
                .foregroundColor(ReverieColors.accent(colorScheme).opacity(0.7))

            VStack(spacing: 16) {
                visualizationStep(text: "Close your eyes gently", step: 0)
                visualizationStep(text: "Picture a place that feels safe", step: 1)
                visualizationStep(text: "Notice colors, sounds, textures", step: 2)
                visualizationStep(text: "Feel the peace of this place", step: 3)
                visualizationStep(text: "Stay here as long as you need", step: 4)
            }

            Text("Your mind can create sanctuary anywhere")
                .font(.custom("Georgia-Italic", size: 13))
                .foregroundColor(ReverieColors.textSecondary(colorScheme))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(32)
        .background(
            ReverieCardSurface(
                cornerRadius: ReverieLayout.Radius.large,
                includeBorder: false,
                includeTexture: true
            )
        )
    }

    private func visualizationStep(text: String, step: Int) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(audioManager.currentStep > step ? ReverieColors.accent(colorScheme).opacity(0.3) : ReverieColors.textTertiary(colorScheme).opacity(0.2))
                .frame(width: 8, height: 8)

            Text(text)
                .font(.custom("Georgia", size: 15))
                .foregroundColor(audioManager.currentStep > step ? ReverieColors.textPrimary(colorScheme) : ReverieColors.textTertiary(colorScheme))

            Spacer()

            if audioManager.currentStep > step {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(ReverieColors.accent(colorScheme))
                    .transition(.scale)
            }
        }
        .opacity(audioManager.currentStep >= step ? 1.0 : 0.5)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: audioManager.currentStep)
    }

    // MARK: - Self-Compassion Visual

    private var selfCompassionVisual: some View {
        VStack(spacing: 24) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 56))
                .foregroundColor(ReverieColors.accent(colorScheme).opacity(0.7))

            VStack(spacing: 16) {
                compassionPrompt(text: "This is a moment of difficulty", step: 0)
                compassionPrompt(text: "Difficulty is part of being human", step: 1)
                compassionPrompt(text: "May I be kind to myself", step: 2)
                compassionPrompt(text: "May I give myself what I need", step: 3)
            }

            Text("Speak to yourself with the kindness you'd offer a friend")
                .font(.custom("Georgia-Italic", size: 13))
                .foregroundColor(ReverieColors.textSecondary(colorScheme))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(32)
        .background(
            ReverieCardSurface(
                cornerRadius: ReverieLayout.Radius.large,
                includeBorder: false,
                includeTexture: true
            )
        )
    }

    private func compassionPrompt(text: String, step: Int) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "quote.opening")
                .font(.system(size: 12))
                .foregroundColor(audioManager.currentStep > step ? ReverieColors.accent(colorScheme).opacity(0.5) : ReverieColors.textTertiary(colorScheme).opacity(0.3))
                .frame(width: 20)

            Text(text)
                .font(.custom("Georgia-Italic", size: 15))
                .foregroundColor(audioManager.currentStep > step ? ReverieColors.textPrimary(colorScheme) : ReverieColors.textTertiary(colorScheme))

            Spacer()

            if audioManager.currentStep > step {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(ReverieColors.accent(colorScheme))
                    .transition(.scale)
            }
        }
        .opacity(audioManager.currentStep >= step ? 1.0 : 0.5)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: audioManager.currentStep)
    }

    // MARK: - Exercise Logic

    private func startExercise() {
        // Start audio guidance
        audioManager.playGuide(for: technique)

        // Start step timer with technique-specific duration and steps
        audioManager.startStepTimer(
            totalSteps: technique.stepCount,
            duration: technique.durationInSeconds,
            onComplete: {
                completeExercise()
            }
        )
    }

    private func completeExercise() {
        guard !hasCompleted else { return }
        hasCompleted = true

        // Play completion haptic
        ReverieHaptics.success()

        // Stop audio
        audioManager.stop()

        // Notify completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            onComplete()
        }
    }
}

// MARK: - Preview
struct GuidedExerciseView_Previews: PreviewProvider {
    static var previews: some View {
        GuidedExerciseView(
            technique: .fiveFourThreeTwoOne,
            groundednessBefore: 2,
            onComplete: {
                guidedExerciseLogger.debug("Exercise completed")
            }
        )
    }
}
