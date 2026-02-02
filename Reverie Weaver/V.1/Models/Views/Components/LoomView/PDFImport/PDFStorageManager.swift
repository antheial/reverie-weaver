//
//  PDFStorageManager.swift
//  Reverie Weaver
//
//  Handles file system operations for PDF storage
//

import Foundation
import PDFKit
import UIKit

// MARK: - Error Types

/// Errors that can occur during PDF import
enum PDFImportError: Error, LocalizedError {
    case accessDenied
    case copyFailed(String)
    case directoryCreationFailed
    case invalidPDF
    case insufficientStorage

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Unable to access the PDF file"
        case .copyFailed(let reason):
            return "Failed to copy PDF: \(reason)"
        case .directoryCreationFailed:
            return "Failed to create storage directory"
        case .invalidPDF:
            return "The file is not a valid PDF"
        case .insufficientStorage:
            return "Not enough storage space"
        }
    }
}

/// Result of PDF validation before import
enum PDFValidationResult {
    case valid(pageCount: Int)
    case tooLarge(sizeMB: Int64)
    case invalidFormat
    case accessDenied
    case unknown(String)
}

/// Successful import result
struct PDFImportResult {
    let relativePath: String
    let pageCount: Int
}

/// Manages PDF file storage on the file system
/// Note: This class is Sendable and thread-safe for file operations
final class PDFStorageManager: @unchecked Sendable {
    static let shared = PDFStorageManager()

    private let fileManager = FileManager.default
    private let pdfFolderName = "PDFImports"
    private let thumbnailFolderName = "PDFThumbnails"

    private init() {
        // Create directories on initialization
        _ = pdfDirectoryURL
        _ = thumbnailDirectoryURL
    }

    // MARK: - Directory URLs

    /// Documents directory
    private var documentsURL: URL? {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
    }

    /// Directory for storing PDFs
    var pdfDirectoryURL: URL? {
        guard let docs = documentsURL else { return nil }
        let url = docs.appendingPathComponent(pdfFolderName)
        createDirectoryIfNeeded(at: url)
        return url
    }

    /// Directory for storing thumbnails
    var thumbnailDirectoryURL: URL? {
        guard let docs = documentsURL else { return nil }
        let url = docs.appendingPathComponent(thumbnailFolderName)
        createDirectoryIfNeeded(at: url)
        return url
    }

    private func createDirectoryIfNeeded(at url: URL) {
        if !fileManager.fileExists(atPath: url.path) {
            do {
                try fileManager.createDirectory(at: url, withIntermediateDirectories: true)

                // Exclude from iCloud backup for privacy
                var mutableURL = url
                var resourceValues = URLResourceValues()
                resourceValues.isExcludedFromBackup = true
                try? mutableURL.setResourceValues(resourceValues)
            } catch {
                #if DEBUG
                print("PDFStorageManager: Failed to create directory at \(url): \(error)")
                #endif
            }
        }
    }

    // MARK: - Validation

    /// Validate a PDF before importing
    /// - Parameter url: The URL to validate
    /// - Returns: Validation result indicating if PDF can be imported
    func validatePDF(at url: URL, maxSizeMB: Int64 = 100) -> PDFValidationResult {
        // Start accessing security-scoped resource if needed
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        // Check file size
        do {
            let attributes = try fileManager.attributesOfItem(atPath: url.path)
            if let fileSize = attributes[.size] as? Int64 {
                let sizeMB = fileSize / (1024 * 1024)
                if sizeMB > maxSizeMB {
                    return .tooLarge(sizeMB: sizeMB)
                }
            }
        } catch {
            #if DEBUG
            print("PDFStorageManager: Failed to get file attributes: \(error)")
            #endif
            return .accessDenied
        }

        // Check if it's a valid PDF
        guard let document = PDFDocument(url: url) else {
            return .invalidFormat
        }

        let pageCount = document.pageCount
        if pageCount == 0 {
            return .invalidFormat
        }

        return .valid(pageCount: pageCount)
    }

