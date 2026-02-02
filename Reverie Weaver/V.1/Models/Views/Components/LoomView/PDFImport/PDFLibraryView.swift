//
//  PDFLibraryView.swift
//  Reverie Weaver
//
//  Main library view for imported PDFs and task lists
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - Active Sort Option (Enhancement 4)

enum ActiveSortOption: String, CaseIterable {
    case none = "none"
    case progress = "progress"
    case deadline = "deadline"

    var displayName: String {
        switch self {
        case .none: return "Default"
        case .progress: return "Nearly Done"
        case .deadline: return "Deadline"
        }
    }

    var icon: String {
        switch self {
        case .none: return "arrow.up.arrow.down"
        case .progress: return "chart.bar.fill"
        case .deadline: return "calendar"
        }
    }
}

struct PDFLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var localization = LocalizationManager.shared

    @Query(sort: \ImportedPDF.importedAt, order: .reverse)
    private var importedPDFs: [ImportedPDF]

    // Query for standalone task lists (image-sourced, no parent PDF)
    @Query(filter: #Predicate<PDFTaskList> { $0.parentPDF == nil }, sort: \PDFTaskList.createdAt, order: .reverse)
    private var standaloneTaskLists: [PDFTaskList]

    // Query for PriorityTasks to sync completion status
    @Query private var allPriorityTasks: [PriorityTask]

    @State private var showDocumentPicker = false
    @State private var showArchivedSection = false  // Toggle for showing archived items
    @State private var showImageScanView = false  // For image import sheet
    @State private var selectedPDFForBrowser: ImportedPDF?  // For page browser sheet (item-based)
    @State private var selectedTaskListForEditor: PDFTaskList?  // For task list editor sheet (item-based)
    @State private var filterStatus: TaskListStatus? = nil
    @State private var activeSortOption: ActiveSortOption = .none
    @State private var showDeleteConfirmation = false
    @State private var pdfToDelete: ImportedPDF?
    @State private var taskListToDelete: PDFTaskList?
    @State private var showTaskListDeleteConfirmation = false
    @State private var taskListToRename: PDFTaskList?  // For rename sheet (item-based)
    @State private var renameText = ""
    @State private var pdfToSchedule: ImportedPDF?  // For schedule editor sheet (item-based)

    // Error handling states
    @State private var showImportError = false
    @State private var importErrorMessage = ""
    @State private var showLargePDFWarning = false
    @State private var pendingLargePDFURL: URL?
    @State private var pendingLargePDFPageCount: Int = 0

    // Constants for validation
    private let maxRecommendedPageCount = 200
    private let maxAllowedPageCount = 1000
    private let maxFileSizeMB: Int64 = 100

    var body: some View {
        NavigationStack {
            ZStack {
                ReverieWeaverBackground()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection

                        // Filter chips
                        filterSection

                        // Content
                        if importedPDFs.isEmpty && standaloneTaskLists.isEmpty {
                            emptyStateView
                        } else if showArchivedSection {
                            // Archived section - show only archived items
                            archivedContentSection
                        } else {
                            // Main content - excludes archived unless specifically filtered
                            // Standalone image task lists section
                            if !filteredStandaloneTaskLists.isEmpty {
                                standaloneTaskListsSection
                            }

                            // PDF task lists section
                            if !importedPDFs.isEmpty {
                                taskListsSection
                            }

                            // Show "No items" if filters result in empty
                            if filteredStandaloneTaskLists.isEmpty && !hasVisiblePDFTaskLists {
                                noFilteredItemsView
                            }
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(localization.localize("common.done")) {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.sageGreen)
                }

                ToolbarItem(placement: .principal) {
                    Text(localization.localize("pdf.library.title"))
                        .font(.system(size: 17, weight: .semibold))
                        .fontDesign(.serif)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                }
            }
            .sheet(isPresented: $showDocumentPicker) {
                DocumentPicker { url in
                    importPDF(from: url)
                }
            }
            .sheet(isPresented: $showImageScanView) {
                ImageScanView { taskList in
                    showImageScanView = false
                    // Open the task list editor for the newly created list
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        selectedTaskListForEditor = taskList
                    }
                }
            }
            .sheet(item: $selectedPDFForBrowser) { pdf in
                PDFPageBrowserView(pdf: pdf) { taskList in
                    selectedPDFForBrowser = nil
                    // Use DispatchQueue to avoid sheet transition conflicts
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        selectedTaskListForEditor = taskList
                    }
                }
            }
            .sheet(item: $selectedTaskListForEditor) { taskList in
                TaskListEditorSheet(taskList: taskList)
            }
            .alert(localization.localize("pdf.delete.title"), isPresented: $showDeleteConfirmation) {
                Button(localization.localize("common.cancel"), role: .cancel) {}
                Button(localization.localize("common.delete"), role: .destructive) {
                    if let pdf = pdfToDelete {
                        deletePDF(pdf)
                    }
                }
            } message: {
                Text(localization.localize("pdf.delete.message"))
            }
            .alert(localization.localize("pdf.deleteList.title"), isPresented: $showTaskListDeleteConfirmation) {
                Button(localization.localize("common.cancel"), role: .cancel) {}
                Button(localization.localize("common.delete"), role: .destructive) {
                    if let taskList = taskListToDelete {
                        deleteTaskList(taskList)
                    }
                }
            } message: {
                Text(localization.localize("pdf.deleteList.message"))
            }
            .sheet(item: $taskListToRename) { taskList in
                RenameTaskListSheet(
                    currentName: taskList.name,
                    onRename: { newName in
                        taskList.name = newName
                        taskListToRename = nil
                    }
                )
                .presentationDetents([.height(200)])
            }
            // Schedule editor sheet
            .sheet(item: $pdfToSchedule) { pdf in
                PDFScheduleEditorSheet(pdf: pdf)
            }
            // Import error alert
            .alert(localization.localize("pdf.error.importFailed"), isPresented: $showImportError) {
                Button(localization.localize("common.ok"), role: .cancel) {}
            } message: {
                Text(importErrorMessage)
            }
            // Large PDF warning alert
            .alert(localization.localize("pdf.warning.largePDF"), isPresented: $showLargePDFWarning) {
                Button(localization.localize("common.cancel"), role: .cancel) {
                    pendingLargePDFURL = nil
                }
                Button(localization.localize("common.continueAnyway")) {
                    if let url = pendingLargePDFURL {
                        performImport(from: url, skipValidation: true)
                    }
                    pendingLargePDFURL = nil
                }
            } message: {
                Text(String(format: localization.localize("pdf.warning.largePDFMessage"), pendingLargePDFPageCount))
            }
            // Sync completion status when view appears
            .onAppear {
                syncCompletionStatusFromLoomView()
            }
        }
    }

    // MARK: - Completion Sync

    /// Sync completion status from PriorityTasks back to ExtractedTasks
    /// Called when the library view appears
    private func syncCompletionStatusFromLoomView() {
        #if DEBUG
        print("PDFLibraryView: Syncing completion status from LoomView...")
        #endif

        var updatedCount = 0

        // Build a lookup of completed PriorityTasks and their subtasks by sourceExtractedTaskId
        var completedTaskIds = Set<UUID>()
        var completedSubtaskIds = Set<UUID>()

        for priorityTask in allPriorityTasks {
            // Check if PriorityTask is completed
            if priorityTask.isCompleted, let sourceId = priorityTask.sourceExtractedTaskId {
                completedTaskIds.insert(sourceId)
            }

            // Check subtasks
            if let subtasks = priorityTask.subTasks {
                for subtask in subtasks {
                    if subtask.isCompleted, let sourceId = subtask.sourceExtractedTaskId {
                        completedSubtaskIds.insert(sourceId)
                    }
                }
            }
        }

        // Update ExtractedTasks in all PDFs
        for pdf in importedPDFs {
            guard let taskLists = pdf.taskLists else { continue }

            for taskList in taskLists {
                guard let tasks = taskList.tasks else { continue }

                for task in tasks {
                    // Update main task completion
                    if completedTaskIds.contains(task.id) && !task.isCompleted {
                        task.isCompleted = true
                        task.completedAt = Date()
                        updatedCount += 1
                    }

                    // Update subtasks
                    if let subtasks = task.subtasks {
                        for subtask in subtasks {
                            if completedSubtaskIds.contains(subtask.id) && !subtask.isCompleted {
                                subtask.isCompleted = true
                                subtask.completedAt = Date()
                                updatedCount += 1
                            }
                        }
                    }
                }

                // Recalculate task list status
                taskList.recalculateStatus()
            }
        }

        // Update standalone task lists
        for taskList in standaloneTaskLists {
            guard let tasks = taskList.tasks else { continue }

            for task in tasks {
                if completedTaskIds.contains(task.id) && !task.isCompleted {
                    task.isCompleted = true
                    task.completedAt = Date()
                    updatedCount += 1
                }

                if let subtasks = task.subtasks {
                    for subtask in subtasks {
                        if completedSubtaskIds.contains(subtask.id) && !subtask.isCompleted {
                            subtask.isCompleted = true
                            subtask.completedAt = Date()
                            updatedCount += 1
                        }
                    }
                }
            }

            // Recalculate task list status
            taskList.recalculateStatus()
        }

        #if DEBUG
        print("PDFLibraryView: Synced \(updatedCount) task completions")
        #endif
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            // Side-by-side import buttons
            HStack(spacing: 12) {
                // Import PDF button
                Button {
                    showDocumentPicker = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.badge.plus")
                            .font(.system(size: 18, weight: .medium))

                        Text(localization.localize("pdf.importPDF"))
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(Color.sageGreen)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .reverieCardStyle(colorScheme: colorScheme)
                }
                .buttonStyle(.plain)

                // Scan Image button
                Button {
                    showImageScanView = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 18, weight: .medium))

                        Text(localization.localize("image.scanImage"))
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(Color.sageGreen)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .reverieCardStyle(colorScheme: colorScheme)
                }
                .buttonStyle(.plain)
            }

            // Stats row
            if !importedPDFs.isEmpty {
                HStack(spacing: 20) {
                    StatPill(
                        icon: "doc.fill",
                        value: "\(importedPDFs.count)",
                        label: localization.localize("pdf.pdfs")
                    )

                    StatPill(
                        icon: "list.bullet",
                        value: "\(totalTaskLists)",
                        label: localization.localize("pdf.lists")
                    )

                    StatPill(
                        icon: "checkmark.circle.fill",
                        value: "\(totalCompletedTasks)/\(totalTasks)",
                        label: localization.localize("pdf.tasks")
                    )
                }
            }
        }
    }

    // MARK: - Filter Section

    private var filterSection: some View {
        VStack(spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    FilterChip(
                        title: localization.localize("pdf.filter.all"),
                        isSelected: filterStatus == nil && !showArchivedSection,
                        colorScheme: colorScheme
                    ) {
                        withAnimation(.snappy) {
                            filterStatus = nil
                            showArchivedSection = false
                        }
                    }

                    // Only show Backlog and Active in main filters
                    FilterChip(
                        title: TaskListStatus.backlog.localizedName(localization),
                        icon: TaskListStatus.backlog.icon,
                        isSelected: filterStatus == .backlog && !showArchivedSection,
                        colorScheme: colorScheme
                    ) {
                        withAnimation(.snappy) {
                            filterStatus = .backlog
                            showArchivedSection = false
                        }
                    }

                    FilterChip(
                        title: TaskListStatus.active.localizedName(localization),
                        icon: TaskListStatus.active.icon,
                        isSelected: filterStatus == .active && !showArchivedSection,
                        colorScheme: colorScheme
                    ) {
                        withAnimation(.snappy) {
                            filterStatus = .active
                            showArchivedSection = false
                        }
                    }

                    // Archived as a separate toggle
                    FilterChip(
                        title: TaskListStatus.archived.localizedName(localization),
                        icon: TaskListStatus.archived.icon,
                        isSelected: showArchivedSection,
                        colorScheme: colorScheme
                    ) {
                        withAnimation(.snappy) {
                            showArchivedSection.toggle()
                            if showArchivedSection {
                                filterStatus = .archived
                            } else {
                                filterStatus = nil
                            }
                        }
                    }
                }
                .padding(.horizontal, 4)
            }

            // Sort options (only show when Active filter is selected) - Enhancement 4
            if filterStatus == .active {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Text(localization.localize("pdf.sortBy"))
                            .font(.system(size: 11))
                            .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme))

                        ForEach(ActiveSortOption.allCases, id: \.self) { option in
                            SortChip(
                                title: option.displayName,
                                icon: option.icon,
                                isSelected: activeSortOption == option,
                                colorScheme: colorScheme
                            ) {
                                withAnimation(.snappy) { activeSortOption = option }
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.6))

            Text(localization.localize("pdf.empty.title"))
                .font(.system(size: 16, weight: .medium))
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

            Text(localization.localize("pdf.empty.subtitle"))
                .font(.system(size: 13))
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 60)
    }

    // MARK: - Standalone Task Lists Section (Image-sourced)

    private var standaloneTaskListsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack(spacing: 8) {
                Image(systemName: "photo.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.sageGreen)

                Text(localization.localize("image.section.title"))
                    .font(.system(size: 14, weight: .semibold))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

                Spacer()

                Text("\(filteredStandaloneTaskLists.count)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.15))
                    )
            }
            .padding(.horizontal, 4)

            // Task list cards
            ForEach(sortedStandaloneTaskLists) { taskList in
                ImageTaskListCard(
                    taskList: taskList,
                    colorScheme: colorScheme,
                    onTap: {
                        selectedTaskListForEditor = taskList
                    },
                    onRename: {
                        taskListToRename = taskList
                        renameText = taskList.name
                    },
                    onDelete: {
                        taskListToDelete = taskList
                        showTaskListDeleteConfirmation = true
                    },
                    onChangeStatus: { newStatus in
                        changeTaskListStatus(taskList, to: newStatus)
                    }
                )
            }
        }
    }

    /// Sorted standalone task lists based on current sort option
    private var sortedStandaloneTaskLists: [PDFTaskList] {
        let lists = filteredStandaloneTaskLists

        guard filterStatus == .active else {
            return lists
        }

        switch activeSortOption {
        case .none:
            return lists
        case .progress:
            return lists.sorted { $0.progressPercentage > $1.progressPercentage }
        case .deadline:
            // Standalone lists don't have deadlines, so just return as-is
            return lists
        }
    }

    // MARK: - Task Lists Section

    private var taskListsSection: some View {
        VStack(spacing: 16) {
            ForEach(importedPDFs) { pdf in
                PDFCard(
                    pdf: pdf,
                    filterStatus: filterStatus,
                    colorScheme: colorScheme,
                    sortOption: activeSortOption,
                    onTapPDF: {
                        // Use item-based sheet - just set the item
                        selectedPDFForBrowser = pdf
                    },
                    onTapTaskList: { taskList in
                        // Use item-based sheet - just set the item
                        selectedTaskListForEditor = taskList
                    },
                    onDeletePDF: {
                        pdfToDelete = pdf
                        showDeleteConfirmation = true
                    },
                    onSchedulePDF: {
                        // Use item-based sheet - just set the item
                        pdfToSchedule = pdf
                    },
                    onRenameTaskList: { taskList in
                        // Use item-based sheet - just set the item
                        taskListToRename = taskList
                        renameText = taskList.name
                    },
                    onDeleteTaskList: { taskList in
                        taskListToDelete = taskList
                        showTaskListDeleteConfirmation = true
                    },
                    onChangeTaskListStatus: { taskList, newStatus in
                        changeTaskListStatus(taskList, to: newStatus)
                    }
                )
            }
        }
    }

    // MARK: - Change Task List Status (Enhancement 3)

    private func changeTaskListStatus(_ taskList: PDFTaskList, to newStatus: TaskListStatus) {
        withAnimation(.snappy) {
            taskList.status = newStatus

            // If manually archiving, mark all tasks and subtasks as completed
            // This ensures the archived status persists (recalculateStatus respects archive when all completed)
            if newStatus == .archived {
                taskList.tasks?.forEach { task in
                    if !task.isCompleted {
                        task.isCompleted = true
                        task.completedAt = Date()
                    }
                    // Also complete subtasks
                    task.subtasks?.forEach { subtask in
                        if !subtask.isCompleted {
                            subtask.isCompleted = true
                            subtask.completedAt = Date()
                        }
                    }
                }
            }
        }
        ReverieHaptics.lightFeedback()
    }

    // MARK: - Computed Properties

    private var totalTaskLists: Int {
        let pdfLists = importedPDFs.reduce(0) { $0 + ($1.taskLists?.count ?? 0) }
        return pdfLists + standaloneTaskLists.count
    }

    private var totalTasks: Int {
        let pdfTasks = importedPDFs.reduce(0) { $0 + $1.totalTaskCount }
        let standaloneTasks = standaloneTaskLists.reduce(0) { $0 + ($1.tasks?.count ?? 0) }
        return pdfTasks + standaloneTasks
    }

    private var totalCompletedTasks: Int {
        let pdfCompleted = importedPDFs.reduce(0) { $0 + $1.completedTaskCount }
        let standaloneCompleted = standaloneTaskLists.reduce(0) { $0 + ($1.tasks?.filter { $0.isCompleted }.count ?? 0) }
        return pdfCompleted + standaloneCompleted
    }

    /// Filtered standalone task lists based on current filter status
    /// Excludes archived items unless specifically viewing archived section
    private var filteredStandaloneTaskLists: [PDFTaskList] {
        if showArchivedSection {
            return standaloneTaskLists.filter { $0.status == .archived }
        }

        guard let status = filterStatus else {
            // "All" filter excludes archived
            return standaloneTaskLists.filter { $0.status != .archived }
        }
        return standaloneTaskLists.filter { $0.status == status }
    }

    /// Check if any PDFs have visible task lists based on current filter
    private var hasVisiblePDFTaskLists: Bool {
        for pdf in importedPDFs {
            guard let taskLists = pdf.taskLists else { continue }
            let visibleLists = taskLists.filter { taskList in
                if showArchivedSection {
                    return taskList.status == .archived
                }
                if let status = filterStatus {
                    return taskList.status == status
                }
                // "All" excludes archived
                return taskList.status != .archived
            }
            if !visibleLists.isEmpty {
                return true
            }
        }
        return false
    }

    /// Count of archived items (for badge display)
    private var archivedItemCount: Int {
        let archivedStandalone = standaloneTaskLists.filter { $0.status == .archived }.count
        let archivedPDF = importedPDFs.reduce(0) { total, pdf in
            total + (pdf.taskLists?.filter { $0.status == .archived }.count ?? 0)
        }
        return archivedStandalone + archivedPDF
    }

    // MARK: - Archived Content Section

    private var archivedContentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack(spacing: 8) {
                Image(systemName: "archivebox.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme))

                Text(localization.localize("pdf.archived.title"))
                    .font(.system(size: 14, weight: .semibold))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

                Spacer()

                Text("\(archivedItemCount)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.15))
                    )
            }
            .padding(.horizontal, 4)

            if archivedItemCount == 0 {
                // Empty archived state
                VStack(spacing: 12) {
                    Image(systemName: "archivebox")
                        .font(.system(size: 36, weight: .light))
                        .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.5))

                    Text(localization.localize("pdf.archived.empty"))
                        .font(.system(size: 14))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                // Archived standalone task lists
                let archivedStandalone = standaloneTaskLists.filter { $0.status == .archived }
                if !archivedStandalone.isEmpty {
                    ForEach(archivedStandalone) { taskList in
                        ImageTaskListCard(
                            taskList: taskList,
                            colorScheme: colorScheme,
                            onTap: {
                                selectedTaskListForEditor = taskList
                            },
                            onRename: {
                                taskListToRename = taskList
                                renameText = taskList.name
                            },
                            onDelete: {
                                taskListToDelete = taskList
                                showTaskListDeleteConfirmation = true
                            },
                            onChangeStatus: { newStatus in
                                changeTaskListStatus(taskList, to: newStatus)
                            }
                        )
                    }
                }

                // Archived PDF task lists
                ForEach(importedPDFs) { pdf in
                    let archivedLists = pdf.taskLists?.filter { $0.status == .archived } ?? []
                    if !archivedLists.isEmpty {
                        PDFCard(
                            pdf: pdf,
                            filterStatus: .archived,
                            colorScheme: colorScheme,
                            sortOption: .none,
                            onTapPDF: {
                                selectedPDFForBrowser = pdf
                            },
                            onTapTaskList: { taskList in
                                selectedTaskListForEditor = taskList
                            },
                            onDeletePDF: {
                                pdfToDelete = pdf
                                showDeleteConfirmation = true
                            },
                            onSchedulePDF: {
                                pdfToSchedule = pdf
                            },
                            onRenameTaskList: { taskList in
                                taskListToRename = taskList
                                renameText = taskList.name
                            },
                            onDeleteTaskList: { taskList in
                                taskListToDelete = taskList
                                showTaskListDeleteConfirmation = true
                            },
                            onChangeTaskListStatus: { taskList, newStatus in
                                changeTaskListStatus(taskList, to: newStatus)
                            }
                        )
                    }
                }
            }
        }
    }

    // MARK: - No Filtered Items View

    private var noFilteredItemsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.5))

            Text(localization.localize("pdf.filter.noItems"))
                .font(.system(size: 14))
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Actions

    private func importPDF(from url: URL) {
        // Validate PDF before import
        let validation = PDFStorageManager.shared.validatePDF(at: url)

        switch validation {
        case .valid(let pageCount):
            // Check if PDF is large and warn user
            if pageCount > maxRecommendedPageCount {
                if pageCount > maxAllowedPageCount {
                    importErrorMessage = "This PDF has \(pageCount) pages, which exceeds the maximum of \(maxAllowedPageCount) pages. Please use a smaller PDF."
                    showImportError = true
                    return
                }
                // Show warning for large PDFs
                pendingLargePDFURL = url
                pendingLargePDFPageCount = pageCount
                showLargePDFWarning = true
                return
            }
            performImport(from: url, skipValidation: false)

        case .tooLarge(let sizeMB):
            importErrorMessage = "This PDF is \(sizeMB) MB, which exceeds the maximum of \(maxFileSizeMB) MB. Please use a smaller file."
            showImportError = true

        case .invalidFormat:
            importErrorMessage = "Unable to read this file. Please make sure it's a valid PDF document."
            showImportError = true

        case .accessDenied:
            importErrorMessage = "Unable to access this file. Please check that you have permission to read it."
            showImportError = true

        case .unknown(let error):
            importErrorMessage = "An error occurred while importing the PDF: \(error)"
            showImportError = true
        }
    }

    private func performImport(from url: URL, skipValidation: Bool) {
        let result = PDFStorageManager.shared.importPDF(from: url)

        switch result {
        case .success(let importResult):
            let pdf = ImportedPDF(
                fileName: url.lastPathComponent,
                fileRelativePath: importResult.relativePath,
                pageCount: importResult.pageCount
            )

            // Generate thumbnail
            if let pdfURL = pdf.fileURL {
                pdf.thumbnailRelativePath = PDFStorageManager.shared.generateThumbnail(
                    for: pdfURL,
                    pdfId: pdf.id
                )
            }

            modelContext.insert(pdf)

            // Open page browser for the new PDF (use item-based sheet)
            selectedPDFForBrowser = pdf

        case .failure(let error):
            switch error {
            case .accessDenied:
                importErrorMessage = "Unable to access this file. Please try again or choose a different file."
            case .copyFailed(let underlying):
                importErrorMessage = "Failed to save the PDF: \(underlying)"
            case .directoryCreationFailed:
                importErrorMessage = "Unable to create storage directory. Please check available storage space."
            case .invalidPDF:
                importErrorMessage = "This file doesn't appear to be a valid PDF document."
            case .insufficientStorage:
                importErrorMessage = "Not enough storage space to import this PDF. Please free up some space and try again."
            }
            showImportError = true
        }
    }

    private func deletePDF(_ pdf: ImportedPDF) {
        // Delete files from disk
        PDFStorageManager.shared.deletePDF(
            relativePath: pdf.fileRelativePath,
            thumbnailRelativePath: pdf.thumbnailRelativePath
        )

        // Delete from SwiftData
        modelContext.delete(pdf)
    }

    private func deleteTaskList(_ taskList: PDFTaskList) {
        // Remove from parent PDF
        if let pdf = taskList.parentPDF {
            pdf.taskLists?.removeAll { $0.id == taskList.id }
        }

        // Delete from SwiftData
        modelContext.delete(taskList)
    }
}

