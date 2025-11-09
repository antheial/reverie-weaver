//
//  MicroHabitProgress.swift
//  Reverie Weaver
//
//  Created by Antheia Li on 10/20/25.
//
//
// MicroHabitProgress.swift
// ReverieWeaver
//
// Track progression from quick actions to full habits
//

import SwiftUI
import SwiftData

@Model
final class MicroHabitProgress {
    var titleKey: String // Links to MicroHabit.titleKey
    var completionCount: Int
    var lastCompleted: Date
    var convertedToHabit: Bool
    var id: UUID
    
    init(titleKey: String, completionCount: Int = 1, lastCompleted: Date = Date(), convertedToHabit: Bool = false) {
        self.id = UUID()
        self.titleKey = titleKey
        self.completionCount = completionCount
        self.lastCompleted = lastCompleted
        self.convertedToHabit = convertedToHabit
    }
}

// Manager for tracking progression
class MicroHabitProgressManager {
    let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // Get completion count for a specific quick action
    func getCompletionCount(for titleKey: String) -> Int {
        let descriptor = FetchDescriptor<MicroHabitProgress>(
            predicate: #Predicate { $0.titleKey == titleKey }
        )
        
        if let progress = try? modelContext.fetch(descriptor).first {
            return progress.completionCount
        }
        return 0
    }
    
    // Record a completion
    func recordCompletion(for titleKey: String) -> Int {
        let descriptor = FetchDescriptor<MicroHabitProgress>(
            predicate: #Predicate { $0.titleKey == titleKey }
        )
        
        if let progress = try? modelContext.fetch(descriptor).first {
            progress.completionCount += 1
            progress.lastCompleted = Date()
            try? modelContext.save()
            return progress.completionCount
        } else {
            let newProgress = MicroHabitProgress(titleKey: titleKey)
            modelContext.insert(newProgress)
            try? modelContext.save()
            return 1
        }
    }
    
    // Check if ready to suggest full habit (3+ completions)
    func shouldSuggestHabit(for titleKey: String) -> Bool {
        let count = getCompletionCount(for: titleKey)
        let descriptor = FetchDescriptor<MicroHabitProgress>(
            predicate: #Predicate { $0.titleKey == titleKey }
        )
        
        if let progress = try? modelContext.fetch(descriptor).first {
            return count >= 3 && !progress.convertedToHabit
        }
        return false
    }
    
    // Mark as converted to habit
    func markAsConverted(for titleKey: String) {
        let descriptor = FetchDescriptor<MicroHabitProgress>(
            predicate: #Predicate { $0.titleKey == titleKey }
        )
        
        if let progress = try? modelContext.fetch(descriptor).first {
            progress.convertedToHabit = true
            try? modelContext.save()
        }
    }
    
    // Get quick actions nearing completion (1-2 completions)
    func getAlmostReadyActions() -> [String] {
        let descriptor = FetchDescriptor<MicroHabitProgress>(
            predicate: #Predicate { progress in
                progress.completionCount >= 1 && progress.completionCount < 3 && !progress.convertedToHabit
            }
        )
        
        if let allProgress = try? modelContext.fetch(descriptor) {
            return allProgress.map { $0.titleKey }
        }
        return []
    }
    
    // Get recently completed actions (last 7 days - weekly refresh)
    func getRecentlyCompleted(days: Int = 7) -> [String] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let descriptor = FetchDescriptor<MicroHabitProgress>(
            predicate: #Predicate { $0.lastCompleted >= cutoffDate }
        )
        
        
        if let recent = try? modelContext.fetch(descriptor) {
            return recent.map { $0.titleKey }
        }
        return []
    }
    
    // Get total unique quick actions completed
    func getTotalUniqueActions() -> Int {
        let descriptor = FetchDescriptor<MicroHabitProgress>()
        if let all = try? modelContext.fetch(descriptor) {
            return all.count
        }
        return 0
    }
    
    // Get total completions across all quick actions
    func getTotalCompletions() -> Int {
        let descriptor = FetchDescriptor<MicroHabitProgress>()
        if let all = try? modelContext.fetch(descriptor) {
            return all.reduce(0) { $0 + $1.completionCount }
        }
        return 0
    }
}
