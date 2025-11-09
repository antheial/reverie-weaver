//
//  AchievementsView.swift
//  Reverie Weaver
//
//  ✨ UPDATED (Pomodoro achievements removed)
//  - Keeps aesthetic + grid layout
//  - Uses time-adaptive background/text
//  - Calls manager without pomodoro dependency
//

import SwiftUI
import SwiftData

struct AchievementsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext

    // Core data sources
    @Query private var completions: [HabitCompletion]
    @Query private var habits: [Habit]
    @Query private var miniChallengeProgress: [MiniChallengeProgress]

    // If you store planned rest days, wire them here; empty Set is safe default.
    // @Query private var restPlans: [RestPlan]

    @StateObject private var achievementManager = AchievementManager.shared

    var body: some View {
        ZStack {
            ReverieWeaverBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    header

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        ForEach(AchievementType.allCases, id: \.self) { achievement in
                            achievementCard(for: achievement)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 60)
                }
            }
        }
        .onAppear { updateAchievements() }
    }

    // MARK: - Header
    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.paleMauve)

                Text("Achievements")
                    .font(.system(size: 14, weight: .semibold))
                    .fontDesign(.serif)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

                Spacer()
            }

            Text("Your milestones — unlocked through focus and consistency.")
                .font(.system(size: 11))
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    // MARK: - Achievement Card
    private func achievementCard(for type: AchievementType) -> some View {
        let isUnlocked = achievementManager.isUnlocked(type)
        let repeatCount = achievementManager.repeatCount(for: type)

        return VStack(spacing: 6) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: icon(for: type))
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(isUnlocked ? color(for: type) : Color.dynamicSecondaryLabel.opacity(0.3))
                    .padding(10)
                    .background(
                        Circle()
                            .fill(isUnlocked ? color(for: type).opacity(0.15) : Color.dynamicSecondaryLabel.opacity(0.05))
                    )

                if isUnlocked, repeatCount > 1, !type.isOneTime {
                    Text("×\(repeatCount)")
                        .font(.system(size: 9, weight: .semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(color(for: type).opacity(0.18)))
                        .offset(x: 6, y: -6)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                }
            }

            Text(title(for: type))
                .font(.system(size: 11, weight: .semibold))
                .fontDesign(.serif)
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                .multilineTextAlignment(.center)

            Text(description(for: type))
                .font(.system(size: 9))
                .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal, 4)
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .reverieCardStyle(colorScheme: colorScheme, cornerRadius: 16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(isUnlocked ? color(for: type).opacity(0.5) : Color.clear, lineWidth: 1)
        )
        .opacity(isUnlocked ? 1 : 0.6)
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: isUnlocked)
    }

    // MARK: - Update Achievements
    private func updateAchievements() {
        // let planned = Set(restPlans.map { Calendar.current.startOfDay(for: $0.date) })
        let planned = Set<Date>()

        achievementManager.attachContext(modelContext)
        achievementManager.checkAchievements(
            completions: completions,
            habits: habits,
            miniChallengeProgress: miniChallengeProgress,
            plannedRestDays: planned
        )
    }

    // MARK: - Card Helpers (Pomodoro cases removed)
    private func icon(for type: AchievementType) -> String {
        switch type {
        case .firstHabit: return "sparkles"
        case .perfectDay: return "checkmark.seal.fill"
        case .streak7: return "flame.fill"
        case .streak30: return "flame.circle.fill"
        case .earlyBird: return "sunrise.fill"
        case .milestone10: return "leaf.fill"
        case .milestone50: return "circle.grid.cross.fill"
        case .milestone100: return "trophy.fill"
        case .weekWarrior: return "calendar"
        case .monthMaster: return "calendar.circle.fill"
        case .consistency: return "hourglass"
        case .perfectMorning: return "sunrise"
        case .nightOwl: return "moon.stars.fill"
        case .evenSplit: return "circle.lefthalf.filled"
        case .p50Kickoff: return "sparkles"
        case .miniChallengeFinisher: return "flag.checkered"
        case .gracefulReturn: return "arrow.uturn.left.circle"
        case .mindfulRest: return "bed.double"
        }
    }

    private func title(for type: AchievementType) -> String {
        switch type {
        case .firstHabit: return "First Step"
        case .perfectDay: return "Perfect Day"
        case .streak7: return "7-Day Streak"
        case .streak30: return "30-Day Streak"
        case .earlyBird: return "Early Bird"
        case .milestone10: return "10 Threads"
        case .milestone50: return "50 Threads"
        case .milestone100: return "100 Threads"
        case .weekWarrior: return "Week Warrior"
        case .monthMaster: return "Month Master"
        case .consistency: return "Consistency"
        case .perfectMorning: return "Perfect Morning"
        case .nightOwl: return "Night Owl"
        case .evenSplit: return "Even Split"
        case .p50Kickoff: return "Kickoff P50"
        case .miniChallengeFinisher: return "Focus Sprint Finisher"
        case .gracefulReturn: return "Graceful Return"
        case .mindfulRest: return "Mindful Rest"
        }
    }

    private func description(for type: AchievementType) -> String {
        switch type {
        case .firstHabit: return "Start your first habit journey."
        case .perfectDay: return "Complete all habits in a single day."
        case .streak7: return "Maintain a 7-day completion streak."
        case .streak30: return "Sustain discipline for 30 days straight."
        case .earlyBird: return "Complete a habit before 8 AM."
        case .milestone10: return "Weave 10 total threads."
        case .milestone50: return "Weave 50 total threads."
        case .milestone100: return "Weave 100 total threads."
        case .weekWarrior: return "Complete every habit for one week."
        case .monthMaster: return "Complete 75% of habits for one month."
        case .consistency: return "Complete habits for 21+ consecutive days."
        case .perfectMorning: return "Finish any two habits before 10am."
        case .nightOwl: return "Complete a habit after 10pm."
        case .evenSplit: return "One morning habit and one evening habit in a day."
        case .p50Kickoff: return "Complete all 7 Project 50 habits (lifetime)."
        case .miniChallengeFinisher: return "Finish a 7-day mini challenge."
        case .gracefulReturn: return "Log a completion after a 3-day break."
        case .mindfulRest: return "Plan a rest day, then complete 4+ habits next day."
        }
    }

    private func color(for type: AchievementType) -> Color {
        switch type {
        case .firstHabit: return .paleMauve
        case .perfectDay: return .sageGreen
        case .streak7: return .terracottaRose
        case .streak30: return .dustyBlue
        case .earlyBird: return .sunriseOrange
        case .milestone10: return .sageGreen
        case .milestone50: return .dustyBlue
        case .milestone100: return .paleMauve
        case .weekWarrior: return .sageGreen
        case .monthMaster: return .dustyBlue
        case .consistency: return .terracottaRose
        case .perfectMorning: return .sunriseOrange
        case .nightOwl: return .dustyBlue
        case .evenSplit: return .paleMauve
        case .p50Kickoff: return .paleMauve
        case .miniChallengeFinisher: return .sageGreen
        case .gracefulReturn: return .terracottaRose
        case .mindfulRest: return .dustyBlue
        }
    }
}

#Preview {
    AchievementsView()
        .preferredColorScheme(.dark)
}