// MARK: - Supporting Views

private struct StatPill: View {
    let icon: String
    let value: String
    let label: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme))

            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.12))
        )
    }
}

private struct FilterChip: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let colorScheme: ColorScheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 11))
                }
                Text(title)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
            }
            .foregroundStyle(isSelected ? Color.white : Color.timeAdaptiveSecondary(colorScheme: colorScheme))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(isSelected ? Color.dustyBlue : Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.15))
            )
        }
        .buttonStyle(.plain)
    }
}

private struct SortChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let colorScheme: ColorScheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
            }
            .foregroundStyle(isSelected ? Color.white : Color.timeAdaptiveSecondary(colorScheme: colorScheme))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(isSelected ? Color.sageGreen : Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.12))
            )
        }
        .buttonStyle(.plain)
    }
}

private struct PDFCard: View {
    let pdf: ImportedPDF
    let filterStatus: TaskListStatus?
    let colorScheme: ColorScheme
    let sortOption: ActiveSortOption
    let onTapPDF: () -> Void
    let onTapTaskList: (PDFTaskList) -> Void
    let onDeletePDF: () -> Void
    let onSchedulePDF: () -> Void
    let onRenameTaskList: (PDFTaskList) -> Void
    let onDeleteTaskList: (PDFTaskList) -> Void
    let onChangeTaskListStatus: (PDFTaskList, TaskListStatus) -> Void

