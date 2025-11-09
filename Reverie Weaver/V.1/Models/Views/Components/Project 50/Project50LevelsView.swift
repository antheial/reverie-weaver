//
// Project50LevelsView.swift
// Reverie Weaver
//
// Created by Antheia Li on 10/23/25.
//

//
// Project50LevelsView.swift
// Reverie Weaver
// Complete Project 50 Progress Dashboard
// Shows: Days elapsed, current level, completion %, level cards, danger zone
// ✅ FIXED: Wired up completion provider for progress tracking
//

import SwiftUI
import SwiftData
import Combine

struct Project50LevelsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var habits: [Habit]
    @Query private var completions: [HabitCompletion]

    @StateObject private var manager = Project50ProgressManager.shared

    @State private var showConfirmUnlock = false
    @State private var unlockTarget: Int?

    @State private var showPreviewLevel: IdentifiableInt?
    @State private var showUnlockLevel: IdentifiableInt?

    @State private var showResetConfirmation = false
    @State private var showDeleteConfirmation = false

    var body: some View {
        ZStack {
            ReverieWeaverBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {

                    // MARK: - Dashboard
                    progressDashboard

                    Divider()
                        .padding(.horizontal, 24)

                    // MARK: - Levels List
                    VStack(spacing: 16) {
                        ForEach(1...3, id: \.self) { level in
                            levelCard(for: level)
                        }
                    }
                    .padding(.horizontal, 20)

                    // MARK: - Danger Zone
                    dangerZoneSection

                    Spacer(minLength: 60)
                }
                .padding(.top, 32)
            }
        }
        .navigationTitle("Project 50 Levels")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
                setupCompletionTracking()
                manager.refreshEligibility()
                // ✅ Force initial progress calculation
                    _ = manager.completion(for: manager.journey.currentLevel)
                }
                // ✅ Refresh progress when completions change
                .onChange(of: completions.count) { oldValue, newValue in
                    manager.refreshEligibility()
                }
                // ✅ Refresh when habits change (affects calculation)
                .onChange(of: habits.count) { oldValue, newValue in
                    setupCompletionTracking()
                    manager.refreshEligibility()
        }
        // Preview sheet
        .sheet(item: $showPreviewLevel) { identifiable in
            Project50OverviewHabits(level: identifiable.value, mode: .preview)
        }
        // Unlock sheet
        .sheet(item: $showUnlockLevel) { identifiable in
            Project50OverviewHabits(level: identifiable.value, mode: .unlock)
        }
        // Reset confirmation
        .alert("Reset Journey?", isPresented: $showResetConfirmation) {
            Button("Reset", role: .destructive) {
                resetJourney()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will reset your progress but keep your habits on your desk. You can continue from where you are.")
        }
        // Delete confirmation
        .alert("Delete All Project 50 Habits?", isPresented: $showDeleteConfirmation) {
            Button("Delete All", role: .destructive) {
                deleteAllProject50Habits()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            let count = habits.filter { $0.programTag == "P50" }.count
            return Text("This will remove all \(count) Project 50 habits from your desk and reset your progress. This cannot be undone.")
        }
    }

    // MARK: - ✅ FIXED: True Daily Consistency Tracking with Correct Progress Calculation
    // Returns daysCap (total days required) to calculate: successfulDays / totalDaysRequired
    private func setupCompletionTracking() {
        manager.completionProvider = { [self] level, levelStartDate in
            // 1. Filter Project 50 habits for this specific level
            let levelHabits = habits.filter { habit in
                guard let tag = habit.programTag else { return false }
                return tag == "P50" && habit.programLevel == level
            }

            let activeHabitsCount = levelHabits.count
            guard activeHabitsCount > 0, let startDate = levelStartDate else {
                return (activeHabitsCount: 0, totalCompletions: 0, daysSinceLevelStartCapped: 0)
            }

            // 2. Calculate elapsed days since this level started
            let calendar = Calendar.current
            let daysSinceStart = calendar.dateComponents([.day], from: startDate, to: Date()).day ?? 0

            // Cap the tracking window based on level duration
            let daysCap: Int
            switch level {
            case 1:
                daysCap = 21  // Level 1: Days 1-21 (21 days)
            case 2:
                daysCap = 29  // Level 2: Days 22-50 (29 days)
            case 3:
                daysCap = 29  // Level 3: Days 51+ (ongoing, but cap at 29 for calculation)
            default:
                daysCap = 21
            }

            let daysSinceLevelStartCapped = min(max(daysSinceStart, 1), daysCap)

            // 3. Identify all relevant completions
            let habitIds = Set(levelHabits.map { $0.id })
            let windowStart = calendar.date(byAdding: .day, value: -daysSinceLevelStartCapped, to: Date()) ?? startDate

            let relevantCompletions = completions.filter { completion in
                habitIds.contains(completion.habitId) &&
                completion.completedAt >= windowStart &&
                completion.completedAt <= Date()
            }

            // 4. Group completions by day
            let groupedByDay = Dictionary(grouping: relevantCompletions) { completion in
                calendar.startOfDay(for: completion.completedAt)
            }

            // 5. Count "successful" days (≥80% of habits done)
            let successfulDays = groupedByDay.values.filter { dayCompletions in
                dayCompletions.count >= Int(Double(activeHabitsCount) * 0.80)
            }.count

            // 6. Return structured data for the manager
            // ✅ FIXED: Return daysCap (total days required) not daysSinceLevelStartCapped (days elapsed)
            // This ensures progress = successfulDays / totalDaysRequired
            return (
                activeHabitsCount: activeHabitsCount,
                totalCompletions: successfulDays,
                daysSinceLevelStartCapped: daysCap  // ✅ Changed from daysSinceLevelStartCapped to daysCap
            )
        }
    }
}

