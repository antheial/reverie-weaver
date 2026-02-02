//
//  ProfileGamificationViews.swift
//  Reverie Weaver
//
//  Created by Antheia Li on 10/24/25.
//
//

import SwiftUI
import SwiftData

// MARK: - Constellation Badge View
struct ConstellationBadgeView: View {
    let constellation: ConstellationBadge
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

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
                                        .font(.system(size: 11, weight: .bold))
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
                .font(.system(size: 11, weight: .medium))
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

// MARK: - Constellation Story View (Magical Artifact Edition)

struct ConstellationStoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    let constellation: ConstellationBadge

    private let goldColor = Color(hex: "D4AF37")
    private let midnightStart = Color(hex: "0F172A")
    private let midnightEnd = Color(hex: "151515")
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.95).ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack {
                    
                    Spacer().frame(height: 50)
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    colors: [midnightStart, midnightEnd],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )

                        VStack {
                            
                            Spacer()
                            
                            ZStack {
                                // 1. Large Faint Diamond
                                Image(systemName: "rhombus.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 300, height: 300)
                                    .foregroundStyle(Color(hex: constellation.colorHex).opacity(0.03))
                                    .blur(radius: 5)
                                
                                // 2. Vertical Axis Line
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.clear, Color(hex: constellation.colorHex).opacity(0.05), .clear],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(width: 1, height: 450)
                                
                                // 3. Sharp Thin Outline
                                Image(systemName: "rhombus")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 260, height: 260)
                                    .foregroundStyle(Color(hex: constellation.colorHex).opacity(0.05))
                                    .fontWeight(.thin)
                            }
                            .offset(y: 120)
                            Spacer()
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 18)
                                .strokeBorder(goldColor.opacity(0.5), lineWidth: 1)
                                .padding(6)
                            
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(
                                    goldColor.opacity(0.3),
                                    style: StrokeStyle(lineWidth: 0.5, dash: [4, 6])
                                )
                                .padding(14)
                            
                            // Corner Flourishes
                            VStack {
                                HStack {
                                    Image(systemName: "sparkle").font(.system(size: 11)).foregroundStyle(goldColor)
                                    Spacer()
                                    Image(systemName: "sparkle").font(.system(size: 11)).foregroundStyle(goldColor)
                                }
                                Spacer()
                                HStack {
                                    Image(systemName: "sparkle").font(.system(size: 11)).foregroundStyle(goldColor)
                                    Spacer()
                                    Image(systemName: "sparkle").font(.system(size: 11)).foregroundStyle(goldColor)
                                }
                            }
                            .padding(10)
                        }
                        
                        VStack(spacing: 0) {
                            
                            // 1. Arcana Number
                            Text(constellation.chapter.romanNumeral)
                                .font(.system(size: 15, weight: .bold, design: .serif))
                                .foregroundStyle(goldColor.opacity(0.6))
                                .padding(.top, 40)
                            
                            // 2. THE MAGICAL BURST
                            ZStack {
                                ForEach(0..<12) { i in
                                    Rectangle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color(hex: constellation.colorHex).opacity(0), Color(hex: constellation.colorHex).opacity(0.1)],
                                                startPoint: .bottom,
                                                endPoint: .top
                                            )
                                        )
                                        .frame(width: 1, height: 100)
                                        .offset(y: -50)
                                        .rotationEffect(.degrees(Double(i) * 30))
                                }
                                
                                // Celestial Rings
                                Circle()
                                    .strokeBorder(goldColor.opacity(0.1), lineWidth: 1)
                                    .frame(width: 140, height: 140)
                                
                                Circle()
                                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [2, 10]))
                                    .foregroundStyle(goldColor.opacity(0.3))
                                    .frame(width: 160, height: 160)
                                    .rotationEffect(.degrees(45))
                                
                                // Diamond Frame
                                Rectangle()
                                    .stroke(goldColor.opacity(0.3), lineWidth: 1)
                                    .frame(width: 90, height: 90)
                                    .rotationEffect(.degrees(45))
                                
                                // Inner Glow Halo
                                Circle()
                                    .fill(Color(hex: constellation.colorHex).opacity(0.15))
                                    .frame(width: 100, height: 100)
                                    .blur(radius: 20)
                                
                                // The Icon
                                Image(systemName: constellation.iconName)
                                    .font(.system(size: 50, weight: .light))
                                    .foregroundStyle(Color(hex: constellation.colorHex))
                                    .shadow(color: Color(hex: constellation.colorHex).opacity(0.8), radius: 10)
                            }
                            .padding(.vertical, 30)
                            
                            // 3. Title (Engraved Look)
                            Text(constellation.name.uppercased())
                                .font(.system(size: 22, weight: .bold, design: .serif))
                                .tracking(3)
                                .foregroundStyle(Color(hex: "F5E6D3"))
                                .multilineTextAlignment(.center)
                                .shadow(color: goldColor.opacity(0.3), radius: 10)
                                .padding(.horizontal, 30)
                            
                            // 4. Alchemical Separator
                            HStack(spacing: 8) {
                                Rectangle().fill(LinearGradient(colors: [.clear, goldColor], startPoint: .leading, endPoint: .trailing)).frame(height: 0.5)
                                Image(systemName: "moon.stars.fill").font(.system(size: 11)).foregroundStyle(goldColor)
                                Rectangle().fill(LinearGradient(colors: [goldColor, .clear], startPoint: .leading, endPoint: .trailing)).frame(height: 0.5)
                            }
                            .frame(width: 120)
                            .opacity(0.5)
                            .padding(.vertical, 24)
                            
                            // 5. The Lore
                            Text(constellation.lore(for: WeaverJourneyManager.shared.currentSeason))
                                .font(.system(size: 13, weight: .regular, design: .serif))
                                .lineSpacing(8)
                                .foregroundStyle(Color(hex: "E0E0E0").opacity(0.9))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                                .padding(.bottom, 50)
                            
                            Spacer()
                            
                            // 6. Unlock Date
                            if let date = constellation.unlockedDate {
                                HStack(spacing: 4) {
                                    Image(systemName: "clock.arrow.circlepath")
                                    Text(date.formatted(date: .long, time: .omitted).uppercased())
                                }
                                .font(.system(size: 11, weight: .bold, design: .serif))
                                .tracking(1)
                                .foregroundStyle(goldColor.opacity(0.5))
                                .padding(.bottom, 30)
                            }
                        }
                    }
                    .frame(width: 340)
                    .frame(minHeight: 650)
                    
                    Spacer().frame(height: 40)
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(12)
                    .background(Circle().fill(.ultraThinMaterial))
                    .padding()
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
                        .font(.system(size: 11, weight: .regular))
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
                        .frame(width: 36, height: 36)
                        .shadow(color: Color.sageGreen.opacity(0.4), radius: 8, y: 4)
                    
                    Image(systemName: milestone.icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(milestone.title)
                        .font(.system(size: 13, weight: .bold))
                        .fontDesign(.serif)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

                    Text("\(milestone.days) days of weaving")
                        .font(.system(size: 12, weight: .medium))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                }
                
                Spacer()
            }
            
            Text(milestone.message)
                .font(.system(size: 12, weight: .regular))
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
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
                        .font(.system(size: 12, weight: .regular))
                        .italic()
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                }
                
                Spacer()
                
                Text("Day \(daysSinceStart)")
                    .font(.system(size: 11, weight: .medium))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
            }
            
            Rectangle()
                .fill(Color(hex: season.colorHex).opacity(0.15))
                .frame(height: 1)
                .padding(.horizontal, -2)
            
            Text(season.description)
                .font(.system(size: 12, weight: .regular))
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
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

