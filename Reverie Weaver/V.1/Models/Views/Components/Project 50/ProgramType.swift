//
//  ProgramType.swift
//  Reverie Weaver
//
//  Created by Antheia Li on 11/7/25.
//


//
// Habit+ProgramTag.swift
// Reverie Weaver
//
// ✅ Extension to protect program tags and provide tag validation
// Add this file to your project to ensure tags are never accidentally modified
//

import Foundation
import SwiftData

extension Habit {
    
    // MARK: - Tag Protection
    
    /// Check if this habit is part of Project 50
    var isProject50: Bool {
        programTag == "P50"
    }
    
    /// Check if this habit is part of a Mini Challenge
    var isMiniChallenge: Bool {
        programTag?.starts(with: "C7-") ?? false
    }
    
    /// Check if this habit is part of any program
    var isProgramHabit: Bool {
        isProject50 || isMiniChallenge
    }
    
    /// Get the mini challenge tag (e.g., "FocusSprint" from "C7-FocusSprint")
    var miniChallengeTag: String? {
        guard let tag = programTag, tag.starts(with: "C7-") else { return nil }
        return String(tag.dropFirst(3))
    }
    
    // MARK: - Tag Validation
    
    /// Validates that program tags follow the correct format
    static func validateProgramTag(_ tag: String?) -> Bool {
        guard let tag = tag else { return true } // nil is valid (regular habit)
        
        // Valid formats:
        // - "P50" for Project 50
        // - "C7-[tag]" for Mini Challenges
        if tag == "P50" { return true }
        if tag.starts(with: "C7-") && tag.count > 3 { return true }
        
        return false
    }
    
    // MARK: - Display Helpers
    
    /// Get a human-readable program name
    var programDisplayName: String? {
        if isProject50 {
            if let level = programLevel {
                return "Project 50 - Level \(level)"
            }
            return "Project 50"
        }
        
        if let challengeTag = miniChallengeTag {
            return "Mini Challenge: \(challengeTag)"
        }
        
        return nil
    }
    
    /// Get a short program badge (for UI display)
    var programBadge: String? {
        if isProject50 {
            if let level = programLevel {
                return "P50-L\(level)"
            }
            return "P50"
        }
        
        if isMiniChallenge {
            return "C7"
        }
        
        return nil
    }
    
    // MARK: - Tag Safety Guards
    
    /// Call this in any edit flow to ensure tags aren't accidentally cleared
    /// Returns true if the edit is safe, false if it would break program tracking
    func canSafelyEdit(newName: String? = nil, 
                      newDescription: String? = nil,
                      newIcon: String? = nil,
                      newProgramTag: String? = nil,
                      newProgramLevel: Int? = nil) -> Bool {
        
        // If trying to modify programTag or programLevel for a program habit
        if isProgramHabit {
            // Don't allow changing tags
            if let newTag = newProgramTag, newTag != programTag {
                print("⚠️ Cannot change programTag for program habit: \(name)")
                return false
            }
            
            // Don't allow changing level for Project 50
            if isProject50, let newLevel = newProgramLevel, newLevel != programLevel {
                print("⚠️ Cannot change programLevel for Project 50 habit: \(name)")
                return false
            }
        }
        
        // All other edits are safe
        return true
    }
}

// MARK: - Query Helpers

extension Habit {
    
    /// Filter habits by program type
    static func filterByProgram(_ habits: [Habit], program: ProgramType) -> [Habit] {
        switch program {
        case .project50:
            return habits.filter { $0.isProject50 }
        case .miniChallenge:
            return habits.filter { $0.isMiniChallenge }
        case .project50Level(let level):
            return habits.filter { $0.isProject50 && $0.programLevel == level }
        case .specificMiniChallenge(let tag):
            return habits.filter { $0.programTag == "C7-\(tag)" }
        case .regular:
            return habits.filter { !$0.isProgramHabit }
        case .all:
            return habits
        }
    }
    
    enum ProgramType {
        case all
        case regular
        case project50
        case project50Level(Int)
        case miniChallenge
        case specificMiniChallenge(String)
    }
}

// MARK: - Debugging Extensions

extension Habit {
    
