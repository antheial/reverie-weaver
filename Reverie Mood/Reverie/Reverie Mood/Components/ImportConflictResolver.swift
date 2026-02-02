//
//  ImportConflictResolver.swift
//  Reverie Mood
//
//  Created by Claude on 1/23/26.
//

import Foundation
import SwiftData
import OSLog

/// Handles conflicts when importing backup data
final class ImportConflictResolver {

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.reverie.mood",
        category: "ImportConflict"
    )

    // MARK: - Conflict Detection

    struct ImportConflict: Identifiable {
        let id = UUID()
        let dayOfYear: Int
        let year: Int
        let existingEntry: MoodEntry
        let importedEntry: MoodEntry

        var dateString: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: existingEntry.date)
        }

        var hasContentDifference: Bool {
            existingEntry.moodId != importedEntry.moodId ||
            existingEntry.reflection != importedEntry.reflection ||
            existingEntry.photoFileName != importedEntry.photoFileName
        }

        var isNewerInBackup: Bool {
            importedEntry.date > existingEntry.date
        }
    }

    struct ConflictAnalysis {
        var totalImported: Int = 0
        var newEntries: Int = 0
        var conflicts: [ImportConflict] = []
        var identicalEntries: Int = 0

        var hasConflicts: Bool {
            !conflicts.isEmpty
        }
    }

    /// Analyzes import and detects conflicts
    func analyzeImport(
        importedEntries: [MoodEntry],
        existingEntries: [MoodEntry]
    ) -> ConflictAnalysis {
        var analysis = ConflictAnalysis()
        analysis.totalImported = importedEntries.count

        // Create lookup dictionary for existing entries
        var existingDict: [String: MoodEntry] = [:]
        for entry in existingEntries {
            let key = "\(entry.year)_\(entry.dayOfYear)"
            existingDict[key] = entry
        }

        // Check each imported entry
        for importedEntry in importedEntries {
            let key = "\(importedEntry.year)_\(importedEntry.dayOfYear)"

            if let existingEntry = existingDict[key] {
                // Entry exists - check if there's a conflict
                let conflict = ImportConflict(
                    dayOfYear: importedEntry.dayOfYear,
                    year: importedEntry.year,
                    existingEntry: existingEntry,
                    importedEntry: importedEntry
                )

                if conflict.hasContentDifference {
                    analysis.conflicts.append(conflict)
                    logger.info("Conflict detected: \(importedEntry.year)/day \(importedEntry.dayOfYear)")
                } else {
                    analysis.identicalEntries += 1
                }
            } else {
                // New entry
                analysis.newEntries += 1
            }
        }

        logger.info("Import analysis: \(analysis.newEntries) new, \(analysis.conflicts.count) conflicts, \(analysis.identicalEntries) identical")

        return analysis
    }

    // MARK: - Resolution Strategies

    enum ResolutionStrategy {
        case keepExisting           // Keep all existing entries, skip imported
        case replaceWithImported    // Replace all with imported entries
        case keepNewer             // Keep whichever is newer (by date)
        case manual                // User chooses for each conflict
    }

    struct ResolutionDecision {
        let conflict: ImportConflict
        let action: ConflictAction

        enum ConflictAction {
            case keepExisting
            case useImported
        }
    }

    /// Applies resolution strategy to conflicts
    func resolveConflicts(
        conflicts: [ImportConflict],
        strategy: ResolutionStrategy,
        manualDecisions: [UUID: ResolutionDecision.ConflictAction] = [:]
    ) -> [ResolutionDecision] {
        var decisions: [ResolutionDecision] = []

        for conflict in conflicts {
            let action: ResolutionDecision.ConflictAction

            switch strategy {
            case .keepExisting:
                action = .keepExisting

            case .replaceWithImported:
                action = .useImported

            case .keepNewer:
                action = conflict.isNewerInBackup ? .useImported : .keepExisting

            case .manual:
                action = manualDecisions[conflict.id] ?? .keepExisting
            }

            decisions.append(ResolutionDecision(conflict: conflict, action: action))
        }

        return decisions
    }

    // MARK: - Import Execution

    struct ImportResult {
        var imported: Int = 0
        var skipped: Int = 0
        var replaced: Int = 0
        var errors: [String] = []
    }

    /// Executes import with conflict resolution
    func executeImport(
        importedEntries: [MoodEntry],
        existingEntries: [MoodEntry],
        decisions: [ResolutionDecision],
        modelContext: ModelContext
    ) -> ImportResult {
        var result = ImportResult()

        // Create lookup for decisions
        var decisionDict: [String: ResolutionDecision.ConflictAction] = [:]
        for decision in decisions {
            let key = "\(decision.conflict.year)_\(decision.conflict.dayOfYear)"
            decisionDict[key] = decision.action
        }

        // Create lookup for existing entries
        var existingDict: [String: MoodEntry] = [:]
        for entry in existingEntries {
            let key = "\(entry.year)_\(entry.dayOfYear)"
            existingDict[key] = entry
        }

        // Process each imported entry
        for importedEntry in importedEntries {
            let key = "\(importedEntry.year)_\(importedEntry.dayOfYear)"

            if let existingEntry = existingDict[key] {
                // Conflict - apply decision
                let action = decisionDict[key] ?? .keepExisting

                switch action {
                case .keepExisting:
                    result.skipped += 1
                    logger.debug("Skipped: \(key) (keeping existing)")

                case .useImported:
                    // Delete existing and insert imported
                    modelContext.delete(existingEntry)
                    modelContext.insert(importedEntry)
                    result.replaced += 1
                    logger.debug("Replaced: \(key) (using imported)")
                }
            } else {
                // New entry - insert
                modelContext.insert(importedEntry)
                result.imported += 1
                logger.debug("Imported new: \(key)")
            }
        }

        // Save changes
        do {
            try modelContext.save()
            logger.info("Import completed: \(result.imported) new, \(result.replaced) replaced, \(result.skipped) skipped")
        } catch {
            result.errors.append("Failed to save: \(error.localizedDescription)")
            logger.error("Import save failed: \(error.localizedDescription)")
        }

        return result
    }

    // MARK: - Preview

    /// Generates preview of what will happen with given strategy
    func generatePreview(
        analysis: ConflictAnalysis,
        strategy: ResolutionStrategy
    ) -> ImportPreview {
        let decisions = resolveConflicts(conflicts: analysis.conflicts, strategy: strategy)

        let willImport = analysis.newEntries
        var willReplace = 0
        var willSkip = 0

        for decision in decisions {
            switch decision.action {
            case .useImported:
                willReplace += 1
            case .keepExisting:
                willSkip += 1
            }
        }

        return ImportPreview(
            newEntries: analysis.newEntries,
            willReplace: willReplace,
            willSkip: willSkip,
            totalAffected: willImport + willReplace
        )
    }

    struct ImportPreview {
        let newEntries: Int
        let willReplace: Int
        let willSkip: Int
        let totalAffected: Int

        var summary: String {
            var parts: [String] = []

            if newEntries > 0 {
                parts.append("\(newEntries) new entries will be added")
            }
            if willReplace > 0 {
                parts.append("\(willReplace) existing entries will be replaced")
            }
            if willSkip > 0 {
                parts.append("\(willSkip) entries will be skipped")
            }

            return parts.joined(separator: "\n")
        }
    }
}
