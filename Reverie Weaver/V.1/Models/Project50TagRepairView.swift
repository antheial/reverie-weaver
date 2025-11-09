//
// Project50TagRepair.swift (NOT USED)
// Reverie Weaver
//
// Utility to add P50 tags to existing habits that match Project 50 names
// Use this ONCE to fix habits created before the P50 tagging system
//

import SwiftUI
import SwiftData

struct Project50TagRepairView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var habits: [Habit]
    
    @State private var repairStatus: RepairStatus = .ready
    @State private var repairedHabits: [String] = []
    @State private var unmatchedHabits: [String] = []
    
    enum RepairStatus {
        case ready
        case scanning
        case completed
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                ReverieWeaverBackground()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "wrench.and.screwdriver.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(Color.sageGreen)
                            
                            Text("P50 Tag Repair")
                                .font(.system(size: 24, weight: .bold))
                            
                            Text("Add P50 tags to existing habits")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.dynamicSecondaryLabel)
                        }
                        .padding(.top, 40)
                        
                        // Status Card
                        statusCard
                        
                        // Results
                        if repairStatus == .completed {
                            resultsSection
                        }
                        
                        // Action Button
                        if repairStatus == .ready {
                            Button {
                                repairTags()
                            } label: {
                                Text("Scan & Repair Tags")
                                    .font(.system(size: 16, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.sageGreen)
                                    .foregroundColor(.white)
                                    .cornerRadius(16)
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        if repairStatus == .completed {
                            Button {
                                dismiss()
                            } label: {
                                Text("Done")
                                    .font(.system(size: 16, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.dynamicSecondaryLabel.opacity(0.2))
                                    .foregroundColor(Color.dynamicLabel)
                                    .cornerRadius(16)
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Debug Tool")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
    
    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: statusIcon)
                    .font(.system(size: 20))
                    .foregroundStyle(statusColor)
                Text(statusTitle)
                    .font(.system(size: 16, weight: .semibold))
            }
            
            Text(statusMessage)
                .font(.system(size: 14))
                .foregroundStyle(Color.dynamicSecondaryLabel)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.dynamicSecondaryLabel.opacity(0.1))
        .cornerRadius(16)
        .padding(.horizontal, 20)
    }
    
    private var resultsSection: some View {
        VStack(spacing: 16) {
            // Repaired Habits
            if !repairedHabits.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.sageGreen)
                        Text("Tagged as P50 (\(repairedHabits.count))")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    
                    ForEach(repairedHabits, id: \.self) { name in
                        HStack {
                            Circle()
                                .fill(Color.sageGreen.opacity(0.3))
                                .frame(width: 6, height: 6)
                            Text(name)
                                .font(.system(size: 14))
                                .foregroundStyle(Color.dynamicLabel)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color.sageGreen.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal, 20)
            }
            
            // Unmatched Habits
            if !unmatchedHabits.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(Color.dustyBlue)
                        Text("Not P50 (\(unmatchedHabits.count))")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    
                    ForEach(unmatchedHabits, id: \.self) { name in
                        HStack {
                            Circle()
                                .fill(Color.dynamicSecondaryLabel.opacity(0.3))
                                .frame(width: 6, height: 6)
                            Text(name)
                                .font(.system(size: 14))
                                .foregroundStyle(Color.dynamicSecondaryLabel)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color.dynamicSecondaryLabel.opacity(0.05))
                .cornerRadius(12)
                .padding(.horizontal, 20)
            }
        }
    }
    
    private var statusIcon: String {
        switch repairStatus {
        case .ready: return "wrench.and.screwdriver"
        case .scanning: return "hourglass"
        case .completed: return "checkmark.circle.fill"
        }
    }
    
    private var statusColor: Color {
        switch repairStatus {
        case .ready: return .dynamicLabel
        case .scanning: return .dustyBlue
        case .completed: return .sageGreen
        }
    }
    
    private var statusTitle: String {
        switch repairStatus {
        case .ready: return "Ready to Scan"
        case .scanning: return "Scanning..."
        case .completed: return "Repair Complete"
        }
    }
    
    private var statusMessage: String {
        switch repairStatus {
        case .ready:
            return "This will scan your habits and add P50 tags to those matching Level 1 Project 50 habit names."
        case .scanning:
            return "Checking habit names against Project 50 data..."
        case .completed:
            return "Tags have been added. Check Project 50 Levels view to see updated progress."
        }
    }
    
    // MARK: - Repair Logic
    
    private func repairTags() {
        repairStatus = .scanning
        repairedHabits = []
        unmatchedHabits = []
        
        // Get all Level 1 Project 50 habit names
        let level1Names = getAllLevel1HabitNames()
        
        // Scan existing habits
        for habit in habits {
            // Skip if already tagged
            if habit.programTag == "P50" {
                continue
            }
            
            // Check if habit name matches any Level 1 P50 habit (fuzzy matching)
            let matchesLevel1 = level1Names.contains { p50Name in
                fuzzyMatch(habitName: habit.name, p50Name: p50Name)
            }
            
            if matchesLevel1 {
                // Tag it!
                habit.programTag = "P50"
                habit.programLevel = 1
                repairedHabits.append(habit.name)
            } else {
                unmatchedHabits.append(habit.name)
            }
        }
        
        // Save changes
        do {
            try modelContext.save()
            
            // Force refresh progress calculation
            Project50ProgressManager.shared.refreshEligibility()
            
            // Add delay for visual feedback
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    repairStatus = .completed
                }
            }
        } catch {
            print("Error saving tags: \(error)")
        }
    }
    
    private func fuzzyMatch(habitName: String, p50Name: String) -> Bool {
        // Normalize both names: lowercase, remove extra spaces, remove punctuation
        let normalize: (String) -> String = { name in
            name.lowercased()
                .replacingOccurrences(of: "  ", with: " ")
                .trimmingCharacters(in: .whitespaces)
        }
        
        let normalizedHabit = normalize(habitName)
        let normalizedP50 = normalize(p50Name)
        
        // Exact match after normalization
        if normalizedHabit == normalizedP50 {
            return true
        }
        
        // Extract base name (before any colon or parentheses with details)
        let getBaseName: (String) -> String = { name in
            // Get everything before ":" or "("
            if let colonIndex = name.firstIndex(of: ":") {
                return String(name[..<colonIndex]).trimmingCharacters(in: .whitespaces)
            }
            // For names with parentheses, compare the part before
            let components = name.components(separatedBy: " (")
            return components[0].trimmingCharacters(in: .whitespaces)
        }
        
        let habitBase = normalize(getBaseName(habitName))
        let p50Base = normalize(getBaseName(p50Name))
        
        // Match if base names are the same
        // e.g., "Morning Reset (6 min)" matches "Morning Reset (5 min)"
        if habitBase == p50Base && !habitBase.isEmpty {
            return true
        }
        
        // Also check contains (for habits with additional descriptive text)
        if normalizedHabit.contains(normalizedP50) || normalizedP50.contains(normalizedHabit) {
            return true
        }
        
        return false
    }
    
    private func getAllLevel1HabitNames() -> [String] {
        // Extract all Level 1 habit names from Project50Data
        var names: [String] = []
        
        for category in Project50Data.categories {
            if let level1Habits = category.levels[1] {
                names.append(contentsOf: level1Habits.map { $0.name })
            }
        }
        
        return names
    }
}

// MARK: - Preview
#Preview {
    Project50TagRepairView()
}
