//
//  MyJourneyView.swift
//  Reverie Weaver
//
//

import SwiftUI
import SwiftData

enum JourneyAlert: Identifiable {
    case reset
    case changeGoal
    case error(message: String)

    var id: String {
        switch self {
        case .reset: return "reset"
        case .changeGoal: return "changeGoal"
        case .error: return "error"
        }
    }
}

struct MyJourneyView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    
    @Bindable var journey: PersonalizedJourney
    
    // For navigation to goal selector after reset
    var onJourneyReset: (() -> Void)?
    
    @State private var activeAlert: JourneyAlert?
    
    @State private var isResetting = false
    @State private var navigationPath = NavigationPath()
    
    // Use selectedChallenge to navigate via sheet instead of navigation destination
    @State private var selectedMiniChallenge: MiniChallenge?
    @State private var selectedThemeWeek: ThemeWeekProgram?
    @State private var showProject50 = false
    @State private var showPlaceholder: String?
    
    // MARK: FIX - Track initial color scheme to prevent auto-dismiss
    @State private var initialColorScheme: ColorScheme?

    // Track if journey was deleted to prevent accessing deleted object
    @State private var journeyDeleted = false

    // Journey completion celebration
    @State private var showCompletionCelebration = false

    // Step unlocking animation tracking
    @State private var previouslyUnlockedStepIDs: Set<UUID> = []
    @State private var newlyUnlockedStepID: UUID?

    /// Check if journey is fully completed (all steps done)
    private var isJourneyComplete: Bool {
        !journey.steps.isEmpty && journey.steps.allSatisfy { $0.isCompleted }
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                // MARK: CHANGED - Added Background
                ReverieWeaverBackground()
                    .id(initialColorScheme)
                
                if !journeyDeleted {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 24) {
                            // Validation Check
                            if journey.goal == nil || journey.steps.isEmpty {
                                errorStateView
                            } else {
                                // Editorial Header
                                editorialHeader

                                // Progress Header
                                progressHeader

                                // Journey Complete Banner (if all steps done)
                                if isJourneyComplete {
                                    journeyCompleteBanner
                                }

                                // Current Step Highlight (only show if not complete)
                                if !isJourneyComplete, let currentStep = journey.currentStep {
                                    currentStepCard(currentStep)
                                }

                                // Full Roadmap
                                roadmapSection

                                // Optional Boosters
                                if !journey.optionalBoosters.isEmpty {
                                    boostersSection
                                }

                                // Reset Journey Button (changes to "Start New Journey" when complete)
                                resetButton
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("My Journey")
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("My Journey")
                        .font(.custom("Georgia", size: 18))
                        .fontWeight(.semibold)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .medium))
                            Text("Close")
                                .font(.system(size: 15, weight: .medium))
                        }
                    }
                    .disabled(isResetting)
                }
            }
            // Use navigationDestination for Project50 only (it doesn't have nested NavigationStack issue)
            .navigationDestination(isPresented: $showProject50) {
                Project50LevelsView()
            }
            .alert(item: $activeAlert) { alert in
                switch alert {
                case .reset:
                    return Alert(
                        title: Text("Reset Your Journey?"),
                        message: Text("This will delete your current journey progress completely. You can start fresh anytime."),
                        primaryButton: .destructive(Text("Reset & Delete"), action: {
                            resetJourney(archiveFirst: false)
                        }),
                        secondaryButton: .cancel()
                    )
                case .changeGoal:
                    return Alert(
                        title: Text(isJourneyComplete ? "Start a New Journey?" : "Change Your Goal?"),
                        message: Text(isJourneyComplete
                            ? "Your completed journey will be saved to your history. Ready to begin a new adventure?"
                            : "Your current progress will be saved to your history. You can then choose a new goal."),
                        primaryButton: .default(Text(isJourneyComplete ? "Start New" : "Change Goal"), action: {
                            resetJourney(archiveFirst: true)
                        }),
                        secondaryButton: .cancel()
                    )
                case .error(let message):
                    return Alert(
                        title: Text("Error"),
                        message: Text(message),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
            .disabled(isResetting)
        }
        .sheet(item: $selectedMiniChallenge) { challenge in
            MiniChallengeDetailView(challenge: challenge)
        }
        .sheet(item: $selectedThemeWeek) { program in
            ThemeWeekDetailView(program: program)
        }
        .sheet(item: $showPlaceholder) { programTag in
            PlaceholderChallengeView(programTag: programTag)
        }
        .sheet(isPresented: $showCompletionCelebration) {
            JourneyCompletionCelebrationSheet(journey: journey)
        }
        .onAppear {
            // Store initial color scheme on first appear
            if initialColorScheme == nil {
                initialColorScheme = colorScheme
            }

            // Initialize unlocked step tracking
            previouslyUnlockedStepIDs = Set(journey.steps.filter { $0.isUnlocked }.map { $0.id })

            JourneyProgressManager.shared.syncJourneyProgress(in: modelContext)
        }
        .onChange(of: journey.steps) { _, newSteps in
            // Detect newly unlocked steps
            let currentlyUnlockedIDs = Set(newSteps.filter { $0.isUnlocked }.map { $0.id })
            let newlyUnlocked = currentlyUnlockedIDs.subtracting(previouslyUnlockedStepIDs)

            if let newID = newlyUnlocked.first {
                // Trigger celebration animation
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    newlyUnlockedStepID = newID
                }

                // Haptic feedback
                ReverieHaptics.successFeedback()

                // Clear the animation after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        newlyUnlockedStepID = nil
                    }
                }
            }

            // Update tracking
            previouslyUnlockedStepIDs = currentlyUnlockedIDs
        }
    }
    
    // MARK: - Editorial Header
    
    private var editorialHeader: some View {
        VStack(spacing: 16) {
            // Editorial-style header
            Text("YOUR PERSONALIZED PATH")
                .font(.custom("Georgia", size: 12))
                .fontWeight(.semibold)
                .tracking(1.2)
                .multilineTextAlignment(.center)
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                .frame(maxWidth: .infinity)
            
            // Divider
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.primary.opacity(0.35))
                    .frame(height: 1)
                
                Spacer()
                    .frame(width: 30)
                
                Image(systemName: "star.fill")
                    .font(.system(size: 14, weight: .medium))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                
                Spacer()
                    .frame(width: 30)
                
                Rectangle()
                    .fill(Color.primary.opacity(0.2))
                    .frame(height: 1)
            }
        }
        .padding(.bottom, 4)
    }
    
    // MARK: - Error State View
    
    private var errorStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Journey Data Error")
                .font(.custom("Georgia", size: 20))
                .fontWeight(.semibold)
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
            
            Text("There was an issue loading your journey. Please reset and create a new journey.")
                .font(.custom("Georgia", size: 14))
                .multilineTextAlignment(.center)
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                .padding(.horizontal)
            
            Button {
               activeAlert = .reset
            } label: {
                HStack(spacing: 8) {
                    Text("Reset Journey")
                        .font(.system(size: 15, weight: .semibold))
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [Color.orange, Color.orange.opacity(0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(color: Color.orange.opacity(0.3), radius: 8, y: 4)
            }
            .padding(.horizontal, 20)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Progress Header
    
    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                // Icon with background
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(hex: journey.goal?.color ?? "9B7EBD").opacity(0.25),
                                    Color(hex: journey.goal?.color ?? "9B7EBD").opacity(0.1),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 20
                            )
                        )
                        .frame(width: 40, height: 40)
                        .blur(radius: 6)
                    
                    Circle()
                        .fill(Color(hex: journey.goal?.color ?? "9B7EBD").opacity(colorScheme == .dark ? 0.2 : 0.15))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    Color(hex: journey.goal?.color ?? "9B7EBD").opacity(0.5),
                                    lineWidth: 1
                                )
                        )
                    
                    Image(systemName: journey.goal?.icon ?? "star.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color(hex: journey.goal?.color ?? "9B7EBD"))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(journey.goal?.rawValue ?? "")
                        .font(.custom("Georgia", size: 22))
                        .fontWeight(.semibold)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    
                    Text(journey.totalDuration)
                        .font(.custom("Georgia", size: 13))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                }
                Spacer()
            }
            
            // Progress Section Card
            VStack(alignment: .leading, spacing: 10) {
                Text("Progress")
                    .font(.custom("Georgia", size: 15))
                    .fontWeight(.semibold)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                
                // Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.primary.opacity(0.1))
                            .frame(height: 10)
                        
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(hex: journey.goal?.color ?? "9B7EBD"),
                                        Color(hex: journey.goal?.color ?? "9B7EBD").opacity(0.8)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(0, geometry.size.width * journey.progressPercentage), height: 10)
                    }
                }
                .frame(height: 10)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Journey progress")
                .accessibilityValue("\(Int(journey.progressPercentage * 100)) percent complete")
                
                HStack {
                    Text("\(Int(journey.progressPercentage * 100))% Complete")
                        .font(.custom("Georgia", size: 13))
                        .fontWeight(.medium)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    Spacer()
                    Text("\(journey.steps.filter { $0.isCompleted }.count) / \(journey.steps.count) steps")
                        .font(.custom("Georgia", size: 12))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                }
                .accessibilityElement(children: .combine)
            }
            .padding(16)
            .reverieCardStyle(
                colorScheme: colorScheme,
                cornerRadius: 16
            )
        }
    }
    
    // MARK: - Current Step Card
    
    private func currentStepCard(_ step: JourneyStep) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Up Next")
                    .font(.custom("Georgia", size: 12))
                    .fontWeight(.semibold)
                    .textCase(.uppercase)
                    .tracking(1.2)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                Spacer()
                
                if JourneyProgressManager.shared.isChallengeActive(step.programTag, in: modelContext) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        Text("In Progress")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.green)
                    }
                } else {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundColor(Color(hex: journey.goal?.color ?? "9B7EBD"))
                        .font(.system(size: 20))
                        .accessibilityHidden(true)
                }
            }
            
            Text(step.title)
                .font(.custom("Georgia", size: 18))
                .fontWeight(.semibold)
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
            
            Text(step.reason)
                .font(.custom("Georgia", size: 14))
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.custom("Georgia", size: 12))
                    .accessibilityHidden(true)
                Text(step.duration)
                    .font(.custom("Georgia", size: 12))
            }
            .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Duration: \(step.duration)")
            
            Button {
                navigateToChallenge(programTag: step.programTag)
            } label: {
                HStack(spacing: 8) {
                    Text(JourneyProgressManager.shared.isChallengeActive(step.programTag, in: modelContext) ? "Continue Challenge" : "Start This Challenge")
                        .font(.system(size: 15, weight: .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(colorScheme == .dark ? .black.opacity(0.8) : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: journey.goal?.color ?? "9B7EBD"),
                                    Color(hex: journey.goal?.color ?? "9B7EBD").opacity(0.85)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(
                    color: Color(hex: journey.goal?.color ?? "9B7EBD").opacity(0.3),
                    radius: 8,
                    y: 4
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Start \(step.title)")
            .accessibilityHint("Navigate to this challenge")
            .padding(.top, 4)
        }
        .padding(16)
        .reverieCardStyle(
            colorScheme: colorScheme,
            cornerRadius: 16
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    Color(hex: journey.goal?.color ?? "9B7EBD").opacity(0.4),
                    lineWidth: 1.5
                )
        )
        .accessibilityElement(children: .contain)
    }
    
    // MARK: - Roadmap Section
    
    private var roadmapSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Your Roadmap")
                    .font(.custom("Georgia", size: 18))
                    .fontWeight(.semibold)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 20) {
                ForEach(Array(journey.steps.enumerated()), id: \.element.id) { index, step in
                    HStack(alignment: .top, spacing: 12) {
                        // Status Indicator with Challenge Icon
                        ZStack {
                            // Celebration glow for newly unlocked steps
                            if newlyUnlockedStepID == step.id {
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [
                                                Color(hex: journey.goal?.color ?? "9B7EBD").opacity(0.5),
                                                Color(hex: journey.goal?.color ?? "9B7EBD").opacity(0.2),
                                                Color.clear
                                            ],
                                            center: .center,
                                            startRadius: 0,
                                            endRadius: 25
                                        )
                                    )
                                    .frame(width: 50, height: 50)
                                    .blur(radius: 8)
                                    .transition(.scale.combined(with: .opacity))
                            }

                            Circle()
                                .fill(stepBackgroundColor(for: step))
                                .frame(width: 32, height: 32)

                            Circle()
                                .strokeBorder(stepColor(for: step).opacity(0.5), lineWidth: 1.5)
                                .frame(width: 32, height: 32)

                            if step.isCompleted {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            } else if step.isUnlocked {
                                if JourneyProgressManager.shared.isChallengeActive(step.programTag, in: modelContext) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(stepColor(for: step))
                                } else {
                                    Image(systemName: iconForProgramTag(step.programTag))
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(stepColor(for: step))
                                        // Scale animation for newly unlocked
                                        .scaleEffect(newlyUnlockedStepID == step.id ? 1.2 : 1.0)
                                        .animation(.spring(response: 0.4, dampingFraction: 0.5), value: newlyUnlockedStepID)
                                }
                            } else {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color.gray.opacity(0.8))
                            }
                        }
                        .accessibilityHidden(true)
                        
                        // Step Details
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(step.title)
                                    .font(.custom("Georgia", size: 14))
                                    .fontWeight(.medium)
                                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                                
                                if !step.isCompleted && step.isUnlocked &&
                                   JourneyProgressManager.shared.isChallengeActive(step.programTag, in: modelContext) {
                                    Text("Active")
                                        .font(.system(size: 9, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(Color.green))
                                }
                            }
                            
                            Text(step.reason)
                                .font(.custom("Georgia", size: 12))
                                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.system(size: 10))
                                Text(step.duration)
                                    .font(.custom("Georgia", size: 11))
                            }
                            .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                        }
                        
                        Spacer()
                    }
                    .opacity(step.isUnlocked || step.isCompleted ? 1.0 : 0.5)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Step \(index + 1): \(step.title). \(step.reason). Duration: \(step.duration)")
                    .accessibilityValue(step.isCompleted ? "Completed" : (step.isUnlocked ? "Available" : "Locked"))
                    
                    // Connector Line
                    if index < journey.steps.count - 1 {
                        Rectangle()
                            .fill(Color.primary.opacity(0.15))
                            .frame(width: 2, height: 20)
                            .padding(.leading, 15)
                            .accessibilityHidden(true)
                    }
                }
            }
            .padding(16)
            .reverieCardStyle(colorScheme: colorScheme)
        }
    }
    
    // MARK: - Boosters Section
    
    private var boostersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Optional Boosters")
                .font(.custom("Georgia", size: 16))
                .fontWeight(.semibold)
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
            
            Text("Add these anytime to supercharge your journey")
                .font(.custom("Georgia", size: 12))
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
            
            FlowLayout(spacing: 8) {
                ForEach(journey.optionalBoosters, id: \.self) { tag in
                    Text(programDisplayName(for: tag))
                        .font(.custom("Georgia", size: 12))
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.primary.opacity(0.05))
                        )
                        .overlay(
                            Capsule()
                                .strokeBorder(
                                    Color.primary.opacity(0.1),
                                    lineWidth: 0.5
                                )
                        )
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                }
            }
        }
        .padding(16)
        .reverieCardStyle(
            colorScheme: colorScheme,
            cornerRadius: 16
        )
    }
    
    // MARK: - Reset Button
    
    // MARK: - Journey Complete Banner

    private var journeyCompleteBanner: some View {
        VStack(spacing: 16) {
            // Celebration Icon
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: journey.goal?.color ?? "9B7EBD").opacity(0.3),
                                Color(hex: journey.goal?.color ?? "9B7EBD").opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 30
                        )
                    )
                    .frame(width: 56, height: 56)
                    .blur(radius: 8)

                Circle()
                    .fill(Color(hex: journey.goal?.color ?? "9B7EBD").opacity(colorScheme == .dark ? 0.25 : 0.2))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Circle()
                            .strokeBorder(Color(hex: journey.goal?.color ?? "9B7EBD").opacity(0.5), lineWidth: 1.5)
                    )

                Image(systemName: "star.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color(hex: journey.goal?.color ?? "9B7EBD"))
            }

            VStack(spacing: 6) {
                Text("Journey Complete! 🎉")
                    .font(.custom("Georgia", size: 20))
                    .fontWeight(.bold)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

                Text("You've completed all \(journey.steps.count) steps of your \(journey.goal?.rawValue ?? "") journey.")
                    .font(.custom("Georgia", size: 14))
                    .multilineTextAlignment(.center)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // View Celebration Details Button
            Button {
                showCompletionCelebration = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 13))
                    Text("View Your Achievement")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(colorScheme == .dark ? .black.opacity(0.8) : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: journey.goal?.color ?? "9B7EBD"),
                                    Color(hex: journey.goal?.color ?? "9B7EBD").opacity(0.85)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(
                    color: Color(hex: journey.goal?.color ?? "9B7EBD").opacity(0.3),
                    radius: 6,
                    y: 3
                )
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .reverieCardStyle(colorScheme: colorScheme, cornerRadius: 16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    Color(hex: journey.goal?.color ?? "9B7EBD").opacity(0.4),
                    lineWidth: 1.5
                )
        )
    }

    // MARK: - Journey Management Buttons

    private var resetButton: some View {
        VStack(spacing: 10) {
            // Change Goal button (archives current journey, starts new one)
            Button {
                activeAlert = .changeGoal
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: isJourneyComplete ? "sparkles" : "arrow.triangle.swap")
                        .font(.system(size: 13))
                    Text(isJourneyComplete ? "Start a New Journey" : "Change Goal")
                        .font(.custom("Georgia", size: 14))
                        .fontWeight(.medium)
                }
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: journey.goal?.color ?? "9B7EBD").opacity(colorScheme == .dark ? 0.15 : 0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            Color(hex: journey.goal?.color ?? "9B7EBD").opacity(0.3),
                            lineWidth: 0.5
                        )
                )
            }
            .accessibilityLabel(isJourneyComplete ? "Start a New Journey" : "Change Goal")
            .accessibilityHint("Archive current journey and choose a new goal")

            // Reset/Delete button (only show if not complete - for starting fresh)
            if !isJourneyComplete {
                Button {
                    activeAlert = .reset
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12))
                        Text("Reset Progress")
                            .font(.custom("Georgia", size: 13))
                    }
                    .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                }
                .accessibilityLabel("Reset Progress")
                .accessibilityHint("Delete current journey and start fresh")
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Navigation Helper
    
    private func navigateToChallenge(programTag: String) {
        // 1. Check Project 50 first
        if programTag == "Project50" {
            showProject50 = true
            return
        }
        
        // 2. Check Theme Week Programs
        if let themeWeek = ThemeWeekData.programs.first(where: { $0.tag == programTag }) {
            selectedThemeWeek = themeWeek
            return
        }
        
        // 3. Check Mini Challenges
        if let challenge = MiniChallengeData.challenges.first(where: { $0.tag == programTag }) {
            selectedMiniChallenge = challenge
            return
        }
        
        // 4. Fallback for unrecognized tags
        showPlaceholder = programTag
    }
    
    // MARK: - Helpers
    
    /// Returns the icon for a given program tag
    private func iconForProgramTag(_ tag: String) -> String {
        // Check Mini Challenges first
        if let challenge = MiniChallengeData.challenges.first(where: { $0.tag == tag }) {
            return challenge.icon
        }
        
        // Check Theme Weeks
        if let themeWeek = ThemeWeekData.programs.first(where: { $0.tag == tag }) {
            return themeWeek.icon
        }
        
        // Project 50
        if tag == "Project50" {
            return "sparkles"
        }
        
        // Fallback
        return "circle.fill"
    }
    
    private func stepColor(for step: JourneyStep) -> Color {
        if step.isCompleted {
            return .green
        } else if step.isUnlocked {
            return Color(hex: journey.goal?.color ?? "9B7EBD")
        } else {
            // MARK: CHANGED - Safer color for locked state
            return Color.gray
        }
    }
    
    private func stepBackgroundColor(for step: JourneyStep) -> Color {
        if step.isCompleted {
            return .green.opacity(0.9)
        } else if step.isUnlocked {
            return Color(hex: journey.goal?.color ?? "9B7EBD").opacity(0.15)
        } else {
            // MARK: CHANGED - Safer background for locked state
            return Color.gray.opacity(0.1)
        }
    }
    
    private func programDisplayName(for tag: String) -> String {
        // Use ChallengeRouter for consistent display names across the app
        return ChallengeRouter.displayName(for: tag)
    }
    
    /// Reset the journey with optional archiving
    /// - Parameter archiveFirst: If true, marks journey as inactive (archived) instead of deleting
    private func resetJourney(archiveFirst: Bool = false) {
        guard !isResetting else { return }
        isResetting = true

        Task { @MainActor in
            do {
                if !navigationPath.isEmpty {
                    navigationPath.removeLast(navigationPath.count)
                    // Small delay to ensure navigation is cleared
                    try? await Task.sleep(nanoseconds: 50_000_000)
                }

                if archiveFirst {
                    // Archive the journey instead of deleting - preserves history
                    journey.isActive = false
                    journey.archivedDate = Date()

                    #if DEBUG
                    print("📦 Journey archived: \(journey.goal?.rawValue ?? "Unknown")")
                    #endif
                } else {
                    // Delete the journey completely
                    journeyDeleted = true
                    modelContext.delete(journey)

                    #if DEBUG
                    print("🗑️ Journey deleted successfully")
                    #endif
                }

                try modelContext.save()

                ReverieHaptics.successFeedback()

                onJourneyReset?()

                if onJourneyReset == nil {
                    isResetting = false
                    dismiss()
                }

            } catch {
                if !archiveFirst {
                    journeyDeleted = false
                }
                isResetting = false
                activeAlert = .error(message: "Failed to update journey. Please try again.")
                #if DEBUG
                print("❌ Failed to update journey: \(error.localizedDescription)")
                #endif
            }
        }
    }
}

