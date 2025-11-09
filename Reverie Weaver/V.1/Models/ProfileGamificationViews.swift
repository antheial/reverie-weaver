//
//  ConstellationBadgeView.swift
//  Reverie Weaver
//
//  Created by Antheia Li on 10/24/25.
//
//
// ProfileGamificationViews.swift
// Reverie Weaver
//
// SwiftUI components for the gamification system
// to be integrated into ProfileView
//

import SwiftUI
import SwiftData

// MARK: - Constellation Badge View

struct ConstellationBadgeView: View {
    let constellation: ConstellationBadge
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Glow effect for unlocked
                if constellation.isUnlocked {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(hex: constellation.colorHex).opacity(0.4),
                                    Color(hex: constellation.colorHex).opacity(0.1),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 40
                            )
                        )
                        .frame(width: 70, height: 70)
                        .blur(radius: 8)
                }
                
                // Badge circle
                Circle()
                    .fill(
                        constellation.isUnlocked
                        ? Color(hex: constellation.colorHex).opacity(colorScheme == .dark ? 0.25 : 0.15)
                        : Color.dynamicSecondaryLabel.opacity(0.1)
                    )
                    .frame(width: 60, height: 60)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                constellation.isUnlocked
                                ? Color(hex: constellation.colorHex).opacity(0.4)
                                : Color.dynamicSecondaryLabel.opacity(0.2),
                                lineWidth: 2
                            )
                    )
                
                // Icon
                Image(systemName: constellation.iconName)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(
                        constellation.isUnlocked
                        ? Color(hex: constellation.colorHex)
                        : Color.dynamicSecondaryLabel.opacity(0.4)
                    )
                
                // Sparkle indicator for unlocked
                if constellation.isUnlocked {
                    VStack {
                        HStack {
                            Spacer()
                            Circle()
                                .fill(Color(hex: "FFD18B"))
                                .frame(width: 18, height: 18)
                                .overlay(
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundStyle(.white)
                                )
                                .offset(x: 8, y: -8)
                        }
                        Spacer()
                    }
                    .frame(width: 60, height: 60)
                }
            }
            
            Text(constellation.name)
                .font(.system(size: 10, weight: .medium))
                .fontDesign(.serif)
                .foregroundStyle(
                    constellation.isUnlocked
                    ? Color.dynamicLabel
                    : Color.dynamicSecondaryLabel.opacity(0.6)
                )
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: 28)
        }
        .frame(width: 70)
    }
}

// MARK: - Constellation Story Sheet

struct ConstellationStoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    let constellation: ConstellationBadge
    
    var body: some View {
        ZStack {
            ReverieWeaverBackground()
            
            ScrollView {
                VStack(spacing: 24) {
                    Spacer().frame(height: 20)
                    
                    // Icon
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color(hex: constellation.colorHex).opacity(0.3),
                                        Color(hex: constellation.colorHex).opacity(0.1),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 120, height: 120)
                            .blur(radius: 20)
                        
                        Circle()
                            .fill(Color(hex: constellation.colorHex).opacity(0.2))
                            .frame(width: 100, height: 100)
                            .overlay(
                                Circle()
                                    .strokeBorder(
                                        Color(hex: constellation.colorHex).opacity(0.4),
                                        lineWidth: 3
                                    )
                            )
                            .shadow(color: Color(hex: constellation.colorHex).opacity(0.3), radius: 20, y: 8)
                        
                        Image(systemName: constellation.iconName)
                            .font(.system(size: 46, weight: .semibold))
                            .foregroundStyle(Color(hex: constellation.colorHex))
                    }
                    
                    // Title
                    VStack(spacing: 8) {
                        Text(constellation.name)
                            .font(.system(size: 28, weight: .bold))
                            .fontDesign(.serif)
                            .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

                        Text("Constellation Unlocked")
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(1)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(Color(hex: constellation.colorHex))
                            )
                        
                        if let date = constellation.unlockedDate {
                            Text(date.formatted(date: .abbreviated, time: .omitted))
                                .font(.system(size: 11, weight: .regular))
                                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        }
                    }
                    
                    // Divider
                    HStack(spacing: 12) {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.clear,
                                        Color(hex: constellation.colorHex).opacity(0.3),
                                        Color.clear
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 40)
                    
                    // Story
                    Text(constellation.story)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(
                            colorScheme == .dark
                            ? Color.white.opacity(0.95)
                            : Color.black.opacity(0.85)
                        )
                        .lineSpacing(6)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    // Category badge
                    HStack(spacing: 6) {
                        Image(systemName: "tag.fill")
                            .font(.system(size: 10))
                        Text(constellation.category)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(Color(hex: constellation.colorHex).opacity(0.8))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color(hex: constellation.colorHex).opacity(0.1))
                            .overlay(
                                Capsule()
                                    .strokeBorder(Color(hex: constellation.colorHex).opacity(0.3), lineWidth: 1)
                            )
                    )
                    
                    Spacer().frame(height: 20)
                }
                .padding(.horizontal, 24)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    dismiss()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.35))
                            .frame(width: 32, height: 32)
                            .shadow(color: Color.shadowColor, radius: 4, y: 2)
                        Circle()
                            .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                            .frame(width: 32, height: 32)
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .semibold))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Invisible Achievement Row

