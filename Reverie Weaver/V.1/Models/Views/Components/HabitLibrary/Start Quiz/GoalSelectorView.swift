//
//  GoalSelectorView.swift
//  Reverie Weaver
//
//  Onboarding quiz to help users choose their journey
//
//  ✅ FIXED: White circles now show goal color
//  ✅ FIXED: Optional booster capsules now visible
//  ✅ FIXED: Navigation flow simplified - HabitLibraryView handles MyJourneyView presentation
//

import SwiftUI
import SwiftData

struct GoalSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedGoal: UserGoal?
    @State private var showJourneyPreview = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var isCreatingJourney = false
    
    // MARK: FIX - Track initial color scheme to prevent auto-dismiss
    @State private var initialColorScheme: ColorScheme?
    
    var onJourneyCreated: (PersonalizedJourney) -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                ReverieWeaverBackground()
                    .id(initialColorScheme) // Prevents re-render on color scheme change
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header with Newspaper/Ink Style
                        VStack(spacing: 16) {
                            // Editorial-style header
                            Text("YOUR JOURNEY STARTS HERE")
                                .font(.custom("Georgia", size: 23))
                                .fontWeight(.semibold)
                                .tracking(1.2)
                                .multilineTextAlignment(.center)
                                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 12)
                            
                            // Divider
                            HStack(spacing: 0) {
                                Rectangle()
                                    .fill(Color.dynamicSecondaryLabel.opacity(0.4))
                                    .frame(height: 1)
                                
                                Spacer()
                                    .frame(width: 30)
                                
                                Image(systemName: "star.fill")
                                    .font(.system(size: 14, weight: .medium))
                                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                                
                                Spacer()
                                    .frame(width: 30)
                                
                                Rectangle()
                                    .fill(Color.dynamicSecondaryLabel.opacity(0.4))
                                    .frame(height: 1)
                            }
                            
                            // ✅ NEW: Progress Indicators
                            progressIndicators
                            
                            headerSection
                        }
                        
                        // Goal Cards (Updated with Spotlight Effect)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(UserGoal.allCases, id: \.self) { goal in
                                let isSpotlightActive = selectedGoal != nil
                                let isSelected = selectedGoal == goal
                                
                                GoalCard(
                                    goal: goal,
                                    isSelected: isSelected,
                                    onSelect: {
                                        // ✅ ENHANCED: Haptic feedback for selection
                                        if !isSelected {
                                            let generator = UIImpactFeedbackGenerator(style: .medium)
                                            generator.impactOccurred()
                                        }
                                        
                                        withAnimation(.spring(response: 0.3)) {
                                            selectedGoal = goal
                                        }
                                    }
                                )
                                // ✨ UX: Spotlight Effect
                                .scaleEffect(isSelected ? 1.05 : (isSpotlightActive ? 0.95 : 1.0))
                                .opacity(isSpotlightActive && !isSelected ? 0.4 : 1.0)
                                .blur(radius: isSpotlightActive && !isSelected ? 2 : 0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedGoal)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Continue Button
                        if selectedGoal != nil {
                            continueButton
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        
                        // ✅ NEW: Skip Option
                        skipButton
                            .transition(.opacity)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Choose Your Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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
                    .disabled(isCreatingJourney)
                }
            }
            // ✅ FIX: Pass goal color to JourneyPreviewView
            .sheet(isPresented: $showJourneyPreview) {
                if let goal = selectedGoal {
                    JourneyPreviewView(
                        journey: JourneyTemplates.journey(for: goal),
                        goalColor: goal.color,  // ✅ Pass color explicitly
                        onConfirm: {
                            createJourney(for: goal)
                        },
                        isLoading: $isCreatingJourney
                    )
                }
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .disabled(isCreatingJourney)
        }
        .onAppear {
            // Store initial color scheme on first appear
            if initialColorScheme == nil {
                initialColorScheme = colorScheme
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("What matters most to you right now?")
                .font(.custom("Georgia", size: 16))
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                .padding(.horizontal, 20)
            
            Text("Choose one goal to start your personalized journey")
                .font(.custom("Georgia", size: 13))
                .multilineTextAlignment(.center)
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                .padding(.horizontal, 30)
        }
        .padding(.bottom, 4)
    }
    
    // MARK: - ✅ NEW: Progress Indicators
    
    private var progressIndicators: some View {
        HStack(spacing: 8) {
            // Step 1: Select Goal (current)
            progressDot(isActive: true, isCompleted: selectedGoal != nil)
            
            progressLine(isCompleted: selectedGoal != nil)
            
            // Step 2: Preview Journey
            progressDot(isActive: false, isCompleted: false)
            
            progressLine(isCompleted: false)
            
            // Step 3: Start Journey
            progressDot(isActive: false, isCompleted: false)
        }
        .padding(.horizontal, 60)
        .padding(.vertical, 12)
    }
    
    private func progressDot(isActive: Bool, isCompleted: Bool) -> some View {
        Circle()
            .fill(
                isCompleted || isActive
                    ? Color(hex: selectedGoal?.color ?? "9B7EBD")
                    : Color.gray.opacity(0.3)
            )
            .frame(width: isActive ? 10 : 8, height: isActive ? 10 : 8)
            .overlay(
                Circle()
                    .strokeBorder(
                        isActive ? Color(hex: selectedGoal?.color ?? "9B7EBD").opacity(0.3) : Color.clear,
                        lineWidth: 3
                    )
            )
            .animation(.spring(response: 0.3), value: isActive)
            .animation(.spring(response: 0.3), value: isCompleted)
    }
    
    private func progressLine(isCompleted: Bool) -> some View {
        Capsule()
            .fill(
                isCompleted
                    ? Color(hex: selectedGoal?.color ?? "9B7EBD")
                    : Color.gray.opacity(0.3)
            )
            .frame(height: 2)
            .animation(.spring(response: 0.3), value: isCompleted)
    }
    
    // MARK: - Continue Button
    
    private var continueButton: some View {
        Button {
            guard selectedGoal != nil else { return }
            // ✅ ENHANCED: Success haptic
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            showJourneyPreview = true
        } label: {
            HStack(spacing: 8) {
                if isCreatingJourney {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Text("Creating...")
                        .font(.system(size: 15, weight: .semibold))
                } else {
                    Text("See My Journey")
                        .font(.system(size: 15, weight: .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: selectedGoal?.color ?? "9B7EBD"),
                                Color(hex: selectedGoal?.color ?? "9B7EBD").opacity(0.85)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .shadow(
                color: Color(hex: selectedGoal?.color ?? "9B7EBD").opacity(0.3),
                radius: 8,
                y: 4
            )
        }
        .disabled(isCreatingJourney)
        .padding(.horizontal, 20)
        .accessibilityLabel(isCreatingJourney ? "Creating your journey" : "See My Journey")
        .accessibilityHint(isCreatingJourney ? "" : "View personalized journey for selected goal")
    }
    
    // MARK: - ✅ NEW: Skip Button (Browse Challenges Alternative)

    private var skipButton: some View {
        Button {
            // ✅ Light haptic for skip
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            dismiss()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 13))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Browse Challenges")
                        .font(.system(size: 14, weight: .medium))

                    Text("Explore habits at your own pace")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.primary.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
        .padding(.horizontal, 20)
    }
    
    // MARK: - Actions
    
    private func createJourney(for goal: UserGoal) {
        guard !isCreatingJourney else { return }
        isCreatingJourney = true
        
        Task { @MainActor in
            do {
                let journey = JourneyTemplates.journey(for: goal)
                
                // Validate journey has required data
                guard journey.goal != nil, !journey.steps.isEmpty else {
                    throw JourneyCreationError.invalidData
                }
                
                modelContext.insert(journey)
                try modelContext.save()
                
                print("✅ Journey created and saved for goal: \(goal.rawValue)")
                
                // Small delay for better UX
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                
                isCreatingJourney = false
                
                // ✅ FIX: Dismiss the preview sheet first
                showJourneyPreview = false
                
                // ✅ FIX: Call the callback - HabitLibraryView will handle navigation
                onJourneyCreated(journey)
                
                // ✅ FIX: Dismiss GoalSelectorView after callback
                // HabitLibraryView's callback will show MyJourneyView
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    dismiss()
                }
                
            } catch let error as JourneyCreationError {
                isCreatingJourney = false
                errorMessage = error.localizedDescription
                showErrorAlert = true
            } catch {
                isCreatingJourney = false
                errorMessage = "Failed to create your journey. Please try again."
                showErrorAlert = true
                print("Failed to save journey: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Journey Creation Error

enum JourneyCreationError: LocalizedError {
    case invalidData
    case saveFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidData:
            return "Journey data is incomplete. Please try selecting a different goal."
        case .saveFailed:
            return "Failed to save your journey. Please try again."
        }
    }
}

// MARK: - Goal Card

struct GoalCard: View {
    let goal: UserGoal
    let isSelected: Bool
    let onSelect: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    // Animation State
    @State private var rotation: Double = 0
    
    var body: some View {
        VStack(spacing: 7) {  // ✅ REFINED: Reduced from 10pt to 7pt
            // Icon with background circle - SMALLER
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: goal.color).opacity(0.25),
                                Color(hex: goal.color).opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 20  // ✅ REFINED: Reduced from 24
                        )
                    )
                    .frame(width: 40, height: 40)  // ✅ REFINED: Reduced from 48
                    .blur(radius: 4)  // ✅ REFINED: Reduced from 5
                
                Circle()
                    .fill(Color(hex: goal.color).opacity(colorScheme == .dark ? 0.2 : 0.15))
                    .frame(width: 38, height: 38)  // ✅ REFINED: Reduced from 44
                    .overlay(
                        Circle()
                            .strokeBorder(
                                Color(hex: goal.color).opacity(isSelected ? 0.6 : 0.4),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
                
                Image(systemName: goal.icon)
                    .font(.system(size: 18, weight: .semibold))  // ✅ REFINED: Reduced from 20
                    .foregroundStyle(Color(hex: goal.color))
            }
            
            // Title - Slightly smaller
            Text(goal.rawValue)
                .font(.system(size: 13, weight: .semibold))  // ✅ REFINED: Reduced from 14
                .fontDesign(.serif)
                .multilineTextAlignment(.center)
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(2)
            
            // Subtitle - More compact
            Text(goal.subtitle)
                .font(.system(size: 10, weight: .regular))  // ✅ REFINED: Reduced from 11
                .multilineTextAlignment(.center)
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(2)
                .lineSpacing(-1)  // ✅ REFINED: Tighter line spacing
            
            // Time Commitment Badge - More compact
            HStack(spacing: 3) {  // ✅ REFINED: Reduced from 4
                Image(systemName: "clock")
                    .font(.system(size: 8))  // ✅ REFINED: Reduced from 9
                Text(goal.dailyCommitment)
                    .font(.system(size: 9, weight: .medium))  // ✅ REFINED: Reduced from 10
            }
            .foregroundStyle(Color(hex: goal.color))
            .padding(.horizontal, 7)  // ✅ REFINED: Reduced from 8
            .padding(.vertical, 3)  // ✅ REFINED: Reduced from 4
            .background(
                Capsule()
                    .fill(Color(hex: goal.color).opacity(colorScheme == .dark ? 0.2 : 0.15))
                    .overlay(
                        Capsule()
                            .strokeBorder(Color(hex: goal.color).opacity(0.3), lineWidth: 0.5)
                    )
            )
        }
        .padding(.vertical, 11)  // ✅ REFINED: Reduced from 14
        .padding(.horizontal, 8)  // ✅ REFINED: Reduced from 10
        .frame(maxWidth: .infinity, minHeight: 145)  // ✅ REFINED: Reduced from 170 to 145
        // Base Card Style
        .reverieCardStyle(
            colorScheme: colorScheme,
            cornerRadius: 16,
            backgroundOpacity: isSelected ? (colorScheme == .dark ? 0.35 : 0.30) : nil
        )
        // 1. Static Base Border (always visible, faint)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    Color(hex: goal.color).opacity(isSelected ? 0.0 : 0.3), // Hide when glowing to avoid clash
                    lineWidth: 1
                )
        )
        // 2. The Glowing Trailing Border (Only when selected)
        .overlay(
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: goal.color).opacity(0.0), // Tail (Transparent)
                                    Color(hex: goal.color).opacity(0.0),
                                    Color(hex: goal.color).opacity(0.1),
                                    Color(hex: goal.color),              // Head (Bright)
                                    Color(hex: goal.color).opacity(0.1),
                                    Color(hex: goal.color).opacity(0.0)  // Fade out
                                ]),
                                center: .center,
                                startAngle: .degrees(rotation),
                                endAngle: .degrees(rotation + 360)
                            ),
                            lineWidth: 2.5
                        )
                }
            }
        )
        .shadow(
            color: isSelected ? Color(hex: goal.color).opacity(0.25) : Color.clear,
            radius: isSelected ? 10 : 0,
            x: 0,
            y: isSelected ? 4 : 0
        )
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        // 3. Animation Triggers
        .onAppear {
            startRotation()
        }
        .onChange(of: isSelected) { _, newValue in
            if newValue {
                rotation = 0
                startRotation()
            }
        }
        .onTapGesture {
            onSelect()  // ✅ Use closure instead of direct action
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(goal.rawValue). \(goal.subtitle). Daily commitment: \(goal.dailyCommitment)")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityHint(isSelected ? "Selected" : "Double tap to select this goal")
    }
    
    // ✅ Helper function MUST be inside the struct
    private func startRotation() {
        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
            rotation = 360
        }
    }
}

