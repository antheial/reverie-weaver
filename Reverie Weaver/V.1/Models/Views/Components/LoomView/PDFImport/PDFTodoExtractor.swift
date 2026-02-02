//
//  PDFTodoExtractor.swift
//  Reverie Weaver
//
//  Extracts todo items from PDF text with smart line detection
//  Uses a hybrid approach: PDFKit for native text + Vision OCR fallback
//

import Foundation
import PDFKit
import CoreGraphics
import Vision
import UIKit

// MARK: - Text Fragment with Spatial Data

/// Represents a text fragment with its position on the page
struct TextFragment: Sendable {
    let text: String
    let bounds: CGRect        // Position on PDF page
    let indentLevel: Int      // Calculated from X position (0 = no indent, 1+ = nested)
    let isBold: Bool          // Font weight indicator (header detection)
    let fontSize: CGFloat     // For header detection

    /// Y position for sorting (PDF coordinates: bottom = 0)
    var yPosition: CGFloat { bounds.origin.y }

    /// X position for indentation analysis
    var xPosition: CGFloat { bounds.origin.x }
}

/// Represents a line reconstructed from fragments
struct ReconstructedLine: Sendable {
    let text: String
    let indentLevel: Int
    let isBold: Bool
    let fontSize: CGFloat
    let yPosition: CGFloat
}

/// Extracts and parses todo items from PDF content
/// Uses smart detection for indentation, spacing, and various list formats
/// Implements a "Native + Vision" hybrid approach for maximum accuracy
class PDFTodoExtractor {
    static let shared = PDFTodoExtractor()

    private init() {}

    // MARK: - Configuration

    /// Minimum text length to consider for OCR fallback
    private let minNativeTextLength = 50

    /// Y-coordinate tolerance for grouping fragments into lines (in PDF points)
    private let lineGroupingTolerance: CGFloat = 5.0

    /// Base X position - fragments with X > this + threshold are considered indented
    private var baseIndentX: CGFloat = 0

    /// Indentation step size (in PDF points, typically 20-40 for a single indent)
    private let indentStepSize: CGFloat = 25.0

    // MARK: - Enhanced Text Extraction

    /// Extract text from a specific page using the hybrid approach
    /// First tries PDFKit with spatial analysis, falls back to Vision OCR if needed
    func extractText(from pdfURL: URL, pageIndex: Int, selectionRect: CGRect? = nil) -> String? {
        guard let document = PDFDocument(url: pdfURL),
              let page = document.page(at: pageIndex) else {
            #if DEBUG
            print("PDFTodoExtractor: Failed to load PDF or page \(pageIndex)")
            #endif
            return nil
        }

        // Try native extraction first
        let nativeText: String?
        if let rect = selectionRect {
            nativeText = page.selection(for: rect)?.string
        } else {
            nativeText = page.string
        }

        // Check if native extraction yielded good results
        if let text = nativeText, text.count >= minNativeTextLength {
            #if DEBUG
            print("PDFTodoExtractor: Using native PDFKit extraction (\(text.count) chars)")
            #endif
            return text
        }

        // Native extraction failed or returned minimal text - try Vision OCR
        #if DEBUG
        print("PDFTodoExtractor: Native extraction insufficient, trying Vision OCR")
        #endif

        return extractTextWithVisionOCR(from: page, selectionRect: selectionRect)
    }

    /// Extract text using spatial analysis (bounding boxes) for better line reconstruction
    func extractTextWithSpatialAnalysis(from pdfURL: URL, pageIndex: Int, selectionRect: CGRect? = nil) -> [ReconstructedLine] {
        guard let document = PDFDocument(url: pdfURL),
              let page = document.page(at: pageIndex) else {
            return []
        }

        let pageBounds = page.bounds(for: .mediaBox)
        let targetRect = selectionRect ?? pageBounds

        // Get all text selections in the target area
        guard let pageContent = page.string, !pageContent.isEmpty else {
            // No native text - fall back to OCR and return simple lines
            if let ocrText = extractTextWithVisionOCR(from: page, selectionRect: selectionRect) {
                return ocrText.components(separatedBy: .newlines)
                    .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                    .enumerated()
                    .map { ReconstructedLine(text: $0.element, indentLevel: 0, isBold: false, fontSize: 12, yPosition: CGFloat($0.offset)) }
            }
            return []
        }

        // Extract fragments with spatial data
        var fragments: [TextFragment] = []

        // Get selection for the entire area to analyze
        if let selection = page.selection(for: targetRect) {
            // Get selections per line for spatial analysis
            let selectionsByLine = selection.selectionsByLine()
            if !selectionsByLine.isEmpty {
                for lineSelection in selectionsByLine {
                    if let text = lineSelection.string?.trimmingCharacters(in: .whitespaces),
                       !text.isEmpty {
                        let bounds = lineSelection.bounds(for: page)

                        // Check for bold/font attributes if available
                        var isBold = false
                        var fontSize: CGFloat = 12

                        // Try to get font attributes from the first character
                        if let attributedString = lineSelection.attributedString {
                            if let font = attributedString.attribute(.font, at: 0, effectiveRange: nil) as? UIFont {
                                isBold = font.fontDescriptor.symbolicTraits.contains(.traitBold)
                                fontSize = font.pointSize
                            }
                        }

                        fragments.append(TextFragment(
                            text: text,
                            bounds: bounds,
                            indentLevel: 0, // Will be calculated after we know baseIndentX
                            isBold: isBold,
                            fontSize: fontSize
                        ))
                    }
                }
            }
        }

        guard !fragments.isEmpty else { return [] }

        // Calculate base indentation (minimum X position)
        baseIndentX = fragments.map { $0.xPosition }.min() ?? 0

        // Recalculate indent levels based on X position
        let fragmentsWithIndent = fragments.map { fragment -> TextFragment in
            let indentLevel = max(0, Int((fragment.xPosition - baseIndentX) / indentStepSize))
            return TextFragment(
                text: fragment.text,
                bounds: fragment.bounds,
                indentLevel: indentLevel,
                isBold: fragment.isBold,
                fontSize: fragment.fontSize
            )
        }

        // Sort by Y position (top to bottom in reading order - PDF Y is bottom-up)
        let sortedFragments = fragmentsWithIndent.sorted { $0.yPosition > $1.yPosition }

        // Group fragments into lines based on Y-coordinate proximity
        var lines: [ReconstructedLine] = []
        var currentLineFragments: [TextFragment] = []
        var currentLineY: CGFloat = sortedFragments.first?.yPosition ?? 0

        for fragment in sortedFragments {
            if abs(fragment.yPosition - currentLineY) <= lineGroupingTolerance {
                // Same line - add to current group
                currentLineFragments.append(fragment)
            } else {
                // New line - finalize current line and start new one
                if !currentLineFragments.isEmpty {
                    lines.append(reconstructLine(from: currentLineFragments))
                }
                currentLineFragments = [fragment]
                currentLineY = fragment.yPosition
            }
        }

        // Don't forget the last line
        if !currentLineFragments.isEmpty {
            lines.append(reconstructLine(from: currentLineFragments))
        }

        #if DEBUG
        print("PDFTodoExtractor: Spatial analysis found \(lines.count) lines")
        for (i, line) in lines.prefix(10).enumerated() {
            print("  [\(i)] indent=\(line.indentLevel) bold=\(line.isBold): \(line.text.prefix(50))")
        }
        #endif

        return lines
    }

    /// Reconstruct a single line from multiple fragments
    private func reconstructLine(from fragments: [TextFragment]) -> ReconstructedLine {
        // Sort fragments by X position (left to right)
        let sorted = fragments.sorted { $0.xPosition < $1.xPosition }

        // Combine text
        let text = sorted.map { $0.text }.joined(separator: " ")

        // Use the leftmost fragment's properties for the line
        let firstFragment = sorted.first!

        return ReconstructedLine(
            text: text,
            indentLevel: firstFragment.indentLevel,
            isBold: firstFragment.isBold,
            fontSize: firstFragment.fontSize,
            yPosition: firstFragment.yPosition
        )
    }