// MARK: - Journey Completion Celebration Sheet

struct JourneyCompletionCelebrationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let journey: PersonalizedJourney

    private var accentColor: Color {
        Color(hex: journey.goal?.color ?? "9B7EBD")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ReverieWeaverBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        // Trophy Animation Area
                        ZStack {
                            // Radiating circles
                            ForEach(0..<3) { i in
                                Circle()
                                    .stroke(accentColor.opacity(0.15 - Double(i) * 0.04), lineWidth: 1)
                                    .frame(width: CGFloat(100 + i * 40), height: CGFloat(100 + i * 40))
                            }

                            // Main trophy circle
                            ZStack {
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [
                                                accentColor.opacity(0.4),
                                                accentColor.opacity(0.15),
                                                Color.clear
                                            ],
                                            center: .center,
                                            startRadius: 0,
                                            endRadius: 50
                                        )
                                    )
                                    .frame(width: 90, height: 90)
                                    .blur(radius: 10)

                                Circle()
                                    .fill(accentColor.opacity(colorScheme == .dark ? 0.25 : 0.2))
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(accentColor.opacity(0.5), lineWidth: 2)
                                    )

                                Image(systemName: "trophy.fill")
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [accentColor, accentColor.opacity(0.7)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            }
                        }
                        .frame(height: 160)
                        .padding(.top, 20)

                        // Title Section
                        VStack(spacing: 8) {
                            Text("Congratulations!")
                                .font(.custom("Georgia", size: 28))
                                .fontWeight(.bold)
                                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

                            Text("You've completed your \(journey.goal?.rawValue ?? "") journey")
                                .font(.custom("Georgia", size: 16))
                                .multilineTextAlignment(.center)
                                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        }

                        // Stats Card
                        VStack(spacing: 16) {
                            HStack(spacing: 24) {
                                statItem(
                                    value: "\(journey.steps.count)",
                                    label: "Steps Completed",
                                    icon: "checkmark.circle.fill"
                                )

                                statItem(
                                    value: journey.totalDuration,
                                    label: "Journey Duration",
                                    icon: "clock.fill"
                                )
                            }

                            Divider()
                                .padding(.horizontal, 20)

                            // Steps Summary
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Your Completed Path")
                                    .font(.system(size: 13, weight: .semibold))
                                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)

                                ForEach(journey.steps, id: \.id) { step in
                                    HStack(spacing: 10) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 14))
                                            .foregroundStyle(.green)

                                        Text(step.title)
                                            .font(.system(size: 13))
                                            .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

                                        Spacer()

                                        Text(step.duration)
                                            .font(.system(size: 11))
                                            .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                                    }
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                        .padding(20)
                        .reverieCardStyle(colorScheme: colorScheme, cornerRadius: 16)

                        // Encouragement Message
                        Text("\"The journey of self-improvement never truly ends—it simply evolves. You've built lasting habits and gained insights that will serve you for years to come.\"")
                            .font(.custom("Georgia", size: 14))
                            .italic()
                            .multilineTextAlignment(.center)
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                            .padding(.horizontal, 20)

                        // Done Button
                        Button {
                            dismiss()
                        } label: {
                            Text("Continue")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(colorScheme == .dark ? .black.opacity(0.8) : .white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            LinearGradient(
                                                colors: [accentColor, accentColor.opacity(0.85)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                )
                                .shadow(color: accentColor.opacity(0.3), radius: 8, y: 4)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Achievement Unlocked")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .presentationDetents([.large, .fraction(0.85)])
        .presentationDragIndicator(.visible)
    }

    private func statItem(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(accentColor)

            Text(value)
                .font(.system(size: 20, weight: .bold))
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

            Text(label)
                .font(.system(size: 11))
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - String Extension for Identifiable

extension String: @retroactive Identifiable {
    public var id: String { self }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: PersonalizedJourney.self, configurations: config)
    
    let journey = JourneyTemplates.journey(for: .betterFocus)
    container.mainContext.insert(journey)
    
    return MyJourneyView(journey: journey)
        .modelContainer(container)
}
