//
//  PDFImportModels.swift
//  Reverie Weaver
//
//  SwiftData models for PDF todo import feature
//

import Foundation
import SwiftData
import CoreGraphics
import SwiftUI
import UIKit

// MARK: - PDF Priority Level

/// Priority level for PDF plans
enum PDFPriority: String, Codable, CaseIterable {
    case high = "high"
    case medium = "medium"
    case low = "low"

    var displayName: String {
        switch self {
        case .high: return "High"
        case .medium: return "Medium"
        case .low: return "Low"
        }
    }

    var color: Color {
        switch self {
        case .high: return Color.red.opacity(0.85)
        case .medium: return Color.orange.opacity(0.85)
        case .low: return Color.green.opacity(0.85)
        }
    }

    var icon: String {
        switch self {
        case .high: return "flame.fill"
        case .medium: return "bolt.fill"
        case .low: return "leaf.fill"
        }
    }

    var sortOrder: Int {
        switch self {
        case .high: return 0
        case .medium: return 1
        case .low: return 2
        }
    }
}

// MARK: - PDF Category

/// Category for organizing PDFs
enum PDFCategory: String, Codable, CaseIterable {
    case study = "study"
    case work = "work"
    case personal = "personal"
    case project = "project"
    case custom = "custom"

    var displayName: String {
        switch self {
        case .study: return "Study"
        case .work: return "Work"
        case .personal: return "Personal"
        case .project: return "Project"
        case .custom: return "Custom"
        }
    }

    var icon: String {
        switch self {
        case .study: return "book.fill"
        case .work: return "briefcase.fill"
        case .personal: return "person.fill"
        case .project: return "folder.fill"
        case .custom: return "tag.fill"
        }
    }

    var color: Color {
        switch self {
        case .study: return Color.blue.opacity(0.8)
        case .work: return Color.purple.opacity(0.8)
        case .personal: return Color.pink.opacity(0.8)
        case .project: return Color.orange.opacity(0.8)
        case .custom: return Color.gray.opacity(0.8)
        }
    }
}

// MARK: - Task List Source Type

/// Source type for task lists (PDF extraction or image scan)
enum TaskListSourceType: String, Codable, CaseIterable {
    case pdf = "pdf"
    case image = "image"

    var displayName: String {
        switch self {
        case .pdf: return "PDF"
        case .image: return "Image"
        }
    }

    var icon: String {
        switch self {
        case .pdf: return "doc.fill"
        case .image: return "photo.fill"
        }
    }
}

// MARK: - Task List Status

enum TaskListStatus: String, Codable, CaseIterable {
    case backlog = "backlog"
    case active = "active"
    case archived = "archived"

    var displayName: String {
        switch self {
        case .backlog: return "Backlog"
        case .active: return "Active"
        case .archived: return "Archived"
        }
    }

    /// Localized name using LocalizationManager
    func localizedName(_ localization: LocalizationManager) -> String {
        switch self {
        case .backlog: return localization.localize("pdf.filter.backlog")
        case .active: return localization.localize("pdf.filter.active")
        case .archived: return localization.localize("pdf.filter.archived")
        }
    }

    var icon: String {
        switch self {
        case .backlog: return "tray.full"
        case .active: return "bolt.fill"
        case .archived: return "archivebox"
        }
    }
}

// MARK: - Imported PDF

/// Reference to a PDF file stored on disk
@Model
class ImportedPDF: Identifiable {
    var id: UUID
    var fileName: String
    var fileRelativePath: String      // Relative path within Documents/PDFImports/
    var importedAt: Date
    var pageCount: Int
    var thumbnailRelativePath: String? // Cached first-page thumbnail

    // MARK: - Schedule & Organization Properties
    var displayTitle: String? = nil          // User-editable display name (nil = use fileName)
    var startDate: Date? = nil               // When to start working on this PDF
    var endDate: Date? = nil                 // Deadline for completing tasks
    var priorityRawValue: String = "medium"  // Raw value for PDFPriority (default: medium)
    var categoryRawValue: String = "personal" // Raw value for PDFCategory (default: personal)
    var customCategoryName: String? = nil    // Custom category name when category == .custom
    var seriesOrder: Int? = nil              // Order within linked PDF series (1, 2, 3...)

    @Relationship(deleteRule: .cascade)
    var taskLists: [PDFTaskList]? = []

    // Self-referential relationship for linked PDFs (series)
    // Note: We use UUID reference instead of @Relationship to avoid
    // SwiftData migration issues with self-referential inverse relationships
    var linkedPDFIds: [UUID] = []        // IDs of child PDFs in series
    var parentSeriesPDFId: UUID? = nil   // ID of parent PDF if this is a child

