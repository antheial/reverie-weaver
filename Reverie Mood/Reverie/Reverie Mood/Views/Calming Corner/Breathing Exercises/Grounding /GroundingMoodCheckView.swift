//
//  GroundingMoodCheckView.swift
//  Reverie Mood
//
//  Pre-exercise mood check for grounding exercises
//

import SwiftUI
import OSLog

private let moodCheckLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.reverie.mood", category: "GroundingMoodCheck")

struct GroundingMoodCheckView: View {
    let technique: GroundingTechnique
    let onContinue: (Int) -> Void
    let onDismiss: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedGroundedness: Int? = nil
    @State private var isExpanded = false

    private let moodEmojis = ["😰", "😟", "😐", "🙂", "😊"]
    private let moodLabels = [
        "Very ungrounded",
        "Somewhat ungrounded",
        "Neutral",
        "Somewhat grounded",
        "Very grounded"
    ]

    var body: some View {
        ZStack {
            // Warm background
            ReverieColors.background(colorScheme)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Close button
                    HStack {
                        Spacer()
                        Button(action: onDismiss) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(ReverieColors.textSecondary(colorScheme))
                                .frame(width: 32, height: 32)
                                .background(
                                    Circle()
                                        .fill(ReverieColors.textPrimary(colorScheme).opacity(0.08))
                                )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                    // Main content
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: technique.icon)
                                .font(.system(size: 40))
                                .foregroundColor(ReverieColors.accent(colorScheme))
                                .padding(.bottom, 8)

                            Text(technique.title)
                                .font(.custom("Georgia", size: 24))
                                .tracking(-0.3)
                                .foregroundColor(ReverieColors.textPrimary(colorScheme))
                                .multilineTextAlignment(.center)

                            Text("Before we begin...")
                                .font(.custom("Georgia-Italic", size: 14))
                                .foregroundColor(ReverieColors.textSecondary(colorScheme))
                        }
                        .padding(.top, 24)

                        // Question card
                        VStack(spacing: 24) {
                            Text("How grounded do you feel right now?")
                                .font(.custom("Georgia", size: 18))
                                .tracking(-0.2)
                                .foregroundColor(ReverieColors.textPrimary(colorScheme))
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)

                            // Emoji scale
                            HStack(spacing: 16) {
                                ForEach(1...5, id: \.self) { level in
                                    moodButton(level: level)
                                }
                            }
                            .padding(.vertical, 8)

                            // Label for selected mood
                            if let selected = selectedGroundedness {
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

                        // Continue button
                        if selectedGroundedness != nil {
                            Button(action: {
                                guard let selected = selectedGroundedness else { return }
                                ReverieHaptics.light()
                                onContinue(selected)
                            }) {
                                HStack(spacing: 8) {
                                    Text("Begin Exercise")
                                        .font(ReverieTypography.labelMedium)
                                        .tracking(1.2)

                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(ReverieColors.textPrimary(colorScheme))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: ReverieLayout.Radius.medium)
                                        .fill(ReverieColors.accent(colorScheme).opacity(0.12))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: ReverieLayout.Radius.medium)
                                        .stroke(ReverieColors.accent(colorScheme).opacity(0.3), lineWidth: 1)
                                )
                            }
                            .padding(.horizontal, 24)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }

                        Spacer(minLength: 40)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isExpanded = true
            }
        }
    }

    private func moodButton(level: Int) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedGroundedness = level
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
                        selectedGroundedness == level
                            ? ReverieColors.accent(colorScheme).opacity(0.15)
                            : ReverieColors.textPrimary(colorScheme).opacity(0.04)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: ReverieLayout.Radius.small)
                    .stroke(
                        selectedGroundedness == level
                            ? ReverieColors.accent(colorScheme).opacity(0.4)
                            : Color.clear,
                        lineWidth: 2
                    )
            )
            .scaleEffect(selectedGroundedness == level ? 1.05 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
struct GroundingMoodCheckView_Previews: PreviewProvider {
    static var previews: some View {
        GroundingMoodCheckView(
            technique: .boxBreathing,
            onContinue: { mood in
                moodCheckLogger.debug("Selected mood: \(mood)")
            },
            onDismiss: {
                moodCheckLogger.debug("Dismissed")
            }
        )
    }
}
