//
//  ChallengeRouter.swift
//  Reverie Weaver
//
//  Created by Antheia Li on 12/8/25.
//
//

import SwiftUI

struct ChallengeRouter {
    
    // MARK: - Main Router
    
    /// Routes to the appropriate challenge view based on program tag
    ///
    /// Supported tags:
    /// - Mini Challenges: FocusSprint, DigitalDetox, BreathCalm, EnergyRecharge, etc.
    /// - Theme Weeks: GentleRhythmW1, FocusMasteryW1, SlowDownW1, etc.
    /// - Project 50: "Project50"
    @ViewBuilder
    static func view(for programTag: String) -> some View {
        switch challengeType(for: programTag) {
        case .project50:
            Project50LevelsView()
            
        case .themeWeek(let program):
            ThemeWeekDetailView(program: program)
            
        case .miniChallenge(let challenge):
            MiniChallengeDetailView(challenge: challenge)
            
        case .unknown:
            #if DEBUG
            let _ = logUnknownTag(programTag)
            #endif
            PlaceholderChallengeView(programTag: programTag)
        }
    }
    
    // MARK: - Helper Methods for Sheet Presentations
    
    /// Find a MiniChallenge by tag
    static func miniChallenge(for tag: String) -> MiniChallenge? {
        MiniChallengeData.challenges.first(where: { $0.tag == tag })
    }
    
    /// Find a ThemeWeekProgram by tag
    static func themeWeek(for tag: String) -> ThemeWeekProgram? {
        ThemeWeekData.programs.first(where: { $0.tag == tag })
    }
    
    /// Check if a tag is for Project 50
    static func isProject50(_ tag: String) -> Bool {
        tag == "Project50"
    }
    
    /// Check if a tag is for a Theme Week
    /// Uses suffix matching (W1, W2, W3) or explicit program list lookup
    static func isThemeWeek(_ tag: String) -> Bool {
        // Check explicit program list first (most reliable)
        if ThemeWeekData.programs.contains(where: { $0.tag == tag }) {
            return true
        }
        // Fallback: Theme Week tags end with W1, W2, W3
        // Only match if it's a pattern like "SomethingW1" not random strings containing W1
        let suffixes = ["W1", "W2", "W3"]
        return suffixes.contains(where: { suffix in
            tag.hasSuffix(suffix) && tag.count > suffix.count
        })
    }
    
    /// Check if a tag is for a Mini Challenge
    static func isMiniChallenge(_ tag: String) -> Bool {
        MiniChallengeData.challenges.contains(where: { $0.tag == tag })
    }
    
    // MARK: - Challenge Type Detection
    
    /// Get the type of challenge for a given tag
    enum ChallengeType {
        case project50
        case themeWeek(ThemeWeekProgram)
        case miniChallenge(MiniChallenge)
        case unknown
    }
    
    static func challengeType(for tag: String) -> ChallengeType {
        // 1. Check Project 50 first (exact match)
        if tag == "Project50" {
            return .project50
        }
        
        // 2. Check Theme Week Programs
        if let themeWeek = ThemeWeekData.programs.first(where: { $0.tag == tag }) {
            return .themeWeek(themeWeek)
        }
        
        // 3. Check Mini Challenges
        if let challenge = MiniChallengeData.challenges.first(where: { $0.tag == tag }) {
            return .miniChallenge(challenge)
        }
        
        // 4. Unknown tag
        return .unknown
    }
    
    // MARK: - Display Helpers
    
    /// Get display name for a program tag
    static func displayName(for tag: String) -> String {
        switch challengeType(for: tag) {
        case .project50:
            return "Project 50"
        case .themeWeek(let program):
            return program.title
        case .miniChallenge(let challenge):
            return challenge.title
        case .unknown:
            return formatProgramTag(tag)
        }
    }
    
    /// Get icon for a program tag
    static func icon(for tag: String) -> String {
        switch challengeType(for: tag) {
        case .project50:
            return "sparkles"
        case .themeWeek(let program):
            return program.icon
        case .miniChallenge(let challenge):
            return challenge.icon
        case .unknown:
            return "circle.fill"
        }
    }
    
    /// Get accent color hex for a program tag
    static func colorHex(for tag: String) -> String {
        switch challengeType(for: tag) {
        case .project50:
            return "9B7EBD"
        case .themeWeek(let program):
            return program.colorHex
        case .miniChallenge(let challenge):
            return challenge.colorHex
        case .unknown:
            return "808080"
        }
    }
    
    // MARK: - Private Helpers
    
    /// Format program tag for display (fallback for unknown tags)
    private static func formatProgramTag(_ tag: String) -> String {
        var result = ""
        for char in tag {
            if char.isUppercase && !result.isEmpty {
                result += " "
            }
            result += String(char)
        }
        
        return result
            .replacingOccurrences(of: " W 1", with: " Week 1")
            .replacingOccurrences(of: " W 2", with: " Week 2")
            .replacingOccurrences(of: " W 3", with: " Week 3")
    }
    
    private static func logUnknownTag(_ tag: String) {
        print("⚠️ ChallengeRouter: Unknown program tag '\(tag)'")
        print("   Available Mini Challenges: \(MiniChallengeData.challenges.map { $0.tag })")
        print("   Available Theme Weeks: \(ThemeWeekData.programs.map { $0.tag })")
    }
}

// MARK: - Placeholder View for Unimplemented Challenges

struct PlaceholderChallengeView: View {
    let programTag: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationStack {
            ZStack {
                ReverieWeaverBackground()
                
                VStack(spacing: 20) {
                    Image(systemName: "hammer.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                    
                    Text("Challenge Coming Soon")
                        .font(.custom("Georgia", size: 24))
                        .fontWeight(.semibold)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    
                    Text("The \(ChallengeRouter.displayName(for: programTag)) challenge will be available soon.")
                        .font(.custom("Georgia", size: 14))
                        .multilineTextAlignment(.center)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        .padding(.horizontal, 40)
                    
                    #if DEBUG
                    // Show debug info in debug builds
                    VStack(spacing: 4) {
                        Text("Tag: \(programTag)")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.gray)
                        
                        Text("Type: Unknown")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 8)
                    #endif
                    
                    Button {
                        dismiss()
                    } label: {
                        Text("Go Back")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.orange)
                            )
                    }
                    .padding(.horizontal, 40)
                }
                .padding()
            }
            .navigationTitle(ChallengeRouter.displayName(for: programTag))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Placeholder View") {
    PlaceholderChallengeView(programTag: "UnknownChallenge")
}