    /// Check available storage space
    func hasAvailableStorage(requiredBytes: Int64 = 50 * 1024 * 1024) -> Bool {
        guard let documentsURL = documentsURL else { return false }

        do {
            let values = try documentsURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            if let available = values.volumeAvailableCapacityForImportantUsage {
                return available > requiredBytes
            }
        } catch {
            #if DEBUG
            print("PDFStorageManager: Failed to check storage: \(error)")
            #endif
        }

        return true // Assume available if can't check
    }

    // MARK: - Import PDF

    /// Import a PDF from a source URL and return the result
    /// - Parameter sourceURL: The URL of the PDF to import
    /// - Returns: Result with import details or error
    func importPDF(from sourceURL: URL) -> Result<PDFImportResult, PDFImportError> {
        guard let pdfDir = pdfDirectoryURL else {
            #if DEBUG
            print("PDFStorageManager: Failed to get PDF directory")
            #endif
            return .failure(.directoryCreationFailed)
        }

        // Check storage availability
        if !hasAvailableStorage() {
            return .failure(.insufficientStorage)
        }

        // Start accessing security-scoped resource if needed
        let accessing = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        // Validate PDF first
        guard let document = PDFDocument(url: sourceURL) else {
            return .failure(.invalidPDF)
        }

        let pageCount = document.pageCount
        if pageCount == 0 {
            return .failure(.invalidPDF)
        }

        // Generate unique filename
        let originalName = sourceURL.deletingPathExtension().lastPathComponent
        let uniqueName = "\(originalName)_\(UUID().uuidString.prefix(8)).pdf"
        let destinationURL = pdfDir.appendingPathComponent(uniqueName)

        do {
            // Copy the file
            try fileManager.copyItem(at: sourceURL, to: destinationURL)

            // Set backup exclusion attribute
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            var mutableURL = destinationURL
            try? mutableURL.setResourceValues(resourceValues)

            // Calculate relative path
            let relativePath = "\(pdfFolderName)/\(uniqueName)"

            #if DEBUG
            print("PDFStorageManager: Imported PDF to \(relativePath) (\(pageCount) pages)")
            #endif

            return .success(PDFImportResult(relativePath: relativePath, pageCount: pageCount))
        } catch let error as NSError {
            #if DEBUG
            print("PDFStorageManager: Failed to import PDF: \(error)")
            #endif

            // Clean up partial file if exists
            try? fileManager.removeItem(at: destinationURL)

            if error.domain == NSCocoaErrorDomain {
                switch error.code {
                case NSFileWriteOutOfSpaceError:
                    return .failure(.insufficientStorage)
                case NSFileReadNoPermissionError, NSFileWriteNoPermissionError:
                    return .failure(.accessDenied)
                default:
                    return .failure(.copyFailed(error.localizedDescription))
                }
            }

            return .failure(.copyFailed(error.localizedDescription))
        }
    }

    /// Get the page count of a PDF
    func getPageCount(for url: URL) -> Int {
        guard let document = PDFDocument(url: url) else { return 0 }
        return document.pageCount
    }

    // MARK: - Thumbnails