    private var filteredTaskLists: [PDFTaskList] {
        guard let lists = pdf.taskLists else { return [] }
        var filtered: [PDFTaskList]
        if let status = filterStatus {
            filtered = lists.filter { $0.status == status }
        } else {
            filtered = lists
        }

        // Smart sorting for Active status (Enhancement 4)
        if filterStatus == .active {
            switch sortOption {
            case .progress:
                // Sort by progress (nearly done first)
                filtered.sort { $0.progressPercentage > $1.progressPercentage }
            case .deadline:
                // Sort by deadline (soonest first)
                filtered.sort { list1, list2 in
                    guard let pdf1 = list1.parentPDF, let pdf2 = list2.parentPDF else { return false }
                    guard let date1 = pdf1.endDate else { return false }
                    guard let date2 = pdf2.endDate else { return true }
                    return date1 < date2
                }
            case .none:
                break
            }
        }

        return filtered
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // PDF Header
            HStack(spacing: 12) {
                // Thumbnail with priority border
                ZStack(alignment: .topLeading) {
                    if let thumbURL = pdf.thumbnailURL,
                       let data = try? Data(contentsOf: thumbURL),
                       let image = UIImage(data: data) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 44, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .strokeBorder(pdf.priority.color, lineWidth: 2)
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.12))
                            .frame(width: 44, height: 56)
                            .overlay(
                                Image(systemName: "doc.fill")
                                    .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .strokeBorder(pdf.priority.color, lineWidth: 2)
                            )
                    }