    /// Get detailed tag information for debugging
    var tagDebugInfo: String {
        var info = "Habit: \(name)\n"
        info += "  programTag: \(programTag ?? "nil")\n"
        info += "  programLevel: \(programLevel.map { "\($0)" } ?? "nil")\n"
        info += "  isProject50: \(isProject50)\n"
        info += "  isMiniChallenge: \(isMiniChallenge)\n"
        
        if let displayName = programDisplayName {
            info += "  Program: \(displayName)\n"
        }
        
        return info
    }
    
    /// Print tag info to console (useful for debugging)
    func printTagInfo() {
        print(tagDebugInfo)
    }
}

// MARK: - Batch Operations

extension Array where Element == Habit {
    
    /// Get all Project 50 habits
    var project50Habits: [Habit] {
        filter { $0.isProject50 }
    }
    
    /// Get all Mini Challenge habits
    var miniChallengeHabits: [Habit] {
        filter { $0.isMiniChallenge }
    }
    
    /// Get all program habits (P50 + Mini Challenges)
    var programHabits: [Habit] {
        filter { $0.isProgramHabit }
    }
    
    /// Get all regular (non-program) habits
    var regularHabits: [Habit] {
        filter { !$0.isProgramHabit }
    }
    
    /// Get Project 50 habits for a specific level
    func project50Habits(level: Int) -> [Habit] {
        filter { $0.isProject50 && $0.programLevel == level }
    }
    
    /// Get Mini Challenge habits for a specific tag
    func miniChallengeHabits(tag: String) -> [Habit] {
        filter { $0.programTag == "C7-\(tag)" }
    }
    
    /// Print tag summary for all habits (debugging)
    func printTagSummary() {
        print("\n📊 HABIT TAG SUMMARY")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("Total Habits: \(count)")
        print("  • Project 50: \(project50Habits.count)")
        print("  • Mini Challenges: \(miniChallengeHabits.count)")
        print("  • Regular: \(regularHabits.count)")
        
        if !project50Habits.isEmpty {
            print("\nProject 50 Breakdown:")
            let level1 = project50Habits(level: 1).count
            let level2 = project50Habits(level: 2).count
            let level3 = project50Habits(level: 3).count
            print("  • Level 1: \(level1)")
            print("  • Level 2: \(level2)")
            print("  • Level 3: \(level3)")
        }
        
        if !miniChallengeHabits.isEmpty {
            print("\nMini Challenges:")
            let challengeTags = Set(miniChallengeHabits.compactMap { $0.miniChallengeTag })
            for tag in challengeTags.sorted() {
                let count = miniChallengeHabits(tag: tag).count
                print("  • \(tag): \(count) habits")
            }
        }
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
    }
}

// MARK: - Usage Examples in Comments

/*
 
 EXAMPLE 1: Check if habit is part of a program
 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 
 if habit.isProgramHabit {
     // This is a program habit - don't allow deletion without warning
     showProgramDeletionWarning = true
 }
 
 
 EXAMPLE 2: Filter habits for a specific program
 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 
 // Get only Project 50 Level 2 habits
 let level2Habits = habits.filter { 
     $0.isProject50 && $0.programLevel == 2 
 }
 
 // Or use the helper
 let level2Habits = habits.project50Habits(level: 2)
 
 
 EXAMPLE 3: Protect tags during editing
 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 
 func editHabit(_ habit: Habit, newName: String) {
     // Check if edit is safe
     guard habit.canSafelyEdit(newName: newName) else {
         print("Cannot edit program habit tags")
         return
     }
     
     habit.name = newName
     // Tags remain untouched
 }
 
 
 EXAMPLE 4: Debug tag issues
 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 
 // Print info for single habit
 habit.printTagInfo()
 
 // Print summary for all habits
 habits.printTagSummary()
 
 
 EXAMPLE 5: Display program badge in UI
 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 
 if let badge = habit.programBadge {
     Text(badge)
         .font(.system(size: 9, weight: .bold))
         .padding(.horizontal, 6)
         .padding(.vertical, 2)
         .background(Color.blue)
         .cornerRadius(4)
 }
 
 
 EXAMPLE 6: Validate program tags
 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 
 func createProgramHabit(tag: String, level: Int?) -> Habit? {
     guard Habit.validateProgramTag(tag) else {
         print("Invalid program tag format: \(tag)")
         return nil
     }
     
     return Habit(
         name: "New Habit",
         programTag: tag,
         programLevel: level
     )
 }
 
 */
