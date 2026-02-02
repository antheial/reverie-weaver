//
//  DataMigrationManager.swift
//  Reverie Weaver
//
//  Created by Antheia Li on 11/28/25.
//
// Handles one-time data migrations and repairs.
// Currently used to fix missing P50 tags for legacy habits.
//

import Foundation
import SwiftData
import SwiftUI

struct DataMigrationManager {
    
    /// Runs the P50 tag migration if it hasn't been run yet.
    /// Call this from DeskView.onAppear or App.init.
    @MainActor
    static func runP50MigrationIfNeeded(context: ModelContext) {
        // 1. Check if we already ran this migration
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: "p50_tags_migrated_v1") {
            return
        }
        
        print("🛠️ [Migration] Starting P50 Tag Repair...")
        
        // 2. Fetch all active, non-archived habits
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate { $0.isArchived == false }
        )
        
        guard let habits = try? context.fetch(descriptor) else {
            print("⚠️ [Migration] Failed to fetch habits.")
            return
        }
        
        // 3. Get the list of canonical P50 habit names
        let level1Names = getAllLevel1HabitNames()
        var fixedCount = 0
        
        // 4. Scan and Tag
        for habit in habits {
            // Skip if it already has the tag
            if habit.programTag == "P50" { continue }
            
            // Check for match
            let isMatch = level1Names.contains { p50Name in
                fuzzyMatch(habitName: habit.name, p50Name: p50Name)
            }
            
            if isMatch {
                habit.programTag = "P50"
                habit.programLevel = 1
                fixedCount += 1
                print("   -> Repaired Habit: \(habit.name)")
            }
        }
        
        // 5. Save and Mark Complete
        if fixedCount > 0 {
            do {
                try context.save()
                // Force the progress manager to see the new tags
                Project50ProgressManager.shared.refreshEligibility()
                print("✅ [Migration] Successfully repaired \(fixedCount) habits.")
            } catch {
                print("❌ [Migration] Failed to save changes: \(error)")
                return // Don't set flag if save failed
            }
        } else {
            print("✅ [Migration] No habits needed repair.")
        }
        
        // Set flag so we don't run this heavy scan again
        defaults.set(true, forKey: "p50_tags_migrated_v1")
    }
    
    // MARK: - Private Helpers
    
    /// Fuzzy matches two strings ignoring case, punctuation, and specific formatting
    private static func fuzzyMatch(habitName: String, p50Name: String) -> Bool {
        let normalize: (String) -> String = { name in
            name.lowercased()
                .replacingOccurrences(of: "  ", with: " ")
                .trimmingCharacters(in: .whitespaces)
        }
        
        let normalizedHabit = normalize(habitName)
        let normalizedP50 = normalize(p50Name)
        
        // 1. Exact Match (most likely)
        if normalizedHabit == normalizedP50 { return true }
        
        // 2. Base Name Match (ignores "10 min", "20 min" differences)
        // e.g. "Morning Reset" vs "Morning Reset (10 min)"
        let getBaseName: (String) -> String = { name in
            if let colonIndex = name.firstIndex(of: ":") {
                return String(name[..<colonIndex]).trimmingCharacters(in: .whitespaces)
            }
            let components = name.components(separatedBy: " (")
            return components[0].trimmingCharacters(in: .whitespaces)
        }
        
        let habitBase = normalize(getBaseName(habitName))
        let p50Base = normalize(getBaseName(p50Name))
        
        if habitBase == p50Base && !habitBase.isEmpty { return true }
        
        // 3. Contains Match (Fallback)
        if normalizedHabit.contains(normalizedP50) || normalizedP50.contains(normalizedHabit) {
            return true
        }
        
        return false
    }
    
    /// Retrieves all habit names defined in Project 50 Level 1
    private static func getAllLevel1HabitNames() -> [String] {
        var names: [String] = []
        
        // Assumes Project50Data structure is available globally
        for category in Project50Data.categories {
            if let level1Habits = category.levels[1] {
                names.append(contentsOf: level1Habits.map { $0.name })
            }
        }
        return names
    }
}
