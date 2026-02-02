//
// AchievementsView.swift (MINIMAL FIX - Exactly Preserves Original)
// Reverie Weaver
//
//

import SwiftUI
import SwiftData

struct AchievementsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext

    @Query private var completions: [HabitCompletion]
    @Query private var habits: [Habit]
    @Query private var miniChallengeProgress: [MiniChallengeProgress]
    @Query private var themeWeekProgress: [ThemeWeekProgress]

    @ObservedObject private var achievementManager = AchievementManager.shared
    
    @State private var newlyUnlocked: Set<AchievementType> = []
    @State private var showUnlockAnimation: AchievementType? = nil
    @State private var animationCleanupTimer: Timer?
    
    // Current season color for glow effects
    private var currentSeasonColor: Color {
        Color(hex: WeaverJourneyManager.shared.currentSeason.colorHex)
    }

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
        .onDisappear { cleanupAnimations() }
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
        let metadata = type.metadata
        let cardColor = color(for: type)
        let isUnlocked = achievementManager.isUnlocked(type)
        let repeatCount = achievementManager.repeatCount(for: type)
        let isNewlyUnlocked = newlyUnlocked.contains(type)
        let unlockDate = getUnlockDate(for: type)

        return VStack(spacing: 6) {
            ZStack(alignment: .topTrailing) {
                ZStack {
                    if isNewlyUnlocked {
                        Circle()
                            .fill(cardColor.opacity(0.3))
                            .frame(width: 60, height: 60)
                            .scaleEffect(showUnlockAnimation == type ? 1.8 : 1.0)
                            .opacity(showUnlockAnimation == type ? 0 : 0.6)
                    }
                    
                    Image(systemName: metadata.iconName)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(isUnlocked ? cardColor : Color.dynamicSecondaryLabel.opacity(0.3))
                        .padding(10)
                        .background(
                            Circle()
                                .fill(isUnlocked ? cardColor.opacity(0.15) : Color.dynamicSecondaryLabel.opacity(0.05))
                        )
                        .scaleEffect(showUnlockAnimation == type ? 1.15 : 1.0)
                        .shadow(
                            color: isNewlyUnlocked ? cardColor.opacity(0.5) : .clear,
                            radius: showUnlockAnimation == type ? 12 : 4,
                            x: 0,
                            y: 0
                        )
                }

                if isUnlocked, repeatCount > 1, !type.isOneTime {
                    Text("×\(repeatCount)")
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(cardColor.opacity(0.18)))
                        .offset(x: 6, y: -6)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                }
            }

            Text(metadata.title)
                .font(.system(size: 11, weight: .semibold))
                .fontDesign(.serif)
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                .multilineTextAlignment(.center)

            Text(metadata.description)
                .font(.system(size: 11))
                .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal, 4)
            
            // Unlock date (only if unlocked)
            if isUnlocked, let date = unlockDate {
                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 10))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .accent)
                    .padding(.top, 2)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .reverieCardStyle(colorScheme: colorScheme, cornerRadius: 16)
        .overlay(
            ZStack {
                // Standard border
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isUnlocked ? cardColor.opacity(0.5) : Color.clear,
                        lineWidth: 1
                    )
                
                // Seasonal shimmer glow for newly unlocked
                if isNewlyUnlocked {
                    SeasonalUnlockGlow(cornerRadius: 16, seasonColor: currentSeasonColor)
                }
            }
        )
        .opacity(isUnlocked ? 1 : 0.6)
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: isUnlocked)
    }

    // MARK: - Update Achievements
    private func updateAchievements() {
        achievementManager.attachContext(modelContext)
        
        let previouslyUnlocked = Set(AchievementType.allCases.filter { achievementManager.isUnlocked($0) })
        
        // TODO: Wire up planned rest days when RestPlan model is implemented
        let planned = Set<Date>()

        achievementManager.checkAchievements(
            completions: completions,
            habits: habits,
            miniChallengeProgress: miniChallengeProgress,
            themeWeekProgress: themeWeekProgress,
            plannedRestDays: planned
        )
        
        let currentlyUnlocked = Set(AchievementType.allCases.filter { achievementManager.isUnlocked($0) })
        let justUnlocked = currentlyUnlocked.subtracting(previouslyUnlocked)
        
        if !justUnlocked.isEmpty {
            handleNewUnlocks(justUnlocked)
        }
    }
    
    // MARK: - Animation Management
    private func handleNewUnlocks(_ unlocked: Set<AchievementType>) {
        guard !unlocked.isEmpty else { return }
        
        animationCleanupTimer?.invalidate()
        
        newlyUnlocked = unlocked
        if let firstUnlocked = unlocked.first {
            triggerUnlockAnimation(for: firstUnlocked)
        }
        
        animationCleanupTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            withAnimation {
                self.newlyUnlocked.removeAll()
            }
        }
    }

    private func triggerUnlockAnimation(for type: AchievementType) {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
            showUnlockAnimation = type
        }
        ReverieHaptics.successFeedback()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation {
                if self.showUnlockAnimation == type {
                    self.showUnlockAnimation = nil
                }
            }
        }
    }
    
    private func cleanupAnimations() {
        animationCleanupTimer?.invalidate()
        animationCleanupTimer = nil
        newlyUnlocked.removeAll()
        showUnlockAnimation = nil
    }

    // MARK: - Card Helpers
    
    private func getUnlockDate(for type: AchievementType) -> Date? {
        guard achievementManager.isUnlocked(type) else { return nil }
        
        do {
            let predicate = #Predicate<Achievement> { $0.type == type.rawValue }
            let desc = FetchDescriptor<Achievement>(predicate: predicate)
            let achievements = try modelContext.fetch(desc)
            return achievements.first?.earnedDate
        } catch {
            print("❌ Failed to fetch unlock date: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func color(for type: AchievementType) -> Color {
        switch type {
        // First steps & beginnings
        case .firstHabit: return .paleMauve
        case .p50Kickoff: return Color(hex: "C8B8DB") // Lavender - beginning of journey
        
        // Perfect completions
        case .perfectDay: return .sageGreen
        case .perfectMorning: return .sunriseOrange
        case .weekWarrior: return Color(hex: "88B5A3") // Deeper sage - bigger achievement
        case .monthMaster: return Color(hex: "9B7FA5") // Deep purple - mastery
        
        // Streaks (progression: warm to cool)
        case .streak7: return .terracottaRose
        case .streak30: return Color(hex: "8B7B9B") // Muted purple - longer commitment
        case .consistency: return Color(hex: "A67C7C") // Deeper terracotta - 21 days
        
        // Milestones (progression: light to rich)
        case .milestone10: return Color(hex: "B8C9A3") // Light sage
        case .milestone50: return Color(hex: "7A9BB8") // Medium dusty blue
        case .milestone100: return Color(hex: "D4A574") // Gold-ish - major milestone
        
        // Time-based
        case .earlyBird: return .sunriseOrange
        case .nightOwl: return .dustyBlue
        case .evenSplit: return Color(hex: "B89B9B") // Warm neutral - balance
        
        // Project 50 series (progression theme)
        case .p50Complete: return Color(hex: "7AB88A") // Vibrant green - completion
        case .p50MasteryAchieved: return Color(hex: "E8A87C") // Rich orange - mastery
        case .p50RepeatChampion: return Color(hex: "9B8BC7") // Rich lavender - repeat excellence
        
        // Challenges
        case .miniChallengeFinisher: return Color(hex: "8DB89B") // Fresh green
        case .miniChallenge3Complete: return Color(hex: "7AA38B") // Deeper green - multiple completions
        case .fullProgramComplete: return Color(hex: "9B7FA5") // Purple - program mastery
        case .allTiersExplored: return Color(hex: "C8A87C") // Warm gold - exploration
        
        // Recovery & flexibility
        case .gracefulReturn: return .terracottaRose
        case .mindfulRest: return Color(hex: "A3B5C8") // Calm blue
        case .bonusMaster: return Color(hex: "E8B887") // Warm gold
        
        // Theme Week achievements
        case .themeWeekComplete: return Color(hex: "C8B8DB") // Lavender
        case .flexibleRhythm: return Color(hex: "B8A3C8") // Deeper lavender
        case .gentleConsistency: return Color(hex: "9B87AB") // Deep purple
        case .allBlooms: return Color(hex: "E8C87C") // Bright gold
        case .honoringEnergy: return Color(hex: "7AA38B") // Forest green
        
        // Connection Clarity series
        case .connectionClarityFirstComplete: return Color(hex: "8BA3B8") // Communication blue
        case .connectionClarityFullReflection: return Color(hex: "A89BC8") // Reflective purple
        case .connectionClarityRepeat: return Color(hex: "C89BAB") // Warm rose - mastery
        }
    }
}

// MARK: - Seasonal Unlock Glow Component

struct SeasonalUnlockGlow: View {
    @State private var isPulsing = false
    let cornerRadius: CGFloat
    let seasonColor: Color

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .strokeBorder(
                seasonColor.opacity(isPulsing ? 0.8 : 0.2),
                lineWidth: 2
            )
            .shadow(
                color: seasonColor.opacity(isPulsing ? 0.6 : 0.1),
                radius: isPulsing ? 8 : 2
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
    }
}

#Preview {
    AchievementsView()
        .preferredColorScheme(.dark)
}
