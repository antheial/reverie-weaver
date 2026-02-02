//
// MiniChallengesOverviewIntro.swift
// Reverie Weaver
//
// Landing page for ALL 7-Day Mini Challenges
//

import SwiftUI
import SwiftData

struct MiniChallengesOverviewIntro: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Query private var habits: [Habit]
    
    @State private var selectedChallenge: MiniChallenge?
    @State private var selectedTier: ChallengeTier = .foundation
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                ReverieWeaverBackground()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        heroSection
                        philosophicalQuote
                        tierTabsSection
                        challengesContentSection
                        philosophySection
                    }
                    .padding(.bottom, 100)
                    .padding(.top, 60)
                }
                // 3. Floating Close Button (Top Right)
                    HStack {
                        Spacer()
                        closeButton
                        }
                     .padding(.horizontal)
                     .padding(.top, 10)
                            
                }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedChallenge) { challenge in
                MiniChallengeDetailView(challenge: challenge)
            }
        }
    }
}

// MARK: - View Sections

private extension MiniChallengesOverviewIntro {
    
    // MARK: Hero Section
    var heroSection: some View {
        HybridEditorialChallengeHeader(
            icon: "bolt.fill",
            title: "7-Day Mini Challenges",
            categoryLabel: "Small Sprints",
            subtitle: "Small sprints. Big clarity.",
            accentColor: Color(hex: "FFD18B")
        )
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }
    
    // MARK: Philosophy Section
    var philosophySection: some View {
        OpenEditorialSection(
            icon: "star.fill",
            iconColor: Color(hex: "FFD18B"),
            title: "The Philosophy",
            content: "These 7-day challenges are designed to spark focus, rebuild consistency, and help you experiment with new habits — without the pressure of long commitments. Each challenge includes rescue protocols for bad brain days."
        )
        .padding(.horizontal, 24)
    }
    
    // MARK: Philosophical Quote Section
    var philosophicalQuote: some View {
        VStack(spacing: 12) {
            // Decorative divider
            HStack(spacing: 12) {
                Rectangle()
                    .fill(Color.dynamicSecondaryLabel.opacity(0.2))
                    .frame(height: 0.5)
                    .frame(maxWidth: .infinity)
                
                Image(systemName: "sparkle")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "FFD18B").opacity(0.6))
                
                Rectangle()
                    .fill(Color.dynamicSecondaryLabel.opacity(0.2))
                    .frame(height: 0.5)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 40)
            
            // The quote
            Text("The goal is not perfection. The goal is showing up imperfectly, again and again, until one day you realize you've changed.")
                .font(.custom("Georgia", size: 14))
                .fontWeight(.light)
                .italic()
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                .padding(.horizontal, 32)
            