                    // Priority badge
                    Circle()
                        .fill(pdf.priority.color)
                        .frame(width: 14, height: 14)
                        .overlay(
                            Image(systemName: pdf.priority.icon)
                                .font(.system(size: 7, weight: .bold))
                                .foregroundStyle(.white)
                        )
                        .offset(x: -4, y: -4)
                }

                VStack(alignment: .leading, spacing: 4) {
                    // Title with series indicator
                    HStack(spacing: 6) {
                        Text(pdf.title)
                            .font(.system(size: 14, weight: .semibold))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                            .lineLimit(1)

                        if pdf.isPartOfSeries, let desc = pdf.seriesDescription {
                            Text(desc)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }

                    // Stats row
                    HStack(spacing: 6) {
                        // Category tag
                        HStack(spacing: 3) {
                            Image(systemName: pdf.category.icon)
                                .font(.system(size: 8))
                            Text(pdf.categoryDisplayName)
                                .font(.system(size: 10))
                        }
                        .foregroundStyle(pdf.category.color)

                        Text("•")
                            .font(.system(size: 8))
                            .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme))

                        Text("\(pdf.pageCount) pages")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme))

                        Text("•")
                            .font(.system(size: 8))
                            .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme))

                        Text("\(pdf.taskListCount) lists")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme))
                    }

                    // Schedule info row
                    if pdf.hasSchedule {
                        HStack(spacing: 6) {
                            if pdf.isOverdue {
                                HStack(spacing: 3) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 8))
                                    Text("Overdue")
                                        .font(.system(size: 10, weight: .medium))
                                }
                                .foregroundStyle(.red)
                            } else if let days = pdf.daysRemaining {
                                HStack(spacing: 3) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 8))
                                    Text("\(days) days left")
                                        .font(.system(size: 10))
                                }
                                .foregroundStyle(days <= 2 ? .orange : Color.timeAdaptiveSecondary(colorScheme: colorScheme))
                            }

                            if pdf.totalTaskCount > 0 {
                                Text("•")
                                    .font(.system(size: 8))
                                    .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme))

                                Text("\(pdf.completedTaskCount)/\(pdf.totalTaskCount) done")
                                    .font(.system(size: 10))
                                    .foregroundStyle(pdf.isFullyCompleted ? .green : Color.timeAdaptiveSecondary(colorScheme: colorScheme))
                            }
                        }
                    }
                }

                Spacer()

                // Actions
                Menu {
                    Button {
                        onTapPDF()
                    } label: {
                        Label("Extract New List", systemImage: "text.viewfinder")
                    }

                    Button {
                        onSchedulePDF()
                    } label: {
                        Label("Edit Schedule", systemImage: "calendar.badge.clock")
                    }

                    Divider()

                    Button(role: .destructive) {
                        onDeletePDF()
                    } label: {
                        Label("Delete PDF", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme))
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
            }

            // Task Lists
            if !filteredTaskLists.isEmpty {
                Divider()
                    .padding(.vertical, 4)

                VStack(spacing: 8) {
                    ForEach(filteredTaskLists) { taskList in
                        TaskListRow(
                            taskList: taskList,
                            colorScheme: colorScheme,
                            onTap: {
                                onTapTaskList(taskList)
                            },
                            onRename: {
                                onRenameTaskList(taskList)
                            },
                            onDelete: {
                                onDeleteTaskList(taskList)
                            },
                            onChangeStatus: { newStatus in
                                onChangeTaskListStatus(taskList, newStatus)
                            }
                        )
                    }
                }
            }
        }
        .padding(14)
        .reverieCardStyle(colorScheme: colorScheme)
    }
}

