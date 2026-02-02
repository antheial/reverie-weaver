//
//  EmergencyDataRecovery.swift
//  Reverie Mood
//
//  EMERGENCY: Restore entries from voice memos
//

import SwiftUI
import SwiftData
import OSLog

private let emergencyRecoveryLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.reverie.mood", category: "EmergencyDataRecovery")

struct EmergencyDataRecoveryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allEntries: [MoodEntry]
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var recoveredCount = 0
    @State private var showingResults = false
    @State private var isScanning = false
    @State private var fixedCount = 0
    @State private var showingFixResults = false
    
    var body: some View {
        VStack(spacing: 30) {
            Text("EMERGENCY DATA RECOVERY")
                .font(.headline)
                .foregroundColor(.red)
            
            Text("This will scan for voice memos and create placeholder entries")
                .font(.caption)
                .multilineTextAlignment(.center)
            
            Text("Current entries: \(allEntries.count)")
                .font(.title2)
            
            // MARK: - Scan and Recover Section
            VStack(spacing: 16) {
                if isScanning {
                    ProgressView("Scanning...")
                } else {
                    Button("🔧 SCAN AND RECOVER") {
                        recoverFromVoiceMemos()
                    }
                    .font(.headline)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                if showingResults {
                    Text("✅ Recovered \(recoveredCount) entries from voice memos!")
                        .foregroundColor(.green)
                        .font(.title3)
                }
                
                Text("⚠️ This creates entries with 'Neutral' mood for days that have voice memos but no mood entry. You can edit them later to set the correct mood.")
                    .font(.caption2)
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            
            Divider()
                .padding(.vertical, 8)
            
            // MARK: - Fix Old Recovered Entries Section
            VStack(spacing: 16) {
                Text("🔧 FIX OLD RECOVERED ENTRIES")
                    .font(.headline)
                    .foregroundColor(.blue)
                
                Text("If you see 'RECOVERED' as a mood name or placeholder text, click below to fix them")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                
                Button("🩹 FIX RECOVERED ENTRIES") {
                    fixedCount = cleanupOldRecoveredEntries()
                    showingFixResults = true
                    
                    // Hide result after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        showingFixResults = false
                    }
                }
                .font(.headline)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                if showingFixResults {
                    if fixedCount > 0 {
                        Text("✅ Fixed \(fixedCount) recovered entries!")
                            .foregroundColor(.green)
                            .font(.title3)
                    } else {
                        Text("✨ No entries needed fixing")
                            .foregroundColor(.gray)
                            .font(.title3)
                    }
                }
            }
        }
        .padding()
    }
    
    private func recoverFromVoiceMemos() {
        isScanning = true
        recoveredCount = 0
        
        let currentYear = Calendar.current.component(.year, from: Date())
        let existingDays = Set(allEntries.filter { $0.year == currentYear }.map { $0.dayOfYear })
        
        // Scan days 1-22 for voice memos
        for day in 1...22 {
            // Skip if entry already exists
            guard !existingDays.contains(day) else { continue }
            
            // Check if voice memos exist for this day
            let hasMorning = AudioFileManager.memoExists(year: currentYear, day: day, slot: .morning)
            let hasEvening = AudioFileManager.memoExists(year: currentYear, day: day, slot: .evening)
            
            if hasMorning || hasEvening {
                // Create placeholder entry using proper Neutral mood
                let neutralMood = MoodCategory.neutral
                let entry = MoodEntry(
                    dayOfYear: day,
                    moodId: neutralMood.rawValue,
                    moodName: neutralMood.displayName,
                    moodColor: neutralMood.vintageColor.toHex(),
                    reflection: "", // Leave empty - user can add their own reflection
                    date: dateForDay(day, year: currentYear),
                    year: currentYear,
                    photoFileName: nil,
                    photoDate: nil
                )
                
                modelContext.insert(entry)
                recoveredCount += 1
            }
        }
        
        // Save
        do {
            try modelContext.save()
            showingResults = true
        } catch {
            emergencyRecoveryLogger.error("Recovery failed: \(error.localizedDescription)")
        }
        
        isScanning = false
    }
    
    /// Clean up old recovered entries that have the placeholder text
    /// This fixes entries created with the old recovery format
    func cleanupOldRecoveredEntries() -> Int {
        var fixedCount = 0
        let neutralMood = MoodCategory.neutral
        
        for entry in allEntries {
            // Check if this is an old recovered entry
            if entry.moodName == "Recovered" || entry.reflection.contains("RECOVERED FROM VOICE MEMO") {
                // Fix the mood name
                if entry.moodName == "Recovered" {
                    entry.moodName = neutralMood.displayName
                }
                
                // Clear the placeholder reflection
                if entry.reflection.contains("RECOVERED FROM VOICE MEMO") {
                    entry.reflection = ""
                }
                
                // Ensure proper color
                entry.moodColor = neutralMood.vintageColor.toHex()
                
                fixedCount += 1
                emergencyRecoveryLogger.debug("Fixed recovered entry for day \(entry.dayOfYear)")
            }
        }
        
        if fixedCount > 0 {
            do {
                try modelContext.save()
                emergencyRecoveryLogger.info("Successfully fixed \(fixedCount) recovered entries")
            } catch {
                emergencyRecoveryLogger.error("Failed to save cleanup: \(error.localizedDescription)")
                return 0
            }
        }
        
        return fixedCount
    }
    
    private func dateForDay(_ day: Int, year: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.day = day
        return Calendar.current.date(from: components) ?? Date()
    }
}