// MARK: - Journey Preview View
// ✅ FIXED: Now accepts goalColor parameter for proper circle colors

struct JourneyPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    let journey: PersonalizedJourney
    let goalColor: String  // ✅ FIX: Explicit color parameter
    let onConfirm: () -> Void
    @Binding var isLoading: Bool
    
    // MARK: FIX - Track initial color scheme to prevent auto-dismiss
    @State private var initialColorScheme: ColorScheme?
    
    var body: some View {
        NavigationStack {
            ZStack {
                ReverieWeaverBackground()
                    .id(initialColorScheme) // Prevents re-render on color scheme change
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        headerSection
                        
                        // Steps
                        stepsSection
                        
                        // Optional Boosters
                        if !journey.optionalBoosters.isEmpty {
                            boostersSection
                        }
                        
                        // Confirm Button
                        confirmButton
                    }
                    .padding(20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Your Journey")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .medium))
                            Text("Back")
                                .font(.system(size: 15, weight: .medium))
                        }
                    }
                    .disabled(isLoading)
                }
            }
            .disabled(isLoading)
        }
        .onAppear {
            // Store initial color scheme on first appear
            if initialColorScheme == nil {
                initialColorScheme = colorScheme
            }
        }
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    // Icon with background
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color(hex: goalColor).opacity(0.25),
                                        Color(hex: goalColor).opacity(0.1),
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
                            .fill(Color(hex: goalColor).opacity(colorScheme == .dark ? 0.2 : 0.15))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Circle()
                                    .strokeBorder(
                                        Color(hex: goalColor).opacity(0.5),
                                        lineWidth: 1
                                    )
                            )
                        
                        Image(systemName: journey.goal?.icon ?? "star.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color(hex: goalColor))
                    }
                    
                    Text(journey.goal?.rawValue ?? "")
                        .font(.system(size: 24, weight: .semibold))
                        .fontDesign(.serif)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                }
                
                // Dynamic Effort Assurance Badge
                            HStack(spacing: 12) {
                                Text(journey.totalDuration)
                                    .font(.subheadline)
                                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "hourglass")
                                        .font(.system(size: 10))
                                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                                    
                                    // Uses the goal-specific time estimate
                                    Text("\(journey.goal?.dailyCommitment ?? "~15 mins") / day")
                                        .font(.system(size: 11, weight: .medium))
                                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color(hex: goalColor).opacity(0.1))
                                .overlay(
                                    Capsule().strokeBorder(Color(hex: goalColor).opacity(0.3), lineWidth: 1)
                                )
                                .foregroundStyle(Color.primary.opacity(0.8))
                                .clipShape(Capsule())
                            }
                
                Divider()
                    .padding(.vertical, 4)
            }
        }
    
    private var stepsSection: some View {
            VStack(alignment: .leading, spacing: 0) { // ✅ Spacing 0 for continuous line
                Text("Your Roadmap")
                    .font(.headline)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    .padding(.bottom, 16)
                
                ForEach(Array(journey.steps.enumerated()), id: \.element.id) { index, step in
                    JourneyStepRow(
                        step: step,
                        stepNumber: index + 1,
                        accentColorHex: goalColor,
                        isLast: index == journey.steps.count - 1 // ✅ Pass isLast for line logic
                    )
                }
            }
        }
    
    private var boostersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Optional Boosters")
                .font(.headline)
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
            
            Text("Add these anytime to supercharge your journey")
                .font(.caption)
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
            
            FlowLayout(spacing: 8) {
                ForEach(journey.optionalBoosters, id: \.self) { tag in
                    // ✅ FIX: Visible booster capsules with proper styling
                    Text(programDisplayName(for: tag))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.9) : .primary.opacity(0.8))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color(hex: goalColor).opacity(colorScheme == .dark ? 0.25 : 0.15))
                        )
                        .overlay(
                            Capsule()
                                .strokeBorder(Color(hex: goalColor).opacity(0.4), lineWidth: 0.5)
                        )
                }
            }
        }
    }
    
    private var confirmButton: some View {
        Button {
            guard !isLoading else { return }
            onConfirm()
        } label: {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Text("Creating Your Journey...")
                        .font(.system(size: 15, weight: .semibold))
                } else {
                    Text("Start My Journey")
                        .font(.system(size: 15, weight: .semibold))
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: goalColor),
                                Color(hex: goalColor).opacity(0.85)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .shadow(
                color: Color(hex: goalColor).opacity(0.3),
                radius: 8,
                y: 4
            )
        }
        .disabled(isLoading)
        .accessibilityLabel(isLoading ? "Creating your journey" : "Start My Journey")
        .accessibilityHint(isLoading ? "" : "Confirm and begin your personalized journey")
    }
    
    // MARK: - Helpers

    private func programDisplayName(for tag: String) -> String {
        // Use ChallengeRouter for consistent display names across the app
        return ChallengeRouter.displayName(for: tag)
    }
}