    init(
        fileName: String,
        fileRelativePath: String,
        pageCount: Int = 0,
        priority: PDFPriority = .medium,
        category: PDFCategory = .personal
    ) {
        self.id = UUID()
        self.fileName = fileName
        self.fileRelativePath = fileRelativePath
        self.importedAt = Date()
        self.pageCount = pageCount
        self.priorityRawValue = priority.rawValue
        self.categoryRawValue = category.rawValue
        self.taskLists = []
        self.linkedPDFIds = []
    }

    // MARK: - Computed Properties for Enums

    /// Get/set priority using the enum
    var priority: PDFPriority {
        get {
            PDFPriority(rawValue: priorityRawValue) ?? .medium
        }
        set {
            priorityRawValue = newValue.rawValue
        }
    }

    /// Get/set category using the enum
    var category: PDFCategory {
        get {
            PDFCategory(rawValue: categoryRawValue) ?? .personal
        }
        set {
            categoryRawValue = newValue.rawValue
        }
    }

    /// Display title (uses fileName if displayTitle is nil or empty)
    var title: String {
        if let displayTitle = displayTitle, !displayTitle.isEmpty {
            return displayTitle
        }
        // Remove .pdf extension for cleaner display
        return fileName.replacingOccurrences(of: ".pdf", with: "", options: .caseInsensitive)
    }

    /// Category display name (uses custom name for .custom category)
    var categoryDisplayName: String {
        if category == .custom, let customName = customCategoryName, !customName.isEmpty {
            return customName
        }
        return category.displayName
    }

    // MARK: - Schedule Status Properties

    /// Check if the PDF has incomplete tasks past the end date
    var isOverdue: Bool {
        guard let endDate = endDate else { return false }
        let today = Calendar.current.startOfDay(for: Date())
        let deadline = Calendar.current.startOfDay(for: endDate)
        return today > deadline && completedTaskCount < totalTaskCount
    }

    /// Days remaining until end date (negative if overdue)
    var daysRemaining: Int? {
        guard let endDate = endDate else { return nil }
        let today = Calendar.current.startOfDay(for: Date())
        let deadline = Calendar.current.startOfDay(for: endDate)
        return Calendar.current.dateComponents([.day], from: today, to: deadline).day
    }

    /// Check if PDF is currently active (within date range)
    var isActive: Bool {
        let today = Calendar.current.startOfDay(for: Date())

        // If no start date, consider it active
        if let start = startDate {
            let startDay = Calendar.current.startOfDay(for: start)
            if today < startDay { return false }
        }

        // If no end date, consider it active (ongoing)
        if let end = endDate {
            let endDay = Calendar.current.startOfDay(for: end)
            if today > endDay { return false }
        }

        return true
    }

    /// Check if PDF has a scheduled date range
    var hasSchedule: Bool {
        startDate != nil || endDate != nil
    }

    /// Progress percentage (0.0 - 1.0)
    var progressPercentage: Double {
        guard totalTaskCount > 0 else { return 0 }
        return Double(completedTaskCount) / Double(totalTaskCount)
    }

    /// Check if all tasks are completed
    var isFullyCompleted: Bool {
        totalTaskCount > 0 && completedTaskCount == totalTaskCount
    }

    // MARK: - Series/Linked PDFs Properties

    /// Check if this PDF is part of a series
    var isPartOfSeries: Bool {
        !linkedPDFIds.isEmpty || parentSeriesPDFId != nil
    }

    /// Get the series description (e.g., "Part 2 of 4")
    /// Note: This is a simple version that doesn't require fetching other PDFs
    var seriesDescription: String? {
        guard isPartOfSeries, let order = seriesOrder else { return nil }

        // Count total in series based on linkedPDFIds
        let totalInSeries = linkedPDFIds.count + 1
        return "Part \(order) of \(totalInSeries)"
    }

    /// Get all PDFs in this series (including self)
    /// Note: This simplified version returns just self - use PDFSeriesHelper for full list
    var allSeriesPDFs: [ImportedPDF] {
        // For full series lookup, use PDFSeriesHelper.getAllSeriesPDFs(for:in:)
        return [self]
    }

    /// Deprecated: Use linkedPDFIds instead
    var linkedPDFs: [ImportedPDF]? {
        // This is a compatibility shim - returns nil
        // Use PDFSeriesHelper.getLinkedPDFs(for:in:) for actual lookup
        return nil
    }