    /// Generate and save a thumbnail for a PDF
    /// - Parameters:
    ///   - pdfURL: URL of the PDF
    ///   - pdfId: UUID of the ImportedPDF for naming
    /// - Returns: Relative path to the thumbnail or nil
    func generateThumbnail(for pdfURL: URL, pdfId: UUID) -> String? {
        guard let thumbnailDir = thumbnailDirectoryURL,
              let document = PDFDocument(url: pdfURL),
              let page = document.page(at: 0) else {
            return nil
        }

        // Generate thumbnail
        let pageRect = page.bounds(for: .mediaBox)
        let scale: CGFloat = 200.0 / pageRect.width // Target 200pt width
        let thumbnailSize = CGSize(
            width: pageRect.width * scale,
            height: pageRect.height * scale
        )

        let renderer = UIGraphicsImageRenderer(size: thumbnailSize)
        let image = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: thumbnailSize))

            context.cgContext.translateBy(x: 0, y: thumbnailSize.height)
            context.cgContext.scaleBy(x: scale, y: -scale)

            page.draw(with: .mediaBox, to: context.cgContext)
        }

        // Save thumbnail
        let thumbnailName = "\(pdfId.uuidString).jpg"
        let thumbnailURL = thumbnailDir.appendingPathComponent(thumbnailName)

        guard let data = image.jpegData(compressionQuality: 0.7) else {
            return nil
        }

        do {
            try data.write(to: thumbnailURL)
            let relativePath = "\(thumbnailFolderName)/\(thumbnailName)"

            #if DEBUG
            print("PDFStorageManager: Generated thumbnail at \(relativePath)")
            #endif

            return relativePath
        } catch {
            #if DEBUG
            print("PDFStorageManager: Failed to save thumbnail: \(error)")
            #endif
            return nil
        }
    }

    /// Generate a thumbnail for a specific page
    /// Note: nonisolated to allow calling from background threads
    nonisolated func generatePageThumbnail(for pdfURL: URL, pageIndex: Int, targetWidth: CGFloat = 150) -> UIImage? {
        guard let document = PDFDocument(url: pdfURL),
              let page = document.page(at: pageIndex) else {
            return nil
        }

        let pageRect = page.bounds(for: .mediaBox)
        let scale = targetWidth / pageRect.width
        let thumbnailSize = CGSize(
            width: pageRect.width * scale,
            height: pageRect.height * scale
        )

        let renderer = UIGraphicsImageRenderer(size: thumbnailSize)
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: thumbnailSize))

            context.cgContext.translateBy(x: 0, y: thumbnailSize.height)
            context.cgContext.scaleBy(x: scale, y: -scale)

            page.draw(with: .mediaBox, to: context.cgContext)
        }
    }

    // MARK: - Delete

    /// Delete a PDF and its thumbnail
    /// - Returns: True if deletion was successful
    @discardableResult
    func deletePDF(relativePath: String, thumbnailRelativePath: String?) -> Bool {
        guard let docs = documentsURL else { return false }

        var success = true

        // Delete PDF
        let pdfURL = docs.appendingPathComponent(relativePath)
        do {
            try fileManager.removeItem(at: pdfURL)
        } catch {
            #if DEBUG
            print("PDFStorageManager: Failed to delete PDF at \(relativePath): \(error)")
            #endif
            success = false
        }

        // Delete thumbnail if exists
        if let thumbPath = thumbnailRelativePath {
            let thumbURL = docs.appendingPathComponent(thumbPath)
            do {
                try fileManager.removeItem(at: thumbURL)
            } catch {
                #if DEBUG
                print("PDFStorageManager: Failed to delete thumbnail at \(thumbPath): \(error)")
                #endif
                // Don't fail overall if thumbnail delete fails
            }
        }

        #if DEBUG
        if success {
            print("PDFStorageManager: Deleted PDF at \(relativePath)")
        }
        #endif

        return success
    }

    /// Clear all thumbnails (cache cleanup)
    func clearThumbnailCache() {
        guard let thumbnailDir = thumbnailDirectoryURL else { return }

        try? fileManager.removeItem(at: thumbnailDir)
        createDirectoryIfNeeded(at: thumbnailDir)

        #if DEBUG
        print("PDFStorageManager: Cleared thumbnail cache")
        #endif
    }

    // MARK: - Storage Info

    /// Calculate total storage used by PDFs and thumbnails
    func calculateStorageUsed() -> (pdfs: Int64, thumbnails: Int64) {
        var pdfSize: Int64 = 0
        var thumbSize: Int64 = 0

        if let pdfDir = pdfDirectoryURL {
            pdfSize = calculateDirectorySize(at: pdfDir)
        }

        if let thumbDir = thumbnailDirectoryURL {
            thumbSize = calculateDirectorySize(at: thumbDir)
        }

        return (pdfSize, thumbSize)
    }

    private func calculateDirectorySize(at url: URL) -> Int64 {
        var size: Int64 = 0
        let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey])

        while let fileURL = enumerator?.nextObject() as? URL {
            if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                size += Int64(fileSize)
            }
        }

        return size
    }

    /// Format bytes to human-readable string
    func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
