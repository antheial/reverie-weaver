//
//  ProfileView.swift
//  Reverie Weaver
//
//
//  - ProfileView: identity, stats, grimoire, hidden threads
//  - ProfileSettingsView: personal intention edit, data, storage, support
//

import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Data Queries
    @Query private var profiles: [UserProfile]
    @Query private var habits: [Habit]
    @Query private var completions: [HabitCompletion]
    
    @Query private var allAchievements: [Achievement]
    
    @Query(sort: \ConstellationBadge.chapter, order: .forward)
    private var constellations: [ConstellationBadge]
        
    @Query(sort: \InvisibleAchievement.discoveredDate, order: .reverse)
    private var invisibleAchievements: [InvisibleAchievement]

    @Query(sort: \WeeklyChallenge.weekStartDate, order: .reverse)
    private var weeklyChallenges: [WeeklyChallenge]

    // MARK: - Gamification State
    @State private var selectedConstellation: ConstellationBadge?
    @State private var discoveredInvisible: InvisibleAchievement?
    @State private var showInvisibleDiscovery = false
    @State private var showLevelUpCelebration = false
    @State private var celebratingLevel: WeaverLevel?

    // MARK: - Stats Cache
    @State private var cachedStreak: Int = 0
    @State private var cachedPerfectDays: Int = 0
    @State private var lastStatsUpdate: Date?

    @State private var lockedAlertBadge: ConstellationBadge?

    // MARK: - Loading / Navigation
    @State private var isCalculatingStats = false
    @State private var hasInitializedGamification = false
    @State private var showSettings = false

    @ObservedObject private var localization = LocalizationManager.shared
    @ObservedObject private var journeyManager = WeaverJourneyManager.shared

    // MARK: - Computed
    private var profile: UserProfile? { profiles.first }
    private var totalCompletions: Int { completions.count }

    private var currentStreak: Int {
        if let last = lastStatsUpdate,
           Date().timeIntervalSince(last) < 300 {
            return cachedStreak
        }
        if !isCalculatingStats {
            Task { await recalculateStats() }
        }
        return cachedStreak
    }

    private var perfectDays: Int {
        if let last = lastStatsUpdate,
           Date().timeIntervalSince(last) < 300 {
            return cachedPerfectDays
        }
        return cachedPerfectDays
    }

    // MARK: - Body

    var body: some View {
            NavigationStack {
                ZStack {
                    ReverieWeaverBackground()

                    VStack(spacing: 0) {
                        // Custom header (no toolbar)
                        profileHeaderSection

                        mainScrollContent
                    }
                }
                .navigationBarHidden(true)
                .navigationDestination(isPresented: $showSettings) {
                    ProfileSettingsView()
                }
                
                // Sheet for Unlocked Story
                .sheet(item: $selectedConstellation) { constellation in
                    ConstellationStoryView(constellation: constellation)
                }
                // Alert for locked constellation hint
                .alert(item: $lockedAlertBadge) { badge in
                    Alert(
                        title: Text("\(localization.localize("profile.locked")): \(badge.name)"),
                        message: Text(badge.hintText),
                        dismissButton: .default(Text(localization.localize("profile.keepWeaving")))
                    )
                }
                // Alert for Invisible Achievement
                .alert(localization.localize("profile.hiddenThreadRevealed"), isPresented: $showInvisibleDiscovery) {
                    Button(localization.localize("profile.beautiful")) { ReverieHaptics.lightFeedback() }
                } message: {
                    invisibleDiscoveryMessage
                }
                // Notification Receiver (Throttled)
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ConstellationUnlocked"))) { notification in
                    if let constellation = notification.object as? ConstellationBadge {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            if self.selectedConstellation == nil {
                                self.selectedConstellation = constellation
                            }
                        }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("InvisibleAchievementDiscovered"))) { notification in
                    if let achievement = notification.object as? InvisibleAchievement {
                        discoveredInvisible = achievement
                        showInvisibleDiscovery = true
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("WeaverLevelUp"))) { notification in
                    if let level = notification.object as? WeaverLevel {
                        celebratingLevel = level
                        showLevelUpCelebration = true
                    }
                }
            }
            .withCelebrationModal()  // Add celebration modal support
            .fullScreenCover(isPresented: $showLevelUpCelebration) {
                if let level = celebratingLevel {
                    LevelUpCelebrationView(level: level) {
                        showLevelUpCelebration = false
                        celebratingLevel = nil
                    }
                    .background(Color.clear)
                }
            }
            .task {
                await initialLoadAndCalculations()

                // Show any pending celebrations when profile loads
                if AchievementCelebrationQueue.shared.hasPendingCelebrations {
                    AchievementCelebrationQueue.shared.showPendingCelebrations()
                }
            }
            .onChange(of: completions.count) { _, _ in
                Task { await recalculateStats() }
            }
        }

    // MARK: - Profile Header (Custom - No Toolbar)
    private var profileHeaderSection: some View {
        HStack {
            Text(localization.localize("profile.title"))
                .font(.system(size: 23, weight: .regular))
                .fontDesign(.serif)
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

            Spacer()

            Button {
                ReverieHaptics.lightFeedback()
                showSettings = true
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.adaptiveSectionBackground(colorScheme: colorScheme))
                        .frame(width: 36, height: 36)
                        .shadow(color: Color.shadowColor.opacity(0.1), radius: 4, y: 2)

                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(colorScheme == .dark ? Color.white : Color.black)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }

    // MARK: - Main Content
        private var mainScrollContent: some View {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    
                    // 1. Identity Header (Halo + Integrated Progress)
                    headerSection
                    
                    // 2. Season Banner
                    CurrentSeasonBanner(
                        season: journeyManager.currentSeason,
                        daysSinceStart: journeyManager.daysSinceStart,
                        colorScheme: colorScheme
                    )

                    // 3. Anniversary
                    anniversaryCard

                    // 4. Stats ("Your Journey")
                    statsContainer

                    // 5. Weekly Challenge (after Your Journey)
                    weeklyChalllengeSection

                    // 6. Grimoire (Tarot)
                    grimoireSection
                    
                    // 7. Hidden Threads
                    if !invisibleAchievements.isEmpty {
                        invisibleAchievementsSection
                    }

                    // 8. Personal Intention (Readable)
                    personalIntentionCard
                        .padding(.bottom, 40)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
        }
    
    // MARK: - 1. Identity Header
    
    private var headerSection: some View {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(hex: journeyManager.currentSeason.colorHex).opacity(0.5),
                                    Color(hex: journeyManager.currentSeason.colorHex).opacity(0.1),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 70
                            )
                        )
                        .frame(width: 100, height: 100)
                        .blur(radius: 15)
                    
                    // Avatar Circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.sageGreen, .dustyBlue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)
                        .overlay(
                            Circle()
                                .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(
                            color: Color(hex: journeyManager.currentSeason.colorHex).opacity(0.4),
                            radius: 10,
                            y: 5
                        )

                    Text((profile?.displayName.prefix(1) ?? "W").uppercased())
                        .font(.system(size: 26, weight: .semibold, design: .serif))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                }
                
                // Text & Integrated Progress
                VStack(spacing: 8) {
                    Text(profile?.displayName ?? "Weaver")
                        .font(.system(size: 16, weight: .bold, design: .serif))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    
                    // The Whisper (only consider revealed badges for year-round discovery)
                    Text(WeaverLoreManager.getDailyWhisper(unlockedConstellations: constellations.filter { $0.isRevealed }))
                        .font(.system(size: 12, weight: .medium))
                        .italic()
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.bottom, 8) // Enhanced spacing before level
                    
                    // Time-Adaptive Level & Progress
                    timeAdaptiveLevelProgress
                }
            }
            .padding(.bottom, 4)
        }
    
    // MARK: - 1b. Time-Adaptive Level Progress
    
    private var timeAdaptiveLevelProgress: some View {
        let hour = Calendar.current.component(.hour, from: Date())
        let period = TimeOfDay(hour: hour)
        let config = WeaverLevelCardConfig(period: period, colorScheme: colorScheme)
        
        return VStack(spacing: 8) {
            // Level Title with Time-Adaptive Color & Glow
            Text(journeyManager.currentLevel.title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(config.iconColor)
                .textCase(.uppercase)
                .tracking(1)
                .shadow(color: config.iconGlow, radius: config.iconGlowRadius)
            
            // Progress Bar or Transcendent Message
            if let next = journeyManager.currentLevel.next {
                let progress = min(Double(totalCompletions) / Double(next), 1.0)
                let remaining = max(next - totalCompletions, 0)
                
                VStack(spacing: 6) {
                    // Time-Adaptive Progress Bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: config.progressBarRadius)
                                .fill(config.progressTrackColor)
                            
                            RoundedRectangle(cornerRadius: config.progressBarRadius)
                                .fill(config.progressGradient)
                                .frame(width: geometry.size.width * progress)
                                .shadow(
                                    color: config.progressGlow,
                                    radius: config.progressGlowRadius
                                )
                                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
                        }
                    }
                    .frame(height: config.progressBarHeight)
                    .padding(.horizontal, 40)
                    
                    // Progress Text
                    HStack {
                        Text("\(remaining) \(localization.localize("profile.moreToNextLevel"))")
                        Spacer()
                        Text("\(localization.localize("profile.level")) \(journeyManager.currentLevel.level)")
                    }
                    .font(.system(size: 11, weight: .regular))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    .padding(.horizontal, 40)
                }
                .padding(.top, 4)
            } else {
                // Transcendent Level Message
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(config.transcendentIconColor)
                        .shadow(color: config.transcendentGlow, radius: config.transcendentGlowRadius)
                    
                    Text(localization.localize("profile.transcendentReached"))
                        .font(.system(size: 11, weight: .medium))
                        .italic()
                        .foregroundStyle(config.transcendentTextColor)
                        .shadow(color: config.transcendentGlow, radius: 1)
                    
                    Image(systemName: "star.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(config.transcendentIconColor)
                        .shadow(color: config.transcendentGlow, radius: config.transcendentGlowRadius)
                }
                .padding(.top, 4)
            }
        }
    }

    // MARK: - 2. Stats Section
    
        private var statsContainer: some View {
            VStack(spacing: 12) {
                Text(localization.localize("profile.yourJourney"))
                    .font(.system(size: 13, weight: .regular, design: .serif))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 10) {
                    CompactStatCard(value: "\(currentStreak)", label: localization.localize("profile.daysInRhythm"), color: .sageGreen)
                    CompactStatCard(value: "\(totalCompletions)", label: localization.localize("profile.threadsWoven"), color: .dustyBlue)
                    CompactStatCard(value: "\(allAchievements.count)", label: localization.localize("profile.achievements"), color: .terracottaRose)
                }

                HStack(spacing: 10) {
                    CompactStatCard(value: "\(perfectDays)", label: localization.localize("profile.fullPatterns"), color: .paleMauve)
                    CompactStatCard(value: "\(habits.count)", label: localization.localize("profile.activeThreads"), color: .sageGreen)
                }
            }
            .padding(16)
            .reverieCardStyle(colorScheme: colorScheme)
        }

    private var progressiveGrimoireLore: String {
        // Only consider revealed badges (year-round discovery)
        let revealedConstellations = constellations.filter { $0.isRevealed }

        // Find the highest chapter number the user has unlocked among revealed badges
        let maxUnlockedChapter = revealedConstellations
            .filter { $0.isUnlocked }
            .map { $0.chapter }
            .max() ?? 0

        // Next constellation must also be revealed
        let nextConstellation = revealedConstellations
            .first { $0.chapter == (maxUnlockedChapter + 1) }

        var output = ""

        // 1. REVEALED LORE (Current Chapter)
        if let currentLorePassage = GrimoireLorePassages.all.first(where: { $0.chapter == maxUnlockedChapter }) {
            
            // Logic is now based on Chapter 0 vs. Chapter 1+
            if maxUnlockedChapter > 0 {
                output += "Your journey thread has reached Chapter \(maxUnlockedChapter):\n"
                output += currentLorePassage.text
            } else {
                // Chapter 0 (Prologue) - Show the introductory text without the "Chapter X" header
                output += currentLorePassage.text
            }
        } else {
            // Fallback should only show if Chapter 0 definition is missing (highly unlikely)
            output += "Your story is just beginning. Start weaving your first thread."
        }

        // 2. PROGRESSIVE HINT (Next Chapter)
        if let next = nextConstellation {
            output += "\n\n—\n\n"
            output += "✨The next thread: \(next.name) (Chapter \(next.chapter))\n"
            output += "\(next.hintText)"
        }

        return output
    }
    // MARK: - 3. The Weaver's Grimoire (Tarot Carousel)
    
    private var grimoireSection: some View {
        // Filter to only show revealed badges (year-round discovery)
        let revealedConstellations = constellations.filter { $0.isRevealed }
        let unlockedCount = revealedConstellations.filter { $0.isUnlocked }.count
        let totalRevealed = revealedConstellations.count

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles.rectangle.stack.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.paleMauve)
                Text(localization.localize("profile.grimoire"))
                    .font(.system(size: 14, weight: .semibold, design: .serif))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                Spacer()
                Text("\(unlockedCount)/\(totalRevealed)")
                    .font(.system(size: 12))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
            }
            .padding(.horizontal, 8)

            // Progressive Lore Block
            Text(progressiveGrimoireLore)
                .font(.system(size: 12, weight: .regular, design: .serif))
                .italic()
                .lineSpacing(2)
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
                .padding(.bottom, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    Spacer().frame(width: 0)
                    ForEach(revealedConstellations) { constellation in
                        GrimoireCard(constellation: constellation, colorScheme: colorScheme)
                            .onTapGesture {
                                if constellation.isUnlocked {
                                    // 1. Open the Story
                                    selectedConstellation = constellation
                                    ReverieHaptics.lightFeedback()

                                    // Stop the glow (mark as viewed)
                                    if !constellation.hasBeenViewed {
                                        constellation.hasBeenViewed = true
                                        try? modelContext.save()
                                    }
                                } else {
                                    // 3. Show Locked Hint
                                    lockedAlertBadge = constellation
                                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                                }
                            }
                    }
                    Spacer().frame(width: 0)
                }
            }
        }
    }
    
    // MARK: - Grimoire Lore Data (Segmented for Progressive Reveal)

    private struct LorePassage {
        let chapter: Int
        let text: String
    }

    private struct GrimoireLorePassages {
        // These chapter numbers must match the 'ConstellationBadge.chapter' property
        static let all: [LorePassage] = [
            // Prologue (Chapter 0) - Always visible if 'The First Loom' is unlocked
            LorePassage(chapter: 0, text: "This is your Weaver’s journey so far — written in stars, in seasons, and in a hundred small, honest days that you chose not to abandon yourself."),
            
            // Chapter 1: The Morning Star
            LorePassage(chapter: 1, text: "Under the Morning Star you learned to greet the day with intention, again and again, stringing together mornings that actually belonged to you."),
            
            // Chapter 2: The Tranquil Moon
            LorePassage(chapter: 2, text: "The Tranquil Moon arrived as the echo of that effort—teaching you to close your days on purpose, with quiet instead of collapse."),
            
            // Chapter 3: The Verdant Leaf
            LorePassage(chapter: 3, text: "The Verdant Leaf reminded you that your body is the living loom, worth twenty - one days of care and movement."),
            
            // Chapter 4: The Sacred Flame
            LorePassage(chapter: 4, text: "The Sacred Flame asked for the same steady courage in your creativity: not flashes of inspiration, but a practice you keep feeding."),
            
            // Chapter 5: The Gentle Wind
            LorePassage(chapter: 5, text: "With the Gentle Wind you stopped trying to brute-force your focus and began arranging your environment — desk, rituals, cues — so that attention could flow with less friction."),
            
            // Chapter 6: The Crystal Drop
            LorePassage(chapter: 6, text: "The Crystal Drop showed up in the small, repeated acts of connection: messages sent, time protected, gratitude expressed."),
            
            // Chapter 7: The Steady Mountain
            LorePassage(chapter: 7, text: "The Steady Mountain rose beneath your feet as you simply kept showing up on day after day, proof that tiny anchors can hold more than any single burst of willpower."),
            
            // Chapter 8: The Wandering Cloud
            LorePassage(chapter: 8, text: "As the Wandering Cloud, you experimented and redesigned, learning that joy and playfulness are not the opposite of discipline but the fuel that lets it last."),
            
            // Chapter 9: The Mended Thread
            LorePassage(chapter: 9, text: "You stepped away and came back as the Mended Thread—carrying the quiet knowledge that a broken streak is not the end of the story, only a place where the pattern changes."),
            
            // Chapter 10: The Silent Deep
            LorePassage(chapter: 10, text: "You dove beneath the noise into the Silent Deep, trading scattered moments for true deep-work sessions, and from there forged ..."),
            
            // Chapter 11: The Iron Spindle
            LorePassage(chapter: 11, text: "... the Iron Spindle: the strength to commit to full programs and see them through."),
            
            // Chapter 12: The Golden Solstice
            LorePassage(chapter: 12, text: "Across seasons, you have risen, rested, fallen, and returned. The Golden Solstice marks this truth: you are not a machine running flat; you are a garden that cycles through Spring, Summer, Autumn, and Winter and still finds ways to grow."),
        ]
    }

    // MARK: - 6. Invisible Achievements
    
    private var invisibleAchievementsSection: some View {
        let hour = Calendar.current.component(.hour, from: Date())
        let period = TimeOfDay(hour: hour)
        let config = AchievementSectionConfig(period: period, colorScheme: colorScheme)

        return VStack(spacing: config.spacing) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13))
                    .foregroundStyle(config.iconColor)
                    .shadow(color: config.iconGlow, radius: config.iconGlowRadius)

                Text(localization.localize("profile.hiddenThreads"))
                    .font(.system(size: 13, weight: .semibold))
                    .fontDesign(.serif)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

                Spacer()
            }

            Text(localization.localize("profile.hiddenThreadsDesc"))
                .font(.system(size: 12, weight: .regular))
                .italic()
                .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: config.rowSpacing) {
                ForEach(invisibleAchievements) { achievement in

                    InvisibleAchievementRow(
                        achievement: achievement,
                        colorScheme: colorScheme
                    )
                }
            }
        }
        .padding(config.padding)
        .reverieCardStyle(colorScheme: colorScheme)
    }
    
    // MARK: - 5. Personal Intention
    
        private var personalIntentionCard: some View {
            VStack(alignment: .leading, spacing: 8) {
                Label(localization.localize("profile.myWhy"), systemImage: "heart.fill")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.terracottaRose)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let motto = profile?.personalMotto, !motto.isEmpty {
                    Text("\"\(motto)\"")
                        .font(.system(size: 13, weight: .regular, design: .serif))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        .italic()
                        .padding(.top, 4)
                        .lineSpacing(4)
                } else {
                    Text(localization.localize("profile.setIntention"))
                        .font(.system(size: 13))
                        .italic()
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                }
            }
            .padding(16)
            .reverieCardStyle(colorScheme: colorScheme)
        }
    
    // MARK: - Weekly Challenge Section

    @ViewBuilder
    private var weeklyChalllengeSection: some View {
        let challengeManager = WeeklyChallengeManager.shared

        // Ensure manager has context
        let _ = challengeManager.attachContext(modelContext)

        if let challenge = challengeManager.getCurrentChallenge() {
            WeeklyChallengeCard(challenge: challenge)
        }
    }

    // MARK: - Anniversary Card

    private var anniversaryCard: some View {
            Group {
                if let milestone = journeyManager.checkAnniversary() {
                    AnniversaryCelebrationCard(
                        milestone: milestone,
                        colorScheme: colorScheme
                    )
                }
            }
        }

    // MARK: - Invisible Achievement Alert Message

    private var invisibleDiscoveryMessage: some View {
        Group {
            if let invisible = discoveredInvisible {
                Text(invisible.story)
            }
        }
    }

    // MARK: - Logic & Init
        
        @MainActor
        private func initialLoadAndCalculations() async {
            // 1. Safety Check: Ensure Profile Exists before anything else
            if profiles.isEmpty {
                let newProfile = UserProfile()
                modelContext.insert(newProfile)
                try? modelContext.save()
            }
            
            // 2. Initialize Journey Manager (Reads from AppStorage to set current days/season)
            journeyManager.initialize()
            
            // 3. Update UI Stats (Streak/Perfect Days)
            await recalculateStats()
            
            // 4. Run Gamification Engine
            // We create snapshots of the data to avoid threading issues
            let habitsSnapshot = habits
            let completionsSnapshot = completions
            let total = completionsSnapshot.count
            
            // A. Update Level & Journey State
            journeyManager.startJourney()
            journeyManager.refreshJourney()
            journeyManager.updateLevel(totalCompletions: total)

            // B. Check for new Badges (Constellations)
            let constellationManager = ConstellationManager(modelContext: modelContext)
            constellationManager.initializeConstellations() 
            constellationManager.checkUnlocks(habits: habitsSnapshot, completions: completionsSnapshot)

            // C. Check for Hidden Threads (Invisible Achievements)
            let invisibleManager = InvisibleAchievementManager(modelContext: modelContext)
            invisibleManager.checkForNewAchievements(habits: habitsSnapshot, completions: completionsSnapshot)

            // D. Update Weekly Challenge Progress
            let challengeManager = WeeklyChallengeManager.shared
            challengeManager.attachContext(modelContext)
            challengeManager.updateProgress(completions: completionsSnapshot, habits: habitsSnapshot)
        }

    private func initializeGamification() {
        journeyManager.startJourney()
        journeyManager.refreshJourney()
        journeyManager.updateLevel(totalCompletions: totalCompletions)

        let constellationManager = ConstellationManager(modelContext: modelContext)
        constellationManager.initializeConstellations()
        constellationManager.checkUnlocks(habits: habits, completions: completions)

        let invisibleManager = InvisibleAchievementManager(modelContext: modelContext)
        invisibleManager.checkForNewAchievements(habits: habits, completions: completions)
    }
    
    @MainActor
    private func recalculateStats() async {
        guard !isCalculatingStats else { return }
        isCalculatingStats = true
        defer { isCalculatingStats = false }

        let newStreak = Self.calculateStreakLogic(
            habits: habits,
            completions: completions
        )
        let newPerfectDays = Self.calculatePerfectDaysLogic(
            habits: habits,
            completions: completions
        )

        cachedStreak = newStreak
        cachedPerfectDays = newPerfectDays
        lastStatsUpdate = Date()
    }

    // MARK: - Streak / Perfect-Day Logic

    private static func calculateStreakLogic(habits: [Habit], completions: [HabitCompletion]) -> Int {
        let calendar = Calendar.current
        let completionDates = Set(completions.map { calendar.startOfDay(for: $0.completedAt) })
        
        var streak = 0
        var date = calendar.startOfDay(for: Date())
        guard let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: Date()) else { return 0 }
        
        var iterations = 0
        while date >= oneYearAgo && iterations < 400 {
            iterations += 1
            
            let activeCount = habits.filter { h in
                h.createdAt <= date && (h.archivedAt.map { $0 >= date } ?? true)
            }.count
            
            if activeCount == 0 {
                guard let prev = calendar.date(byAdding: .day, value: -1, to: date) else { break }
                date = prev
                continue
            }
            
            if completionDates.contains(date) {
                streak += 1
            } else {
                break
            }
            
            guard let prev = calendar.date(byAdding: .day, value: -1, to: date) else { break }
            date = prev
        }
        return streak
    }

    private static func calculatePerfectDaysLogic(habits: [Habit], completions: [HabitCompletion]) -> Int {
        guard !habits.isEmpty else { return 0 }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Pre-compute: Group completions by date for O(1) lookup
        var completionsByDate: [Date: Set<UUID>] = [:]
        for completion in completions {
            let day = calendar.startOfDay(for: completion.completedAt)
            completionsByDate[day, default: []].insert(completion.habitId)
        }

        // Pre-compute: Habit active ranges (startDay, endDay, id)
        // This avoids recalculating createdAt/archivedAt for each day
        struct HabitRange {
            let id: UUID
            let startDay: Date
            let endDay: Date? // nil means still active
        }

        let habitRanges: [HabitRange] = habits.map { h in
            HabitRange(
                id: h.id,
                startDay: calendar.startOfDay(for: h.createdAt),
                endDay: h.archivedAt.map { calendar.startOfDay(for: $0) }
            )
        }

        var perfectDaysCount = 0
        var checkDate = today

        for _ in 0..<365 {
            // Get active habits for this day using pre-computed ranges
            let activeHabitIDs = habitRanges.compactMap { range -> UUID? in
                let isAfterStart = range.startDay <= checkDate
                let isBeforeEnd = range.endDay.map { $0 >= checkDate } ?? true
                return (isAfterStart && isBeforeEnd) ? range.id : nil
            }

            if !activeHabitIDs.isEmpty {
                let completedIDs = completionsByDate[checkDate] ?? []
                // Check if all active habits were completed
                if activeHabitIDs.allSatisfy({ completedIDs.contains($0) }) {
                    perfectDaysCount += 1
                }
            }

            guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
        }

        return perfectDaysCount
    }

    // MARK: - Local Subviews

    private struct CompactStatCard: View {
        let value: String
        let label: String
        let color: Color
        @Environment(\.colorScheme) var colorScheme

        var body: some View {
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 22, weight: .semibold, design: .serif))
                    .foregroundStyle(color)
                Text(label)
                    .font(.system(size: 11, weight: .regular, design: .serif))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .reverieCardStyle(colorScheme: colorScheme)
        }
    }
    
    private struct AchievementSectionConfig {
        let spacing: CGFloat; let rowSpacing: CGFloat; let padding: CGFloat
        let iconColor: Color; let iconGlow: Color; let iconGlowRadius: CGFloat

        init(period: TimeOfDay, colorScheme: ColorScheme) {
            if colorScheme == .dark {
                self.spacing = 16; self.rowSpacing = 10; self.padding = 20
                self.iconColor = Color.terracottaRose; self.iconGlow = Color.terracottaRose.opacity(0.3); self.iconGlowRadius = 2
            } else {
                switch period {
                case .deepNight, .evening:
                    self.spacing = 18; self.rowSpacing = 12; self.padding = 22
                    self.iconColor = Color.terracottaRose; self.iconGlow = Color.terracottaRose.opacity(0.4); self.iconGlowRadius = 3
                case .dawn:
                    self.spacing = 17; self.rowSpacing = 11; self.padding = 21
                    self.iconColor = Color.terracottaRose.opacity(0.95); self.iconGlow = Color.orange.opacity(0.25); self.iconGlowRadius = 2.5
                case .earlyMorning, .lateMorning, .earlyAfternoon:
                    self.spacing = 14; self.rowSpacing = 9; self.padding = 18
                    self.iconColor = Color.terracottaRose.opacity(0.8); self.iconGlow = Color.clear; self.iconGlowRadius = 0
                case .lateAfternoon:
                    self.spacing = 15; self.rowSpacing = 10; self.padding = 19
                    self.iconColor = Color.terracottaRose.opacity(0.85); self.iconGlow = Color.orange.opacity(0.15); self.iconGlowRadius = 1.5
                case .goldenHour:
                    self.spacing = 17; self.rowSpacing = 11; self.padding = 21
                    self.iconColor = Color.terracottaRose; self.iconGlow = Color.orange.opacity(0.5); self.iconGlowRadius = 3.5
                case .dusk:
                    self.spacing = 18; self.rowSpacing = 12; self.padding = 22
                    self.iconColor = Color.terracottaRose; self.iconGlow = Color.purple.opacity(0.5); self.iconGlowRadius = 3.5
                }
            }
        }
    }
}