    /// Deprecated: Use parentSeriesPDFId instead
    var parentSeriesPDF: ImportedPDF? {
        // This is a compatibility shim - returns nil
        // Use PDFSeriesHelper.getParentPDF(for:in:) for actual lookup
        return nil
    }

    // MARK: - File URL Properties

    /// Full URL to the PDF file
    var fileURL: URL? {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsURL.appendingPathComponent(fileRelativePath)
    }

    /// Full URL to the thumbnail
    var thumbnailURL: URL? {
        guard let path = thumbnailRelativePath,
              let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsURL.appendingPathComponent(path)
    }

    /// Number of task lists associated with this PDF
    var taskListCount: Int {
        taskLists?.count ?? 0
    }

    /// Total tasks across all lists
    var totalTaskCount: Int {
        taskLists?.reduce(0) { $0 + ($1.tasks?.count ?? 0) } ?? 0
    }

    /// Completed tasks across all lists
    var completedTaskCount: Int {
        taskLists?.reduce(0) { sum, list in
            sum + (list.tasks?.filter { $0.isCompleted }.count ?? 0)
        } ?? 0
    }
}

// MARK: - PDF Task List

/// A single extraction from a page/area of a PDF or image
@Model
class PDFTaskList: Identifiable {
    var id: UUID
    var name: String                  // User-defined name: "Week 1", "Sprint 3", etc.
    var pageNumber: Int               // 0-indexed page number (0 for image sources)
    var extractionRectData: Data?     // CGRect encoded (nil = full page/image)
    var createdAt: Date
    var statusRawValue: String        // Raw value for TaskListStatus
    var sourceTypeRaw: String = "pdf" // Raw value for TaskListSourceType (default to PDF for migration)
    var sourceThumbnailData: Data?    // Small thumbnail for image sources (nil for PDF)

    var parentPDF: ImportedPDF?

    @Relationship(deleteRule: .cascade)
    var tasks: [ExtractedTask]?

    init(
        name: String,
        pageNumber: Int,
        extractionRect: CGRect? = nil,
        status: TaskListStatus = .backlog,
        sourceType: TaskListSourceType = .pdf,
        thumbnailData: Data? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.pageNumber = pageNumber
        self.createdAt = Date()
        self.statusRawValue = status.rawValue
        self.sourceTypeRaw = sourceType.rawValue
        self.sourceThumbnailData = thumbnailData
        self.tasks = []

        if let rect = extractionRect {
            self.extractionRectData = try? JSONEncoder().encode(CodableRect(rect: rect))
        }
    }

    /// Get/set the status using the enum
    var status: TaskListStatus {
        get {
            TaskListStatus(rawValue: statusRawValue) ?? .backlog
        }
        set {
            statusRawValue = newValue.rawValue
        }
    }

    /// Get/set the source type using the enum
    var sourceType: TaskListSourceType {
        get {
            TaskListSourceType(rawValue: sourceTypeRaw) ?? .pdf
        }
        set {
            sourceTypeRaw = newValue.rawValue
        }
    }

    /// Check if this task list originated from an image scan
    var isImageSource: Bool {
        sourceType == .image
    }

    /// Get thumbnail image for image-sourced lists
    var sourceThumbnail: UIImage? {
        guard let data = sourceThumbnailData else { return nil }
        return UIImage(data: data)
    }

    /// Decode the extraction rect
    var extractionRect: CGRect? {
        guard let data = extractionRectData,
              let codable = try? JSONDecoder().decode(CodableRect.self, from: data) else {
            return nil
        }
        return codable.rect
    }

    /// Set the extraction rect
    func setExtractionRect(_ rect: CGRect?) {
        if let rect = rect {
            extractionRectData = try? JSONEncoder().encode(CodableRect(rect: rect))
        } else {
            extractionRectData = nil
        }
    }

    /// Progress: completed / total
    var progress: (completed: Int, total: Int) {
        let total = tasks?.count ?? 0
        let completed = tasks?.filter { $0.isCompleted }.count ?? 0
        return (completed, total)
    }

    /// Progress percentage (0.0 - 1.0)
    var progressPercentage: Double {
        let (completed, total) = progress
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }

    /// Check if all tasks are completed
    var isFullyCompleted: Bool {
        guard let tasks = tasks, !tasks.isEmpty else { return false }
        return tasks.allSatisfy { $0.isCompleted }
    }

    /// Check if any tasks have been added to today's weaves
    var hasTasksAddedToWeaves: Bool {
        guard let tasks = tasks else { return false }
        return tasks.contains { $0.addedToPriorityAt != nil }
    }