private struct TaskListRow: View {
    let taskList: PDFTaskList
    let colorScheme: ColorScheme
    let onTap: () -> Void
    let onRename: () -> Void
    let onDelete: () -> Void
    let onChangeStatus: (TaskListStatus) -> Void

    /// Check if task list is overdue (has end date in the past with incomplete tasks)
    private var isOverdue: Bool {
        guard let pdf = taskList.parentPDF,
              let endDate = pdf.endDate else { return false }
        let today = Calendar.current.startOfDay(for: Date())
        let deadline = Calendar.current.startOfDay(for: endDate)
        return today > deadline && !taskList.isFullyCompleted
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                HStack(spacing: 10) {
                    // Status indicator
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(taskList.name)
                                .font(.system(size: 13, weight: .medium))
                                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                                .lineLimit(1)

                            // Overdue badge
                            if isOverdue {
                                HStack(spacing: 2) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 8))
                                    Text("Overdue")
                                        .font(.system(size: 9, weight: .medium))
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color.red.opacity(0.85))
                                )
                            }
                        }

                        Text("Page \(taskList.pageNumber + 1)")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme))
                    }

                    Spacer()

                    // Progress text
                    let (completed, total) = taskList.progress
                    Text("\(completed)/\(total)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(taskList.isFullyCompleted ? Color.sageGreen : Color.timeAdaptiveSecondary(colorScheme: colorScheme))

                    // Progress ring
                    ZStack {
                        Circle()
                            .stroke(Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.25), lineWidth: 2)

                        Circle()
                            .trim(from: 0, to: taskList.progressPercentage)
                            .stroke(statusColor, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                    }
                    .frame(width: 20, height: 20)

                    // Menu for edit/delete/status change
                    Menu {
                        Button {
                            onTap()
                        } label: {
                            Label("View Tasks", systemImage: "list.bullet")
                        }

                        Button {
                            onRename()
                        } label: {
                            Label("Rename", systemImage: "pencil")
                        }

                        Divider()

                        // Quick status change menu
                        Menu {
                            ForEach(TaskListStatus.allCases, id: \.self) { status in
                                Button {
                                    onChangeStatus(status)
                                } label: {
                                    HStack {
                                        Label(status.displayName, systemImage: status.icon)
                                        if taskList.status == status {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            Label("Change Status", systemImage: "arrow.triangle.2.circlepath")
                        }

                        Divider()

                        Button(role: .destructive) {
                            onDelete()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.7))
                            .frame(width: 24, height: 24)
                            .contentShape(Rectangle())
                    }
                }

                // Progress bar (Enhancement 1)
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.2))

                        RoundedRectangle(cornerRadius: 2)
                            .fill(taskList.isFullyCompleted ? Color.sageGreen : statusColor)
                            .frame(width: geometry.size.width * taskList.progressPercentage)
                    }
                }
                .frame(height: 4)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.08))
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            // Context menu for quick status change (Enhancement 3)
            ForEach(TaskListStatus.allCases, id: \.self) { status in
                Button {
                    onChangeStatus(status)
                } label: {
                    HStack {
                        Label(status.displayName, systemImage: status.icon)
                        if taskList.status == status {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }

            Divider()

            Button {
                onRename()
            } label: {
                Label("Rename", systemImage: "pencil")
            }

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var statusColor: Color {
        switch taskList.status {
        case .backlog: return .secondary
        case .active: return .sageGreen
        case .archived: return .dustyBlue
        }
    }
}

// MARK: - Image Task List Card (Standalone image-sourced lists)

private struct ImageTaskListCard: View {
    let taskList: PDFTaskList
    let colorScheme: ColorScheme
    let onTap: () -> Void
    let onRename: () -> Void
    let onDelete: () -> Void
    let onChangeStatus: (TaskListStatus) -> Void

    @ObservedObject private var localization = LocalizationManager.shared

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    // Thumbnail or placeholder
                    thumbnailView

                    // Content
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(taskList.name)
                                .font(.system(size: 14, weight: .semibold))
                                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                                .lineLimit(1)

                            // Status badge
                            statusBadge
                        }

                        // Source indicator
                        HStack(spacing: 4) {
                            Image(systemName: "photo.fill")
                                .font(.system(size: 9))
                            Text(localization.localize("image.sourceLabel"))
                                .font(.system(size: 10))
                        }
                        .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme))

                        // Progress text
                        let (completed, total) = taskList.progress
                        Text("\(completed) of \(total) tasks completed")
                            .font(.system(size: 11))
                            .foregroundStyle(taskList.isFullyCompleted ? Color.sageGreen : Color.timeAdaptiveSecondary(colorScheme: colorScheme))
                    }

                    Spacer()

                    // Progress ring
                    progressRing

                    // Menu
                    menuButton
                }

                // Progress bar
                progressBar
            }
            .padding(12)
            .reverieCardStyle(colorScheme: colorScheme)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        taskList.isFullyCompleted ?
                        Color.sageGreen.opacity(0.3) :
                        statusColor.opacity(0.2),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            ForEach(TaskListStatus.allCases, id: \.self) { status in
                Button {
                    onChangeStatus(status)
                } label: {
                    HStack {
                        Label(status.displayName, systemImage: status.icon)
                        if taskList.status == status {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }

            Divider()

            Button {
                onRename()
            } label: {
                Label("Rename", systemImage: "pencil")
            }

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Thumbnail View

    private var thumbnailView: some View {
        Group {
            if let thumbnail = taskList.sourceThumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.sageGreen.opacity(0.1))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "photo.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.sageGreen.opacity(0.6))
                    )
            }
        }
    }

    // MARK: - Status Badge

    private var statusBadge: some View {
        Group {
            if taskList.isFullyCompleted {
                HStack(spacing: 3) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 8))
                    Text("Done")
                        .font(.system(size: 9, weight: .medium))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(Color.sageGreen)
                )
            } else {
                HStack(spacing: 3) {
                    Image(systemName: taskList.status.icon)
                        .font(.system(size: 8))
                    Text(taskList.status.displayName)
                        .font(.system(size: 9, weight: .medium))
                }
                .foregroundStyle(statusColor)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(statusColor.opacity(0.15))
                )
            }
        }
    }

    // MARK: - Progress Ring

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.25), lineWidth: 3)

            Circle()
                .trim(from: 0, to: taskList.progressPercentage)
                .stroke(
                    taskList.isFullyCompleted ? Color.sageGreen : statusColor,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            Text("\(Int(taskList.progressPercentage * 100))%")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme))
        }
        .frame(width: 36, height: 36)
    }

    // MARK: - Menu Button

    private var menuButton: some View {
        Menu {
            Button {
                onTap()
            } label: {
                Label("View Tasks", systemImage: "list.bullet")
            }

            Button {
                onRename()
            } label: {
                Label("Rename", systemImage: "pencil")
            }

            Divider()

            Menu {
                ForEach(TaskListStatus.allCases, id: \.self) { status in
                    Button {
                        onChangeStatus(status)
                    } label: {
                        HStack {
                            Label(status.displayName, systemImage: status.icon)
                            if taskList.status == status {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Label("Change Status", systemImage: "arrow.triangle.2.circlepath")
            }

            Divider()

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.7))
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.2))

                RoundedRectangle(cornerRadius: 2)
                    .fill(taskList.isFullyCompleted ? Color.sageGreen : statusColor)
                    .frame(width: geometry.size.width * taskList.progressPercentage)
            }
        }
        .frame(height: 4)
    }

    // MARK: - Status Color

    private var statusColor: Color {
        switch taskList.status {
        case .backlog: return .secondary
        case .active: return .sageGreen
        case .archived: return .dustyBlue
        }
    }
}

