//
// MiniChallengesOverviewIntro.swift
// Reverie Weaver
//
// Created by Antheia Li on 10/23/25.
//

//
// MiniChallengesOverviewIntro.swift
// Reverie Weaver
// Landing page for ALL 7-Day Mini Challenges
// Shows 6 challenge preview cards - tap to see details
// Matches Project50OverviewIntro flow
//

import SwiftUI
import SwiftData

struct MiniChallengesOverviewIntro: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Query private var habits: [Habit]
    
    @State private var selectedChallenge: MiniChallenge?
    
    var body: some View {
        NavigationStack {
            ZStack {
                ReverieWeaverBackground()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        heroSection
                        philosophySection
                        challengesGridSection
                    }
                    .padding(.bottom, 80)
                }
            }
            .toolbar { closeButton }
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
    // ✅ REPLACE WITH THIS (OPTION 3 - MINIMAL EDITORIAL - RECOMMENDED):

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
    
    var philosophySection: some View {
        OpenEditorialSection(
            icon: "star.fill",
            iconColor: Color(hex: "FFD18B"),
            title: "The Philosophy",
            content: "These 7-day challenges are designed to spark focus, rebuild consistency, and help you experiment with new habits — without the pressure of long commitments. Each challenge includes rescue protocols for bad brain days."
        )
        .padding(.horizontal, 24)
    }
    
    // MARK: Challenges Grid
    var challengesGridSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("CHOOSE A CHALLENGE")
                .font(.system(size: 11, weight: .semibold))
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
    var closeButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button { dismiss() } label: {
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

// MARK: - Helper Functions

private extension MiniChallengesOverviewIntro {
    // In MiniChallengesOverviewIntro.swift
    private func isChallengeActive(_ challenge: MiniChallenge) -> Bool {
        habits.contains { habit in
            habit.programTag == "C7-\(challenge.tag)"
        }
    }
}

// MARK: - Challenge Preview Card

private struct ChallengePreviewCard: View {
    let challenge: MiniChallenge
    let isActive: Bool
    let colorScheme: ColorScheme
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
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
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.sageGreen)
                                    .cornerRadius(6)
                            }
                        }
                        
                        Text(challenge.tagline)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color(hex: challenge.colorHex))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.dynamicSecondaryLabel.opacity(0.5))
                }
                
                Text(challenge.description)
                    .font(.system(size: 12))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Habit count
                HStack(spacing: 4) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 10))
                    Text("\(challenge.habits.count) habits")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundStyle(Color.dynamicSecondaryLabel.opacity(0.7))
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .reverieCardStyle(colorScheme: colorScheme)
        }
        .buttonStyle(.plain)
    }
}