// MARK: - Journey Step Row
// ✅ ENHANCED: Better visual timeline with gradient and pulse effects

struct JourneyStepRow: View {
    let step: JourneyStep
    let stepNumber: Int
    let accentColorHex: String
    let isLast: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // ✅ LEFT COLUMN: Enhanced Number Circle + Connector Line
            VStack(spacing: 0) {
                // Enhanced Number Circle with Glow
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(hex: accentColorHex).opacity(0.3),
                                    Color(hex: accentColorHex).opacity(0.1),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 20
                            )
                        )
                        .frame(width: 40, height: 40)
                        .blur(radius: 4)
                    
                    // Main circle with gradient
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: accentColorHex),
                                    Color(hex: accentColorHex).opacity(0.85)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle()
                                .strokeBorder(Color.white.opacity(0.3), lineWidth: 2)
                        )
                        .shadow(color: Color(hex: accentColorHex).opacity(0.4), radius: 6, y: 3)
                    
                    Text("\(stepNumber)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
                
                // Enhanced Vertical Line (Only if not last step)
                if !isLast {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: accentColorHex).opacity(0.7),
                                    Color(hex: accentColorHex).opacity(0.4),
                                    Color(hex: accentColorHex).opacity(0.1)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 3)  // Thicker line
                        .frame(minHeight: 50)  // Taller minimum for better connection
                        .padding(.vertical, 4)  // Spacing around the line
                }
            }
            .frame(width: 32)  // Fixed width for alignment
            
            // RIGHT COLUMN: Text Content with Enhanced Spacing
            VStack(alignment: .leading, spacing: 6) {
                Text(step.title)
                    .font(.system(size: 15, weight: .semibold))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    .padding(.top, 6)  // Align with circle center
                
                Text(step.reason)
                    .font(.system(size: 13))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
                
                // Duration badge
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                    Text(step.duration)
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(Color(hex: accentColorHex))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color(hex: accentColorHex).opacity(colorScheme == .dark ? 0.2 : 0.12))
                        .overlay(
                            Capsule()
                                .strokeBorder(Color(hex: accentColorHex).opacity(0.3), lineWidth: 0.5)
                        )
                )
                .padding(.bottom, isLast ? 0 : 16)  // Extra spacing between steps
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Step \(stepNumber): \(step.title). \(step.reason). Duration: \(step.duration)")
    }
}

// MARK: - Flow Layout Helper

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(
                at: CGPoint(
                    x: bounds.minX + result.positions[index].x,
                    y: bounds.minY + result.positions[index].y
                ),
                proposal: .unspecified
            )
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

// MARK: - Previews

#Preview("Goal Selector") {
    GoalSelectorView { journey in
        print("Journey created: \(journey.goal?.rawValue ?? "Unknown")")
    }
}

#Preview("Goal Card - Selected") {
    GoalCard(goal: .betterFocus, isSelected: true, onSelect: {
        print("Goal selected")
    })
    .padding()
    .frame(width: 180)
}

#Preview("Goal Card - Unselected") {
    GoalCard(goal: .reduceAnxiety, isSelected: false, onSelect: {
        print("Goal selected")
    })
    .padding()
    .frame(width: 180)
}

#Preview("Journey Preview") {
    @Previewable @State var isLoading = false
    
    return JourneyPreviewView(
        journey: JourneyTemplates.journey(for: .reduceAnxiety),
        goalColor: UserGoal.reduceAnxiety.color,
        onConfirm: {
            isLoading = true
        },
        isLoading: $isLoading
    )
}
