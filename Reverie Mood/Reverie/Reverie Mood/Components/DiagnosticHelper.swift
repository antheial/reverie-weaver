//
//  DiagnosticHelper.swift
//  Reverie Mood
//
//  Quick diagnostic to check if data exists in database
//

import SwiftUI
import SwiftData

struct DiagnosticView: View {
    @Query private var allEntries: [MoodEntry]
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 20) {
            Text("DATA DIAGNOSTIC")
                .font(.headline)
            
            Text("Total Entries in Database: \(allEntries.count)")
                .font(.title)
                .foregroundColor(allEntries.count > 0 ? .green : .red)
            
            if allEntries.isEmpty {
                Text("⚠️ NO DATA FOUND IN DATABASE")
                    .foregroundColor(.red)
                    .padding()
                
                Text("This means your entries were deleted from the database.")
                    .multilineTextAlignment(.center)
            } else {
                Text("✅ DATA EXISTS")
                    .foregroundColor(.green)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(allEntries.sorted(by: { $0.dayOfYear < $1.dayOfYear }), id: \.id) { entry in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Day \(entry.dayOfYear), Year \(String(entry.year))")
                                    .font(.headline)
                                
                                Text("Mood: \(entry.moodName)")
                                Text("Reflection: \(entry.reflection.prefix(50))...")
                                    .font(.caption)
                                
                                if let photoName = entry.photoFileName {
                                    Text("Photo: \(photoName)")
                                        .foregroundColor(.blue)
                                }
                                
                                Divider()
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .padding()
    }
}

// To use: In ContentView or YearView, add a button:
// Button("🔍 Check Data") {
//     // Show DiagnosticView as a sheet
// }