    // MARK: - Vision OCR Fallback

    /// Extract text using Vision Framework OCR
    /// Used when native PDFKit extraction fails (scanned documents, image-based PDFs)
    private func extractTextWithVisionOCR(from page: PDFPage, selectionRect: CGRect?) -> String? {
        // Render PDF page to image for OCR
        guard let pageImage = renderPageToImage(page: page, selectionRect: selectionRect) else {
            #if DEBUG
            print("PDFTodoExtractor: Failed to render page to image for OCR")
            #endif
            return nil
        }

        guard let cgImage = pageImage.cgImage else {
            return nil
        }

        // Create Vision request
        var recognizedText = ""
        let semaphore = DispatchSemaphore(value: 0)

        let request = VNRecognizeTextRequest { request, error in
            defer { semaphore.signal() }

            if let error = error {
                #if DEBUG
                print("PDFTodoExtractor: Vision OCR error: \(error)")
                #endif
                return
            }

            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                return
            }

            // Sort observations by Y position (top to bottom)
            let sortedObservations = observations.sorted { $0.boundingBox.origin.y > $1.boundingBox.origin.y }

            // Extract text maintaining line structure
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
            _ = semaphore.wait(timeout: .now() + 10)
        } catch {
            #if DEBUG
            print("PDFTodoExtractor: Vision request failed: \(error)")
            #endif
            return nil
        }

        #if DEBUG
        print("PDFTodoExtractor: Vision OCR extracted \(recognizedText.count) chars")
        #endif