// MARK: - TIME-ADAPTIVE WEAVER LEVEL CARD

struct WeaverLevelCard: View {
    let level: WeaverLevel
    let totalCompletions: Int
    let colorScheme: ColorScheme

    private var progress: Double {
        guard let next = level.next else { return 1.0 }
        return min(Double(totalCompletions) / Double(next), 1.0)
    }

    private var config: WeaverLevelCardConfig {
        let hour = Calendar.current.component(.hour, from: Date())
        let period = TimeOfDay(hour: hour)
        return WeaverLevelCardConfig(period: period, colorScheme: colorScheme)
    }

    var body: some View {
        VStack(spacing: config.spacing) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13))
                    .foregroundStyle(config.iconColor)
                    .shadow(color: config.iconGlow, radius: config.iconGlowRadius)

                Text(level.title)
                    .font(.system(size: 14, weight: .medium))
                    .fontDesign(.serif)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

                Spacer()

                Text("Level \(level.level)")
                    .font(.system(size: 12, weight: .regular))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
            }

            if let next = level.next {
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

                if totalCompletions < next {
                    Text("\(next - totalCompletions) more to next level")
                        .font(.system(size: 11, weight: .regular))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(config.transcendentIconColor)
                        .shadow(color: config.transcendentGlow, radius: config.transcendentGlowRadius)

                    Text("Transcendent Level Reached")
                        .font(.system(size: 11, weight: .medium))
                        .italic()
                        .foregroundStyle(config.transcendentTextColor)
                        .shadow(color: config.transcendentGlow, radius: 1)

                    Image(systemName: "star.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(config.transcendentIconColor)
                        .shadow(color: config.transcendentGlow, radius: config.transcendentGlowRadius)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(config.padding)
        .reverieCardStyle(colorScheme: colorScheme)
    }
}

// MARK: - WEAVER LEVEL CARD CONFIGURATION

struct WeaverLevelCardConfig {
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