// MARK: - Dashboard Section

private extension Project50LevelsView {

    var progressDashboard: some View {
        VStack(spacing: 12) {
            // Stats row
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Days Elapsed")
                        .font(.system(size: 12, weight: .medium))
                        .adaptiveSecondaryText(colorScheme: colorScheme)
                    Text("\(manager.daysSinceStart)")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.dynamicLabel)
                }
                Spacer()
                VStack(alignment: .leading, spacing: 6) {
                    Text("Current Level")
                        .font(.system(size: 12, weight: .medium))
                        .adaptiveSecondaryText(colorScheme: colorScheme)
                    Text("Level \(manager.journey.currentLevel)")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.dynamicLabel)
                }
                Spacer()
                VStack(alignment: .leading, spacing: 6) {
                    Text("Progress")
                        .font(.system(size: 12, weight: .medium))
                        .adaptiveSecondaryText(colorScheme: colorScheme)
                    let p = Int((manager.completion(for: manager.journey.currentLevel)) * 100)
                    Text("\(p)%")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.dynamicLabel)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(colorScheme == .dark ? 0.1 : 0.35))
                    .shadow(color: Color.shadowColor.opacity(0.15), radius: 5, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.2 : 0.4), lineWidth: 1)
            )
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Level Card

    @ViewBuilder
    func levelCard(for level: Int) -> some View {
        let isUnlocked = manager.journey.unlockedLevels.contains(level)
        let isActive = manager.journey.currentLevel == level
        let completion = manager.completion(for: level)

        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Level \(level)")
                    .font(.system(size: 17, weight: .semibold))
                    .fontDesign(.serif)
                    .foregroundStyle(Color.dynamicLabel)

                Spacer()

                if isActive {
                    Text("Active")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(0.5)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.sageGreen)
                        .clipShape(Capsule())
                } else if isUnlocked {
                    Text("Completed")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(0.5)
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.dynamicSecondaryLabel.opacity(0.5))
                        .clipShape(Capsule())
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 9))
                        Text("Locked")
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(0.5)
                    }
                    .foregroundStyle(Color.dynamicSecondaryLabel.opacity(0.6))
                }
            }

            if isUnlocked {
                // Progress bar
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(Int(completion * 100))% complete")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.dynamicSecondaryLabel)

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.dynamicSecondaryLabel.opacity(0.15))

                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.sageGreen)
                                .frame(width: geometry.size.width * completion)
                        }
                    }
                    .frame(height: 6)
                }
            } else {
                // Requirements for locked levels
                VStack(alignment: .leading, spacing: 8) {
                    Text("Requirements:")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.dynamicSecondaryLabel)

                    if level == 2 {
                        requirementRow(
                            text: "21 days elapsed",
                            isMet: manager.daysSinceStart >= 21
                        )
                        requirementRow(
                            text: "75% of Level 1 complete",
                            isMet: manager.completion(for: 1) >= 0.75
                        )
                    } else if level == 3 {
                        requirementRow(
                            text: "50 days elapsed",
                            isMet: manager.daysSinceStart >= 50
                        )
                        requirementRow(
                            text: "75% of Level 2 complete",
                            isMet: manager.completion(for: 2) >= 0.75
                        )
                    }

                    // Preview button
                    Button {
                        showPreviewLevel = IdentifiableInt(id: level)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "eye")
                                .font(.system(size: 11))
                            Text("Preview")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(Color.dustyBlue.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.dustyBlue.opacity(0.12))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(colorScheme == .dark ? 0.1 : 0.35))
                .shadow(color: Color.shadowColor.opacity(0.12), radius: 4, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(
                    isActive ? Color.sageGreen.opacity(0.4) : Color.white.opacity(colorScheme == .dark ? 0.2 : 0.4),
                    lineWidth: isActive ? 1.5 : 1
                )
        )
    }

    @ViewBuilder
    func requirementRow(text: String, isMet: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 12))
                .foregroundStyle(isMet ? Color.sageGreen : Color.dynamicSecondaryLabel.opacity(0.4))

            Text(text)
                .font(.system(size: 11))
                .foregroundStyle(Color.dynamicSecondaryLabel)
        }
    }

    // MARK: - Danger Zone

    var dangerZoneSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("DANGER ZONE")
                .font(.system(size: 10, weight: .bold))
                .tracking(1)
                .foregroundStyle(Color.terracottaRose)
                .padding(.horizontal, 20)

            VStack(spacing: 10) {
                // Reset button
                Button {
                    showResetConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 13))
                        Text("Reset Journey")
                            .font(.system(size: 13, weight: .medium))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.dynamicSecondaryLabel.opacity(0.5))
                    }
                    .foregroundStyle(Color.dynamicLabel)
                    .padding(14)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.3))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Color.terracottaRose.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                // Delete all button
                Button {
                    showDeleteConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                            .font(.system(size: 13))
                        Text("Delete All Project 50 Habits")
                            .font(.system(size: 13, weight: .medium))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.dynamicSecondaryLabel.opacity(0.5))
                    }
                    .foregroundStyle(Color.terracottaRose)
                    .padding(14)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.terracottaRose.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Color.terracottaRose.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Actions

    func resetJourney() {
        manager.resetJourney()
        ReverieHaptics.lightFeedback()
    }

    func deleteAllProject50Habits() {
        // Delete all habits with programTag == "P50"
        let p50Habits = habits.filter { habit in
            guard let tag = habit.programTag else { return false }
            return tag == "P50"
        }

        for habit in p50Habits {
            modelContext.delete(habit)
        }

        try? modelContext.save()

        // Also reset the journey
        manager.resetJourney()
        ReverieHaptics.lightFeedback()
    }
}


// MARK: - Helper Struct for Identifiable Int

struct IdentifiableInt: Identifiable {
    let id: Int
    var value: Int { id }
}