            // Attribution
            Text("— REVERIE WEAVER PHILOSOPHY")
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.2)
                .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                .opacity(0.6)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: Tier Tabs Section
    var tierTabsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("CHOOSE YOUR CHALLENGE")
                .font(.system(size: 12, weight: .semibold))
                .tracking(1)
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                .padding(.horizontal, 24)
            
            // Horizontal scrolling tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ChallengeTier.allCases, id: \.self) { tier in
                        TierTabButton(
                            tier: tier,
                            isSelected: selectedTier == tier,
                            colorScheme: colorScheme
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTier = tier
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
    
    // MARK: Challenges Content Section
    var challengesContentSection: some View {
        VStack(spacing: 12) {
            if selectedTier == .program {
                // Show grouped programs
                programsView
            } else {
                // Show individual challenges
                individualChallengesView
            }
        }
        .animation(.easeInOut(duration: 0.3), value: selectedTier)
    }
    
    // MARK: Individual Challenges View
    var individualChallengesView: some View {
        ForEach(filteredChallenges) { challenge in
            ChallengePreviewCard(
                challenge: challenge,
                isActive: isChallengeActive(challenge),
                colorScheme: colorScheme
            ) {
                selectedChallenge = challenge
            }
            .padding(.horizontal, 24)
        }
    }
    
    // MARK: Programs View (Grouped)
    var programsView: some View {
        ForEach(groupedPrograms.keys.sorted(), id: \.self) { programGroup in
            ProgramGroupCard(
                programGroup: programGroup,
                weeks: groupedPrograms[programGroup] ?? [],
                colorScheme: colorScheme
            ) { challenge in
                selectedChallenge = challenge
            }
            .padding(.horizontal, 24)
        }
    }
    
    // MARK: Challenges Grid (Legacy - kept for reference)
    var challengesGridSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("CHOOSE YOUR CHALLENGE")
                .font(.system(size: 12, weight: .semibold))
                .tracking(1)
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                .padding(.horizontal, 24)
            
            VStack(spacing: 12) {
                ForEach(MiniChallengeData.challenges) { challenge in
                    ChallengePreviewCard(
                        challenge: challenge,
                        isActive: isChallengeActive(challenge),
                        colorScheme: colorScheme
                    ) {
                        selectedChallenge = challenge
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
    }
    
    // MARK: Close Button
    // correct definition - place this inside your struct
    var closeButton: some View {
        GlassCloseButton(action: {
            dismiss()
        })
    }
}

// MARK: - Helper Functions

private extension MiniChallengesOverviewIntro {
    func isChallengeActive(_ challenge: MiniChallenge) -> Bool {
        habits.contains { habit in
            habit.programTag == "C7-\(challenge.tag)"
        }
    }
    
    // MARK: Filtered Challenges
    var filteredChallenges: [MiniChallenge] {
        MiniChallengeData.challenges.filter { $0.tier == selectedTier }
    }
    
    // MARK: Grouped Programs
    var groupedPrograms: [String: [MiniChallenge]] {
        let programs = MiniChallengeData.challenges.filter { $0.tier == .program }
        return Dictionary(grouping: programs) { $0.programGroup ?? "Other" }
    }
}

// MARK: - Challenge Preview Card

private struct ChallengePreviewCard: View {
    let challenge: MiniChallenge
    let isActive: Bool
    let colorScheme: ColorScheme
    let onTap: () -> Void
    
    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(Color(hex: challenge.colorHex).opacity(0.15))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Circle()
                                    .strokeBorder(Color(hex: challenge.colorHex).opacity(0.3), lineWidth: 1)
                            )
                        Image(systemName: challenge.icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(Color(hex: challenge.colorHex))
                    }
                    
                    // Content
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text(challenge.title)
                                .font(.system(size: 14, weight: .semibold))
                                .fontDesign(.serif)
                                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                            
                            if isActive {
                                Text("Active")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.sageGreen)
                                    .cornerRadius(6)
                            }
                        }
                        
                        Text(challenge.tagline)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color(hex: challenge.colorHex))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.dynamicSecondaryLabel.opacity(0.5))
                }
                
                // Description
                Text(challenge.description)
                    .font(.system(size: 12))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Bottom info row
                HStack(spacing: 16) {
                    // Habit count
                    HStack(spacing: 4) {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 11))
                        Text("\(challenge.habits.count) habits")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(Color.dynamicSecondaryLabel.opacity(0.7))
                    
                    // Identity hint
                    Text("Become someone who...")
                        .font(.system(size: 11))
                        .italic()
                        .foregroundStyle(Color.dynamicSecondaryLabel.opacity(0.5))
                        .lineLimit(1)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .reverieCardStyle(colorScheme: colorScheme)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tier Tab Button