struct InvisibleAchievementRow: View {
    let achievement: InvisibleAchievement
    let colorScheme: ColorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color(hex: achievement.colorHex).opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: achievement.iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color(hex: achievement.colorHex))
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(achievement.name)
                        .font(.system(size: 13, weight: .semibold))
                        .fontDesign(.serif)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

                    Spacer()
                    
                    Text(achievement.discoveredDate.timeAgo())
                        .font(.system(size: 10, weight: .regular))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                }
                
                Text(achievement.story)
                    .font(.system(size: 11, weight: .regular))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: achievement.colorHex).opacity(colorScheme == .dark ? 0.12 : 0.08),
                            Color(hex: achievement.colorHex).opacity(colorScheme == .dark ? 0.08 : 0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color(hex: achievement.colorHex).opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Anniversary Celebration Card

struct AnniversaryCelebrationCard: View {
    let milestone: AnniversaryMilestone
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.sageGreen, Color.dustyBlue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .shadow(color: Color.sageGreen.opacity(0.4), radius: 8, y: 4)
                    
                    Image(systemName: milestone.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(milestone.title)
                        .font(.system(size: 18, weight: .bold))
                        .fontDesign(.serif)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

                    Text("\(milestone.days) days of weaving")
                        .font(.system(size: 11, weight: .medium))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                }
                
                Spacer()
            }
            
            Text(milestone.message)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(
                    colorScheme == .dark
                    ? Color.white.opacity(0.95)
                    : Color.black.opacity(0.85)
                )
                .lineSpacing(4)
                .multilineTextAlignment(.leading)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.sageGreen.opacity(colorScheme == .dark ? 0.15 : 0.1),
                            Color.dustyBlue.opacity(colorScheme == .dark ? 0.15 : 0.1),
                            Color.paleMauve.opacity(colorScheme == .dark ? 0.15 : 0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.sageGreen.opacity(0.4), Color.dustyBlue.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: Color.shadowColor.opacity(0.15), radius: 8, y: 4)
    }
}

// MARK: - Current Season Banner