    /// Count of tasks added to weaves
    var tasksAddedCount: Int {
        tasks?.filter { $0.addedToPriorityAt != nil }.count ?? 0
    }

    /// Count of tasks NOT yet added to weaves
    var tasksNotAddedCount: Int {
        tasks?.filter { $0.addedToPriorityAt == nil }.count ?? 0
    }

    /// Recalculate and update status based on task states
    /// Call this after syncing completion status from LoomView
    /// Respects manual archive - only un-archives if tasks become incomplete
    func recalculateStatus() {
        guard let tasks = tasks, !tasks.isEmpty else {
            // No tasks - stay in backlog
            if status != .backlog {
                status = .backlog
            }
            return
        }

        // Check if all tasks (including subtasks) are completed
        let allCompleted = tasks.allSatisfy { task in
            if task.isCompleted {
                // If task has subtasks, they should also be completed
                if let subtasks = task.subtasks, !subtasks.isEmpty {
                    return subtasks.allSatisfy { $0.isCompleted }
                }
                return true
            }
            return false
        }

        // If already archived, respect the manual archive
        // Only un-archive if tasks become incomplete (user uncompleted something)
        if status == .archived {
            if !allCompleted {
                // Tasks became incomplete, move back to active
                status = .active
            }
            // Otherwise stay archived (respect manual archive)
            return
        }

        // Auto-archive when ALL tasks are completed
        if allCompleted {
            status = .archived
            return
        }

        // Backlog ↔ Active transitions
        if hasTasksAddedToWeaves {
            // Some tasks added to weaves but not all completed -> Active
            if status != .active {
                status = .active
            }
        } else {
            // No tasks added to weaves yet -> Backlog
            if status != .backlog {
                status = .backlog
            }
        }
    }
}

// MARK: - Extracted Task

/// Individual task item extracted from PDF
@Model
class ExtractedTask {
    var id: UUID
    var text: String
    var isCompleted: Bool
    var order: Int
    var dueDate: Date?
    var addedToPriorityAt: Date?      // When added to daily Priority Tasks (nil if not)
    var completedAt: Date?
    var isHeader: Bool = false        // True if this is a section header (DAY 1, Morning Block, etc.)

    var parentList: PDFTaskList?
    var parentTask: ExtractedTask? = nil    // For subtasks, points to parent header task

    @Relationship(deleteRule: .cascade)
    var subtasks: [ExtractedTask]? = nil    // Child tasks under this header

    init(
        text: String,
        order: Int,
        dueDate: Date? = nil,
        isHeader: Bool = false
    ) {
        self.id = UUID()
        self.text = text
        self.isCompleted = false
        self.order = order
        self.dueDate = dueDate
        self.isHeader = isHeader
        self.subtasks = []
    }

    /// Check if this task has subtasks
    var hasSubtasks: Bool {
        !(subtasks?.isEmpty ?? true)
    }

    /// Get subtask count
    var subtaskCount: Int {
        subtasks?.count ?? 0
    }

    /// Completed subtask count
    var completedSubtaskCount: Int {
        subtasks?.filter { $0.isCompleted }.count ?? 0
    }

    /// Subtask progress (completed / total)
    var subtaskProgress: (completed: Int, total: Int) {
        (completedSubtaskCount, subtaskCount)
    }

    /// Mark as completed
    func markCompleted() {
        isCompleted = true
        completedAt = Date()
    }

    /// Mark as not completed
    func markIncomplete() {
        isCompleted = false
        completedAt = nil
    }

    /// Check if this task has been added as a Priority Task
    var isAddedToPriority: Bool {
        addedToPriorityAt != nil
    }
}

// MARK: - Helper: Codable CGRect

/// Helper struct to encode/decode CGRect
/// Note: Marked as Sendable for use across actor boundaries
struct CodableRect: Sendable {
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat

    init(rect: CGRect) {
        self.x = rect.origin.x
        self.y = rect.origin.y
        self.width = rect.size.width
        self.height = rect.size.height
    }

    var rect: CGRect {
        CGRect(x: x, y: y, width: width, height: height)
    }
}

// Explicit nonisolated Codable conformance
extension CodableRect: Codable {
    private enum CodingKeys: String, CodingKey {
        case x, y, width, height
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        x = try container.decode(CGFloat.self, forKey: .x)
        y = try container.decode(CGFloat.self, forKey: .y)
        width = try container.decode(CGFloat.self, forKey: .width)
        height = try container.decode(CGFloat.self, forKey: .height)
    }

    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
        try container.encode(width, forKey: .width)
        try container.encode(height, forKey: .height)
    }
}
