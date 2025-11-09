//
// ProfileView.swift
// ReverieWeaver
//
// User profile and settings with gamification integration
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import StoreKit
import UIKit
import CoreText   // needed for CTFramesetter / CoreText drawing

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    @Query private var profiles: [UserProfile]
    @Query private var habits: [Habit]
    @Query private var completions: [HabitCompletion]
    @Query private var allAchievements: [Achievement]
    @Query private var reflections: [Reflection]
    
    @Query(sort: \ReflectionNote.startDate, order: .reverse)
    private var reflectionNotes: [ReflectionNote]

    @State private var showNoDataAlert = false
    @State private var showExportError = false
    @State private var exportErrorMessage = ""
    
    // ✨ NEW: Gamification queries
    @Query private var constellations: [ConstellationBadge]
    @Query(sort: \InvisibleAchievement.discoveredDate, order: .reverse)
    private var invisibleAchievements: [InvisibleAchievement]

    @State private var displayName: String = ""
    @State private var personalMotto: String = ""
    @State private var weekStartsOnSunday: Bool = true
    @State private var showExportSuccess = false
    @State private var showMailUnavailable = false
    @State private var showClearDataAlert = false

    // ✨ NEW: Gamification state
    @State private var selectedConstellation: ConstellationBadge?
    @State private var showConstellationStory = false
    @State private var discoveredInvisible: InvisibleAchievement?
    @State private var showInvisibleDiscovery = false

    @ObservedObject private var localization = LocalizationManager.shared
    @ObservedObject private var journeyManager = WeaverJourneyManager.shared

    private var profile: UserProfile? {
        profiles.first
    }

    private var totalCompletions: Int {
        completions.count
    }

    private var currentStreak: Int {
        var streak = 0
        var date = Calendar.current.startOfDay(for: Date())

        while true {
            let dayCompletions = completions.filter {
                Calendar.current.isDate($0.completedAt, inSameDayAs: date)
            }
            if dayCompletions.isEmpty {
                break
            }
            streak += 1
            date = Calendar.current.date(byAdding: .day, value: -1, to: date)!
        }

        return streak
    }

    private var perfectDays: Int {
        guard !habits.isEmpty else { return 0 }

        let calendar = Calendar.current
        var perfectDaysCount = 0
        var checkDate = Date()

        for _ in 0..<365 {
            let dayCompletions = completions.filter {
                calendar.isDate($0.completedAt, inSameDayAs: checkDate)
            }

            let uniqueHabits = Set(dayCompletions.map { $0.habitId })
            if uniqueHabits.count == habits.count {
                perfectDaysCount += 1
            }

            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = previousDay
        }

        return perfectDaysCount
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ReverieWeaverBackground()
                ScrollView {
                    VStack(spacing: 24) {
                        // 1. Header with profile circle (with seasonal glow)
                        headerSection

                        // ✨ NEW: Gamification sections
                        // 2. NEW: Weaver Level Card (subtle)
                        WeaverLevelCard(
                            level: journeyManager.currentLevel,
                            totalCompletions: totalCompletions,
                            colorScheme: colorScheme
                        )
                        // 3. NEW: Current Season Banner
                        CurrentSeasonBanner(
                            season: journeyManager.currentSeason,
                            daysSinceStart: journeyManager.daysSinceStart,
                            colorScheme: colorScheme
                        )
                        // 4. NEW: Anniversary Celebration (if applicable)
                        if let milestone = journeyManager.checkAnniversary() {
                            AnniversaryCelebrationCard(
                                milestone: milestone,
                                colorScheme: colorScheme
                            )
                        }
                        // 5. Stats Section (existing)
                        statsSection

                        // 6. NEW: Constellation Section
                        constellationSection // ✨ NEW

                        // 7. NEW: Invisible Achievements (if any discovered)
                        if !invisibleAchievements.isEmpty {
                            invisibleAchievementsSection // ✨ NEW
                        }
                        // 8. Personal Intention (existing)
                        personalSection

                        // 9. Preferences (existing - keep week start + language)
                        settingsSection
                        // 10. Data Management (existing)
                        dataSection
                        // 11. Storage Management (existing)
                        storageSection
                        // 12. Support (existing)
                        supportSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 32)
                    .dismissKeyboardOnBackgroundTap()
                }
                .background(Color.clear)
                .navigationTitle(localization.localize("profile.title"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text(localization.localize("profile.title"))
                            .font(.system(size: 23, weight: .regular))
                            .fontDesign(.serif)
                    }
                }
                // ✨ NEW: Constellation story sheet
                .sheet(isPresented: $showConstellationStory) {
                    if let constellation = selectedConstellation {
                        ConstellationStoryView(constellation: constellation)
                    }
                }
                // ✨ NEW: Invisible achievement alert
                .alert("A Hidden Thread Revealed", isPresented: $showInvisibleDiscovery) {
                    Button("Beautiful") {
                        ReverieHaptics.lightFeedback()
                    }
                } message: {
                    if let invisible = discoveredInvisible {
                        Text(invisible.story)
                    }
                }
                .alert(localization.localize("profile.dataExported"), isPresented: $showExportSuccess) {
                    Button(localization.localize("profile.ok")) { }
                } message: {
                    Text(localization.localize("profile.exportSuccess"))
                }
                .alert("Mail Not Available", isPresented: $showMailUnavailable) {
                    Button(localization.localize("profile.ok")) { }
                } message: {
                    Text("Please send your feedback to:\nreveriearchive.studio@gmail.com")
                }
                // Add near line 195 with other alerts
                .alert("No Reflections to Export", isPresented: $showNoDataAlert) {
                    Button("OK") { }
                } message: {
                    Text("You haven't created any reflection notes this month yet. Create a weekly or monthly reflection to export your thoughts as a beautiful PDF.")
                }

                .alert("Export Failed", isPresented: $showExportError) {
                    Button("OK") { }
                } message: {
                    Text(exportErrorMessage)
                }
                .alert("Clear Old Data?", isPresented: $showClearDataAlert) {
                    Button(localization.localize("habit.cancel"), role: .cancel) { }
                    Button("Clear", role: .destructive) {
                        clearOldData()
                    }
                } message: {
                    Text("This will permanently delete reflections and photos older than 1 year. This cannot be undone.")
                }
                // ✨ NEW: Notification listeners:Listen for constellation unlocks
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ConstellationUnlocked"))) { notification in
                    if let constellation = notification.object as? ConstellationBadge {
                        selectedConstellation = constellation
                        showConstellationStory = true
                    }
                }
                // NEW: Listen for invisible achievement discoveries
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("InvisibleAchievementDiscovered"))) { notification in
                    if let achievement = notification.object as? InvisibleAchievement {
                        discoveredInvisible = achievement
                        showInvisibleDiscovery = true
                    }
                }
                .onAppear {
                    loadProfile()
                    initializeGamification() // ✨ NEW
                }
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                // ✨ NEW: Seasonal glow around profile circle
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: journeyManager.currentSeason.colorHex).opacity(0.3),
                                Color(hex: journeyManager.currentSeason.colorHex).opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                    .frame(width: 100, height: 100)
                    .blur(radius: 12)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.sageGreen, .dustyBlue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Text(displayName.prefix(1).uppercased())
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 8) {
                Text(localization.localize("profile.displayName"))
                    .font(.system(size: 12, weight: .regular))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)

                TextField(localization.localize("profile.namePlaceholder"), text: $displayName)
                    .multilingualTextField()
                    .textFieldStyle(.plain)
                    .font(.system(size: 16, weight: .medium))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .reverieCardStyle(colorScheme: colorScheme)                    .onChange(of: displayName) { _, newValue in
                        saveProfile()
                    }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Stats Section (Compact Grid)
    private var statsSection: some View {
        VStack(spacing: 12) {
            Text(localization.localize("profile.yourJourney"))
                .font(.system(size: 13, weight: .regular, design: .serif))
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // 3-column grid
            HStack(spacing: 10) {
                CompactStatCard(
                    value: "\(currentStreak)",
                    label: localization.localize("profile.dayStreak"),
                    color: .sageGreen
                )
                CompactStatCard(
                    value: "\(totalCompletions)",
                    label: localization.localize("profile.completed"),
                    color: .dustyBlue
                )
                CompactStatCard(
                    value: "\(allAchievements.count)",
                    label: localization.localize("profile.achievements"),
                    color: .terracottaRose
                )
            }

            // 2-column grid
            HStack(spacing: 10) {
                CompactStatCard(
                    value: "\(perfectDays)",
                    label: localization.localize("profile.perfectDays"),
                    color: .paleMauve
                )
                CompactStatCard(
                    value: "\(habits.count)",
                    label: localization.localize("profile.activeHabits"),
                    color: .sageGreen
                )
            }
        }
        .padding(16)
        .reverieCardStyle(colorScheme: colorScheme)
    }

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
                    .font(.system(size: 10, weight: .regular, design: .serif))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 6)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        colorScheme == .dark
                        ? Color.white.opacity(0.05)
                        : Color.white.opacity(0.12)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(
                        colorScheme == .dark
                        ? Color.white.opacity(0.25)
                        : Color.inkSecondary.opacity(0.4),
                        lineWidth: 0.5
                    )
            )
        }
    }


    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - ✨ TIME-ADAPTIVE CONSTELLATION SECTION
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var constellationSection: some View {
        let hour = Calendar.current.component(.hour, from: Date())
        let period = TimeOfDay(hour: hour)
        let config = ConstellationSectionConfig(period: period, colorScheme: colorScheme)

        return VStack(spacing: config.spacing) {
            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(config.iconColor)
                    .shadow(color: config.iconGlow, radius: config.iconGlowRadius)  // ✨ Time-adaptive glow

                Text("Constellations")
                    .font(.system(size: ReverieTypography.sectionHeader.size, weight: ReverieTypography.sectionHeader.weight))
                    .fontDesign(.serif)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

                Spacer()

                let unlockedCount = constellations.filter { $0.isUnlocked }.count
                Text("\(unlockedCount)/8")
                    .font(.system(size: ReverieTypography.tinyText.size, weight: ReverieTypography.tinyText.weight))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
            }

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: config.gridMinimum))],  // ✨ Adaptive grid size
                spacing: config.gridSpacing
            ) {
                ForEach(constellations) { constellation in
                    ConstellationBadgeView(
                        constellation: constellation,
                        colorScheme: colorScheme
                    )
                    .onTapGesture {
                        if constellation.isUnlocked {
                            selectedConstellation = constellation
                            showConstellationStory = true
                            ReverieHaptics.lightFeedback()
                        }
                    }
                }
            }

            Text("Tap unlocked constellations to read their stories")
                .font(.system(size: 10, weight: .regular))
                .italic()
                .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(config.padding)  // ✨ Time-adaptive padding
        .reverieCardStyle(colorScheme: colorScheme)  // ✨ Already time-adaptive!
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - ✨ TIME-ADAPTIVE INVISIBLE ACHIEVEMENTS SECTION
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var invisibleAchievementsSection: some View {
        let hour = Calendar.current.component(.hour, from: Date())
        let period = TimeOfDay(hour: hour)
        let config = AchievementSectionConfig(period: period, colorScheme: colorScheme)

        return VStack(spacing: config.spacing) {
            HStack(spacing: 8) {
                Image(systemName: "sparkle")
                    .font(.system(size: 12))
                    .foregroundStyle(config.iconColor)
                    .shadow(color: config.iconGlow, radius: config.iconGlowRadius)  // ✨ Time-adaptive glow

                Text("Hidden Threads")
                    .font(.system(size: ReverieTypography.sectionHeader.size, weight: ReverieTypography.sectionHeader.weight))
                    .fontDesign(.serif)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

                Spacer()
            }

            Text("Quietly discovered moments in your journey")
                .font(.system(size: 11, weight: .regular))
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
        .padding(config.padding)  // ✨ Time-adaptive padding
        .reverieCardStyle(colorScheme: colorScheme)  // ✨ Already time-adaptive!
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - CONSTELLATION SECTION CONFIGURATION
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private struct ConstellationSectionConfig {
        let spacing: CGFloat
        let gridMinimum: CGFloat
        let gridSpacing: CGFloat
        let padding: CGFloat
        let iconColor: Color
        let iconGlow: Color
        let iconGlowRadius: CGFloat

        init(period: TimeOfDay, colorScheme: ColorScheme) {
            if colorScheme == .dark {
                // Dark mode: consistent, magical feel
                self.spacing = 16
                self.gridMinimum = 70
                self.gridSpacing = 12
                self.padding = 20
                self.iconColor = Color.paleMauve
                self.iconGlow = Color.paleMauve.opacity(0.4)
                self.iconGlowRadius = 2
            } else {
                // Light mode: time-adaptive spacing and glow
                switch period {
                case .deepNight, .evening:
                    // Night: More spacious, softer glow
                    self.spacing = 18
                    self.gridMinimum = 72
                    self.gridSpacing = 14
                    self.padding = 22
                    self.iconColor = Color.paleMauve
                    self.iconGlow = Color.paleMauve.opacity(0.5)
                    self.iconGlowRadius = 3

                case .dawn:
                    // Dawn: Gentle awakening
                    self.spacing = 17
                    self.gridMinimum = 71
                    self.gridSpacing = 13
                    self.padding = 21
                    self.iconColor = Color.paleMauve.opacity(0.95)
                    self.iconGlow = Color.orange.opacity(0.3)  // Morning glow
                    self.iconGlowRadius = 2.5

                case .earlyMorning, .lateMorning, .earlyAfternoon:
                    // Day: Compact, crisp
                    self.spacing = 14
                    self.gridMinimum = 68
                    self.gridSpacing = 10
                    self.padding = 18
                    self.iconColor = Color.paleMauve.opacity(0.85)
                    self.iconGlow = Color.clear
                    self.iconGlowRadius = 0

                case .lateAfternoon:
                    // Late afternoon: Balanced
                    self.spacing = 15
                    self.gridMinimum = 69
                    self.gridSpacing = 11
                    self.padding = 19
                    self.iconColor = Color.paleMauve.opacity(0.9)
                    self.iconGlow = Color.orange.opacity(0.15)
                    self.iconGlowRadius = 1.5

                case .goldenHour:
                    // Golden hour: Warm, magical glow
                    self.spacing = 17
                    self.gridMinimum = 71
                    self.gridSpacing = 13
                    self.padding = 21
                    self.iconColor = Color.paleMauve
                    self.iconGlow = Color.orange.opacity(0.6)  // Strong warm glow
                    self.iconGlowRadius = 4

                case .dusk:
                    // Dusk: Ethereal, expanded
                    self.spacing = 18
                    self.gridMinimum = 72
                    self.gridSpacing = 14
                    self.padding = 22
                    self.iconColor = Color.paleMauve
                    self.iconGlow = Color.purple.opacity(0.6)  // Twilight glow
                    self.iconGlowRadius = 4
                }
            }
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - ACHIEVEMENT SECTION CONFIGURATION
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private struct AchievementSectionConfig {
        let spacing: CGFloat
        let rowSpacing: CGFloat
        let padding: CGFloat
        let iconColor: Color
        let iconGlow: Color
        let iconGlowRadius: CGFloat

        init(period: TimeOfDay, colorScheme: ColorScheme) {
            if colorScheme == .dark {
                // Dark mode: consistent
                self.spacing = 16
                self.rowSpacing = 10
                self.padding = 20
                self.iconColor = Color.terracottaRose
                self.iconGlow = Color.terracottaRose.opacity(0.3)
                self.iconGlowRadius = 2
            } else {
                // Light mode: time-adaptive
                switch period {
                case .deepNight, .evening:
                    // Night: Spacious, glowing
                    self.spacing = 18
                    self.rowSpacing = 12
                    self.padding = 22
                    self.iconColor = Color.terracottaRose
                    self.iconGlow = Color.terracottaRose.opacity(0.4)
                    self.iconGlowRadius = 3

                case .dawn:
                    // Dawn: Soft awakening
                    self.spacing = 17
                    self.rowSpacing = 11
                    self.padding = 21
                    self.iconColor = Color.terracottaRose.opacity(0.95)
                    self.iconGlow = Color.orange.opacity(0.25)
                    self.iconGlowRadius = 2.5

                case .earlyMorning, .lateMorning, .earlyAfternoon:
                    // Day: Compact, clear
                    self.spacing = 14
                    self.rowSpacing = 9
                    self.padding = 18
                    self.iconColor = Color.terracottaRose.opacity(0.8)
                    self.iconGlow = Color.clear
                    self.iconGlowRadius = 0

                case .lateAfternoon:
                    // Late afternoon: Transitioning
                    self.spacing = 15
                    self.rowSpacing = 10
                    self.padding = 19
                    self.iconColor = Color.terracottaRose.opacity(0.85)
                    self.iconGlow = Color.orange.opacity(0.15)
                    self.iconGlowRadius = 1.5

                case .goldenHour:
                    // Golden hour: Warm sparkle
                    self.spacing = 17
                    self.rowSpacing = 11
                    self.padding = 21
                    self.iconColor = Color.terracottaRose
                    self.iconGlow = Color.orange.opacity(0.5)
                    self.iconGlowRadius = 3.5

                case .dusk:
                    // Dusk: Magical twilight
                    self.spacing = 18
                    self.rowSpacing = 12
                    self.padding = 22
                    self.iconColor = Color.terracottaRose
                    self.iconGlow = Color.purple.opacity(0.5)
                    self.iconGlowRadius = 3.5
                }
            }
        }
    }

    // MARK: - Personal Section (Keep Existing)
    private var personalSection: some View {
        VStack(spacing: 16) {
            Text(localization.localize("profile.personalIntention"))
                .font(.system(size: 14, weight: .regular))
                .fontDesign(.serif)
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(Color.terracottaRose)
                        .font(.system(size: 14))
                    Text(localization.localize("profile.intentionPrompt"))
                        .font(.system(size: 13, weight: .regular))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                }

                TextField(localization.localize("profile.mottoPlaceholder"), text: $personalMotto, axis: .vertical)
                    .multilingualTextField()
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, weight: .regular))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    .padding(16)
                    .reverieCardStyle(colorScheme: colorScheme)                    .lineLimit(3...5)
                    .onChange(of: personalMotto) { _, newValue in
                        saveProfile()
                    }
            }
        }
        .padding(20)
        .reverieCardStyle(colorScheme: colorScheme)
    }

    // MARK: - Settings Section (Keep Existing - Week Start + Language)
    private var settingsSection: some View {
        VStack(spacing: 12) {
            Text(localization.localize("profile.preferences"))
                .font(.system(size: 14, weight: .regular))
                .fontDesign(.serif)
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Toggle(isOn: $weekStartsOnSunday) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(localization.localize("profile.weekStartSunday"))
                        .font(.system(size: 12, weight: .medium))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    Text(localization.localize("profile.weekStartDesc"))
                        .font(.system(size: 11, weight: .regular))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                }
            }
            .padding(12)
            .reverieCardStyle(colorScheme: colorScheme)            .onChange(of: weekStartsOnSunday) { _, newValue in
                saveProfile()
            }

            VStack(alignment: .leading, spacing: 6) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(localization.localize("profile.language"))
                        .font(.system(size: 12, weight: .medium))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    Text(localization.localize("profile.languageDesc"))
                        .font(.system(size: 11, weight: .regular))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                }

                Picker(localization.localize("profile.language"), selection: $localization.currentLanguage) {
                    ForEach(AppLanguage.allCases, id: \.self) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(12)
            .reverieCardStyle(colorScheme: colorScheme)            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(16)
        .reverieCardStyle(colorScheme: colorScheme)
    }

    // MARK: - Data Section (Keep Existing)
    private var dataSection: some View {
        VStack(spacing: 12) {
            Text(localization.localize("profile.dataManagement"))
                .font(.system(size: 14, weight: .regular))
                .fontDesign(.serif)
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                exportData()
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 13))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                        Text("Export Reflections")
                            .font(.system(size: 12, weight: .medium))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    }
                    Text("Create a PDF of this month's reflection notes")
                        .font(.system(size: 10, weight: .regular))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                        .padding(.leading, 26)
                }
                .padding(12)
                .reverieCardStyle(colorScheme: colorScheme)                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "icloud.fill")
                        .foregroundStyle(Color.dustyBlue)
                        .font(.system(size: 12))
                    Text(localization.localize("profile.icloudBackup"))
                        .font(.system(size: 12, weight: .medium))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                }

                Text(localization.localize("profile.icloudDesc"))
                    .font(.system(size: 11, weight: .regular))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
            }
            .padding(12)
            .reverieCardStyle(colorScheme: colorScheme)            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(16)
        .reverieCardStyle(colorScheme: colorScheme)
    }

    // MARK: - Storage Section (Keep Existing)
    private var storageSection: some View {
        VStack(spacing: 12) {
            Text("Storage Management")
                .font(.system(size: 14, weight: .regular))
                .fontDesign(.serif)
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("App Data Size")
                            .font(.system(size: 12, weight: .medium))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

                        Text(calculateStorageSize())
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color.sageGreen)
                            .shadow(color: Color.sageGreen.opacity(0.6), radius: 3, y: 1)
                    }

                    Spacer()

                    Image(systemName: "externaldrive.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.dustyBlue.opacity(0.75))
                }

                Divider()

                VStack(spacing: 6) {
                    StorageRow(icon: "text.alignleft", label: "Text Data", value: calculateTextSize())
                    StorageRow(icon: "photo", label: "Photos", value: calculatePhotoSize())
                    StorageRow(icon: "checkmark.circle", label: "Completions", value: "\(completions.count)")
                }
            }
            .padding(14)
            .reverieCardStyle(colorScheme: colorScheme)            .clipShape(RoundedRectangle(cornerRadius: 12))

            Button {
                showClearDataAlert = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                        .font(.system(size: 13))
                    Text("Clear Data Older Than 1 Year")
                        .font(.system(size: 12, weight: .medium))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                }
                .foregroundStyle(Color.red.opacity(0.8))
                .padding(12)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)

            Text("Clearing old data removes reflections and photos from over a year ago.")
                .font(.system(size: 11, weight: .regular))
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                .italic()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .reverieCardStyle(colorScheme: colorScheme)
    }

    // MARK: - Support Section (Keep Existing)
    private var supportSection: some View {
        VStack(spacing: 12) {
            Text(localization.localize("profile.support"))
                .font(.system(size: 14, weight: .regular))
                .fontDesign(.serif)
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                requestReview()
            } label: {
                HStack {
                    Image(systemName: "star.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.sageGreen)
                    Text(localization.localize("profile.rateApp"))
                        .font(.system(size: 12, weight: .medium))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                }
                .padding(12)
                .reverieCardStyle(colorScheme: colorScheme)                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)

            Button {
                sendFeedback()
            } label: {
                HStack {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.dustyBlue)
                    Text(localization.localize("profile.sendFeedback"))
                        .font(.system(size: 12, weight: .medium))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                }
                .padding(12)
                .reverieCardStyle(colorScheme: colorScheme)                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)

            HStack {
                Text(localization.localize("profile.version"))
                    .font(.system(size: 12, weight: .regular))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                Spacer()
                Text(appVersion)
                    .font(.system(size: 12, weight: .medium))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
            }
            .padding(12)
            .reverieCardStyle(colorScheme: colorScheme)            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(16)
        .reverieCardStyle(colorScheme: colorScheme)
    }

    // MARK: - Helper Functions (Keep All Existing + Add New)

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func requestReview() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }

    private func sendFeedback() {
        let email = "reveriearchive.studio@gmail.com"
        let subject = "ReverieWeaver Feedback"
        let body = """
        
        
        ---
        App Version: \(appVersion)
        iOS Version: \(UIDevice.current.systemVersion)
        Device: \(UIDevice.current.model)
        """

        let urlString = "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"

        if let url = URL(string: urlString) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                showMailUnavailable = true
            }
        } else {
            showMailUnavailable = true
        }
    }

    private func loadProfile() {
        if let existingProfile = profile {
            displayName = existingProfile.displayName
            personalMotto = existingProfile.personalMotto
            weekStartsOnSunday = existingProfile.weekStartsOnSunday
        } else {
            let newProfile = UserProfile()
            modelContext.insert(newProfile)
            try? modelContext.save()
            displayName = newProfile.displayName
            personalMotto = newProfile.personalMotto
            weekStartsOnSunday = newProfile.weekStartsOnSunday
        }
    }

    private func saveProfile() {
        if let existingProfile = profile {
            existingProfile.displayName = displayName
            existingProfile.personalMotto = personalMotto
            existingProfile.weekStartsOnSunday = weekStartsOnSunday
        } else {
            let newProfile = UserProfile(
                displayName: displayName,
                personalMotto: personalMotto,
                weekStartsOnSunday: weekStartsOnSunday
            )
            modelContext.insert(newProfile)
        }
        try? modelContext.save()
    }

    // MARK: - Export (now Newspaper PDF)
    private func exportData() {
        // Check if there's any data to export first
        let cal = Calendar.current
        let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: Date()))!
        let monthEnd = cal.date(byAdding: .month, value: 1, to: monthStart)!
        
        let weekly = reflectionNotes
            .filter { $0.type.lowercased() == "weekly" && $0.startDate >= monthStart && $0.startDate < monthEnd }
        let monthly = reflectionNotes
            .first { $0.type.lowercased() == "monthly" && $0.startDate >= monthStart && $0.startDate < monthEnd }
        
        // Show alert if no data to export
        guard !weekly.isEmpty || monthly != nil else {
            print("ℹ️ No ReflectionNotes found for this month.")
            showNoDataAlert = true
            ReverieHaptics.lightFeedback()
            return
        }
        
        // If data exists, proceed with export
        exportReflectionNewspaper(for: Date())
    }

    // ═══════════════════════════════════════════════════════════════
    // STEP 4: Improve the exportReflectionNewspaper() Function
    // ═══════════════════════════════════════════════════════════════
    // Replace the existing function with this improved version:

    private func exportReflectionNewspaper(for month: Date = Date()) {
        // Month bounds
        let cal = Calendar.current
        let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: month))!
        let monthEnd = cal.date(byAdding: .month, value: 1, to: monthStart)!

        // Collect entries: up to 4 weekly + 1 monthly
        let weekly = reflectionNotes
            .filter { $0.type.lowercased() == "weekly" && $0.startDate >= monthStart && $0.startDate < monthEnd }
            .sorted { $0.startDate < $1.startDate }
        let monthly = reflectionNotes
            .first { $0.type.lowercased() == "monthly" && $0.startDate >= monthStart && $0.startDate < monthEnd }

        // ✨ IMPROVED: This guard is now redundant since we check in exportData()
        // but keeping it as a safety net
        guard !weekly.isEmpty || monthly != nil else {
            print("ℹ️ No ReflectionNotes found for this month.")
            showNoDataAlert = true
            return
        }

        // Page setup (A4 portrait)
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
        let margin: CGFloat = 40
        let contentRect = pageRect.insetBy(dx: margin, dy: margin)

        // Typography (ink/newspaper vibe)
        let headerFont = UIFont(name: "Georgia-Bold", size: 24) ?? .boldSystemFont(ofSize: 24)
        let sectionTitleFont = UIFont(name: "Georgia-Bold", size: 16) ?? .boldSystemFont(ofSize: 16)
        let metaFont = UIFont(name: "Georgia-Italic", size: 11) ?? .italicSystemFont(ofSize: 11)
        let bodyFont = UIFont(name: "Georgia", size: 12) ?? .systemFont(ofSize: 12)

        // Formatters
        let monthNameFmt = DateFormatter(); monthNameFmt.dateFormat = "MMMM yyyy"
        let dayFmt = DateFormatter(); dayFmt.dateFormat = "MMM d"
        let stampFmt = DateFormatter(); stampFmt.dateFormat = "yyyy-MM-dd HH:mm"

        // File URL
        let pdfName = "Reverie_\(monthNameFmt.string(from: monthStart))_Reflections.pdf"
        let pdfURL = FileManager.default.temporaryDirectory.appendingPathComponent(pdfName)

        // Helpers
        func drawLine(_ ctx: CGContext, x1: CGFloat, y: CGFloat, x2: CGFloat, alpha: CGFloat = 0.12) {
            ctx.saveGState()
            ctx.setStrokeColor(UIColor.black.withAlphaComponent(alpha).cgColor)
            ctx.setLineWidth(0.5)
            ctx.move(to: CGPoint(x: x1, y: y))
            ctx.addLine(to: CGPoint(x: x2, y: y))
            ctx.strokePath()
            ctx.restoreGState()
        }

        func drawText(_ text: String, at rect: CGRect, font: UIFont, color: UIColor = .black) -> CGFloat {
            let style = NSMutableParagraphStyle(); style.lineSpacing = 2; style.alignment = .left
            let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color, .paragraphStyle: style]
            let attributed = NSAttributedString(string: text, attributes: attrs)
            let framesetter = CTFramesetterCreateWithAttributedString(attributed)
            let path = CGMutablePath(); path.addRect(rect)
            let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, nil)
            let context = UIGraphicsGetCurrentContext()!

            context.saveGState()
            context.textMatrix = .identity
            context.translateBy(x: 0, y: rect.origin.y * 2 + rect.height)
            context.scaleBy(x: 1.0, y: -1.0)
            CTFrameDraw(frame, context)
            context.restoreGState()

            let suggested = CTFramesetterSuggestFrameSizeWithConstraints(
                framesetter,
                CFRangeMake(0, 0),
                nil,
                rect.size,
                nil
            )
            return min(suggested.height, rect.height)
        }

        func heightFor(_ text: String, width: CGFloat, font: UIFont) -> CGFloat {
            let style = NSMutableParagraphStyle(); style.lineSpacing = 2
            let attrs: [NSAttributedString.Key: Any] = [.font: font, .paragraphStyle: style]
            let bounding = (text as NSString).boundingRect(
                with: CGSize(width: width, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: attrs,
                context: nil
            )
            return ceil(bounding.height)
        }

        func beginPage(_ renderer: UIGraphicsPDFRendererContext, pageIndex: Int) -> CGFloat {
            renderer.beginPage()
            let ctx = UIGraphicsGetCurrentContext()!

            let brand = "Reverie Archive — Reflection Notes"
            let brandRect = CGRect(x: contentRect.minX, y: contentRect.minY - 4, width: contentRect.width, height: 16)
            _ = drawText(brand, at: brandRect, font: metaFont, color: UIColor(white: 0.1, alpha: 1))

            let title = monthNameFmt.string(from: monthStart)
            let titleRect = CGRect(x: contentRect.minX, y: brandRect.maxY + 8, width: contentRect.width, height: 28)
            _ = drawText(title, at: titleRect, font: headerFont)

            drawLine(ctx, x1: contentRect.minX, y: titleRect.maxY + 8, x2: contentRect.maxX)
            return titleRect.maxY + 16
        }

        func drawFooter(pageIndex: Int) {
            let footerY = pageRect.maxY - margin + 12
            let rect = CGRect(x: contentRect.minX, y: footerY, width: contentRect.width, height: 12)
            _ = drawText("Page \(pageIndex)", at: rect, font: metaFont, color: .darkGray)
        }

        var sections: [ReflectionNote] = weekly
        if let m = monthly { sections.append(m) }

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        do {
            var pageIndex = 1
            try renderer.writePDF(to: pdfURL) { ctx in
                var cursorY = beginPage(ctx, pageIndex: pageIndex)

                for (idx, note) in sections.enumerated() {
                    let headerLabel = note.type.lowercased() == "weekly"
                        ? (note.label.isEmpty ? "Weekly" : note.label)
                        : (note.label.isEmpty ? "Monthly" : note.label)

                    let dateSpan: String = {
                        let s = dayFmt.string(from: note.startDate)
                        if let e = note.endDate { return "\(s) – \(dayFmt.string(from: e))" }
                        return s
                    }()

                    let sectionTitle = note.title.isEmpty ? "Untitled" : note.title
                    let sectionHeader = "\(headerLabel)  ·  \(dateSpan)"
                    let metaLine = (note.author?.isEmpty == false
                                    ? "By \(note.author!) • Last edited \(stampFmt.string(from: note.lastEdited))"
                                    : "Last edited \(stampFmt.string(from: note.lastEdited))")

                    // Space needed
                    let titleH = heightFor(sectionTitle, width: contentRect.width, font: sectionTitleFont)
                    let metaH  = heightFor(metaLine, width: contentRect.width, font: metaFont)
                    let bodyH  = heightFor(note.content, width: contentRect.width, font: bodyFont)
                    let needed = 6 + titleH + 6 + metaH + 8 + bodyH + 18

                    // Page break if needed
                    if cursorY + needed > contentRect.maxY {
                        drawFooter(pageIndex: pageIndex)
                        pageIndex += 1
                        cursorY = beginPage(ctx, pageIndex: pageIndex)
                    }

                    // Section header
                    let shRect = CGRect(x: contentRect.minX, y: cursorY, width: contentRect.width, height: 14)
                    _ = drawText(sectionHeader, at: shRect, font: metaFont, color: .darkGray)
                    cursorY = shRect.maxY + 6

                    // Title
                    let tRect = CGRect(x: contentRect.minX, y: cursorY, width: contentRect.width, height: titleH)
                    _ = drawText(sectionTitle, at: tRect, font: sectionTitleFont)
                    cursorY = tRect.maxY + 6

                    // Meta
                    let mRect = CGRect(x: contentRect.minX, y: cursorY, width: contentRect.width, height: metaH)
                    _ = drawText(metaLine, at: mRect, font: metaFont, color: .darkGray)
                    cursorY = mRect.maxY + 8

                    // Body (chunk across pages if needed)
                    var remaining = note.content
                    while !remaining.isEmpty {
                        let spaceLeft = contentRect.maxY - cursorY
                        if spaceLeft < 40 {
                            drawFooter(pageIndex: pageIndex)
                            pageIndex += 1
                            cursorY = beginPage(ctx, pageIndex: pageIndex)
                        }
                        let style = NSMutableParagraphStyle(); style.lineSpacing = 2
                        let attrs: [NSAttributedString.Key: Any] = [.font: bodyFont, .paragraphStyle: style]
                        let maxRect = CGRect(
                            x: contentRect.minX,
                            y: cursorY,
                            width: contentRect.width,
                            height: contentRect.maxY - cursorY
                        )

                        // Fit as much as possible
                        var low = 0, high = remaining.count, fit = 0
                        while low <= high {
                            let mid = (low + high) / 2
                            let test = String(remaining.prefix(mid))
                            let h = (test as NSString).boundingRect(
                                with: CGSize(width: maxRect.width, height: .greatestFiniteMagnitude),
                                options: [.usesLineFragmentOrigin, .usesFontLeading],
                                attributes: attrs,
                                context: nil
                            ).height
                            if h <= maxRect.height {
                                fit = mid
                                low = mid + 1
                            } else {
                                high = mid - 1
                            }
                        }

                        let chunk = String(remaining.prefix(fit))
                        _ = drawText(chunk, at: maxRect, font: bodyFont)
                        cursorY = maxRect.origin.y + heightFor(chunk, width: maxRect.width, font: bodyFont)
                        remaining.removeFirst(fit)

                        if !remaining.isEmpty {
                            drawFooter(pageIndex: pageIndex)
                            pageIndex += 1
                            cursorY = beginPage(ctx, pageIndex: pageIndex)
                        }
                    }

                    // Divider
                    let lineY = cursorY + 8
                    let cg = UIGraphicsGetCurrentContext()!
                    drawLine(cg, x1: contentRect.minX, y: lineY, x2: contentRect.maxX)
                    cursorY = lineY + 10

                    // Small spacer (not after last)
                    if idx < sections.count - 1 { cursorY += 2 }
                }

                drawFooter(pageIndex: pageIndex)
            }

            // ✨ IMPROVED: Provide success feedback via haptics
            ReverieHaptics.successFeedback()
            
            // Share sheet
            let activityVC = UIActivityViewController(activityItems: [pdfURL], applicationActivities: nil)
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = scene.windows.first,
               let root = window.rootViewController {
                activityVC.popoverPresentationController?.sourceView = root.view
                root.present(activityVC, animated: true)
            } else {
                print("📰 Saved newspaper PDF at: \(pdfURL)")
            }
            
            // ✨ OPTIONAL: Remove this line since share sheet already provides feedback
            // showExportSuccess = true
            
        } catch {
            // ✨ IMPROVED: Show error alert to user instead of just console
            print("❌ PDF export failed: \(error)")
            exportErrorMessage = "Failed to create PDF: \(error.localizedDescription)"
            showExportError = true
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }

    // MARK: - Storage Calculation Functions

    private func calculateStorageSize() -> String {
        let textBytes = completions.count * 200 + reflections.count * 500
        let photoBytes = reflections.filter { $0.photoData != nil }
            .reduce(0) { $0 + ($1.photoData?.count ?? 0) }

        let totalBytes = textBytes + photoBytes
        let totalMB = Double(totalBytes) / 1_024_000

        if totalMB < 1 {
                    return String(format: "%.1f KB", Double(totalBytes) / 1024)
                } else if totalMB < 1000 {
                    return String(format: "%.1f MB", totalMB)
                } else {
                    return String(format: "%.2f GB", totalMB / 1024)
                }
            }

            private func calculateTextSize() -> String {
                let bytes = completions.count * 200 + reflections.count * 500
                let kb = Double(bytes) / 1024
                return String(format: "%.1f KB", kb)
            }

            private func calculatePhotoSize() -> String {
                let photoBytes = reflections.filter { $0.photoData != nil }
                    .reduce(0) { $0 + ($1.photoData?.count ?? 0) }

                if photoBytes < 1_024_000 {
                    return String(format: "%.1f KB", Double(photoBytes) / 1024)
                } else {
                    return String(format: "%.1f MB", Double(photoBytes) / 1_024_000)
                }
            }

            private func clearOldData() {
                let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: Date())!

                let oldReflections = reflections.filter { $0.createdAt < oneYearAgo }

                for reflection in oldReflections {
                    modelContext.delete(reflection)
                }

                let oldCompletions = completions.filter { $0.completedAt < oneYearAgo }

                for completion in oldCompletions {
                    modelContext.delete(completion)
                }

                try? modelContext.save()
            }

            // MARK: - ✨ NEW: Gamification Initialization

            private func initializeGamification() {
                // Start journey if not started
                journeyManager.startJourney()
                journeyManager.refreshJourney()
                journeyManager.updateLevel(totalCompletions: totalCompletions)

                // Initialize constellations (only runs once)
                let constellationManager = ConstellationManager(modelContext: modelContext)
                constellationManager.initializeConstellations()

                // Check for unlocks
                constellationManager.checkUnlocks(habits: habits, completions: completions)

                // Check for invisible achievements
                let invisibleManager = InvisibleAchievementManager(modelContext: modelContext)
                invisibleManager.checkForNewAchievements(habits: habits, completions: completions)
            }
        }

        // MARK: - Storage Row Component
        struct StorageRow: View {
            @Environment(\.colorScheme) private var colorScheme  // ← Add this line
            let icon: String
            let label: String
            let value: String

            var body: some View {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 11))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        .frame(width: 20)

                    Text(label)
                        .font(.system(size: 12, weight: .regular))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

                    Spacer()

                    Text(value)
                        .font(.system(size: 11, weight: .medium))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                }
            }
        }

        #Preview {
            ProfileView()
                .modelContainer(for: [
                    UserProfile.self,
                    Habit.self,
                    HabitCompletion.self,
                    Achievement.self,
                    Reflection.self,
                    ConstellationBadge.self,
                    InvisibleAchievement.self
                ])
        }



