//
//  ConstellationSummarySheets.swift
//  Reverie Weaver
//
//  Quick summary modals for tapped constellation stars
//

import SwiftUI
import SwiftData

// MARK: - Mini Challenge Summary Sheet
struct MiniChallengeQuickSummarySheet: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    
    let challengeID: String
    let challengeName: String
    let completedDate: Date
    
    @Query private var allProgress: [MiniChallengeProgress]
    
    private var progress: MiniChallengeProgress? {
        allProgress.first { $0.challengeID == challengeID }
    }
    
    private func isDayCompleted(_ day: Int) -> Bool {
        // Day must be 0...6 for the UI strip
        guard (0...6).contains(day) else { return false }
        guard let progress = progress else { return false }
        
        // Use Mirror for safe property access to avoid type mismatches
        let mirror = Mirror(reflecting: progress)
        
        // Strategy 1: Look for boolean array properties (dailyCompletions, daysCompleted, etc.)
        for child in mirror.children {
            guard let label = child.label else { continue }
            
            // Check for boolean array properties
            if label == "dailyCompletions" || label == "daysCompleted" || label == "completedDays" {
                if let boolArray = child.value as? [Bool], boolArray.indices.contains(day) {
                    return boolArray[day]
                }
            }
            
            // Check for Set<Int> or [Int] with 1-based day numbers
            if label == "completedDayNumbers" || label == "completedDaysSet" {
                let dayNumber = day + 1  // Convert to 1-based
                if let numbers = child.value as? [Int] {
                    return numbers.contains(dayNumber)
                } else if let numberSet = child.value as? Set<Int> {
                    return numberSet.contains(dayNumber)
                }
            }
        }
        
        // Fallback: Check daysCompleted count (if user completed N days, first N are done)
        // This is a reasonable fallback for sequential completion
        if progress.daysCompleted > day {
            return true
        }
        
        return false
    }
    
    private func dayLabel(_ day: Int) -> String {
        let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        return days[day]
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.paleMauve)
                Text(challengeName)
                    .font(.system(size: 18, weight: .semibold))
                    .fontDesign(.serif)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
            }

            VStack(spacing: 12) {
                Text("Your Week:")
                    .font(.system(size: 13, weight: .medium))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)

                HStack(spacing: 10) {
                    ForEach(0..<7, id: \.self) { day in
                        VStack(spacing: 4) {
                            let done = isDayCompleted(day)
                            ZStack {
                                Circle()
                                    .fill(done ? Color.paleMauve.opacity(0.25) : Color.gray.opacity(0.15))
                                    .frame(width: 26, height: 26)
                                Image(systemName: done ? "checkmark" : "circle")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(done ? Color.paleMauve : Color.gray.opacity(0.6))
                            }
                            Text(dayLabel(day))
                                .font(.system(size: 11, weight: .medium))
                                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        }
                    }
                }
            }

            // Show completion status (full or partial)
            if let progress = progress {
                if progress.isCompleted {
                    Text("Completed: \(formattedDate(completedDate))")
                        .font(.system(size: 13, weight: .medium))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                } else if progress.isArchived {
                    VStack(spacing: 4) {
                        Text("\(Int(progress.successRate * 100))% Success")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.sageGreen.opacity(0.9))
                        Text("Archived: \(formattedDate(progress.archivedDate ?? completedDate))")
                            .font(.system(size: 12, weight: .medium))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    }
                }
            } else {
                Text("Completed: \(formattedDate(completedDate))")
                    .font(.system(size: 13, weight: .medium))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
            }
        }
        .padding(24)
        .presentationDetents([.height(260)])
        .presentationCornerRadius(24)
    }
}

// MARK: - Theme Week Summary Sheet

struct ThemeWeekQuickSummarySheet: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    
    let progressID: String
    let programTitle: String
    let completedDate: Date
    
    @Query private var allProgress: [ThemeWeekProgress]
    
    private var progress: ThemeWeekProgress? {
        allProgress.first { $0.id.uuidString == progressID }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.paleMauve)
                Text(programTitle)
                    .font(.system(size: 18, weight: .semibold))
                    .fontDesign(.serif)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
            }
            
            VStack(spacing: 12) {
                Text("Your Journey:")
                    .font(.system(size: 13, weight: .medium))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                
                HStack(spacing: 10) {
                    ForEach(0..<7, id: \.self) { day in
                        VStack(spacing: 4) {
                            Text(tierIcon(for: day + 1))
                                .font(.system(size: 20))
                            
                            Text(dayLabel(day))
                                .font(.system(size: 11, weight: .medium))
                                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        }
                    }
                }
            }
            
            HStack(spacing: 16) {
                tierStat(icon: "leaf.fill", label: "Seeds", count: progress?.seedCount ?? 0, color: Color(hex: "B8D4C8"))
                tierStat(icon: "leaf.circle.fill", label: "Sprouts", count: progress?.sproutCount ?? 0, color: Color(hex: "9BB5CE"))
                tierStat(icon: "sparkles", label: "Blooms", count: progress?.bloomCount ?? 0, color: Color(hex: "D4B896"))
            }
            
            Text("Completed: \(formattedDate(completedDate))")
                .font(.system(size: 13, weight: .medium))
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
        }
        .padding(24)
        .presentationDetents([.height(280)])
        .presentationCornerRadius(24)
    }
    
    private func tierIcon(for dayNumber: Int) -> String {
        guard let progress = progress,
              let record = progress.completionRecord(for: dayNumber) else {
            return "○"
        }
        
        switch record.tier {
        case .seed: return "🌱"
        case .sprout: return "🌿"
        case .bloom: return "🌳"
        }
    }
    
    private func tierStat(icon: String, label: String, count: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
            Text("\(count)")
                .font(.system(size: 14, weight: .semibold))
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
        }
    }
    
    private func dayLabel(_ day: Int) -> String {
        let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        return days[day]
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Project 50 Milestone Sheet

struct Project50MilestoneSheet: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let oldLevel: Int
    let newLevel: Int
    let achievedDate: Date
    
    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.dustyBlue)
                Text("Project 50 Milestone")
                    .font(.system(size: 18, weight: .semibold))
                    .fontDesign(.serif)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
            }
            
            HStack(spacing: 12) {
                levelBadge(level: oldLevel, color: Color.gray.opacity(0.4))
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.dustyBlue)
                
                levelBadge(level: newLevel, color: Color.dustyBlue)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Unlocked:")
                    .font(.system(size: 13, weight: .semibold))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                
                unlockItem(icon: "plus.circle", text: "\(habitSlotsUnlocked) new habit slots")
                unlockItem(icon: "chart.bar.fill", text: "Advanced tracking")
                if newLevel >= 2 {
                    unlockItem(icon: "sparkles", text: "Enhanced insights")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("Achieved: \(formattedDate(achievedDate))")
                .font(.system(size: 13, weight: .medium))
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
        }
        .padding(24)
        .presentationDetents([.height(280)])
        .presentationCornerRadius(24)
    }
    
    private func levelBadge(level: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Text("\(level)")
                    .font(.system(size: 24, weight: .bold))
                    .fontDesign(.serif)
                    .foregroundStyle(color)
            }
            
            Text("Level \(level)")
                .font(.system(size: 12, weight: .medium))
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
        }
    }
    
    private func unlockItem(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(Color.dustyBlue)
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
        }
    }
    
    private var habitSlotsUnlocked: Int {
        switch newLevel {
        case 1: return 3
        case 2: return 2
        case 3: return 3
        default: return 2
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