private struct TierTabButton: View {
    let tier: ChallengeTier
    let isSelected: Bool
    let colorScheme: ColorScheme
    let onTap: () -> Void
    
    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: tier.icon)
                    .font(.system(size: 12, weight: .medium))
                
                Text(tier.rawValue)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(
                isSelected
                    ? .white
                    : (colorScheme == .dark ? Color.white.opacity(0.9) : Color.black.opacity(0.85))
            )
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                Group {
                    if isSelected {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: tier.color), Color(hex: tier.color).opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color(hex: tier.color).opacity(0.3), radius: 6, y: 2)
                    } else {
                        Capsule()
                            .fill(Color.adaptiveSectionBackground(colorScheme: colorScheme))
                            .overlay(
                                Capsule()
                                    .strokeBorder(Color.adaptiveBorder(colorScheme: colorScheme), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.1), radius: 3, y: 1)
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Program Group Card

private struct ProgramGroupCard: View {
    let programGroup: String
    let weeks: [MiniChallenge]
    let colorScheme: ColorScheme
    let onWeekTap: (MiniChallenge) -> Void
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Program header (expandable)
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        // Icon
                        ZStack {
                            Circle()
                                .fill(Color(hex: programColor).opacity(0.15))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Circle()
                                        .strokeBorder(Color(hex: programColor).opacity(0.3), lineWidth: 1)
                                )
                            Image(systemName: programIcon)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(Color(hex: programColor))
                        }
                        
                        // Content
                        VStack(alignment: .leading, spacing: 3) {
                            Text(programTitle)
                                .font(.system(size: 14, weight: .semibold))
                                .fontDesign(.serif)
                                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                            
                            Text("\(weeks.count) weeks • \(totalDuration)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color(hex: programColor))
                        }
                        
                        Spacer()
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.dynamicSecondaryLabel.opacity(0.5))
                    }
                    
                    // Program description
                    Text(programDescription)
                        .font(.system(size: 12))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
            }
            .buttonStyle(.plain)
            
            // Expanded weeks
            if isExpanded {
                // Divider between header and weeks
                Divider()
                    .padding(.horizontal, 16)
                    .opacity(0.3)
                
                VStack(spacing: 10) {
                    ForEach(Array(weeks.enumerated()), id: \.element.id) { index, week in
                        Button {
                            onWeekTap(week)
                        } label: {
                            HStack(spacing: 12) {
                                // Week indicator
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: programColor).opacity(0.1))
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Circle()
                                                .strokeBorder(Color(hex: programColor).opacity(0.2), lineWidth: 1)
                                        )
                                    
                                    Text("W\(index + 1)")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(Color(hex: programColor))
                                }
                                
                                // Week info
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(week.title)
                                        .font(.system(size: 13, weight: .medium))
                                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                                    
                                    Text(week.tagline)
                                        .font(.system(size: 11))
                                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color.dynamicSecondaryLabel.opacity(0.4))
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        colorScheme == .dark
                                            ? Color.white.opacity(0.03)
                                            : Color.black.opacity(0.02)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .reverieCardStyle(colorScheme: colorScheme)
    }
    
    // MARK: Computed Properties
    
    var programTitle: String {
        // Map programGroup to display names
        switch programGroup {
        case "FeiStrength": return "费教练力量训练"
        case "GlowingJourney": return "Glowing Journey"
        case "ExecutiveEnergy": return "Executive Energy"
        case "RelationshipRenaissance": return "Relationship Renaissance"
        default: return programGroup
        }
    }
    
    var programDescription: String {
        switch programGroup {
        case "FeiStrength": 
            return "Progressive strength training program combining functional fitness with traditional weightlifting for balanced physical development."
        case "GlowingJourney": 
            return "A holistic transformation journey focusing on skincare, nutrition, and wellness habits for radiant health from the inside out."
        case "ExecutiveEnergy": 
            return "High-performance routines designed for busy professionals to optimize energy, focus, and productivity without burnout."
        case "RelationshipRenaissance": 
            return "Intentional practices to deepen connections, improve communication, and cultivate meaningful relationships in your life."
        default: 
            return "A structured program to build lasting habits and create meaningful change over multiple weeks."
        }
    }
    
    var programColor: String {
        weeks.first?.colorHex ?? "A3C7D6"
    }
    
    var programIcon: String {
        weeks.first?.icon ?? "calendar"
    }
    
    var totalDuration: String {
        let totalDays = weeks.reduce(0) { $0 + ($1.durationWeeks * 7) }
        return "\(totalDays) days"
    }
}

