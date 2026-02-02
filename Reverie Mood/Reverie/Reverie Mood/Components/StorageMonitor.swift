//
//  StorageMonitor.swift
//  Reverie Mood
//
//  Created by Claude on 1/23/26.
//

import Foundation
import OSLog
import SwiftData

/// Monitors device storage and warns when space is low
final class StorageMonitor {

    static let shared = StorageMonitor()

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.reverie.mood",
        category: "Storage"
    )

    // MARK: - Storage Thresholds

    private enum StorageThreshold {
        static let critical: Int64 = 50 * 1024 * 1024  // 50MB
        static let warning: Int64 = 100 * 1024 * 1024  // 100MB
        static let comfortable: Int64 = 500 * 1024 * 1024  // 500MB
    }

    // MARK: - Storage Status

    enum StorageStatus {
        case critical(availableMB: Int64)
        case warning(availableMB: Int64)
        case comfortable(availableMB: Int64)

        var isCritical: Bool {
            if case .critical = self { return true }
            return false
        }

        var needsWarning: Bool {
            switch self {
            case .critical, .warning:
                return true
            case .comfortable:
                return false
            }
        }

        var message: String {
            switch self {
            case .critical(let mb):
                return "Critical: Only \(mb)MB left. Save may fail."
            case .warning(let mb):
                return "Low storage: \(mb)MB remaining."
            case .comfortable(let mb):
                return "\(mb)MB available"
            }
        }
    }

    // MARK: - Storage Checks

    /// Gets current storage status
    func getStorageStatus() -> StorageStatus {
        let availableBytes = getAvailableStorage()
        let availableMB = availableBytes / (1024 * 1024)

        if availableBytes < StorageThreshold.critical {
            logger.error("CRITICAL: Only \(availableMB)MB storage remaining")
            return .critical(availableMB: availableMB)
        } else if availableBytes < StorageThreshold.warning {
            logger.warning("Low storage: \(availableMB)MB remaining")
            return .warning(availableMB: availableMB)
        } else {
            return .comfortable(availableMB: availableMB)
        }
    }

    /// Checks if there's enough storage for a save operation
    func canSafeSave(estimatedSize: Int64 = 1024 * 1024) -> Bool {
        let available = getAvailableStorage()
        let needed = estimatedSize + StorageThreshold.critical // Need size + buffer

        return available >= needed
    }

    /// Gets available storage in bytes
    private func getAvailableStorage() -> Int64 {
        do {
            let fileURL = URL(fileURLWithPath: NSHomeDirectory())
            let values = try fileURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])

            if let capacity = values.volumeAvailableCapacityForImportantUsage {
                return capacity
            }
        } catch {
            logger.error("Failed to get storage info: \(error.localizedDescription)")
        }

        // Fallback method
        do {
            let fileURL = URL(fileURLWithPath: NSHomeDirectory())
            let values = try fileURL.resourceValues(forKeys: [.volumeAvailableCapacityKey])

            if let capacity = values.volumeAvailableCapacity {
                return Int64(capacity)
            }
        } catch {
            logger.error("Fallback storage check failed: \(error.localizedDescription)")
        }

        return 0
    }

    /// Gets total storage used by app
    func getAppStorageUsage() -> Int64 {
        var totalSize: Int64 = 0

        // Check Documents directory
        if let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            totalSize += directorySize(at: documentsURL)
        }

        // Check Caches directory
        if let cachesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            totalSize += directorySize(at: cachesURL)
        }

        return totalSize
    }

    private func directorySize(at url: URL) -> Int64 {
        var totalSize: Int64 = 0

        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }

        for case let fileURL as URL in enumerator {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey])
                if let fileSize = resourceValues.fileSize {
                    totalSize += Int64(fileSize)
                }
            } catch {
                continue
            }
        }

        return totalSize
    }

    // MARK: - Storage Breakdown

    struct StorageBreakdown {
        var totalAppUsageMB: Int64
        var photosMB: Int64
        var audioMB: Int64
        var backupsMB: Int64
        var databaseMB: Int64

        // Counts
        var photoCount: Int = 0
        var audioCount: Int = 0
        var backupCount: Int = 0

        // Formatted strings for display
        var totalFormatted: String {
            formatBytes(totalAppUsageMB * 1024 * 1024)
        }

        var photosFormatted: String {
            formatBytes(photosMB * 1024 * 1024)
        }

        var audioFormatted: String {
            formatBytes(audioMB * 1024 * 1024)
        }

        var backupsFormatted: String {
            formatBytes(backupsMB * 1024 * 1024)
        }

        var databaseFormatted: String {
            formatBytes(databaseMB * 1024 * 1024)
        }

        private func formatBytes(_ bytes: Int64) -> String {
            let formatter = ByteCountFormatter()
            formatter.allowedUnits = [.useKB, .useMB, .useGB]
            formatter.countStyle = .file
            return formatter.string(fromByteCount: bytes)
        }
    }

    func getStorageBreakdown() -> StorageBreakdown {
        var breakdown = StorageBreakdown(
            totalAppUsageMB: 0,
            photosMB: 0,
            audioMB: 0,
            backupsMB: 0,
            databaseMB: 0
        )

        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return breakdown
        }

        // Photos
        let photosURL = documentsURL.appendingPathComponent("Photos")
        let (photosSize, photosCount) = directorySizeAndCount(at: photosURL, extensions: ["jpg", "jpeg", "png", "heic"])
        breakdown.photosMB = photosSize / (1024 * 1024)
        breakdown.photoCount = photosCount

        // Audio recordings
        let recordingsURL = documentsURL.appendingPathComponent("Recordings")
        let (audioSize, audioCount) = directorySizeAndCount(at: recordingsURL, extensions: ["m4a", "mp3", "wav"])
        breakdown.audioMB = audioSize / (1024 * 1024)
        breakdown.audioCount = audioCount

        // Backups
        let backupsURL = documentsURL.appendingPathComponent("Backups")
        let (backupsSize, backupsCount) = directorySizeAndCount(at: backupsURL, extensions: ["json"])
        breakdown.backupsMB = backupsSize / (1024 * 1024)
        breakdown.backupCount = backupsCount

        // Total
        breakdown.totalAppUsageMB = getAppStorageUsage() / (1024 * 1024)
        breakdown.databaseMB = max(0, breakdown.totalAppUsageMB - breakdown.photosMB - breakdown.audioMB - breakdown.backupsMB)

        return breakdown
    }

    private func directorySizeAndCount(at url: URL, extensions: [String]? = nil) -> (size: Int64, count: Int) {
        var totalSize: Int64 = 0
        var fileCount: Int = 0

        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return (0, 0)
        }

        for case let fileURL as URL in enumerator {
            // Filter by extension if provided
            if let extensions = extensions {
                let ext = fileURL.pathExtension.lowercased()
                if !extensions.contains(ext) {
                    continue
                }
            }

            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey])
                if let fileSize = resourceValues.fileSize {
                    totalSize += Int64(fileSize)
                    fileCount += 1
                }
            } catch {
                continue
            }
        }

        return (totalSize, fileCount)
    }

    // MARK: - Yearly Archive Support

    struct YearlyStorageInfo {
        let year: Int
        var photoCount: Int = 0
        var audioCount: Int = 0
        var entryCount: Int = 0
        var photoSizeBytes: Int64 = 0
        var audioSizeBytes: Int64 = 0

        var totalSizeBytes: Int64 {
            photoSizeBytes + audioSizeBytes
        }

        var totalFormatted: String {
            let formatter = ByteCountFormatter()
            formatter.allowedUnits = [.useKB, .useMB, .useGB]
            formatter.countStyle = .file
            return formatter.string(fromByteCount: totalSizeBytes)
        }
    }

    /// Get storage info grouped by year
    func getYearlyStorageInfo(entries: [MoodEntry]) -> [YearlyStorageInfo] {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return []
        }

        // Group entries by year
        let entriesByYear = Dictionary(grouping: entries, by: { $0.year })
        var yearlyInfo: [YearlyStorageInfo] = []

        for (year, yearEntries) in entriesByYear.sorted(by: { $0.key < $1.key }) {
            var info = YearlyStorageInfo(year: year)
            info.entryCount = yearEntries.count

            let photosURL = documentsURL.appendingPathComponent("Photos")
            let recordingsURL = documentsURL.appendingPathComponent("Recordings")

            // Count photos and audio for this year
            for entry in yearEntries {
                // Check for photos (filename format: reverie_YEAR_DAY_timestamp.jpg)
                if let photoName = entry.photoFileName {
                    let photoPath = photosURL.appendingPathComponent(photoName)
                    if let attrs = try? FileManager.default.attributesOfItem(atPath: photoPath.path),
                       let size = attrs[.size] as? Int64 {
                        info.photoCount += 1
                        info.photoSizeBytes += size
                    }
                }

                // Check for morning memo
                let morningMemo = recordingsURL.appendingPathComponent("moodmemo_\(entry.year)_\(String(format: "%03d", entry.dayOfYear))_morning.m4a")
                if let attrs = try? FileManager.default.attributesOfItem(atPath: morningMemo.path),
                   let size = attrs[.size] as? Int64 {
                    info.audioCount += 1
                    info.audioSizeBytes += size
                }

                // Check for evening memo
                let eveningMemo = recordingsURL.appendingPathComponent("moodmemo_\(entry.year)_\(String(format: "%03d", entry.dayOfYear))_evening.m4a")
                if let attrs = try? FileManager.default.attributesOfItem(atPath: eveningMemo.path),
                   let size = attrs[.size] as? Int64 {
                    info.audioCount += 1
                    info.audioSizeBytes += size
                }
            }

            yearlyInfo.append(info)
        }

        return yearlyInfo
    }
}