        return recognizedText.isEmpty ? nil : recognizedText
    }

    /// Render a PDF page (or selection) to a UIImage for OCR
    private func renderPageToImage(page: PDFPage, selectionRect: CGRect?) -> UIImage? {
        let pageBounds = page.bounds(for: .mediaBox)
        let targetRect = selectionRect ?? pageBounds

        // Scale for good OCR quality (2x should be sufficient)
        let scale: CGFloat = 2.0
        let renderSize = CGSize(
            width: targetRect.width * scale,
            height: targetRect.height * scale
        )

        let renderer = UIGraphicsImageRenderer(size: renderSize)
        return renderer.image { context in
            // White background
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: renderSize))

            // Set up transform for PDF rendering
            context.cgContext.translateBy(x: 0, y: renderSize.height)
            context.cgContext.scaleBy(x: scale, y: -scale)

            // Offset if we're rendering a selection
            if selectionRect != nil {
                context.cgContext.translateBy(x: -targetRect.origin.x, y: -targetRect.origin.y)
            }

            // Draw PDF page
            page.draw(with: .mediaBox, to: context.cgContext)
        }
    }

    /// Extract text from entire PDF
    func extractAllText(from pdfURL: URL) -> String? {
        guard let document = PDFDocument(url: pdfURL) else {
            return nil
        }

        var fullText = ""
        for i in 0..<document.pageCount {
            if let page = document.page(at: i),
               let text = page.string {
                fullText += text + "\n"
            }
        }

        return fullText.isEmpty ? nil : fullText
    }

    // MARK: - Smart Todo Detection

    /// Parse extracted text into individual todo items using smart detection
    /// If no structured todos are found, falls back to treating each line as a potential task
    func parseTodos(from text: String) -> [String] {
        #if DEBUG
        print("PDFTodoExtractor: Raw text length: \(text.count)")
        print("PDFTodoExtractor: Raw text preview: \(String(text.prefix(200)))")
        #endif

        // First, normalize the text and split into logical segments
        let segments = splitIntoLogicalSegments(text)

        #if DEBUG
        print("PDFTodoExtractor: Found \(segments.count) segments")
        #endif

        var todos: [String] = []
        var structuredTodosFound = false

        // First pass: try to extract structured todos
        for segment in segments {
            let trimmed = segment.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            // Try to extract todo from the segment
            if let todoText = extractTodoText(from: trimmed) {
                let cleaned = cleanTodoText(todoText)
                if !cleaned.isEmpty && cleaned.count >= 2 {
                    todos.append(cleaned)
                    structuredTodosFound = true
                }
            }
        }

        // Fallback: if no structured todos found, treat each meaningful segment as a task
        if !structuredTodosFound {
            #if DEBUG
            print("PDFTodoExtractor: No structured todos found, using fallback extraction")
            #endif

            for segment in segments {
                let trimmed = segment.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { continue }

                // Clean and validate the segment
                let cleaned = cleanTodoText(trimmed)
                if isValidTaskText(cleaned) {
                    todos.append(cleaned)
                }
            }
        }

        // Remove duplicates while preserving order
        var seen = Set<String>()
        let uniqueTodos = todos.filter { seen.insert($0.lowercased()).inserted }

        #if DEBUG
        print("PDFTodoExtractor: Final todo count: \(uniqueTodos.count)")
        #endif

        return uniqueTodos
    }

    /// Check if text is valid as a task (not too short, not a header, etc.)
    private func isValidTaskText(_ text: String) -> Bool {
        // Must be at least 3 characters
        guard text.count >= 3 else { return false }

        // Must not be longer than 500 characters (allow longer tasks from PDFs)
        guard text.count <= 500 else { return false }

        // Skip if it's just a number or very short
        if text.allSatisfy({ $0.isNumber || $0.isWhitespace || $0 == "." }) {
            return false
        }

        // Skip common non-task patterns (document structure)
        let lowercased = text.lowercased()
        let skipPrefixes = ["page ", "chapter ", "figure ", "table ", "http", "www.", "copyright", "all rights"]
        for prefix in skipPrefixes {
            if lowercased.hasPrefix(prefix) {
                return false
            }
        }

        // Skip meta description text (often at beginning of documents)
        let skipContains = ["job description", "this week rebuilds", "emphasizes reviewing"]
        for skip in skipContains {
            if lowercased.contains(skip) {
                return false
            }
        }

        // Accept action-oriented content
        if looksLikeActionItem(text) {
            return true
        }

        // Accept schedule/time patterns (e.g., "Morning Block (2 hrs):")
        if text.contains("(") && text.contains(")") && text.contains(" ") {
            return true
        }

        // Accept lines with colons that have content after (like "Watch: video")
        if text.contains(": ") || text.contains(": \"") || text.contains(": '") {
            return true
        }

        // Accept DAY/Week/WEEK patterns (study plans often use these)
        if lowercased.hasPrefix("day ") || lowercased.hasPrefix("week ") ||
           lowercased.hasPrefix("session ") || lowercased.hasPrefix("foundations") {
            return true
        }

        // Accept multi-word capitalized content (minimum 8 chars for better matching)
        if let first = text.first, first.isUppercase && text.contains(" ") && text.count >= 8 {
            return true
        }

        // Accept time block patterns
        if lowercased.contains("morning") || lowercased.contains("afternoon") ||
           lowercased.contains("evening") || lowercased.contains("block") ||
           lowercased.contains("hrs") || lowercased.contains("hour") || lowercased.contains("min") {
            return true
        }

        // Accept accountability/task patterns
        if lowercased.contains("accountability") || lowercased.contains("screenshot") ||
           lowercased.contains("save to") || lowercased.contains("drawing symbols") {
            return true
        }

        // Accept learning platform content
        if lowercased.contains("youtube") || lowercased.contains("linkedin learning") ||
           lowercased.contains("coursera") || lowercased.contains("udemy") ||
           lowercased.contains("free on") || lowercased.contains("free with") {
            return true
        }

        return false
    }

    /// Split text into logical segments based on various separators
    private func splitIntoLogicalSegments(_ text: String) -> [String] {
        var segments: [String] = []

        // Pre-process: Some PDFs concatenate lines without proper separators
        // Try to detect and split on common patterns
        var processedText = text

        // Split before bullet points that are concatenated (e.g., "...text• Watch" -> "...text\n• Watch")
        // Unicode bullet: \u{2022}
        processedText = processedText.replacingOccurrences(
            of: "([a-z.):\"'\\)])(\u{2022}|•)",
            with: "$1\n$2",
            options: .regularExpression
        )

        // Split before checkbox squares (□ = \u{25A1}, ☐ = \u{2610})
        processedText = processedText.replacingOccurrences(
            of: "([a-z.):\"'\\)])([\u{25A1}\u{2610}])",
            with: "$1\n$2",
            options: .regularExpression
        )

        // Split on "Watch:" patterns that are concatenated (e.g., "...textWatch: " -> "...text\nWatch: ")
        processedText = processedText.replacingOccurrences(
            of: "([a-z.)])Watch:",
            with: "$1\nWatch:",
            options: .regularExpression
        )

        // Split on "Read:" patterns
        processedText = processedText.replacingOccurrences(
            of: "([a-z.)])Read:",
            with: "$1\nRead:",
            options: .regularExpression
        )

        // Split on DAY/WEEK patterns (uppercase headers)
        processedText = processedText.replacingOccurrences(
            of: "([a-z.):\"'\\)])DAY ",
            with: "$1\nDAY ",
            options: .regularExpression
        )
        processedText = processedText.replacingOccurrences(
            of: "([a-z.):\"'\\)])WEEK ",
            with: "$1\nWEEK ",
            options: .regularExpression
        )

        // Split on Morning/Afternoon/Evening Block patterns
        processedText = processedText.replacingOccurrences(
            of: "([a-z.):\"'\\)])Morning ",
            with: "$1\nMorning ",
            options: .regularExpression
        )
        processedText = processedText.replacingOccurrences(
            of: "([a-z.):\"'\\)])Afternoon ",
            with: "$1\nAfternoon ",
            options: .regularExpression
        )
        processedText = processedText.replacingOccurrences(
            of: "([a-z.):\"'\\)])Evening ",
            with: "$1\nEvening ",
            options: .regularExpression
        )

        // Split on Accountability Task patterns
        processedText = processedText.replacingOccurrences(
            of: "([a-z.):\"'\\)])Accountability ",
            with: "$1\nAccountability ",
            options: .regularExpression
        )

        // Split on Theme: patterns
        processedText = processedText.replacingOccurrences(
            of: "([a-z.)])Theme:",
            with: "$1\nTheme:",
            options: .regularExpression
        )

        // Split on time block patterns like "(2 hrs):" followed immediately by content
        processedText = processedText.replacingOccurrences(
            of: "(\\([\\d.]+\\s*hrs?\\):)([A-Z•\u{2022}])",
            with: "$1\n$2",
            options: .regularExpression
        )

        // Split on arrow patterns (→) commonly used in PDFs
        processedText = processedText.replacingOccurrences(
            of: "(\u{2192})",
            with: " $1 ",
            options: .regularExpression
        )

        // Pre-join lines that are clearly continuations (end with incomplete word/sentence)
        // This handles PDF text that wraps mid-sentence
        // IMPORTANT: Do NOT join if the next line is a new task item (bullet, action verb, header)
        var preJoinedLines: [String] = []
        let rawLines = processedText.components(separatedBy: CharacterSet.newlines)

        for (index, line) in rawLines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else {
                preJoinedLines.append("")
                continue
            }

            // Check if next line looks like a continuation
            if index < rawLines.count - 1 {
                let nextLine = rawLines[index + 1].trimmingCharacters(in: .whitespaces)

                // NEVER join if next line is clearly a new item
                let nextIsNewItem = isNewTaskItem(nextLine)

                // If current line ends without sentence-ending punctuation
                // and next line starts with lowercase, it's likely a continuation
                // BUT if current line ends with ":" followed by optional time like "(2 hrs):", it's a header
                let endsWithTimeBlock = trimmed.range(of: "\\(\\d+(\\.\\d+)?\\s*(hrs?|hours?|min)\\):?$",
                                                       options: .regularExpression) != nil
                let endsIncomplete = !trimmed.hasSuffix(".") &&
                                     !trimmed.hasSuffix(":") &&
                                     !trimmed.hasSuffix("!") &&
                                     !trimmed.hasSuffix("?") &&
                                     !trimmed.hasSuffix(")") &&
                                     !endsWithTimeBlock &&
                                     !trimmed.isEmpty

                let nextStartsLower = nextLine.first?.isLowercase == true

                // Also check if line ends with a word that's clearly incomplete
                // (ends with common prefixes/mid-word patterns)
                let endsWithIncompleteWord = trimmed.hasSuffix(" your") ||
                                             trimmed.hasSuffix(" the") ||
                                             trimmed.hasSuffix(" and") ||
                                             trimmed.hasSuffix(" or") ||
                                             trimmed.hasSuffix(" for") ||
                                             trimmed.hasSuffix(" to") ||
                                             trimmed.hasSuffix(" from") ||
                                             trimmed.hasSuffix(" with") ||
                                             trimmed.hasSuffix(" of") ||
                                             trimmed.hasSuffix(" in") ||
                                             trimmed.hasSuffix(" on") ||
                                             trimmed.hasSuffix(" a") ||
                                             trimmed.hasSuffix(" an")

                // Only join if: ends incomplete AND next starts lowercase AND next is NOT a new item
                if ((endsIncomplete && nextStartsLower) || endsWithIncompleteWord) && !nextIsNewItem {
                    // Join with next line
                    if !preJoinedLines.isEmpty && !preJoinedLines.last!.isEmpty {
                        preJoinedLines[preJoinedLines.count - 1] += " " + trimmed
                    } else {
                        preJoinedLines.append(trimmed)
                    }
                    continue
                }
            }

            // Check if this should be appended to previous line
            // But NEVER append if this line is a new task item
            let thisIsNewItem = isNewTaskItem(trimmed)
            if trimmed.first?.isLowercase == true && !preJoinedLines.isEmpty && !thisIsNewItem {
                let lastLine = preJoinedLines.last ?? ""
                if !lastLine.isEmpty &&
                   !lastLine.hasSuffix(".") &&
                   !lastLine.hasSuffix(":") &&
                   !lastLine.hasSuffix("!") &&
                   !lastLine.hasSuffix("?") {
                    preJoinedLines[preJoinedLines.count - 1] += " " + trimmed
                    continue
                }
            }

            preJoinedLines.append(trimmed)
        }

        // First pass: split by newlines (using pre-joined lines)
        let lines = preJoinedLines

        var currentSegment = ""
        var previousLineWasEmpty = false
        var previousIndentLevel = 0

        for (index, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            let currentIndentLevel = countLeadingSpaces(line)

            // Check if this is an empty line
            if trimmedLine.isEmpty {
                // Empty line often indicates segment break
                if !currentSegment.isEmpty {
                    segments.append(currentSegment)
                    currentSegment = ""
                }
                previousLineWasEmpty = true
                continue
            }

            // Check if this line starts a new list item
            let startsNewItem = startsWithListMarker(trimmedLine)

            // Check if this line starts with a keyword that should be its own segment
            let startsWithKeyword = startsWithTaskKeyword(trimmedLine)

            // Check for significant indentation change
            let significantIndentChange = abs(currentIndentLevel - previousIndentLevel) >= 2 && !startsNewItem

            // Check if this looks like a continuation of previous line
            // (starts with lowercase, doesn't start with bullet/keyword, previous line didn't end with period)
            let looksLikeContinuation = !startsNewItem &&
                                        !startsWithKeyword &&
                                        !previousLineWasEmpty &&
                                        !currentSegment.isEmpty &&
                                        (trimmedLine.first?.isLowercase == true ||
                                         (trimmedLine.first?.isUppercase == true && !currentSegment.hasSuffix(".")))

            // Decide whether to start a new segment
            let shouldStartNewSegment = (startsNewItem ||
                                         startsWithKeyword ||
                                         previousLineWasEmpty ||
                                         (significantIndentChange && index > 0)) && !looksLikeContinuation

            if shouldStartNewSegment && !currentSegment.isEmpty {
                segments.append(currentSegment)
                currentSegment = trimmedLine
            } else if currentSegment.isEmpty {
                currentSegment = trimmedLine
            } else {
                // Continuation of current segment - append with space
                // But only if it doesn't look like a separate item
                if !startsNewItem && !startsWithKeyword || looksLikeContinuation {
                    currentSegment += " " + trimmedLine
                } else {
                    segments.append(currentSegment)
                    currentSegment = trimmedLine
                }
            }

            previousLineWasEmpty = false
            previousIndentLevel = currentIndentLevel
        }

        // Don't forget the last segment
        if !currentSegment.isEmpty {
            segments.append(currentSegment)
        }

        // Second pass: split by common delimiters within segments
        var refinedSegments: [String] = []
        for segment in segments {
            // Check if segment contains multiple items separated by semicolons or pipes
            if segment.contains(";") && !segment.contains("http") {
                let subItems = segment.components(separatedBy: ";")
                for item in subItems {
                    let trimmed = item.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty {
                        refinedSegments.append(trimmed)
                    }
                }
            } else if segment.contains(" | ") {
                let subItems = segment.components(separatedBy: " | ")
                for item in subItems {
                    let trimmed = item.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty {
                        refinedSegments.append(trimmed)
                    }
                }
            } else {
                refinedSegments.append(segment)
            }
        }

        #if DEBUG
        print("PDFTodoExtractor: Refined segments:")
        for (i, seg) in refinedSegments.enumerated() {
            print("  [\(i)]: \(seg.prefix(80))")
        }
        #endif

        return refinedSegments
    }

    /// Check if line starts with a keyword that indicates a new task/section
    private func startsWithTaskKeyword(_ line: String) -> Bool {
        let lowercased = line.lowercased()

        // Study plan action keywords
        let actionKeywords = [
            "watch:", "watch ", "listen:", "read:", "read ", "complete:", "finish:", "review:",
            "download ", "practice ", "memorize ", "focus ", "write ", "take ",
            "linkedin learning:", "screenshot ", "list ", "research "
        ]

        for keyword in actionKeywords {
            if lowercased.hasPrefix(keyword) {
                return true
            }
        }

        // Section header keywords
        let sectionKeywords = [
            "day ", "week ", "session ", "part ",
            "morning ", "afternoon ", "evening ", "night ",
            "task:", "todo:", "action:", "step ",
            "accountability ", "theme:", "foundations"
        ]

        for keyword in sectionKeywords {
            if lowercased.hasPrefix(keyword) {
                return true
            }
        }

        // Time block patterns like "Morning Block", "Afternoon Block"
        if lowercased.contains("block") && (lowercased.hasPrefix("morning") ||
           lowercased.hasPrefix("afternoon") || lowercased.hasPrefix("evening")) {
            return true
        }

        // Check for bullet point starts
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("•") || trimmed.hasPrefix("□") || trimmed.hasPrefix("☐") ||
           trimmed.hasPrefix("-") || trimmed.hasPrefix("*") {
            return true
        }

        return false
    }

    /// Count leading spaces/tabs in a line
    private func countLeadingSpaces(_ line: String) -> Int {
        var count = 0
        for char in line {
            if char == " " {
                count += 1
            } else if char == "\t" {
                count += 4 // Count tab as 4 spaces
            } else {
                break
            }
        }
        return count
    }

    /// Check if line starts with a list marker
    private func startsWithListMarker(_ line: String) -> Bool {
        let patterns = [
            "^\\s*[-*\u{2022}\u{25E6}\u{25AA}\u{25B8}\u{25BA}\u{2192}]\\s*",  // Bullet points (• - * etc)
            "^\\s*\\d+[.)]\\s+",                                               // Numbered: 1. or 1)
            "^\\s*[a-zA-Z][.)]\\s+",                                           // Lettered: a. or a)
            "^\\s*\\[.?\\]\\s*",                                               // Checkbox: [ ] or [x]
            "^\\s*[\u{2610}\u{2611}\u{2612}\u{2713}\u{2714}\u{2717}\u{2718}\u{25CB}\u{25CF}\u{25EF}\u{25A1}\u{25A0}]\\s*", // Unicode checkboxes/bullets (☐ ☑ ☒ ✓ ✔ ✗ ✘ ○ ● ◯ □ ■)
            "^\\s*(TODO|TASK|ACTION|NOTE)[:.]?\\s*",                           // Keywords
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                let range = NSRange(line.startIndex..<line.endIndex, in: line)
                if regex.firstMatch(in: line, options: [], range: range) != nil {
                    return true
                }
            }
        }

        // Also check for simple bullet at start (some PDFs use just the bullet without space)
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("•") || trimmed.hasPrefix("□") || trimmed.hasPrefix("☐") {
            return true
        }

        return false
    }

    /// Check if a line is clearly a new task item (should NOT be joined with previous line)
    /// This prevents headers from being merged with their subtasks
    private func isNewTaskItem(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }

        // Bullet points are always new items
        if trimmed.hasPrefix("•") || trimmed.hasPrefix("□") || trimmed.hasPrefix("☐") ||
           trimmed.hasPrefix("-") || trimmed.hasPrefix("*") || trimmed.hasPrefix(">") {
            return true
        }

        // Unicode bullets/checkboxes
        let unicodePrefixes = [
            "\u{2610}", "\u{2611}", "\u{2612}", "\u{2713}", "\u{2714}", "\u{2717}", "\u{2718}",
            "\u{25CB}", "\u{25CF}", "\u{25EF}", "\u{25C9}", "\u{25AA}", "\u{25B8}", "\u{25BA}", "\u{2192}",
            "\u{25A1}", "\u{25A0}", "◦", "‣", "⁃"
        ]
        for prefix in unicodePrefixes {
            if trimmed.hasPrefix(prefix) {
                return true
            }
        }

        // Action verbs with colon are new items (Watch:, Read:, Listen:, etc.)
        let actionVerbPatterns = [
            "^Watch:", "^Read:", "^Listen:", "^Complete:", "^Finish:", "^Review:",
            "^Download:", "^Practice:", "^Take:", "^Write:", "^Focus:",
            "^LinkedIn Learning:", "^Screenshot:", "^Memorize:", "^Research:"
        ]
        for pattern in actionVerbPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                let range = NSRange(trimmed.startIndex..<trimmed.endIndex, in: trimmed)
                if regex.firstMatch(in: trimmed, options: [], range: range) != nil {
                    return true
                }
            }
        }

        // Header patterns are new items (DAY 1, Week 1, Morning Block, etc.)
        let headerPatterns = [
            "^DAY\\s+\\d+", "^Week\\s+\\d+", "^Session\\s+\\d+", "^Part\\s+\\d+",
            "^Morning\\s+(Block|Session)", "^Afternoon\\s+(Block|Session)",
            "^Evening\\s+(Block|Session)", "^Night\\s+(Block|Session)",
            "^Theme:", "^Accountability"
        ]
        for pattern in headerPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                let range = NSRange(trimmed.startIndex..<trimmed.endIndex, in: trimmed)
                if regex.firstMatch(in: trimmed, options: [], range: range) != nil {
                    return true
                }
            }
        }

        // Numbered lists are new items
        if let regex = try? NSRegularExpression(pattern: "^\\d+[.)]\\s+", options: []) {
            let range = NSRange(trimmed.startIndex..<trimmed.endIndex, in: trimmed)
            if regex.firstMatch(in: trimmed, options: [], range: range) != nil {
                return true
            }
        }

        // Checkbox patterns are new items
        if let regex = try? NSRegularExpression(pattern: "^\\[.?\\]\\s*", options: []) {
            let range = NSRange(trimmed.startIndex..<trimmed.endIndex, in: trimmed)
            if regex.firstMatch(in: trimmed, options: [], range: range) != nil {
                return true
            }
        }

        return false
    }

    /// Extract todo text from a line, returning nil if not a todo
    private func extractTodoText(from line: String) -> String? {
        // Pattern 1: Checkbox patterns
        let checkboxPatterns = [
            "^\\s*\\[\\s*\\]\\s*(.+)$",                      // [ ] Task
            "^\\s*\\[[xX\u{2713}\u{2714}]\\]\\s*(.+)$",      // [x] or [X] or [✓] Task
            "^\\s*\\[\\]\\s*(.+)$"                           // [] Task
        ]

        for pattern in checkboxPatterns {
            if let match = matchPattern(pattern, in: line) {
                return match
            }
        }

        // Pattern 2: Unicode checkboxes and bullets
        let unicodePrefixes = [
            "\u{2610}", "\u{2611}", "\u{2612}", "\u{2713}", "\u{2714}", "\u{2717}", "\u{2718}",
            "\u{25CB}", "\u{25CF}", "\u{25EF}", "\u{25C9}", "\u{25AA}", "\u{25B8}", "\u{25BA}", "\u{2192}",
            "\u{25A1}", "\u{25A0}", // □ ■ (checkbox squares)
            "•", "◦", "‣", "⁃"     // Common bullets
        ]
        for prefix in unicodePrefixes {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            if trimmedLine.hasPrefix(prefix) {
                return String(trimmedLine.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
            }
        }

        // Pattern 3: Bullet points (various styles) - with optional space after bullet
        let bulletPatterns = [
            "^\\s*[-*\u{2022}\u{25E6}]\\s*(.+)$",           // - * • ◦ Task (space optional)
            "^\\s*[>]\\s+(.+)$",                             // > Task
            "^\\s*[\u{25A1}\u{2610}]\\s*(.+)$"              // □ ☐ Task (checkbox squares)
        ]

        for pattern in bulletPatterns {
            if let match = matchPattern(pattern, in: line) {
                return match
            }
        }

        // Pattern 4: Numbered lists (various formats)
        let numberedPatterns = [
            "^\\s*\\d+\\.\\s+(.+)$",                         // 1. Task
            "^\\s*\\d+\\)\\s+(.+)$",                         // 1) Task
            "^\\s*\\d+[-\u{2013}]\\s+(.+)$",                 // 1- Task or 1– Task
            "^\\s*[a-zA-Z]\\.\\s+(.+)$",                     // a. Task
            "^\\s*[a-zA-Z]\\)\\s+(.+)$",                     // a) Task
            "^\\s*[ivxIVX]+\\.\\s+(.+)$",                    // i. ii. iii. (Roman numerals)
            "^\\s*[ivxIVX]+\\)\\s+(.+)$"                     // i) ii) iii)
        ]

        for pattern in numberedPatterns {
            if let match = matchPattern(pattern, in: line) {
                return match
            }
        }

        // Pattern 5: Keywords at start
        let keywordPatterns = [
            "^\\s*(TODO|TASK|ACTION|REMINDER|NOTE|IMPORTANT|PRIORITY)[:.]?\\s+(.+)$"
        ]

        for pattern in keywordPatterns {
            if let match = matchPattern(pattern, in: line, captureGroup: 2) {
                return match
            }
        }

        // Pattern 6: Markdown-style task lists
        let markdownPatterns = [
            "^\\s*-\\s*\\[\\s*\\]\\s*(.+)$",                 // - [ ] Task
            "^\\s*-\\s*\\[[xX]\\]\\s*(.+)$",                 // - [x] Task
            "^\\s*\\*\\s*\\[\\s*\\]\\s*(.+)$",               // * [ ] Task
            "^\\s*\\*\\s*\\[[xX]\\]\\s*(.+)$"                // * [x] Task
        ]

        for pattern in markdownPatterns {
            if let match = matchPattern(pattern, in: line) {
                return match
            }
        }

        // Pattern 7: Lines that look like actionable items
        if looksLikeActionItem(line) {
            return line
        }

        // Pattern 8: Short standalone lines that could be tasks
        if looksLikeShortTask(line) {
            return line
        }

        return nil
    }

    /// Check if a line looks like an action item
    private func looksLikeActionItem(_ line: String) -> Bool {
        guard line.count >= 5 && line.count <= 500 else { return false }

        // Common action verbs
        let actionVerbs = [
            "complete", "finish", "review", "update", "create", "write",
            "send", "call", "email", "schedule", "prepare", "submit",
            "check", "fix", "add", "remove", "delete", "edit", "read",
            "buy", "get", "find", "make", "do", "set up", "follow up",
            "respond", "reply", "confirm", "cancel", "book", "order",
            "plan", "organize", "clean", "study", "practice", "learn",
            "research", "draft", "meet", "discuss", "implement", "test",
            "deploy", "launch", "setup", "configure", "install", "download",
            "upload", "share", "print", "scan", "file", "sort", "archive",
            "backup", "sync", "verify", "validate", "approve", "reject",
            "assign", "delegate", "notify", "remind", "track", "monitor",
            // Learning/media consumption verbs
            "watch", "listen", "attend", "take", "complete", "work on",
            "work through", "go through", "start", "begin", "continue",
            "exercise", "workout", "run", "walk", "meditate", "reflect",
            // Study plan specific verbs
            "memorize", "focus", "screenshot", "list", "identify",
            "linkedin learning", "youtube", "coursera", "udemy"
        ]

        let lowercased = line.lowercased()
        for verb in actionVerbs {
            if lowercased.hasPrefix(verb + " ") ||
               lowercased.hasPrefix(verb + ":") ||
               lowercased.hasPrefix(verb + " -") ||
               lowercased.hasPrefix(verb + ": \"") ||   // Watch: "video title"
               lowercased.hasPrefix(verb + ": '") {     // Watch: 'video title'
                return true
            }
        }

        // Check for content that contains action indicators mid-sentence
        // Like "Take handwritten notes" or "Focus heavily on..."
        let containsActionIndicators = [
            "handwritten notes", "take notes", "write down", "look up",
            "save to", "free on", "free with"
        ]

        for indicator in containsActionIndicators {
            if lowercased.contains(indicator) {
                return true
            }
        }

        return false
    }

    /// Check if a line looks like a short task item
    private func looksLikeShortTask(_ line: String) -> Bool {
        let length = line.count

        // Too short or too long
        guard length >= 3 && length <= 100 else { return false }

        // Skip if it's ONLY uppercase with no meaningful content (like "ABC")
        // But allow mixed case headers like "DAY 1: Task Name"
        if line == line.uppercased() && line.count < 10 && !line.contains(":") && !line.contains(" ") {
            return false
        }

        // Skip single words ending with colon (headers like "Notes:")
        // But allow multi-word items with colons like "Morning Block (2 hrs):"
        if line.hasSuffix(":") {
            let withoutColon = String(line.dropLast())
            // Allow if it has spaces (multi-word) or contains action indicators
            if !withoutColon.contains(" ") && !withoutColon.contains("(") {
                return false
            }
        }

        // Skip if it looks like a sentence fragment (starts lowercase, no verb-like pattern)
        if let first = line.first, first.isLowercase && !looksLikeActionItem(line) {
            return false
        }

        // Skip common non-task patterns
        let skipPatterns = [
            "^(page|chapter|section|part|figure|table)\\s*\\d*$",
            "^\\d+$",                            // Just a number
            "^[A-Z][a-z]+\\s+\\d+,?\\s*\\d*$",   // Date like "January 15, 2024"
            "^(by|from|to|for|with|at|on|in)\\s",// Preposition starts
        ]

        for pattern in skipPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                let range = NSRange(line.startIndex..<line.endIndex, in: line)
                if regex.firstMatch(in: line, options: [], range: range) != nil {
                    return false
                }
            }
        }

        // Accept if it starts with capital and is reasonably short
        if let first = line.first, first.isUppercase && length <= 80 {
            // Additional check: should have at least one space (multi-word)
            if line.contains(" ") {
                return true
            }
        }

        // Accept schedule/time block patterns like "Morning Block (2 hrs):"
        if line.contains("(") && line.contains(")") && line.contains(" ") {
            return true
        }

        // Accept DAY/Week/Session patterns
        let schedulePatterns = ["^DAY\\s+\\d+", "^Week\\s+\\d+", "^Session\\s+\\d+", "^Part\\s+\\d+"]
        for pattern in schedulePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                let range = NSRange(line.startIndex..<line.endIndex, in: line)
                if regex.firstMatch(in: line, options: [], range: range) != nil {
                    return true
                }
            }
        }

        return false
    }

    /// Match a regex pattern and return the captured group
    private func matchPattern(_ pattern: String, in text: String, captureGroup: Int = 1) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }

        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        if let match = regex.firstMatch(in: text, options: [], range: range) {
            if match.numberOfRanges > captureGroup {
                if let captureRange = Range(match.range(at: captureGroup), in: text) {
                    return String(text[captureRange])
                }
            }
        }

        return nil
    }

    /// Clean up todo text
    private func cleanTodoText(_ text: String) -> String {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove leading bullet characters if present
        let bulletChars: [Character] = ["•", "◦", "‣", "⁃", "□", "☐", "-", "*"]
        if let first = cleaned.first, bulletChars.contains(first) {
            cleaned = String(cleaned.dropFirst()).trimmingCharacters(in: .whitespaces)
        }

        // Only remove trailing colons if they're standalone (not part of time blocks)
        // Keep colons for patterns like "Morning Block (2 hrs):" or "Watch:"
        if cleaned.hasSuffix(":") && !cleaned.contains("(") && !cleaned.contains(")") {
            // Check if it's a single word header like "Notes:" - remove those
            let withoutColon = String(cleaned.dropLast())
            if !withoutColon.contains(" ") {
                cleaned = withoutColon.trimmingCharacters(in: .whitespaces)
            }
        }

        // Remove leading/trailing quotes only if they match
        if (cleaned.hasPrefix("\"") && cleaned.hasSuffix("\"")) ||
           (cleaned.hasPrefix("'") && cleaned.hasSuffix("'")) {
            cleaned = String(cleaned.dropFirst().dropLast())
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

    // MARK: - Structured Study Plan Extraction

    /// Represents a hierarchical level in a study/work plan
    enum PlanLevel: Int, Comparable {
        case week = 0
        case day = 1
        case timeBlock = 2
        case task = 3

        static func < (lhs: PlanLevel, rhs: PlanLevel) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
    }

    /// Detect what level a line represents in a study plan hierarchy
    private func detectPlanLevel(_ text: String) -> PlanLevel? {
        let lowercased = text.lowercased()

        // Week level: "WEEK 1:", "Week 1: FOUNDATIONS"
        if lowercased.hasPrefix("week ") && text.contains(":") {
            return .week
        }

        // Day level: "DAY 1:", "Day 1: Topic Name"
        if lowercased.hasPrefix("day ") && (text.contains(":") || lowercased.contains("day ")) {
            return .day
        }

        // Time block level: "Morning Block", "Afternoon Block (2 hrs):"
        if (lowercased.contains("morning") || lowercased.contains("afternoon") ||
            lowercased.contains("evening") || lowercased.contains("night")) &&
           (lowercased.contains("block") || lowercased.contains("hrs") || lowercased.contains("hour")) {
            return .timeBlock
        }

        // Accountability task (special - treat as task but keep the label)
        if lowercased.hasPrefix("accountability") {
            return .task
        }

        // Task level: bullet points, action items
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("•") || trimmed.hasPrefix("□") || trimmed.hasPrefix("☐") ||
           trimmed.hasPrefix("-") || trimmed.hasPrefix("*") {
            return .task
        }

        // Action verbs indicate tasks
        if looksLikeActionItem(text) {
            return .task
        }

        return nil
    }

    /// Extract a short label from a header (e.g., "DAY 1" from "DAY 1: Construction Drawing Fundamentals")
    private func extractShortLabel(_ text: String) -> String {
        let lowercased = text.lowercased()

        // Week patterns
        if let match = matchPattern("^(WEEK\\s*\\d+)", in: text.uppercased()) {
            return match
        }

        // Day patterns
        if let match = matchPattern("^(DAY\\s*\\d+)", in: text.uppercased()) {
            return match
        }

        // Time block patterns - extract just the time part
        if lowercased.contains("morning") {
            return "Morning"
        }
        if lowercased.contains("afternoon") {
            return "Afternoon"
        }
        if lowercased.contains("evening") {
            return "Evening"
        }

        return ""
    }

    /// Parse text with study plan organization, returning tasks with context prefixes
    /// Example output: "[Day 1 · Morning] Watch: How to Read Construction Plans"
    func parseStudyPlanTodos(from text: String, includeHeaders: Bool = false) -> [String] {
        #if DEBUG
        print("PDFTodoExtractor: Parsing as study plan, text length: \(text.count)")
        #endif

        let segments = splitIntoLogicalSegments(text)

        var todos: [String] = []
        var currentWeek: String = ""
        var currentDay: String = ""
        var currentTimeBlock: String = ""

        for segment in segments {
            let trimmed = segment.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            let level = detectPlanLevel(trimmed)

            switch level {
            case .week:
                currentWeek = extractShortLabel(trimmed)
                currentDay = ""
                currentTimeBlock = ""
                if includeHeaders {
                    todos.append("📅 " + cleanTodoText(trimmed))
                }

            case .day:
                currentDay = extractShortLabel(trimmed)
                currentTimeBlock = ""
                if includeHeaders {
                    let prefix = currentWeek.isEmpty ? "" : "[\(currentWeek)] "
                    todos.append("📋 " + prefix + cleanTodoText(trimmed))
                }

            case .timeBlock:
                currentTimeBlock = extractShortLabel(trimmed)
                if includeHeaders {
                    var prefix = ""
                    if !currentDay.isEmpty {
                        prefix = "[\(currentDay)] "
                    } else if !currentWeek.isEmpty {
                        prefix = "[\(currentWeek)] "
                    }
                    todos.append("⏰ " + prefix + cleanTodoText(trimmed))
                }

            case .task:
                // Build context prefix
                var contextParts: [String] = []
                if !currentDay.isEmpty {
                    contextParts.append(currentDay)
                } else if !currentWeek.isEmpty {
                    contextParts.append(currentWeek)
                }
                if !currentTimeBlock.isEmpty {
                    contextParts.append(currentTimeBlock)
                }

                let cleaned = cleanTodoText(trimmed)
                if isValidTaskText(cleaned) {
                    if contextParts.isEmpty {
                        todos.append(cleaned)
                    } else {
                        let context = contextParts.joined(separator: " · ")
                        todos.append("[\(context)] \(cleaned)")
                    }
                }

            case .none:
                // Check if it's valid content without a clear level
                let cleaned = cleanTodoText(trimmed)
                if isValidTaskText(cleaned) {
                    // Add with current context
                    var contextParts: [String] = []
                    if !currentDay.isEmpty {
                        contextParts.append(currentDay)
                    }
                    if !currentTimeBlock.isEmpty {
                        contextParts.append(currentTimeBlock)
                    }

                    if contextParts.isEmpty {
                        todos.append(cleaned)
                    } else {
                        let context = contextParts.joined(separator: " · ")
                        todos.append("[\(context)] \(cleaned)")
                    }
                }
            }
        }

        // Remove duplicates while preserving order
        var seen = Set<String>()
        let uniqueTodos = todos.filter { seen.insert($0.lowercased()).inserted }

        #if DEBUG
        print("PDFTodoExtractor: Study plan extraction found \(uniqueTodos.count) items")
        for (i, todo) in uniqueTodos.enumerated() {
            print("  \(i + 1). \(todo)")
        }
        #endif

        return uniqueTodos
    }

    /// Detect if text appears to be a structured study/work plan
    func isStructuredPlan(_ text: String) -> Bool {
        let lowercased = text.lowercased()

        // Check for plan indicators
        let planIndicators = [
            "week 1", "week 2", "day 1", "day 2",
            "morning block", "afternoon block", "evening block",
            "foundations", "fundamentals",
            "(2 hrs)", "(1.5 hrs)", "(1 hr)",
            "accountability task"
        ]

        var matchCount = 0
        for indicator in planIndicators {
            if lowercased.contains(indicator) {
                matchCount += 1
            }
        }

        // If we find 2+ indicators, it's likely a structured plan
        return matchCount >= 2
    }

    // MARK: - Full Extraction Pipeline

    /// Extract todos from a PDF page with optional selection
    /// Automatically detects if content is a structured study plan
    func extractTodos(from pdfURL: URL, pageIndex: Int, selectionRect: CGRect? = nil) -> [String] {
        guard let text = extractText(from: pdfURL, pageIndex: pageIndex, selectionRect: selectionRect) else {
            return []
        }

        // Auto-detect if this is a structured plan
        let todos: [String]
        if isStructuredPlan(text) {
            #if DEBUG
            print("PDFTodoExtractor: Detected structured study plan, using organized extraction")
            #endif
            todos = parseStudyPlanTodos(from: text, includeHeaders: false)
        } else {
            todos = parseTodos(from: text)
        }

        #if DEBUG
        print("PDFTodoExtractor: Found \(todos.count) todos on page \(pageIndex)")
        for (i, todo) in todos.enumerated() {
            print("  \(i + 1). \(todo)")
        }
        #endif

        return todos
    }

    /// Extract todos with explicit mode selection
    func extractTodos(from pdfURL: URL, pageIndex: Int, selectionRect: CGRect? = nil, organizeAsStudyPlan: Bool) -> [String] {
        guard let text = extractText(from: pdfURL, pageIndex: pageIndex, selectionRect: selectionRect) else {
            return []
        }

        if organizeAsStudyPlan {
            return parseStudyPlanTodos(from: text, includeHeaders: false)
        } else {
            return parseTodos(from: text)
        }
    }

    // MARK: - Hierarchical Task Extraction

    /// Represents a task that may have subtasks
    struct HierarchicalTask {
        let text: String
        let isHeader: Bool
        var subtasks: [String]

        init(text: String, isHeader: Bool = false, subtasks: [String] = []) {
            self.text = text
            self.isHeader = isHeader
            self.subtasks = subtasks
        }
    }

    /// Extract hierarchical tasks with headers and subtasks
    /// Returns tasks organized as: header tasks (DAY 1, Morning Block) with their bullet point subtasks
    /// Uses spatial analysis (bounding boxes) when available for more accurate indentation detection
    func extractHierarchicalTodos(from pdfURL: URL, pageIndex: Int, selectionRect: CGRect? = nil, useSpatialAnalysis: Bool = true) -> [HierarchicalTask] {
        // Try spatial analysis first for better indentation detection
        if useSpatialAnalysis {
            let spatialLines = extractTextWithSpatialAnalysis(from: pdfURL, pageIndex: pageIndex, selectionRect: selectionRect)
            if !spatialLines.isEmpty {
                #if DEBUG
                print("PDFTodoExtractor: Using spatial analysis for hierarchical extraction (\(spatialLines.count) lines)")
                #endif
                return parseHierarchicalTodosFromSpatialLines(spatialLines)
            }
        }

        // Fall back to text-based extraction
        guard let text = extractText(from: pdfURL, pageIndex: pageIndex, selectionRect: selectionRect) else {
            return []
        }

        return parseHierarchicalTodos(from: text)
    }

    /// Parse hierarchical todos from spatially-analyzed lines
    /// Uses indentation levels from bounding box X-coordinates for accurate parent-child relationships
    private func parseHierarchicalTodosFromSpatialLines(_ lines: [ReconstructedLine]) -> [HierarchicalTask] {
        #if DEBUG
        print("PDFTodoExtractor: Parsing \(lines.count) spatial lines into hierarchical todos")
        #endif

        var results: [HierarchicalTask] = []
        var currentHeader: HierarchicalTask? = nil
        var currentHeaderIndent: Int = 0

        for line in lines {
            let trimmed = line.text.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            let level = detectPlanLevel(trimmed)
            let cleaned = cleanTodoText(trimmed)

            // Use spatial indentation as primary indicator for nesting
            let isIndented = line.indentLevel > currentHeaderIndent

            // Bold text or larger font often indicates headers
            let looksLikeHeaderByStyle = line.isBold || line.fontSize > 14

            switch level {
            case .week, .day, .timeBlock:
                // These are always headers - save previous and start new
                if let header = currentHeader {
                    results.append(header)
                }
                currentHeader = HierarchicalTask(text: cleaned, isHeader: true)
                currentHeaderIndent = line.indentLevel

            case .task:
                // Task item - check spatial indentation
                if isValidTaskText(cleaned) {
                    if currentHeader != nil && isIndented {
                        // Clearly a subtask based on spatial indentation
                        currentHeader?.subtasks.append(cleaned)
                    } else if currentHeader != nil && line.indentLevel == currentHeaderIndent {
                        // Same indentation as header - could be subtask if it's a bullet point
                        if startsWithListMarker(trimmed) {
                            currentHeader?.subtasks.append(cleaned)
                        } else {
                            // New top-level item
                            results.append(currentHeader!)
                            currentHeader = nil
                            results.append(HierarchicalTask(text: cleaned, isHeader: false))
                        }
                    } else {
                        // No header context - add as standalone task
                        if let header = currentHeader {
                            results.append(header)
                            currentHeader = nil
                        }
                        results.append(HierarchicalTask(text: cleaned, isHeader: false))
                    }
                }

            case .none:
                if isValidTaskText(cleaned) {
                    // Use style-based header detection combined with pattern matching
                    if looksLikeHeaderByStyle || looksLikeHeader(cleaned) {
                        if let header = currentHeader {
                            results.append(header)
                        }
                        currentHeader = HierarchicalTask(text: cleaned, isHeader: true)
                        currentHeaderIndent = line.indentLevel
                    } else if currentHeader != nil && (isIndented || startsWithListMarker(trimmed)) {
                        // Subtask based on indentation or bullet marker
                        currentHeader?.subtasks.append(cleaned)
                    } else if currentHeader != nil {
                        // Same level but no bullet - could be continuation or new item
                        // Check if it follows the header pattern
                        if line.indentLevel <= currentHeaderIndent && !startsWithListMarker(trimmed) {
                            results.append(currentHeader!)
                            currentHeader = nil
                            results.append(HierarchicalTask(text: cleaned, isHeader: false))
                        } else {
                            currentHeader?.subtasks.append(cleaned)
                        }
                    } else {
                        results.append(HierarchicalTask(text: cleaned, isHeader: false))
                    }
                }
            }
        }

        // Don't forget the last header
        if let header = currentHeader {
            results.append(header)
        }

        // Post-process: if a header has no subtasks and isn't really a section header, convert to regular task
        var finalResults: [HierarchicalTask] = []
        for task in results {
            if task.isHeader && task.subtasks.isEmpty && !isDefinitelyHeader(task.text) {
                // Convert to regular task
                finalResults.append(HierarchicalTask(text: task.text, isHeader: false))
            } else {
                finalResults.append(task)
            }
        }

        #if DEBUG
        print("PDFTodoExtractor: Spatial hierarchical extraction found \(finalResults.count) items")
        for (i, task) in finalResults.enumerated() {
            if task.isHeader {
                print("  \(i + 1). [HEADER] \(task.text) (\(task.subtasks.count) subtasks)")
                for (j, subtask) in task.subtasks.enumerated() {
                    print("      \(j + 1). \(subtask)")
                }
            } else {
                print("  \(i + 1). \(task.text)")
            }
        }
        #endif

        return finalResults
    }

    /// Parse text into hierarchical tasks with headers and subtasks
    func parseHierarchicalTodos(from text: String) -> [HierarchicalTask] {
        #if DEBUG
        print("PDFTodoExtractor: Parsing hierarchical todos, text length: \(text.count)")
        #endif

        let segments = splitIntoLogicalSegments(text)

        var results: [HierarchicalTask] = []
        var currentHeader: HierarchicalTask? = nil

        for segment in segments {
            let trimmed = segment.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            let level = detectPlanLevel(trimmed)
            let cleaned = cleanTodoText(trimmed)

            switch level {
            case .week:
                // Week is a top-level header - save previous and start new
                if let header = currentHeader {
                    results.append(header)
                }
                currentHeader = HierarchicalTask(text: cleaned, isHeader: true)

            case .day:
                // Day is a header - save previous and start new
                if let header = currentHeader {
                    results.append(header)
                }
                currentHeader = HierarchicalTask(text: cleaned, isHeader: true)

            case .timeBlock:
                // Time block is a header - save previous and start new
                if let header = currentHeader {
                    results.append(header)
                }
                currentHeader = HierarchicalTask(text: cleaned, isHeader: true)

            case .task:
                // Task item - add as subtask to current header, or as standalone
                if isValidTaskText(cleaned) {
                    if currentHeader != nil {
                        currentHeader?.subtasks.append(cleaned)
                    } else {
                        // No header context - add as standalone task
                        results.append(HierarchicalTask(text: cleaned, isHeader: false))
                    }
                }

            case .none:
                // Could be either a header or task depending on content
                if isValidTaskText(cleaned) {
                    // Check if it looks like a header (short, capitalized, ends with colon)
                    if looksLikeHeader(cleaned) {
                        if let header = currentHeader {
                            results.append(header)
                        }
                        currentHeader = HierarchicalTask(text: cleaned, isHeader: true)
                    } else if currentHeader != nil {
                        currentHeader?.subtasks.append(cleaned)
                    } else {
                        results.append(HierarchicalTask(text: cleaned, isHeader: false))
                    }
                }
            }
        }

        // Don't forget the last header
        if let header = currentHeader {
            results.append(header)
        }

        // Post-process: if a header has no subtasks and isn't really a section header, convert to regular task
        var finalResults: [HierarchicalTask] = []
        for task in results {
            if task.isHeader && task.subtasks.isEmpty && !isDefinitelyHeader(task.text) {
                // Convert to regular task
                finalResults.append(HierarchicalTask(text: task.text, isHeader: false))
            } else {
                finalResults.append(task)
            }
        }

        #if DEBUG
        print("PDFTodoExtractor: Hierarchical extraction found \(finalResults.count) items")
        for (i, task) in finalResults.enumerated() {
            if task.isHeader {
                print("  \(i + 1). [HEADER] \(task.text) (\(task.subtasks.count) subtasks)")
                for (j, subtask) in task.subtasks.enumerated() {
                    print("      \(j + 1). \(subtask)")
                }
            } else {
                print("  \(i + 1). \(task.text)")
            }
        }
        #endif

        return finalResults
    }

    /// Check if text looks like a section header
    private func looksLikeHeader(_ text: String) -> Bool {
        let lower = text.lowercased()

        // Definite header patterns
        if lower.hasPrefix("day ") || lower.hasPrefix("week ") ||
           lower.contains("block") || lower.contains("session") ||
           lower.hasPrefix("part ") || lower.hasPrefix("phase ") {
            return true
        }

        // Ends with colon and is relatively short
        if text.hasSuffix(":") && text.count < 60 {
            return true
        }

        // Contains time indicators
        if lower.contains("(") && (lower.contains("hr") || lower.contains("min")) {
            return true
        }

        return false
    }

    /// Check if text is definitely a section header (more strict)
    private func isDefinitelyHeader(_ text: String) -> Bool {
        // Use text directly in regex matching (lowercased variable was unused)

        // Very clear header patterns
        let definitePatterns = [
            "day \\d+", "week \\d+", "session \\d+", "part \\d+", "phase \\d+",
            "morning block", "afternoon block", "evening block", "night block",
            "morning session", "afternoon session",
            "\\(\\d+(\\.\\d+)?\\s*(hr|hour|min)"
        ]

        for pattern in definitePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                let range = NSRange(text.startIndex..<text.endIndex, in: text)
                if regex.firstMatch(in: text, options: [], range: range) != nil {
                    return true
                }
            }
        }

        return false
    }

    // MARK: - Vision OCR with Spatial Data

    /// Extract text with spatial data using Vision OCR
    /// Returns ReconstructedLines with indentation calculated from bounding boxes
    /// Useful for scanned documents where PDFKit extraction fails
    func extractSpatialLinesWithVisionOCR(from pdfURL: URL, pageIndex: Int, selectionRect: CGRect? = nil) -> [ReconstructedLine] {
        guard let document = PDFDocument(url: pdfURL),
              let page = document.page(at: pageIndex) else {
            return []
        }

        // Render PDF page to image
        guard let pageImage = renderPageToImage(page: page, selectionRect: selectionRect),
              let cgImage = pageImage.cgImage else {
            return []
        }

        var spatialLines: [ReconstructedLine] = []
        let semaphore = DispatchSemaphore(value: 0)

        let request = VNRecognizeTextRequest { request, error in
            defer { semaphore.signal() }

            if let error = error {
                #if DEBUG
                print("PDFTodoExtractor: Vision OCR spatial error: \(error)")
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

            // Convert observations to ReconstructedLines
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

            // Group by approximate Y position (normalized coordinates, ~2% tolerance)
            let yTolerance: CGFloat = 0.02
            var groupedLines: [[((y: CGFloat, x: CGFloat, text: String))]] = []
            var processedIndices = Set<Int>()

            for (i, line) in rawLines.enumerated() {
                if processedIndices.contains(i) { continue }

                var group = [line]
                processedIndices.insert(i)

                for (j, otherLine) in rawLines.enumerated() where j != i {
                    if processedIndices.contains(j) { continue }
                    if abs(otherLine.y - line.y) < yTolerance {
                        group.append(otherLine)
                        processedIndices.insert(j)
                    }
                }

                groupedLines.append(group)
            }

            // Sort groups by Y (top to bottom in reading order - Vision Y is bottom-up)
            groupedLines.sort { $0[0].y > $1[0].y }

            // Convert groups to ReconstructedLines
            for group in groupedLines {
                // Sort within group by X (left to right)
                let sortedGroup = group.sorted { $0.x < $1.x }

                // Combine text from fragments on the same line
                let text = sortedGroup.map { $0.text }.joined(separator: " ")
                let leftmostX = sortedGroup.first?.x ?? 0

                // Calculate indent level (normalized coordinates, step size ~5% of width)
                let indentStep: CGFloat = 0.05
                let indentLevel = max(0, Int((leftmostX - minX) / indentStep))

                spatialLines.append(ReconstructedLine(
                    text: text,
                    indentLevel: indentLevel,
                    isBold: false,  // Vision doesn't give font info
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
            _ = semaphore.wait(timeout: .now() + 15)  // Allow more time for spatial analysis
        } catch {
            #if DEBUG
            print("PDFTodoExtractor: Vision OCR spatial request failed: \(error)")
            #endif
            return []
        }

        #if DEBUG
        print("PDFTodoExtractor: Vision OCR extracted \(spatialLines.count) spatial lines")
        for (i, line) in spatialLines.prefix(10).enumerated() {
            print("  [\(i)] indent=\(line.indentLevel): \(line.text.prefix(50))")
        }
        #endif

        return spatialLines
    }

    /// Extract hierarchical todos using Vision OCR with spatial analysis
    /// Best for scanned documents or PDFs with poor native text extraction
    func extractHierarchicalTodosWithVisionOCR(from pdfURL: URL, pageIndex: Int, selectionRect: CGRect? = nil) -> [HierarchicalTask] {
        let spatialLines = extractSpatialLinesWithVisionOCR(from: pdfURL, pageIndex: pageIndex, selectionRect: selectionRect)

        if spatialLines.isEmpty {
            #if DEBUG
            print("PDFTodoExtractor: Vision OCR extraction failed, falling back to native")
            #endif
            return extractHierarchicalTodos(from: pdfURL, pageIndex: pageIndex, selectionRect: selectionRect, useSpatialAnalysis: false)
        }

        return parseHierarchicalTodosFromSpatialLines(spatialLines)
    }
}
