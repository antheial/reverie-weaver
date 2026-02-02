//
//  ImageTodoExtractor.swift
//  Reverie Weaver
//
//  Extracts todo items from images using Vision OCR
//  Reuses parsing logic from PDFTodoExtractor for consistency
//

import Foundation
import Vision
import UIKit
import CoreGraphics

/// Extracts and parses todo items from images using Vision OCR
/// Leverages PDFTodoExtractor's parsing logic for consistent task detection
class ImageTodoExtractor {
    static let shared = ImageTodoExtractor()

    private init() {}

    // MARK: - Configuration

    /// Y-coordinate tolerance for grouping observations into lines (normalized 0-1)
    private let lineGroupingTolerance: CGFloat = 0.02

    /// X-coordinate step for indentation detection (normalized 0-1)
    private let indentStepSize: CGFloat = 0.05

    // MARK: - Image Processing

    /// Compress and resize image for optimal thumbnail storage
    /// Returns JPEG data at reduced size (~150px wide) for memory efficiency
    func createThumbnail(from image: UIImage, maxWidth: CGFloat = 150) -> Data? {
        let scale = maxWidth / image.size.width
        let newHeight = image.size.height * scale
        let newSize = CGSize(width: maxWidth, height: newHeight)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }

        return resizedImage.jpegData(compressionQuality: 0.6)
    }

    /// Crop image to the specified rect (in image coordinates)
    func cropImage(_ image: UIImage, to rect: CGRect) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        // Convert to image coordinate system
        let scale = image.scale
        let scaledRect = CGRect(
            x: rect.origin.x * scale,
            y: rect.origin.y * scale,
            width: rect.width * scale,
            height: rect.height * scale
        )

        guard let croppedCGImage = cgImage.cropping(to: scaledRect) else { return nil }
        return UIImage(cgImage: croppedCGImage, scale: scale, orientation: image.imageOrientation)
    }

    // MARK: - Text Extraction

    /// Extract raw text from an image using Vision OCR
    func extractText(from image: UIImage, cropRect: CGRect? = nil) -> String? {
        // Optionally crop the image first
        let targetImage: UIImage
        if let rect = cropRect {
            guard let cropped = cropImage(image, to: rect) else { return nil }
            targetImage = cropped
        } else {
            targetImage = image
        }

        guard let cgImage = targetImage.cgImage else { return nil }

        var recognizedText = ""
        let semaphore = DispatchSemaphore(value: 0)

        let request = VNRecognizeTextRequest { request, error in
            defer { semaphore.signal() }

            if let error = error {
                #if DEBUG
                print("ImageTodoExtractor: Vision OCR error: \(error)")
                #endif
                return
            }

            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                return
            }

            // Sort observations by Y position (top to bottom)
            // Vision Y is bottom-up, so higher Y = higher on image
            let sortedObservations = observations.sorted { $0.boundingBox.origin.y > $1.boundingBox.origin.y }

            // Group by approximate Y position and extract text
            var lines: [(y: CGFloat, text: String)] = []

            for observation in sortedObservations {
                guard let candidate = observation.topCandidates(1).first else { continue }
                let y = observation.boundingBox.origin.y
                let text = candidate.string

                // Group by approximate Y position
                if let lastIndex = lines.lastIndex(where: { abs($0.y - y) < 0.02 }) {
                    // Same line - append
                    lines[lastIndex].text += " " + text
                } else {
                    // New line
                    lines.append((y: y, text: text))
                }
            }

            // Sort by Y (top to bottom) and join
            recognizedText = lines
                .sorted { $0.y > $1.y }
                .map { $0.text }
                .joined(separator: "\n")
        }

        // Configure for accuracy
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["en-US", "zh-Hans", "zh-Hant"]

        // Perform recognition
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
            _ = semaphore.wait(timeout: .now() + 15)
        } catch {
            #if DEBUG
            print("ImageTodoExtractor: Vision request failed: \(error)")
            #endif
            return nil
        }

        #if DEBUG
        print("ImageTodoExtractor: Extracted \(recognizedText.count) chars from image")
        #endif

        return recognizedText.isEmpty ? nil : recognizedText
    }

    /// Extract text with spatial data (line positions and indentation)
    func extractSpatialLines(from image: UIImage, cropRect: CGRect? = nil) -> [ReconstructedLine] {
        // Optionally crop the image first
        let targetImage: UIImage
        if let rect = cropRect {
            guard let cropped = cropImage(image, to: rect) else { return [] }
            targetImage = cropped
        } else {
            targetImage = image
        }

        guard let cgImage = targetImage.cgImage else { return [] }

        var spatialLines: [ReconstructedLine] = []
        let semaphore = DispatchSemaphore(value: 0)

        let request = VNRecognizeTextRequest { [weak self] request, error in
            defer { semaphore.signal() }

            guard let self = self else { return }

            if let error = error {
                #if DEBUG
                print("ImageTodoExtractor: Vision spatial OCR error: \(error)")
                #endif
                return
            }

            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                return
            }

            // Calculate base X position for indentation
            var minX: CGFloat = 1.0
            for observation in observations {
                let x = observation.boundingBox.origin.x
                if x < minX {
                    minX = x
                }
            }

            // Convert observations to raw line data
            var rawLines: [(y: CGFloat, x: CGFloat, text: String)] = []

            for observation in observations {
                guard let candidate = observation.topCandidates(1).first else { continue }
                let bbox = observation.boundingBox

                rawLines.append((
                    y: bbox.origin.y,
                    x: bbox.origin.x,
                    text: candidate.string
                ))
            }

            // Group by approximate Y position
            var groupedLines: [[(y: CGFloat, x: CGFloat, text: String)]] = []
            var processedIndices = Set<Int>()

            for (i, line) in rawLines.enumerated() {
                if processedIndices.contains(i) { continue }

                var group = [line]
                processedIndices.insert(i)

                for (j, otherLine) in rawLines.enumerated() where j != i {
                    if processedIndices.contains(j) { continue }
                    if abs(otherLine.y - line.y) < self.lineGroupingTolerance {
                        group.append(otherLine)
                        processedIndices.insert(j)
                    }
                }

                groupedLines.append(group)
            }

            // Sort groups by Y (top to bottom - Vision Y is bottom-up)
            groupedLines.sort { $0[0].y > $1[0].y }

            // Convert groups to ReconstructedLines
            for group in groupedLines {
                // Sort within group by X (left to right)
                let sortedGroup = group.sorted { $0.x < $1.x }

                // Combine text from fragments on the same line
                let text = sortedGroup.map { $0.text }.joined(separator: " ")
                let leftmostX = sortedGroup.first?.x ?? 0

                // Calculate indent level
                let indentLevel = max(0, Int((leftmostX - minX) / self.indentStepSize))

                spatialLines.append(ReconstructedLine(
                    text: text,
                    indentLevel: indentLevel,
                    isBold: false,  // Vision doesn't provide font info
                    fontSize: 12,   // Default
                    yPosition: sortedGroup.first?.y ?? 0
                ))
            }
        }

        // Configure for maximum accuracy
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["en-US", "zh-Hans", "zh-Hant"]

        // Perform recognition
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
            _ = semaphore.wait(timeout: .now() + 15)
        } catch {
            #if DEBUG
            print("ImageTodoExtractor: Vision spatial request failed: \(error)")
            #endif
            return []
        }

        #if DEBUG
        print("ImageTodoExtractor: Extracted \(spatialLines.count) spatial lines")
        #endif

        return spatialLines
    }

    // MARK: - Todo Extraction

    /// Extract todos from an image
    /// Uses PDFTodoExtractor's parsing logic for consistent task detection
    func extractTodos(from image: UIImage, cropRect: CGRect? = nil) -> [String] {
        guard let text = extractText(from: image, cropRect: cropRect) else {
            return []
        }

        // Use PDFTodoExtractor's parsing logic
        let pdfExtractor = PDFTodoExtractor.shared

        // Auto-detect if this is a structured plan
        if pdfExtractor.isStructuredPlan(text) {
            #if DEBUG
            print("ImageTodoExtractor: Detected structured study plan")
            #endif
            return pdfExtractor.parseStudyPlanTodos(from: text, includeHeaders: false)
        } else {
            return pdfExtractor.parseTodos(from: text)
        }
    }

    /// Extract hierarchical todos from an image
    /// Returns tasks with headers and subtasks for better organization
    func extractHierarchicalTodos(from image: UIImage, cropRect: CGRect? = nil) -> [PDFTodoExtractor.HierarchicalTask] {
        // First try spatial extraction
        let spatialLines = extractSpatialLines(from: image, cropRect: cropRect)

        if !spatialLines.isEmpty {
            #if DEBUG
            print("ImageTodoExtractor: Using spatial analysis for hierarchical extraction")
            #endif
            // Use PDFTodoExtractor's spatial line parsing (it's internal but we can work around)
            return parseHierarchicalFromSpatialLines(spatialLines)
        }

        // Fall back to text-based extraction
        guard let text = extractText(from: image, cropRect: cropRect) else {
            return []
        }

        return PDFTodoExtractor.shared.parseHierarchicalTodos(from: text)
    }

    /// Parse hierarchical tasks from spatial lines
    /// Mirrors PDFTodoExtractor's parseHierarchicalTodosFromSpatialLines
    private func parseHierarchicalFromSpatialLines(_ lines: [ReconstructedLine]) -> [PDFTodoExtractor.HierarchicalTask] {
        var results: [PDFTodoExtractor.HierarchicalTask] = []
        var currentHeader: PDFTodoExtractor.HierarchicalTask? = nil
        var currentHeaderIndent: Int = 0

        for line in lines {
            let trimmed = line.text.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            // Clean the text
            let cleaned = cleanTodoText(trimmed)

            // Detect if this is a header based on patterns
            let isHeader = isHeaderPattern(trimmed)
            let isIndented = line.indentLevel > currentHeaderIndent
            let isBulletPoint = startsWithBullet(trimmed)

            if isHeader {
                // Save previous header and start new one
                if let header = currentHeader {
                    results.append(header)
                }
                currentHeader = PDFTodoExtractor.HierarchicalTask(text: cleaned, isHeader: true)
                currentHeaderIndent = line.indentLevel
            } else if isValidTaskText(cleaned) {
                if currentHeader != nil && (isIndented || isBulletPoint) {
                    // Subtask
                    currentHeader?.subtasks.append(cleaned)
                } else if currentHeader != nil && line.indentLevel <= currentHeaderIndent && !isBulletPoint {
                    // Same level, not bullet - new item
                    results.append(currentHeader!)
                    currentHeader = nil
                    results.append(PDFTodoExtractor.HierarchicalTask(text: cleaned, isHeader: false))
                } else if currentHeader != nil {
                    // Add as subtask
                    currentHeader?.subtasks.append(cleaned)
                } else {
                    // Standalone task
                    results.append(PDFTodoExtractor.HierarchicalTask(text: cleaned, isHeader: false))
                }
            }
        }

        // Don't forget the last header
        if let header = currentHeader {
            results.append(header)
        }

        // Post-process: convert headers with no subtasks to regular tasks if not clearly headers
        var finalResults: [PDFTodoExtractor.HierarchicalTask] = []
        for task in results {
            if task.isHeader && task.subtasks.isEmpty && !isDefinitelyHeader(task.text) {
                finalResults.append(PDFTodoExtractor.HierarchicalTask(text: task.text, isHeader: false))
            } else {
                finalResults.append(task)
            }
        }

        return finalResults
    }

    // MARK: - Helper Methods

    /// Check if text looks like a header pattern
    private func isHeaderPattern(_ text: String) -> Bool {
        let lower = text.lowercased()

        // Day/Week patterns
        if lower.hasPrefix("day ") || lower.hasPrefix("week ") ||
           lower.hasPrefix("session ") || lower.hasPrefix("part ") {
            return true
        }

        // Time block patterns
        if (lower.contains("morning") || lower.contains("afternoon") ||
            lower.contains("evening")) && (lower.contains("block") || lower.contains("hrs")) {
            return true
        }

        // Ends with colon and is short
        if text.hasSuffix(":") && text.count < 60 {
            return true
        }

        return false
    }

    /// Check if text is definitely a header
    private func isDefinitelyHeader(_ text: String) -> Bool {
        let patterns = [
            "day \\d+", "week \\d+", "session \\d+", "part \\d+",
            "morning block", "afternoon block", "evening block",
            "\\(\\d+(\\.\\d+)?\\s*(hr|hour|min)"
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                let range = NSRange(text.startIndex..<text.endIndex, in: text)
                if regex.firstMatch(in: text, options: [], range: range) != nil {
                    return true
                }
            }
        }

        return false
    }

    /// Check if text starts with a bullet point
    private func startsWithBullet(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        let bullets = ["•", "◦", "‣", "⁃", "□", "☐", "-", "*", ">",
                       "\u{2610}", "\u{2611}", "\u{2612}", "\u{25CB}", "\u{25CF}"]

        for bullet in bullets {
            if trimmed.hasPrefix(bullet) {
                return true
            }
        }

        // Numbered lists
        if let regex = try? NSRegularExpression(pattern: "^\\d+[.)]\\s+", options: []) {
            let range = NSRange(trimmed.startIndex..<trimmed.endIndex, in: trimmed)
            if regex.firstMatch(in: trimmed, options: [], range: range) != nil {
                return true
            }
        }

        return false
    }

    /// Check if text is valid as a task
    private func isValidTaskText(_ text: String) -> Bool {
        guard text.count >= 3 && text.count <= 500 else { return false }

        // Skip if just numbers
        if text.allSatisfy({ $0.isNumber || $0.isWhitespace || $0 == "." }) {
            return false
        }

        // Skip common non-task patterns
        let lower = text.lowercased()
        let skipPrefixes = ["page ", "chapter ", "figure ", "table ", "http", "www.", "copyright"]
        for prefix in skipPrefixes {
            if lower.hasPrefix(prefix) {
                return false
            }
        }

        return true
    }

    /// Clean up todo text
    private func cleanTodoText(_ text: String) -> String {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove leading bullet characters
        let bulletChars: [Character] = ["•", "◦", "‣", "⁃", "□", "☐", "-", "*"]
        if let first = cleaned.first, bulletChars.contains(first) {
            cleaned = String(cleaned.dropFirst()).trimmingCharacters(in: .whitespaces)
        }

        // Collapse multiple spaces
        while cleaned.contains("  ") {
            cleaned = cleaned.replacingOccurrences(of: "  ", with: " ")
        }

        // Capitalize first letter
        if let first = cleaned.first, first.isLowercase {
            cleaned = first.uppercased() + cleaned.dropFirst()
        }

        return cleaned
    }
}
