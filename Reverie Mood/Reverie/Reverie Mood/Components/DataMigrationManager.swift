//
//  DataMigrationManager.swift
//  Reverie Mood
//
//  Created by Claude on 1/23/26.
//

import Foundation
import SwiftData
import OSLog

/// Manages schema migrations and automatic backups to prevent data loss
final class DataMigrationManager {

    static let shared = DataMigrationManager()

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.reverie.mood",
        category: "DataMigration"
    )

    // MARK: - Schema Version Tracking

    /// Current schema version - increment when making schema changes
    /// Version History:
    /// 1: Initial release (MoodEntry only)
    /// 2: Added GroundingEntry model
    private static let currentSchemaVersion = 2

    private var storedSchemaVersion: Int {
        get { UserDefaults.standard.integer(forKey: "schemaVersion") }
        set { UserDefaults.standard.set(newValue, forKey: "schemaVersion") }
    }
    
    private var lastBackupDate: Double {
        get { UserDefaults.standard.double(forKey: "lastBackupDate") }
        set { UserDefaults.standard.set(newValue, forKey: "lastBackupDate") }
    }
    
    private var autoBackupEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "autoBackupEnabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "autoBackupEnabled") }
    }

    // MARK: - Migration Detection

    /// Checks if migration is needed and creates backup before proceeding
    func checkAndPrepareMigration(modelContext: ModelContext) async {
        let currentVersion = Self.currentSchemaVersion
        let previousVersion = storedSchemaVersion

        if previousVersion < currentVersion {
            logger.warning("Schema migration detected: v\(previousVersion) → v\(currentVersion)")

            // Create automatic backup before migration
            if autoBackupEnabled {
                await createPreMigrationBackup(modelContext: modelContext, fromVersion: previousVersion, toVersion: currentVersion)
            }

            // Update stored version
            storedSchemaVersion = currentVersion
            logger.info("Schema version updated to v\(currentVersion)")
        } else {
            logger.info("Schema version current: v\(currentVersion)")
        }
    }

    // MARK: - Automatic Backups

    /// Creates a backup before schema migration
    private func createPreMigrationBackup(modelContext: ModelContext, fromVersion: Int, toVersion: Int) async {
        logger.info("Creating pre-migration backup (v\(fromVersion) → v\(toVersion))")

        do {
            let descriptor = FetchDescriptor<MoodEntry>()
            let entries = try modelContext.fetch(descriptor)

            if entries.isEmpty {
                logger.info("No entries to backup")
                return
            }

            let backupData = try JSONEncoder().encode(entries)
            let timestamp = Date().timeIntervalSince1970
            let filename = "reverie_backup_v\(fromVersion)_to_v\(toVersion)_\(Int(timestamp)).json"

            // Save to Documents/Backups directory
            let backupURL = getBackupDirectory().appendingPathComponent(filename)
            try backupData.write(to: backupURL)

            logger.info("Pre-migration backup created: \(filename) (\(entries.count) entries)")

            // Also save to iCloud if available
            await saveToiCloud(backupData: backupData, filename: filename)

            // Update last backup date
            lastBackupDate = timestamp

            // Verify backup integrity
            if await verifyBackup(backupData: backupData) {
                logger.info("Pre-migration backup verified successfully")
            } else {
                logger.error("Pre-migration backup verification FAILED - backup may be corrupted")
            }

            // Clean up old backups after pre-migration backup
            cleanupOldBackups()

        } catch {
            logger.error("Failed to create pre-migration backup: \(error.localizedDescription)")
        }
    }

    /// Creates a periodic backup (daily or on-demand)
    func createPeriodicBackup(modelContext: ModelContext) async {
        logger.info("Creating periodic backup")

        do {
            let descriptor = FetchDescriptor<MoodEntry>()
            let entries = try modelContext.fetch(descriptor)

            if entries.isEmpty {
                logger.info("No entries to backup")
                return
            }

            let backupData = try JSONEncoder().encode(entries)
            let timestamp = Date().timeIntervalSince1970
            let filename = "reverie_backup_\(Int(timestamp)).json"

            // Save to Documents/Backups directory
            let backupURL = getBackupDirectory().appendingPathComponent(filename)
            try backupData.write(to: backupURL)

            logger.info("Periodic backup created: \(filename) (\(entries.count) entries)")

            // Also save to iCloud if available
            await saveToiCloud(backupData: backupData, filename: filename)

            // Update last backup date
            lastBackupDate = timestamp

            // Verify backup integrity
            if await verifyBackup(backupData: backupData) {
                logger.info("Periodic backup verified successfully")
            } else {
                logger.error("Periodic backup verification FAILED - backup may be corrupted")
            }

            // Clean up old backups (keep last 10)
            cleanupOldBackups()

        } catch {
            logger.error("Failed to create periodic backup: \(error.localizedDescription)")
        }
    }

    /// Checks if daily backup is needed
    func shouldCreateDailyBackup() -> Bool {
        guard autoBackupEnabled else { return false }

        let lastBackup = Date(timeIntervalSince1970: lastBackupDate)
        let daysSinceBackup = Calendar.current.dateComponents([.day], from: lastBackup, to: Date()).day ?? 0

        return daysSinceBackup >= 1
    }

    // MARK: - iCloud Backup

    private func saveToiCloud(backupData: Data, filename: String) async {
        guard let iCloudURL = FileManager.default.url(forUbiquityContainerIdentifier: nil) else {
            logger.info("iCloud not available")
            return
        }

        let backupDirectory = iCloudURL.appendingPathComponent("Documents/Backups", isDirectory: true)

        do {
            // Create directory if needed
            try FileManager.default.createDirectory(at: backupDirectory, withIntermediateDirectories: true)

            let iCloudBackupURL = backupDirectory.appendingPathComponent(filename)
            try backupData.write(to: iCloudBackupURL)

            logger.info("Backup saved to iCloud: \(filename)")
        } catch {
            logger.error("Failed to save backup to iCloud: \(error.localizedDescription)")
        }
    }

    // MARK: - Backup Directory Management

    private func getBackupDirectory() -> URL {
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("Backups", isDirectory: true)
            try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            return tempDir
        }

        let backupDir = docs.appendingPathComponent("Backups", isDirectory: true)
        try? FileManager.default.createDirectory(at: backupDir, withIntermediateDirectories: true)
        return backupDir
    }

    /// Returns all available backups (local + iCloud)
    func getAvailableBackups() -> [BackupFile] {
        var backups: [BackupFile] = []

        // Local backups
        let localBackupDir = getBackupDirectory()
        if let localFiles = try? FileManager.default.contentsOfDirectory(at: localBackupDir, includingPropertiesForKeys: [.creationDateKey]) {
            for fileURL in localFiles where fileURL.pathExtension == "json" {
                if let creationDate = try? fileURL.resourceValues(forKeys: [.creationDateKey]).creationDate {
                    backups.append(BackupFile(url: fileURL, date: creationDate, location: .local))
                }
            }
        }

        // iCloud backups
        if let iCloudURL = FileManager.default.url(forUbiquityContainerIdentifier: nil) {
            let iCloudBackupDir = iCloudURL.appendingPathComponent("Documents/Backups", isDirectory: true)
            if let iCloudFiles = try? FileManager.default.contentsOfDirectory(at: iCloudBackupDir, includingPropertiesForKeys: [.creationDateKey]) {
                for fileURL in iCloudFiles where fileURL.pathExtension == "json" {
                    if let creationDate = try? fileURL.resourceValues(forKeys: [.creationDateKey]).creationDate {
                        backups.append(BackupFile(url: fileURL, date: creationDate, location: .iCloud))
                    }
                }
            }
        }

        // Sort by date (newest first)
        return backups.sorted { $0.date > $1.date }
    }

    /// Cleans up old backups, keeping only the 5 most recent for each location
    /// Call this after any backup operation (manual, periodic, or pre-migration)
    func cleanupOldBackups() {
        let maxBackups = 5

        // Clean up local backups
        let localBackups = getAvailableBackups().filter { $0.location == .local }
        if localBackups.count > maxBackups {
            let oldLocalBackups = Array(localBackups.dropFirst(maxBackups))
            for backup in oldLocalBackups {
                try? FileManager.default.removeItem(at: backup.url)
                logger.info("Removed old local backup: \(backup.url.lastPathComponent)")
            }
        }

        // Clean up iCloud backups
        let iCloudBackups = getAvailableBackups().filter { $0.location == .iCloud }
        if iCloudBackups.count > maxBackups {
            let oldICloudBackups = Array(iCloudBackups.dropFirst(maxBackups))
            for backup in oldICloudBackups {
                try? FileManager.default.removeItem(at: backup.url)
                logger.info("Removed old iCloud backup: \(backup.url.lastPathComponent)")
            }
        }
    }

    // MARK: - Backup Verification

    /// Verifies that a backup can be successfully decoded
    private func verifyBackup(backupData: Data) async -> Bool {
        do {
            // Try to decode the backup
            let decoder = JSONDecoder()
            let entries = try decoder.decode([MoodEntry].self, from: backupData)

            // Verify all entries have required fields
            for entry in entries {
                guard !entry.moodId.isEmpty,
                      !entry.moodName.isEmpty,
                      entry.year >= 2020,
                      entry.year <= 2100,
                      entry.dayOfYear >= 1,
                      entry.dayOfYear <= 366 else {
                    logger.error("Backup verification failed: Invalid entry data")
                    return false
                }
            }

            logger.info("Backup verification passed: \(entries.count) entries valid")
            return true

        } catch {
            logger.error("Backup verification failed: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Data Integrity Check

    /// Verifies data integrity on app launch
    func verifyDataIntegrity(modelContext: ModelContext) async -> DataIntegrityReport {
        logger.info("Starting data integrity check")

        var report = DataIntegrityReport()

        do {
            // Check MoodEntry integrity
            let descriptor = FetchDescriptor<MoodEntry>()
            let entries = try modelContext.fetch(descriptor)

            report.totalEntries = entries.count

            // Check for corrupted entries
            for entry in entries {
                let entryId = entry.persistentModelID

                // Verify required fields
                if entry.moodId.isEmpty || entry.moodName.isEmpty {
                    report.corruptedEntries.append(entryId)
                }

                // Verify year/day consistency
                if entry.year < 2020 || entry.year > 2100 {
                    report.corruptedEntries.append(entryId)
                }

                if entry.dayOfYear < 1 || entry.dayOfYear > 366 {
                    report.corruptedEntries.append(entryId)
                }

                // Check for orphaned photos
                if let photoFileName = entry.photoFileName {
                    let photoURL = MoodEntry.photosDirectory().appendingPathComponent(photoFileName)
                    if !FileManager.default.fileExists(atPath: photoURL.path) {
                        report.orphanedPhotos.append(photoFileName)
                    }
                }
            }

            report.isHealthy = report.corruptedEntries.isEmpty && report.orphanedPhotos.isEmpty

            if report.isHealthy {
                logger.info("Data integrity check passed: \(entries.count) entries OK")
            } else {
                logger.warning("Data integrity issues found: \(report.corruptedEntries.count) corrupted, \(report.orphanedPhotos.count) orphaned photos")
            }

        } catch {
            logger.error("Data integrity check failed: \(error.localizedDescription)")
            report.isHealthy = false
        }

        return report
    }
}

// MARK: - Supporting Types

struct BackupFile: Identifiable {
    let id = UUID()
    let url: URL
    let date: Date
    let location: BackupLocation

    enum BackupLocation {
        case local
        case iCloud
    }
}

struct DataIntegrityReport {
    var totalEntries: Int = 0
    var corruptedEntries: [PersistentIdentifier] = []
    var orphanedPhotos: [String] = []
    var isHealthy: Bool = true
}