struct CurrentSeasonBanner: View {
    let season: Season
    let daysSinceStart: Int
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top row: Icon, Title, and Day count
            HStack(spacing: 12) {
                Image(systemName: season.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: season.colorHex))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(season.name)
                        .font(.system(size: 13, weight: .medium))
                        .fontDesign(.serif)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    
                    Text(season.subtitle)
                        .font(.system(size: 11, weight: .regular))
                        .italic()
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                }
                
                Spacer()
                
                Text("Day \(daysSinceStart)")
                    .font(.system(size: 10, weight: .medium))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
            }
            
            // Subtle divider
            Rectangle()
                .fill(Color(hex: season.colorHex).opacity(0.15))
                .frame(height: 1)
                .padding(.horizontal, -2)
            
            // Description text
            Text(season.description)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(
                    colorScheme == .dark
                    ? Color.white.opacity(0.85)
                    : Color.black.opacity(0.75)
                )
                .lineSpacing(3)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: season.colorHex).opacity(colorScheme == .dark ? 0.12 : 0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color(hex: season.colorHex).opacity(0.25), lineWidth: 1)
        )
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - ✨ TIME-ADAPTIVE WEAVER LEVEL CARD
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct WeaverLevelCard: View {
    let level: WeaverLevel
    let totalCompletions: Int
    let colorScheme: ColorScheme

    private var progress: Double {
        guard let next = level.next else { return 1.0 }
        return min(Double(totalCompletions) / Double(next), 1.0)
    }

    // Time-adaptive configuration
    private var config: WeaverLevelCardConfig {
        let hour = Calendar.current.component(.hour, from: Date())
        let period = TimeOfDay(hour: hour)
        return WeaverLevelCardConfig(period: period, colorScheme: colorScheme)
    }

    var body: some View {
        VStack(spacing: config.spacing) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12))
                    .foregroundStyle(config.iconColor)
                    .shadow(color: config.iconGlow, radius: config.iconGlowRadius)  // ✨ Time-adaptive glow

                Text(level.title)
                    .font(.system(size: 14, weight: .medium))
                    .fontDesign(.serif)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

                Spacer()

                Text("Level \(level.level)")
                    .font(.system(size: 11, weight: .regular))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
            }

            // Time-adaptive progress bar
            if let next = level.next {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background track
                        RoundedRectangle(cornerRadius: config.progressBarRadius)
                            .fill(config.progressTrackColor)

                        // Progress fill with time-adaptive gradient
                        RoundedRectangle(cornerRadius: config.progressBarRadius)
                            .fill(config.progressGradient)
                            .frame(width: geometry.size.width * progress)
                            .shadow(
                                color: config.progressGlow,
                                radius: config.progressGlowRadius
                            )  // ✨ Glowing progress bar
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
                    }
                }
                .frame(height: config.progressBarHeight)

                // Remaining completions text
                if totalCompletions < next {
                    Text("\(next - totalCompletions) more to next level")
                        .font(.system(size: 9, weight: .regular))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            } else {
                // Transcendent level message
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(config.transcendentIconColor)
                        .shadow(color: config.transcendentGlow, radius: config.transcendentGlowRadius)

                    Text("Transcendent Level Reached")
                        .font(.system(size: 10, weight: .medium))
                        .italic()
                        .foregroundStyle(config.transcendentTextColor)
                        .shadow(color: config.transcendentGlow, radius: 1)

                    Image(systemName: "star.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(config.transcendentIconColor)
                        .shadow(color: config.transcendentGlow, radius: config.transcendentGlowRadius)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(config.padding)  // ✨ Time-adaptive padding
        .reverieCardStyle(colorScheme: colorScheme)  // ✨ Already time-adaptive!
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - WEAVER LEVEL CARD CONFIGURATION
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

private struct WeaverLevelCardConfig {
    let spacing: CGFloat
    let padding: CGFloat
    let iconColor: Color
    let iconGlow: Color
    let iconGlowRadius: CGFloat
    let progressBarHeight: CGFloat
    let progressBarRadius: CGFloat
    let progressTrackColor: Color
    let progressGradient: LinearGradient
    let progressGlow: Color
    let progressGlowRadius: CGFloat
    let transcendentIconColor: Color
    let transcendentTextColor: Color
    let transcendentGlow: Color
    let transcendentGlowRadius: CGFloat

    init(period: TimeOfDay, colorScheme: ColorScheme) {
        if colorScheme == .dark {
            // Dark mode: consistent, elegant
            self.spacing = 12
            self.padding = 16
            self.iconColor = Color.paleMauve.opacity(0.7)
            self.iconGlow = Color.paleMauve.opacity(0.3)
            self.iconGlowRadius = 2
            self.progressBarHeight = 4
            self.progressBarRadius = 3
            self.progressTrackColor = Color.dynamicSecondaryLabel.opacity(0.1)
            self.progressGradient = LinearGradient(
                colors: [Color.paleMauve.opacity(0.5), Color.sageGreen.opacity(0.5)],
                startPoint: .leading,
                endPoint: .trailing
            )
            self.progressGlow = Color.clear
            self.progressGlowRadius = 0
            self.transcendentIconColor = Color.paleMauve.opacity(0.8)
            self.transcendentTextColor = Color.paleMauve.opacity(0.8)
            self.transcendentGlow = Color.paleMauve.opacity(0.3)
            self.transcendentGlowRadius = 2
        } else {
            // Light mode: time-adaptive magic
            switch period {
            case .deepNight, .evening:
                // Night: Dreamy, glowing progress
                self.spacing = 14
                self.padding = 18
                self.iconColor = Color.paleMauve.opacity(0.8)
                self.iconGlow = Color.paleMauve.opacity(0.4)
                self.iconGlowRadius = 3
                self.progressBarHeight = 5
                self.progressBarRadius = 4
                self.progressTrackColor = Color.dynamicSecondaryLabel.opacity(0.12)
                self.progressGradient = LinearGradient(
                    colors: [Color.paleMauve.opacity(0.6), Color.sageGreen.opacity(0.6)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                self.progressGlow = Color.paleMauve.opacity(0.3)
                self.progressGlowRadius = 2
                self.transcendentIconColor = Color.paleMauve
                self.transcendentTextColor = Color.paleMauve.opacity(0.9)
                self.transcendentGlow = Color.paleMauve.opacity(0.5)
                self.transcendentGlowRadius = 3

            case .dawn:
                // Dawn: Gentle awakening with warm tones
                self.spacing = 13
                self.padding = 17
                self.iconColor = Color.paleMauve.opacity(0.75)
                self.iconGlow = Color.orange.opacity(0.25)
                self.iconGlowRadius = 2.5
                self.progressBarHeight = 4.5
                self.progressBarRadius = 3.5
                self.progressTrackColor = Color.dynamicSecondaryLabel.opacity(0.1)
                self.progressGradient = LinearGradient(
                    colors: [
                        Color.orange.opacity(0.4),
                        Color.paleMauve.opacity(0.5),
                        Color.sageGreen.opacity(0.5)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                self.progressGlow = Color.orange.opacity(0.2)
                self.progressGlowRadius = 1.5
                self.transcendentIconColor = Color.orange.opacity(0.8)
                self.transcendentTextColor = Color.paleMauve.opacity(0.85)
                self.transcendentGlow = Color.orange.opacity(0.3)
                self.transcendentGlowRadius = 2.5

            case .earlyMorning, .lateMorning, .earlyAfternoon:
                // Day: Crisp, clear, efficient
                self.spacing = 11
                self.padding = 15
                self.iconColor = Color.paleMauve.opacity(0.6)
                self.iconGlow = Color.clear
                self.iconGlowRadius = 0
                self.progressBarHeight = 4
                self.progressBarRadius = 3
                self.progressTrackColor = Color.dynamicSecondaryLabel.opacity(0.08)
                self.progressGradient = LinearGradient(
                    colors: [Color.paleMauve.opacity(0.45), Color.sageGreen.opacity(0.45)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                self.progressGlow = Color.clear
                self.progressGlowRadius = 0
                self.transcendentIconColor = Color.paleMauve.opacity(0.7)
                self.transcendentTextColor = Color.paleMauve.opacity(0.75)
                self.transcendentGlow = Color.clear
                self.transcendentGlowRadius = 0

            case .lateAfternoon:
                // Late afternoon: Transitioning warmth
                self.spacing = 12
                self.padding = 16
                self.iconColor = Color.paleMauve.opacity(0.7)
                self.iconGlow = Color.orange.opacity(0.15)
                self.iconGlowRadius = 1.5
                self.progressBarHeight = 4
                self.progressBarRadius = 3
                self.progressTrackColor = Color.dynamicSecondaryLabel.opacity(0.09)
                self.progressGradient = LinearGradient(
                    colors: [Color.paleMauve.opacity(0.5), Color.sageGreen.opacity(0.5)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                self.progressGlow = Color.orange.opacity(0.1)
                self.progressGlowRadius = 1
                self.transcendentIconColor = Color.paleMauve.opacity(0.8)
                self.transcendentTextColor = Color.paleMauve.opacity(0.8)
                self.transcendentGlow = Color.orange.opacity(0.2)
                self.transcendentGlowRadius = 2

            case .goldenHour:
                // Golden hour: Warm, glowing achievement
                self.spacing = 14
                self.padding = 18
                self.iconColor = Color.paleMauve
                self.iconGlow = Color.orange.opacity(0.6)
                self.iconGlowRadius = 4
                self.progressBarHeight = 5
                self.progressBarRadius = 4
                self.progressTrackColor = Color.dynamicSecondaryLabel.opacity(0.1)
                self.progressGradient = LinearGradient(
                    colors: [
                        Color.orange.opacity(0.5),
                        Color.paleMauve.opacity(0.6),
                        Color.sageGreen.opacity(0.6)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                self.progressGlow = Color.orange.opacity(0.4)
                self.progressGlowRadius = 2.5
                self.transcendentIconColor = Color.orange
                self.transcendentTextColor = Color.paleMauve
                self.transcendentGlow = Color.orange.opacity(0.6)
                self.transcendentGlowRadius = 4

            case .dusk:
                // Dusk: Magical twilight achievement
                self.spacing = 14
                self.padding = 18
                self.iconColor = Color.paleMauve
                self.iconGlow = Color.purple.opacity(0.6)
                self.iconGlowRadius = 4
                self.progressBarHeight = 5
                self.progressBarRadius = 4
                self.progressTrackColor = Color.dynamicSecondaryLabel.opacity(0.12)
                self.progressGradient = LinearGradient(
                    colors: [
                        Color.purple.opacity(0.5),
                        Color.paleMauve.opacity(0.6),
                        Color.sageGreen.opacity(0.5)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                self.progressGlow = Color.purple.opacity(0.4)
                self.progressGlowRadius = 3
                self.transcendentIconColor = Color.purple.opacity(0.9)
                self.transcendentTextColor = Color.paleMauve
                self.transcendentGlow = Color.purple.opacity(0.6)
                self.transcendentGlowRadius = 4
            }
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// WHAT ADAPTS THROUGHOUT THE DAY
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/*

VISUAL CHANGES BY TIME OF DAY:
═════════════════════════════════════════════════════════════

🌙 NIGHT (12-5 AM, 9 PM-12 AM)
   ✨ Icon: Soft purple glow
   📊 Progress bar: Slightly thicker (5pt), glowing edges
   🎨 Colors: Richer, more saturated
   📐 Layout: More spacious (18pt padding)
   💫 Feel: Dreamy, accomplished

🌅 DAWN (5-7 AM)
   ✨ Icon: Warm orange morning glow
   📊 Progress bar: Orange-tinted gradient start
   🎨 Colors: Awakening warmth
   📐 Layout: Gentle spacing (17pt)
   💫 Feel: New beginnings

☀️ MORNING/AFTERNOON (7 AM-5 PM)
   ✨ Icon: No glow (crisp & clear)
   📊 Progress bar: Standard (4pt), no glow
   🎨 Colors: Lighter, efficient
   📐 Layout: Compact (15pt padding)
   💫 Feel: Professional, focused

🌆 GOLDEN HOUR (5-7 PM)
   ✨ Icon: Strong golden glow (4pt)
   📊 Progress bar: Orange gradient, glowing (2.5pt)
   🎨 Colors: Warm, celebratory
   📐 Layout: Expanded (18pt)
   💫 Feel: Achievement unlocked!

🌃 DUSK (7-9 PM)
   ✨ Icon: Purple twilight glow (4pt)
   📊 Progress bar: Purple-tinted, glowing (3pt)
   🎨 Colors: Magical, ethereal
   📐 Layout: Spacious (18pt)
   💫 Feel: Mystical transcendence

🌑 DARK MODE (Any Time)
   ✨ Icon: Subtle purple glow (2pt)
   📊 Progress bar: Standard gradient
   🎨 Colors: Consistent elegance
   📐 Layout: Balanced (16pt)
   💫 Feel: Sophisticated


COMPARISON TABLE:
═════════════════════════════════════════════════════════════

┌──────────────┬─────────┬────────┬─────────────────────────┐
│ Time         │ Padding │ Bar Ht │ Glow Effect             │
├──────────────┼─────────┼────────┼─────────────────────────┤
│ Night        │ 18pt    │ 5pt    │ 🟣 Purple (2pt glow)    │
│ Dawn         │ 17pt    │ 4.5pt  │ 🟠 Orange (1.5pt glow)  │
│ Morning/Day  │ 15pt    │ 4pt    │ None (crisp)            │
│ Afternoon    │ 16pt    │ 4pt    │ 🟠 Subtle (1pt glow)    │
│ Golden Hour  │ 18pt    │ 5pt    │ 🟠 Strong (2.5pt glow)  │
│ Dusk         │ 18pt    │ 5pt    │ 🟣 Purple (3pt glow)    │
│ Dark Mode    │ 16pt    │ 4pt    │ Minimal (consistent)    │
└──────────────┴─────────┴────────┴─────────────────────────┘


TRANSCENDENT LEVEL MESSAGING:
═════════════════════════════════════════════════════════════

When max level is reached, the card shows special effects:

🌅 Dawn: ⭐ "Transcendent Level" ⭐ with warm orange glow
🌆 Golden Hour: ⭐ Strong golden aura around stars ⭐
🌃 Dusk: ⭐ Purple twilight magic around message ⭐
🌙 Night: ⭐ Soft luminescent glow ⭐

The transcendent message feels EARNED and SPECIAL!


WHY THESE CHANGES MATTER:
═════════════════════════════════════════════════════════════

✨ Progress Bar Glow:
   • Golden Hour: Achievement feels GLORIOUS
   • Dusk: Progress feels MAGICAL
   • Day: Clean and professional
   • Night: Gentle and encouraging

🎨 Gradient Colors:
   • Dawn/Golden Hour: Orange tint = warmth, growth
   • Dusk: Purple tint = mystical achievement
   • Day: Standard colors = clarity
   • Adapts to the emotion of the time

📐 Spacing & Size:
   • More spacious at night = celebration
   • Compact during day = efficiency
   • Progress bar slightly thicker when glowing = emphasis

💫 Overall Psychology:
   • Morning: "Let's get to work!"
   • Golden Hour: "Look how far you've come!"
   • Dusk: "You're transcending!"
   • Night: "Rest, you've earned it"


IMPLEMENTATION NOTES:
═════════════════════════════════════════════════════════════

✅ Drop-in replacement for existing WeaverLevelCard
✅ All animations preserved (spring animation)
✅ Works with existing WeaverLevel model
✅ Integrates with timeAdaptiveText
✅ Uses time-adaptive card style
✅ Consistent with Reverie Weaver aesthetic
✅ Performance: Minimal overhead (just config calculation)

The card now CELEBRATES progress differently throughout
the day, making achievement feel more meaningful!

*/

// MARK: - Helper Extensions

extension Date {
    func timeAgo() -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day, .hour, .minute], from: self, to: now)
        
        if let days = components.day, days > 0 {
            if days == 1 {
                return "1 day ago"
            } else if days < 7 {
                return "\(days) days ago"
            } else if days < 30 {
                let weeks = days / 7
                return weeks == 1 ? "1 week ago" : "\(weeks) weeks ago"
            } else if days < 365 {
                let months = days / 30
                return months == 1 ? "1 month ago" : "\(months) months ago"
            } else {
                let years = days / 365
                return years == 1 ? "1 year ago" : "\(years) years ago"
            }
        } else if let hours = components.hour, hours > 0 {
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        } else if let minutes = components.minute, minutes > 0 {
            return minutes == 1 ? "1 minute ago" : "\(minutes) minutes ago"
        } else {
            return "Just now"
        }
    }
}