// MARK: - Document Picker

struct DocumentPicker: UIViewControllerRepresentable {
    let onPick: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // Use .pdf content type to allow importing from Files app, iCloud, On My iPhone, etc.
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        picker.shouldShowFileExtensions = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void

        init(onPick: @escaping (URL) -> Void) {
            self.onPick = onPick
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            // The URL is security-scoped; PDFStorageManager handles accessing it
            onPick(url)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            // User cancelled - no action needed
        }
    }
}

// MARK: - Rename Task List Sheet

private struct RenameTaskListSheet: View {
    let currentName: String
    let onRename: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var localization = LocalizationManager.shared
    @State private var newName: String = ""
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 6) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.sageGreen)

                    Text(localization.localize("pdf.renameTaskList"))
                        .font(.system(size: 16, weight: .semibold))
                        .fontDesign(.serif)
                }
                .padding(.top, 8)

                // Text field
                TextField(localization.localize("pdf.taskListName"), text: $newName)
                    .font(.system(size: 15))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(colorScheme == .dark ? 0.12 : 0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Color.sageGreen.opacity(isTextFieldFocused ? 0.5 : 0), lineWidth: 1.5)
                    )
                    .focused($isTextFieldFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        if !newName.isEmpty {
                            onRename(newName)
                        }
                    }
                    .padding(.horizontal, 20)

                Spacer()

                // Action buttons
                HStack(spacing: 12) {
                    Button {
                        dismiss()
                    } label: {
                        Text(localization.localize("common.cancel"))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(colorScheme == .dark ? 0.12 : 0.08))
                            )
                    }
                    .buttonStyle(.plain)

                    Button {
                        if !newName.isEmpty {
                            onRename(newName)
                        }
                    } label: {
                        Text(localization.localize("common.save"))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(newName.isEmpty ? Color.white.opacity(0.5) : Color.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(newName.isEmpty ? Color.sageGreen.opacity(0.5) : Color.sageGreen)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(newName.isEmpty)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
            .background(ReverieWeaverBackground())
            .onAppear {
                newName = currentName
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isTextFieldFocused = true
                }
            }
        }
    }
}
