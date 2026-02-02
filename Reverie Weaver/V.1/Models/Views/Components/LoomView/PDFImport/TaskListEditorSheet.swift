//
//  TaskListEditorSheet.swift
//  Reverie Weaver
//
//  Edit extracted tasks and add to Priority Tasks
//

import SwiftUI
import SwiftData
import PDFKit

struct TaskListEditorSheet: View {
    @Bindable var taskList: PDFTaskList

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var localization = LocalizationManager.shared

    @State private var isEditing = false
    @State private var editingTaskId: UUID?
    @State private var editText = ""
    @State private var newTaskText = ""
    @State private var selectedTasks: Set<UUID> = []
    @State private var showAddToPrioritySheet = false
    @State private var showDeleteConfirmation = false
    @State private var taskToDelete: ExtractedTask?
    @State private var isScanningNextPage = false
    @State private var draggedTaskId: UUID?
    @State private var showPDFSelectionSheet = false
    @State private var showArchivePrompt = false
    @State private var hasShownArchivePrompt = false  // Prevent showing multiple times per session
    @State private var showAddedConfirmation = false
    @State private var addedTaskCount = 0
    @State private var showDuplicateAlert = false
    @State private var duplicateMessage = ""

    @Query private var existingPriorityTasks: [PriorityTask]

    /// Get top-level tasks (headers and standalone tasks)
    /// Note: taskList.tasks already contains only top-level tasks by design
    private var sortedTasks: [ExtractedTask] {
        let allTasks = taskList.tasks ?? []
        #if DEBUG
        print("TaskListEditorSheet: taskList.tasks count = \(allTasks.count)")
        for task in allTasks {
            print("  - Task: '\(task.text.prefix(30))...' isHeader=\(task.isHeader) parentTask=\(task.parentTask != nil ? "set" : "nil") subtasks=\(task.subtasks?.count ?? 0)")
        }
        #endif
        // Filter to get only top-level tasks (headers or tasks without a parent)
        return allTasks
            .filter { $0.isHeader || $0.parentTask == nil }
            .sorted { $0.order < $1.order }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ReverieWeaverBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        // Header info
                        headerCard

                        // Status selector
                        statusSelector

                        // Task list
                        taskListSection

                        // Add new task
                        addTaskSection

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 16)
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
                    Text(taskList.name)
                        .font(.system(size: 16, weight: .semibold))
                        .fontDesign(.serif)
                        .lineLimit(1)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if !selectedTasks.isEmpty {
                        Button {
                            showAddToPrioritySheet = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                Text("\(selectedTasks.count)")
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.sageGreen)
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddToPrioritySheet) {
                AddToPrioritySheet(
                    selectedTasks: selectedTaskObjects,
                    onAdd: { tasks in
                        let count = addToPriorityTasks(tasks)
                        selectedTasks.removeAll()
                        // Show confirmation toast
                        if count > 0 {
                            addedTaskCount = count
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                showAddedConfirmation = true
                            }
                            // Auto-hide after 2.5 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    showAddedConfirmation = false
                                }
                            }
                        }
                    }
                )
                .presentationDetents([.medium])
            }
            .sheet(isPresented: $showPDFSelectionSheet) {
                if let pdf = taskList.parentPDF {
                    PDFSelectionForAppendView(
                        pdf: pdf,
                        onTasksExtracted: { extractedTasks in
                            appendExtractedTasks(extractedTasks)
                        }
                    )
                }
            }
            .alert(localization.localize("pdf.task.delete"), isPresented: $showDeleteConfirmation) {
                Button(localization.localize("common.cancel"), role: .cancel) {}
                Button(localization.localize("common.delete"), role: .destructive) {
                    if let task = taskToDelete {
                        deleteTask(task)
                    }
                }
            }
            // Auto-archive prompt (Enhancement 2)
            .alert(localization.localize("pdf.archivePrompt.title"), isPresented: $showArchivePrompt) {
                Button(localization.localize("pdf.archivePrompt.keepActive"), role: .cancel) {}
                Button(localization.localize("pdf.archivePrompt.archive")) {
                    withAnimation(.snappy) {
                        taskList.status = .archived
                    }
                    ReverieHaptics.completionFeedback()
                }
            } message: {
                Text(localization.localize("pdf.archivePrompt.message"))
            }
            // Duplicate task alert
            .alert(localization.localize("pdf.duplicateAlert.title"), isPresented: $showDuplicateAlert) {
                Button(localization.localize("common.ok"), role: .cancel) {}
            } message: {
                Text(duplicateMessage)
            }
            // Success confirmation toast overlay
            .overlay(alignment: .top) {
                if showAddedConfirmation {
                    TaskAddedConfirmationToast(
                        taskCount: addedTaskCount,
                        colorScheme: colorScheme
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .opacity
                    ))
                    .padding(.top, 60)
                }
            }
        }
    }

    /// Append extracted tasks from PDF selection to the current task list
    private func appendExtractedTasks(_ hierarchicalTasks: [PDFTodoExtractor.HierarchicalTask]) {
        let currentOrder = taskList.tasks?.count ?? 0

        for (index, hTask) in hierarchicalTasks.enumerated() {
            // Create the main task (could be header or standalone)
            let extractedTask = ExtractedTask(
                text: hTask.text,
                order: currentOrder + index,
                isHeader: hTask.isHeader
            )
            extractedTask.parentList = taskList

            // Add subtasks if any
            if !hTask.subtasks.isEmpty {
                var subtaskObjects: [ExtractedTask] = []
                for (subIndex, subtaskText) in hTask.subtasks.enumerated() {
                    let subtask = ExtractedTask(
                        text: subtaskText,
                        order: subIndex,
                        isHeader: false
                    )
                    subtask.parentTask = extractedTask
                    subtask.parentList = taskList
                    modelContext.insert(subtask)
                    subtaskObjects.append(subtask)
                }
                extractedTask.subtasks = subtaskObjects
            }

            // Add to task list
            if taskList.tasks == nil {
                taskList.tasks = []
            }
            taskList.tasks?.append(extractedTask)
            modelContext.insert(extractedTask)
        }

        ReverieHaptics.completionFeedback()

        #if DEBUG
        print("TaskListEditorSheet: Appended \(hierarchicalTasks.count) tasks from PDF selection")
        #endif
    }

    // MARK: - Selected Task Objects

    /// Get all selected tasks including both top-level tasks and subtasks
    private var selectedTaskObjects: [ExtractedTask] {
        var selected: [ExtractedTask] = []

        // Get selected top-level tasks
        for task in sortedTasks {
            if selectedTasks.contains(task.id) {
                selected.append(task)
            }

            // Also check subtasks if this is a header
            if task.isHeader, let subtasks = task.subtasks {
                for subtask in subtasks {
                    if selectedTasks.contains(subtask.id) {
                        selected.append(subtask)
                    }
                }
            }
        }

        return selected
    }

    // MARK: - Header Card

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // PDF info
            if let pdf = taskList.parentPDF {
                HStack(spacing: 10) {
                    Image(systemName: "doc.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme))

                    Text(pdf.fileName)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme))
                        .lineLimit(1)

                    Text(String(format: localization.localize("pdf.pageNumber"), taskList.pageNumber + 1))
                        .font(.system(size: 11))
                        .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.7))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.1))
                        )
                }
            }

            // Progress
            let (completed, total) = taskList.progress
            HStack(spacing: 12) {
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.2))

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.sageGreen)
                            .frame(width: geometry.size.width * taskList.progressPercentage)
                    }
                }
                .frame(height: 6)

                Text("\(completed)/\(total)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme))
            }
        }
        .padding(14)
        .reverieCardStyle(colorScheme: colorScheme)
    }

    // MARK: - Status Selector

    private var statusSelector: some View {
        HStack(spacing: 8) {
            ForEach(TaskListStatus.allCases, id: \.self) { status in
                Button {
                    withAnimation(.snappy) {
                        taskList.status = status
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: status.icon)
                            .font(.system(size: 11))

                        Text(status.localizedName(localization))
                            .font(.system(size: 12, weight: taskList.status == status ? .semibold : .regular))
                    }
                    .foregroundStyle(taskList.status == status ? Color.white : Color.timeAdaptiveSecondary(colorScheme: colorScheme))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(taskList.status == status ?
                                  statusColor(status) :
                                  Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.15))
                    )
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
    }

    private func statusColor(_ status: TaskListStatus) -> Color {
        switch status {
        case .backlog: return .secondary
        case .active: return .sageGreen
        case .archived: return .dustyBlue
        }
    }

    // MARK: - Task List Section

    private var taskListSection: some View {
        VStack(spacing: 12) {
            if sortedTasks.isEmpty {
                // Empty state - helps debug blank page issue
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.5))

                    Text(localization.localize("pdf.noTasks"))
                        .font(.system(size: 14))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)

                    #if DEBUG
                    Text("Debug: taskList.tasks = \(taskList.tasks?.count ?? -1)")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.orange)
                    #endif
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }

            ForEach(sortedTasks) { task in
                VStack(spacing: 0) {
                    // Main task row - with drag and drop support
                    TaskRow(
                        task: task,
                        isSelected: selectedTasks.contains(task.id),
                        isEditing: editingTaskId == task.id,
                        editText: $editText,
                        colorScheme: colorScheme,
                        isHeader: task.isHeader,
                        subtaskCount: task.subtaskCount,
                        isBeingDragged: draggedTaskId == task.id,
                        onToggleComplete: {
                            toggleComplete(task)
                        },
                        onToggleSelect: {
                            toggleSelect(task)
                        },
                        onStartEdit: {
                            startEditing(task)
                        },
                        onSaveEdit: {
                            saveEdit(task)
                        },
                        onCancelEdit: {
                            cancelEdit()
                        },
                        onDelete: {
                            taskToDelete = task
                            showDeleteConfirmation = true
                        }
                    )
                    .draggable(task.id.uuidString) {
                        // Drag preview
                        TaskDragPreview(task: task, colorScheme: colorScheme)
                    }
                    .dropDestination(for: String.self) { items, _ in
                        guard let droppedIdString = items.first,
                              let droppedId = UUID(uuidString: droppedIdString),
                              droppedId != task.id else {
                            return false
                        }
                        makeSubtask(taskId: droppedId, ofParent: task)
                        return true
                    } isTargeted: { isTargeted in
                        // Visual feedback when a task is being dragged over this row
                        if isTargeted {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                // The row will highlight via the isDropTarget state
                            }
                        }
                    }

                    // Subtasks (if header has subtasks)
                    if task.isHeader && task.hasSubtasks {
                        SubtaskListView(
                            subtasks: task.subtasks?.sorted { $0.order < $1.order } ?? [],
                            selectedTasks: $selectedTasks,
                            editingTaskId: $editingTaskId,
                            editText: $editText,
                            colorScheme: colorScheme,
                            draggedTaskId: $draggedTaskId,
                            onToggleComplete: { subtask in
                                toggleComplete(subtask)
                            },
                            onToggleSelect: { subtask in
                                toggleSelect(subtask)
                            },
                            onStartEdit: { subtask in
                                startEditing(subtask)
                            },
                            onSaveEdit: { subtask in
                                saveEdit(subtask)
                            },
                            onCancelEdit: {
                                cancelEdit()
                            },
                            onDelete: { subtask in
                                taskToDelete = subtask
                                showDeleteConfirmation = true
                            },
                            onMakeSubtaskOfParent: { subtask, newParent in
                                makeSubtask(taskId: subtask.id, ofParent: newParent)
                            }
                        )
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(task.isHeader ?
                              Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.1) :
                              Color.clear)
                )
            }
        }
    }

    /// Convert a task into a subtask of another task (the parent)
    /// If the task has subtasks, they will also become subtasks of the new parent
    private func makeSubtask(taskId: UUID, ofParent parent: ExtractedTask) {
        // Find the task to move - search both top-level and subtasks
        var taskToMove: ExtractedTask?

        // First check top-level tasks
        if let allTasks = taskList.tasks {
            taskToMove = allTasks.first(where: { $0.id == taskId })

            // If not found, search in subtasks
            if taskToMove == nil {
                for task in allTasks where task.isHeader {
                    if let subtask = task.subtasks?.first(where: { $0.id == taskId }) {
                        taskToMove = subtask
                        break
                    }
                }
            }
        }

        guard let taskToMove = taskToMove else {
            return
        }

        // Don't allow making a parent task a subtask of its own subtask
        if let parentSubtasks = parent.subtasks, parentSubtasks.contains(where: { $0.id == taskId }) {
            return
        }

        // Don't allow making a task a subtask of itself
        if taskId == parent.id {
            return
        }

        // Capture the subtasks before modifying
        let existingSubtasks = taskToMove.subtasks ?? []

        // Remove from current parent (if it's a subtask)
        if let currentParent = taskToMove.parentTask {
            currentParent.subtasks?.removeAll { $0.id == taskId }
        }

        // Remove from top-level tasks list if it was there
        taskList.tasks?.removeAll { $0.id == taskId }

        // Convert parent to header if not already
        if !parent.isHeader {
            parent.isHeader = true
        }

        // Initialize parent's subtasks array if needed
        if parent.subtasks == nil {
            parent.subtasks = []
        }

        // Set up the new subtask relationship for the moved task
        taskToMove.parentTask = parent
        taskToMove.isHeader = false  // Subtasks cannot be headers
        taskToMove.subtasks = nil    // Clear its subtasks reference (they'll be moved separately)

        // Add the moved task to parent's subtasks
        let baseOrder = parent.subtasks?.count ?? 0
        taskToMove.order = baseOrder
        parent.subtasks?.append(taskToMove)

        // Also add all the task's former subtasks as subtasks of the new parent
        for (index, formerSubtask) in existingSubtasks.enumerated() {
            formerSubtask.parentTask = parent
            formerSubtask.order = baseOrder + 1 + index
            parent.subtasks?.append(formerSubtask)
        }

        ReverieHaptics.lightFeedback()

        #if DEBUG
        let subtaskCount = existingSubtasks.count
        if subtaskCount > 0 {
            print("TaskListEditorSheet: Made '\(taskToMove.text.prefix(30))...' + \(subtaskCount) subtasks into subtasks of '\(parent.text.prefix(30))...'")
        } else {
            print("TaskListEditorSheet: Made '\(taskToMove.text.prefix(30))...' a subtask of '\(parent.text.prefix(30))...'")
        }
        #endif
    }

    // MARK: - Add Task Section

    private var addTaskSection: some View {
        VStack(spacing: 12) {
            // Text field for adding a task manually
            HStack(spacing: 10) {
                TextField(localization.localize("pdf.task.addPlaceholder"), text: $newTaskText)
                    .font(.system(size: 14))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.12))
                    )

                Button {
                    addNewTask()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(newTaskText.isEmpty ? Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.4) : Color.sageGreen)
                }
                .disabled(newTaskText.isEmpty)
            }

            // PDF scan options (only show if PDF is available)
            if hasPDFAvailable {
                HStack(spacing: 10) {
                    // Scan Next Page button (only if there's a next page)
                    if canScanNextPage {
                        Button {
                            scanNextPage()
                        } label: {
                            HStack(spacing: 6) {
                                if isScanningNextPage {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                        .tint(Color.sageGreen)
                                } else {
                                    Image(systemName: "doc.text.magnifyingglass")
                                        .font(.system(size: 12))
                                }

                                Text(localization.localize("pdf.scanNextPage"))
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundStyle(Color.sageGreen)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.sageGreen.opacity(colorScheme == .dark ? 0.12 : 0.08))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(Color.sageGreen.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(isScanningNextPage)
                    }

                    // Select from PDF button (always available if PDF exists)
                    Button {
                        showPDFSelectionSheet = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "rectangle.dashed.and.paperclip")
                                .font(.system(size: 12))

                            Text(localization.localize("pdf.selectFromPDF"))
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(Color.dustyBlue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.dustyBlue.opacity(colorScheme == .dark ? 0.12 : 0.08))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(Color.dustyBlue.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    /// Check if the parent PDF is available
    private var hasPDFAvailable: Bool {
        taskList.parentPDF?.fileURL != nil
    }

    /// Check if there's a next page to scan in the PDF
    private var canScanNextPage: Bool {
        guard let pdf = taskList.parentPDF,
              pdf.fileURL != nil else {
            return false
        }
        // Check if the next page exists
        let nextPageIndex = taskList.pageNumber + 1
        return nextPageIndex < pdf.pageCount
    }

    // MARK: - Actions

    private func toggleComplete(_ task: ExtractedTask) {
        withAnimation(.snappy) {
            if task.isCompleted {
                task.markIncomplete()
            } else {
                task.markCompleted()
            }
        }
        ReverieHaptics.lightFeedback()

        // Check if all tasks are completed and show archive prompt (Enhancement 2)
        checkForCompletionAndPromptArchive()
    }

    /// Check if all tasks are completed and prompt to archive if so
    private func checkForCompletionAndPromptArchive() {
        // Only prompt once per session and only if status is active
        guard !hasShownArchivePrompt,
              taskList.status == .active,
              taskList.isFullyCompleted else {
            return
        }

        // Small delay to let the UI update first
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            hasShownArchivePrompt = true
            showArchivePrompt = true
        }
    }

    private func toggleSelect(_ task: ExtractedTask) {
        if selectedTasks.contains(task.id) {
            selectedTasks.remove(task.id)
            // If this is a header, also deselect all subtasks
            if task.isHeader, let subtasks = task.subtasks {
                for subtask in subtasks {
                    selectedTasks.remove(subtask.id)
                }
            }
        } else {
            selectedTasks.insert(task.id)
            // If this is a header, also select all subtasks
            if task.isHeader, let subtasks = task.subtasks {
                for subtask in subtasks {
                    selectedTasks.insert(subtask.id)
                }
            }
        }
        ReverieHaptics.lightFeedback()
    }

    private func startEditing(_ task: ExtractedTask) {
        editingTaskId = task.id
        editText = task.text
    }

    private func saveEdit(_ task: ExtractedTask) {
        if !editText.isEmpty {
            task.text = editText
        }
        editingTaskId = nil
        editText = ""
    }

    private func cancelEdit() {
        editingTaskId = nil
        editText = ""
    }

    private func deleteTask(_ task: ExtractedTask) {
        taskList.tasks?.removeAll { $0.id == task.id }
        modelContext.delete(task)
        selectedTasks.remove(task.id)
    }

    private func addNewTask() {
        let newOrder = (taskList.tasks?.count ?? 0)
        let task = ExtractedTask(text: newTaskText, order: newOrder)
        task.parentList = taskList

        if taskList.tasks == nil {
            taskList.tasks = []
        }
        taskList.tasks?.append(task)
        modelContext.insert(task)

        newTaskText = ""
        ReverieHaptics.lightFeedback()
    }

    /// Scan the next page of the PDF and add extracted tasks to the current list
    private func scanNextPage() {
        guard let pdf = taskList.parentPDF,
              let fileURL = pdf.fileURL else {
            return
        }

        let nextPageIndex = taskList.pageNumber + 1
        guard nextPageIndex < pdf.pageCount else {
            return
        }

        isScanningNextPage = true

        // Perform extraction on background thread
        DispatchQueue.global(qos: .userInitiated).async {
            // Extract hierarchical tasks from the next page
            let extractor = PDFTodoExtractor.shared
            let hierarchicalTasks = extractor.extractHierarchicalTodos(
                from: fileURL,
                pageIndex: nextPageIndex,
                selectionRect: nil,
                useSpatialAnalysis: true
            )

            DispatchQueue.main.async {
                // Add extracted tasks to the current task list
                let currentOrder = taskList.tasks?.count ?? 0

                for (index, hTask) in hierarchicalTasks.enumerated() {
                    // Create the main task (could be header or standalone)
                    let extractedTask = ExtractedTask(
                        text: hTask.text,
                        order: currentOrder + index,
                        isHeader: hTask.isHeader
                    )
                    extractedTask.parentList = taskList

                    // Add subtasks if any
                    if !hTask.subtasks.isEmpty {
                        var subtaskObjects: [ExtractedTask] = []
                        for (subIndex, subtaskText) in hTask.subtasks.enumerated() {
                            let subtask = ExtractedTask(
                                text: subtaskText,
                                order: subIndex,
                                isHeader: false
                            )
                            subtask.parentTask = extractedTask
                            subtask.parentList = taskList
                            modelContext.insert(subtask)
                            subtaskObjects.append(subtask)
                        }
                        extractedTask.subtasks = subtaskObjects
                    }

                    // Add to task list
                    if taskList.tasks == nil {
                        taskList.tasks = []
                    }
                    taskList.tasks?.append(extractedTask)
                    modelContext.insert(extractedTask)
                }

                isScanningNextPage = false
                ReverieHaptics.completionFeedback()

                #if DEBUG
                print("TaskListEditorSheet: Added \(hierarchicalTasks.count) tasks from page \(nextPageIndex + 1)")
                #endif
            }
        }
    }

    /// Result of adding tasks to priority
    private struct AddToPriorityResult {
        var addedCount: Int = 0
        var duplicateCount: Int = 0
        var appendedToExistingCount: Int = 0
    }

    @discardableResult
    private func addToPriorityTasks(_ tasks: [ExtractedTask]) -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        var result = AddToPriorityResult()

        #if DEBUG
        print("addToPriorityTasks: Received \(tasks.count) tasks")
        for task in tasks {
            print("  - '\(task.text.prefix(40))...' isHeader=\(task.isHeader) subtasks=\(task.subtasks?.count ?? 0)")
        }
        #endif

        // Track which tasks we've already processed (to avoid duplicates)
        var processedTaskIds = Set<UUID>()

        // First pass: identify header tasks and their subtasks
        // Headers with subtasks become a single PriorityTask with SubTasks
        for task in tasks {
            // Skip if already processed
            guard !processedTaskIds.contains(task.id) else { continue }

            // Check if a PriorityTask with same source exists today (for appending subtasks)
            let existingTodayTask = existingPriorityTasks.first { priorityTask in
                priorityTask.sourceExtractedTaskId == task.id &&
                Calendar.current.isDate(priorityTask.startDate, inSameDayAs: today)
            }

            // Check if this is a header with subtasks
            if task.isHeader, let subtasks = task.subtasks, !subtasks.isEmpty {

                // Scenario 1: Parent already exists TODAY - append new subtasks to it
                if let existingTask = existingTodayTask {
                    let appendedCount = appendSubtasksToExistingTask(
                        existingTask: existingTask,
                        subtasks: subtasks,
                        selectedSubtaskIds: Set(tasks.map { $0.id }),
                        processedTaskIds: &processedTaskIds
                    )
                    result.appendedToExistingCount += appendedCount

                    if appendedCount == 0 {
                        // All subtasks were already added
                        result.duplicateCount += 1
                    }
                    processedTaskIds.insert(task.id)
                    continue
                }

                // Scenario 2: Parent exists on DIFFERENT day - create new parent + selected subtasks for today
                // Scenario 3: Parent doesn't exist at all - create new parent + selected subtasks
                let priorityTask = PriorityTask(
                    title: task.text,
                    startDate: today,
                    sourceExtractedTaskId: task.id,
                    sourceTaskListId: taskList.id
                )
                modelContext.insert(priorityTask)

                // Convert ExtractedTask subtasks to SubTask objects
                var subTaskObjects: [SubTask] = []
                for subtask in subtasks {
                    // Check if subtask is in the selected list OR include all subtasks of selected header
                    let subtaskSelected = tasks.contains { $0.id == subtask.id }

                    // Include subtask if it's selected, or if the parent header is selected
                    // (selecting a header should include all its subtasks)
                    if subtaskSelected || selectedTasks.contains(task.id) {
                        // Check if this subtask is already added (by sourceExtractedTaskId)
                        let subtaskAlreadyAdded = existingPriorityTasks.contains { pt in
                            pt.subTasks?.contains { $0.sourceExtractedTaskId == subtask.id } ?? false
                        }

                        guard !subtaskAlreadyAdded else {
                            processedTaskIds.insert(subtask.id)
                            continue
                        }

                        let subTask = SubTask(
                            title: subtask.text,
                            sourceExtractedTaskId: subtask.id
                        )
                        modelContext.insert(subTask)
                        subTaskObjects.append(subTask)

                        // Mark subtask as added and processed
                        subtask.addedToPriorityAt = Date()
                        processedTaskIds.insert(subtask.id)
                    }
                }

                // Attach subtasks to priority task
                if !subTaskObjects.isEmpty {
                    priorityTask.subTasks = subTaskObjects
                    #if DEBUG
                    print("addToPriorityTasks: Created PriorityTask '\(task.text.prefix(30))...' with \(subTaskObjects.count) subtasks")
                    #endif
                }

                // Mark header as added
                task.addedToPriorityAt = Date()
                processedTaskIds.insert(task.id)
                result.addedCount += 1

                // Update task list status to Active
                if taskList.status == .backlog {
                    taskList.status = .active
                }

            } else if task.parentTask == nil {
                // This is a standalone task (not a subtask of a header)

                // Check if already added (by sourceExtractedTaskId)
                let alreadyLinked = existingPriorityTasks.contains { priorityTask in
                    priorityTask.sourceExtractedTaskId == task.id &&
                    Calendar.current.isDate(priorityTask.startDate, inSameDayAs: today)
                }

                if alreadyLinked {
                    result.duplicateCount += 1
                    processedTaskIds.insert(task.id)
                    continue
                }

                // Create as individual priority task
                let priorityTask = PriorityTask(
                    title: task.text,
                    startDate: today,
                    sourceExtractedTaskId: task.id,
                    sourceTaskListId: taskList.id
                )
                modelContext.insert(priorityTask)

                // Mark as added
                task.addedToPriorityAt = Date()
                processedTaskIds.insert(task.id)
                result.addedCount += 1

                // Update task list status to Active
                if taskList.status == .backlog {
                    taskList.status = .active
                }
            }
            // Note: Subtasks that have a parent are handled above with their parent header
        }

        // Second pass: handle orphan subtasks (selected subtasks whose parent wasn't selected)
        for task in tasks {
            guard !processedTaskIds.contains(task.id) else { continue }

            // This is a subtask whose parent header wasn't selected
            // Check if parent exists today - if so, append to it
            if let parentTask = task.parentTask {
                let existingParent = existingPriorityTasks.first { priorityTask in
                    priorityTask.sourceExtractedTaskId == parentTask.id &&
                    Calendar.current.isDate(priorityTask.startDate, inSameDayAs: today)
                }

                if let existingParent = existingParent {
                    // Append this subtask to existing parent
                    let subtaskAlreadyExists = existingParent.subTasks?.contains {
                        $0.sourceExtractedTaskId == task.id
                    } ?? false

                    if !subtaskAlreadyExists {
                        let subTask = SubTask(
                            title: task.text,
                            sourceExtractedTaskId: task.id
                        )
                        modelContext.insert(subTask)

                        if existingParent.subTasks == nil {
                            existingParent.subTasks = []
                        }
                        existingParent.subTasks?.append(subTask)

                        task.addedToPriorityAt = Date()
                        result.appendedToExistingCount += 1
                    } else {
                        result.duplicateCount += 1
                    }
                    processedTaskIds.insert(task.id)
                    continue
                }

                // Parent doesn't exist today - create parent + this subtask
                let priorityTask = PriorityTask(
                    title: parentTask.text,
                    startDate: today,
                    sourceExtractedTaskId: parentTask.id,
                    sourceTaskListId: taskList.id
                )
                modelContext.insert(priorityTask)

                let subTask = SubTask(
                    title: task.text,
                    sourceExtractedTaskId: task.id
                )
                modelContext.insert(subTask)
                priorityTask.subTasks = [subTask]

                parentTask.addedToPriorityAt = Date()
                task.addedToPriorityAt = Date()
                processedTaskIds.insert(task.id)
                processedTaskIds.insert(parentTask.id)
                result.addedCount += 1

                // Update task list status to Active
                if taskList.status == .backlog {
                    taskList.status = .active
                }
            } else {
                // Orphan task with no parent - add as standalone
                let alreadyLinked = existingPriorityTasks.contains { priorityTask in
                    priorityTask.sourceExtractedTaskId == task.id &&
                    Calendar.current.isDate(priorityTask.startDate, inSameDayAs: today)
                }

                if alreadyLinked {
                    result.duplicateCount += 1
                    processedTaskIds.insert(task.id)
                    continue
                }

                let priorityTask = PriorityTask(
                    title: task.text,
                    startDate: today,
                    sourceExtractedTaskId: task.id,
                    sourceTaskListId: taskList.id
                )
                modelContext.insert(priorityTask)

                task.addedToPriorityAt = Date()
                processedTaskIds.insert(task.id)
                result.addedCount += 1

                // Update task list status to Active
                if taskList.status == .backlog {
                    taskList.status = .active
                }
            }
        }

        // Show duplicate alert if needed
        if result.duplicateCount > 0 && result.addedCount == 0 && result.appendedToExistingCount == 0 {
            duplicateMessage = result.duplicateCount == 1
                ? localization.localize("pdf.taskAlreadyAdded")
                : String(format: localization.localize("pdf.tasksAlreadyAdded"), result.duplicateCount)
            showDuplicateAlert = true
        }

        ReverieHaptics.completionFeedback()
        return result.addedCount + result.appendedToExistingCount
    }

    /// Append new subtasks to an existing PriorityTask
    private func appendSubtasksToExistingTask(
        existingTask: PriorityTask,
        subtasks: [ExtractedTask],
        selectedSubtaskIds: Set<UUID>,
        processedTaskIds: inout Set<UUID>
    ) -> Int {
        var appendedCount = 0

        for subtask in subtasks {
            // Only include if selected
            guard selectedSubtaskIds.contains(subtask.id) || selectedTasks.contains(subtask.id) else {
                continue
            }

            // Check if already exists
            let alreadyExists = existingTask.subTasks?.contains {
                $0.sourceExtractedTaskId == subtask.id
            } ?? false

            guard !alreadyExists else {
                processedTaskIds.insert(subtask.id)
                continue
            }

            let subTask = SubTask(
                title: subtask.text,
                sourceExtractedTaskId: subtask.id
            )
            modelContext.insert(subTask)

            if existingTask.subTasks == nil {
                existingTask.subTasks = []
            }
            existingTask.subTasks?.append(subTask)

            subtask.addedToPriorityAt = Date()
            processedTaskIds.insert(subtask.id)
            appendedCount += 1
        }

        return appendedCount
    }
}

// MARK: - Task Drag Preview

private struct TaskDragPreview: View {
    let task: ExtractedTask
    let colorScheme: ColorScheme

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: task.isHeader ? "folder.fill" : "doc.text")
                .font(.system(size: 14))
                .foregroundStyle(Color.sageGreen)

            Text(task.text)
                .font(.system(size: 13, weight: task.isHeader ? .semibold : .regular))
                .lineLimit(2)
                .foregroundStyle(Color.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(colorScheme == .dark ?
                      Color.black.opacity(0.9) :
                      Color.white.opacity(0.95))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.sageGreen.opacity(0.5), lineWidth: 1.5)
        )
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        .frame(maxWidth: 280)
    }
}

// MARK: - Task Row

private struct TaskRow: View {
    let task: ExtractedTask
    let isSelected: Bool
    let isEditing: Bool
    @Binding var editText: String
    let colorScheme: ColorScheme
    var isHeader: Bool = false
    var subtaskCount: Int = 0
    var isBeingDragged: Bool = false
    let onToggleComplete: () -> Void
    let onToggleSelect: () -> Void
    let onStartEdit: () -> Void
    let onSaveEdit: () -> Void
    let onCancelEdit: () -> Void
    let onDelete: () -> Void

    @State private var isDropTarget: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            // Selection checkbox
            Button(action: onToggleSelect) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? Color.sageGreen : Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.5))
            }
            .buttonStyle(.plain)

            // Completion checkbox (only for non-headers)
            if !isHeader {
                Button(action: onToggleComplete) {
                    Image(systemName: task.isCompleted ? "checkmark.square.fill" : "square")
                        .font(.system(size: 18))
                        .foregroundStyle(task.isCompleted ? Color.sageGreen : Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.6))
                }
                .buttonStyle(.plain)
            } else {
                // Header icon
                Image(systemName: "folder.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.sageGreen)
            }

            // Task text or edit field
            if isEditing {
                TextField(LocalizationManager.shared.localize("pdf.task.task"), text: $editText)
                    .font(.system(size: isHeader ? 15 : 14, weight: isHeader ? .semibold : .regular))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.12))
                    )

                Button(action: onSaveEdit) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.sageGreen)
                }

                Button(action: onCancelEdit) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme))
                }
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.text)
                        .font(.system(size: isHeader ? 15 : 14, weight: isHeader ? .semibold : .regular))
                        .strikethrough(task.isCompleted && !isHeader)
                        .foregroundStyle(task.isCompleted && !isHeader ?
                                         Color.timeAdaptiveSecondary(colorScheme: colorScheme) :
                                         Color.timeAdaptivePrimary(colorScheme: colorScheme))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Subtask progress for headers
                    if isHeader && subtaskCount > 0 {
                        let (completed, total) = task.subtaskProgress
                        Text("\(completed)/\(total) completed")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme))
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    onStartEdit()
                }

                // Added to priority indicator
                if task.isAddedToPriority {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.paleMauve)
                }

                // Delete button
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.5))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, isHeader ? 12 : 10)
        .background(
            RoundedRectangle(cornerRadius: isHeader ? 12 : 10)
                .fill(isSelected ?
                      Color.sageGreen.opacity(colorScheme == .dark ? 0.12 : 0.08) :
                      (isHeader ? Color.clear : Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.08)))
        )
        .overlay(
            RoundedRectangle(cornerRadius: isHeader ? 12 : 10)
                .strokeBorder(
                    isSelected ? Color.sageGreen.opacity(0.3) : Color.clear,
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Subtask List View

private struct SubtaskListView: View {
    let subtasks: [ExtractedTask]
    @Binding var selectedTasks: Set<UUID>
    @Binding var editingTaskId: UUID?
    @Binding var editText: String
    let colorScheme: ColorScheme
    @Binding var draggedTaskId: UUID?
    let onToggleComplete: (ExtractedTask) -> Void
    let onToggleSelect: (ExtractedTask) -> Void
    let onStartEdit: (ExtractedTask) -> Void
    let onSaveEdit: (ExtractedTask) -> Void
    let onCancelEdit: () -> Void
    let onDelete: (ExtractedTask) -> Void
    let onMakeSubtaskOfParent: (ExtractedTask, ExtractedTask) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(subtasks) { subtask in
                SubtaskRow(
                    subtask: subtask,
                    isSelected: selectedTasks.contains(subtask.id),
                    isEditing: editingTaskId == subtask.id,
                    editText: $editText,
                    colorScheme: colorScheme,
                    onToggleComplete: { onToggleComplete(subtask) },
                    onToggleSelect: { onToggleSelect(subtask) },
                    onStartEdit: { onStartEdit(subtask) },
                    onSaveEdit: { onSaveEdit(subtask) },
                    onCancelEdit: onCancelEdit,
                    onDelete: { onDelete(subtask) }
                )
                .draggable(subtask.id.uuidString) {
                    // Drag preview for subtask
                    TaskDragPreview(task: subtask, colorScheme: colorScheme)
                }
            }
        }
        .padding(.bottom, 8)
    }
}

// MARK: - Subtask Row (extracted for drag support)

private struct SubtaskRow: View {
    let subtask: ExtractedTask
    let isSelected: Bool
    let isEditing: Bool
    @Binding var editText: String
    let colorScheme: ColorScheme
    let onToggleComplete: () -> Void
    let onToggleSelect: () -> Void
    let onStartEdit: () -> Void
    let onSaveEdit: () -> Void
    let onCancelEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            // Indent line
            Rectangle()
                .fill(Color.sageGreen.opacity(0.3))
                .frame(width: 2)
                .padding(.leading, 20)

            // Selection checkbox
            Button(action: onToggleSelect) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundStyle(isSelected ? Color.sageGreen : Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.5))
            }
            .buttonStyle(.plain)

            // Completion checkbox
            Button(action: onToggleComplete) {
                Image(systemName: subtask.isCompleted ? "checkmark.square.fill" : "square")
                    .font(.system(size: 16))
                    .foregroundStyle(subtask.isCompleted ? Color.sageGreen : Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.6))
            }
            .buttonStyle(.plain)

            // Subtask text
            if isEditing {
                TextField("", text: $editText)
                    .font(.system(size: 13))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.12))
                    )

                Button(action: onSaveEdit) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.sageGreen)
                }

                Button(action: onCancelEdit) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme))
                }
            } else {
                Text(subtask.text)
                    .font(.system(size: 13))
                    .strikethrough(subtask.isCompleted)
                    .foregroundStyle(subtask.isCompleted ? Color.timeAdaptiveSecondary(colorScheme: colorScheme) : Color.timeAdaptivePrimary(colorScheme: colorScheme).opacity(0.85))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onStartEdit()
                    }

                if subtask.isAddedToPriority {
                    Image(systemName: "star.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(Color.paleMauve)
                }

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.4))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            isSelected ?
            Color.sageGreen.opacity(colorScheme == .dark ? 0.08 : 0.05) :
            Color.clear
        )
    }
}

// MARK: - Add to Priority Sheet

private struct AddToPrioritySheet: View {
    let selectedTasks: [ExtractedTask]
    let onAdd: ([ExtractedTask]) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var localization = LocalizationManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                ReverieWeaverBackground()

                VStack(spacing: 20) {
                    // Preview
                    VStack(alignment: .leading, spacing: 12) {
                        Text(localization.localize("pdf.addToToday"))
                            .font(.system(size: 14, weight: .semibold))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

                        Text(String(format: localization.localize("pdf.tasksWillBeAdded"), selectedTasks.count))
                            .font(.system(size: 13))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)

                        Divider()

                        ForEach(selectedTasks.prefix(5)) { task in
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.sageGreen)

                                Text(task.text)
                                    .font(.system(size: 13))
                                    .lineLimit(1)
                            }
                        }

                        if selectedTasks.count > 5 {
                            Text(String(format: localization.localize("pdf.andMore"), selectedTasks.count - 5))
                                .font(.system(size: 12))
                                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .dark ?
                                  Color.white.opacity(0.04) :
                                  Color.white.opacity(0.6))
                    )

                    Spacer()

                    // Action buttons
                    HStack(spacing: 12) {
                        Button {
                            dismiss()
                        } label: {
                            Text(localization.localize("common.cancel"))
                                .font(.system(size: 14, weight: .medium))
                                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(colorScheme == .dark ? 0.12 : 0.08))
                                )
                        }
                        .buttonStyle(.plain)

                        Button {
                            onAdd(selectedTasks)
                            dismiss()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus.circle.fill")
                                Text(localization.localize("pdf.addToTodayButton"))
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.sageGreen)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - PDF Selection For Append View

/// A view that allows users to select an area from the PDF and extract tasks to append to an existing task list
struct PDFSelectionForAppendView: View {
    let pdf: ImportedPDF
    let onTasksExtracted: ([PDFTodoExtractor.HierarchicalTask]) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var localization = LocalizationManager.shared

    @State private var selectedPageIndex: Int = 0
    @State private var showSelectionView = false

    var body: some View {
        NavigationStack {
            ZStack {
                ReverieWeaverBackground()

                VStack(spacing: 0) {
                    // Header info
                    VStack(spacing: 8) {
                        Image(systemName: "rectangle.dashed.and.paperclip")
                            .font(.system(size: 28))
                            .foregroundStyle(Color.dustyBlue)

                        Text(localization.localize("pdf.selectFromPDF"))
                            .font(.system(size: 16, weight: .semibold))
                            .fontDesign(.serif)

                        Text(localization.localize("pdf.selectFromPDF.hint"))
                            .font(.system(size: 13))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
                    .background(Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.08))

                    // Page grid
                    if let pdfURL = pdf.fileURL {
                        ScrollView {
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ], spacing: 12) {
                                ForEach(0..<pdf.pageCount, id: \.self) { pageIndex in
                                    PageThumbnailButton(
                                        pdfURL: pdfURL,
                                        pageIndex: pageIndex,
                                        colorScheme: colorScheme,
                                        onSelect: {
                                            selectedPageIndex = pageIndex
                                            showSelectionView = true
                                        }
                                    )
                                }
                            }
                            .padding(16)
                        }
                    } else {
                        // No PDF available
                        VStack(spacing: 12) {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.5))

                            Text(localization.localize("pdf.unableToLoadPDF"))
                                .font(.system(size: 14))
                                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(localization.localize("common.cancel")) {
                        dismiss()
                    }
                    .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme))
                }

                ToolbarItem(placement: .principal) {
                    Text(pdf.fileName)
                        .font(.system(size: 14, weight: .medium))
                        .lineLimit(1)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                }
            }
            .sheet(isPresented: $showSelectionView) {
                PDFSelectionForAppendDetailView(
                    pdf: pdf,
                    pageIndex: selectedPageIndex,
                    onComplete: { tasks in
                        onTasksExtracted(tasks)
                        dismiss()
                    }
                )
            }
        }
    }
}

// MARK: - Page Thumbnail Button

private struct PageThumbnailButton: View {
    let pdfURL: URL
    let pageIndex: Int
    let colorScheme: ColorScheme
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                // PDF page thumbnail
                PDFPageView(pdfURL: pdfURL, pageIndex: pageIndex)
                    .frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.25), lineWidth: 0.5)
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

                // Page number
                Text(String(format: LocalizationManager.shared.localize("pdf.pageNumber"), pageIndex + 1))
                    .font(.system(size: 11))
                    .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme))
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - PDF Selection For Append Detail View

private struct PDFSelectionForAppendDetailView: View {
    let pdf: ImportedPDF
    let pageIndex: Int
    let onComplete: ([PDFTodoExtractor.HierarchicalTask]) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var localization = LocalizationManager.shared

    @State private var selectionRect: CGRect?
    @State private var dragStart: CGPoint?
    @State private var dragCurrent: CGPoint?
    @State private var pageSize: CGSize = .zero
    @State private var renderedPDFFrame: CGRect = .zero
    @State private var isExtracting = false
    @State private var showPreview = false
    @State private var previewTasks: [PDFTodoExtractor.HierarchicalTask] = []
    @State private var isFullPageExtraction = false

    var body: some View {
        NavigationStack {
            ZStack {
                ReverieWeaverBackground()

                VStack(spacing: 0) {
                    // Instructions
                    instructionBar

                    // PDF Page with selection overlay
                    GeometryReader { geometry in
                        ZStack {
                            PDFPageView(pdfURL: pdf.fileURL, pageIndex: pageIndex)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                                .allowsHitTesting(false)

                            Color.clear
                                .contentShape(Rectangle())
                                .gesture(dragGesture)

                            if let rect = currentSelectionRect {
                                SelectionRectangleView(rect: rect, colorScheme: colorScheme)
                                    .allowsHitTesting(false)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onAppear {
                            calculatePageSize()
                            updateRenderedPDFFrame(for: geometry.size)
                        }
                        .onChange(of: geometry.size) { _, newSize in
                            updateRenderedPDFFrame(for: newSize)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    // Bottom actions
                    actionBar
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(localization.localize("common.cancel")) {
                        dismiss()
                    }
                    .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme))
                }

                ToolbarItem(placement: .principal) {
                    Text(localization.localize("pdf.selectArea"))
                        .font(.system(size: 16, weight: .semibold))
                        .fontDesign(.serif)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if selectionRect != nil {
                        Button {
                            selectionRect = nil
                        } label: {
                            Text(localization.localize("common.clear"))
                                .font(.system(size: 14))
                                .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme))
                        }
                    }
                }
            }
            .sheet(isPresented: $showPreview) {
                AppendPreviewSheet(
                    previewTasks: $previewTasks,
                    onSave: {
                        onComplete(previewTasks)
                        dismiss()
                    },
                    onCancel: {
                        previewTasks = []
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    private var currentSelectionRect: CGRect? {
        if let rect = selectionRect { return rect }
        guard let start = dragStart, let current = dragCurrent else { return nil }
        let minX = min(start.x, current.x)
        let minY = min(start.y, current.y)
        let width = abs(current.x - start.x)
        let height = abs(current.y - start.y)
        return CGRect(x: minX, y: minY, width: width, height: height)
    }

    private var instructionBar: some View {
        HStack(spacing: 10) {
            Image(systemName: selectionRect == nil ? "rectangle.dashed" : "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(selectionRect == nil ? Color.timeAdaptiveSecondary(colorScheme: colorScheme) : Color.sageGreen)

            Text(selectionRect == nil ?
                 localization.localize("pdf.drawRectangle") :
                 localization.localize("pdf.selectionReady"))
                .font(.system(size: 12))
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.1))
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                if dragStart == nil { dragStart = value.startLocation }
                dragCurrent = value.location
            }
            .onEnded { value in
                if let start = dragStart {
                    let minX = min(start.x, value.location.x)
                    let minY = min(start.y, value.location.y)
                    let width = abs(value.location.x - start.x)
                    let height = abs(value.location.y - start.y)
                    if width > 30 && height > 30 {
                        selectionRect = CGRect(x: minX, y: minY, width: width, height: height)
                        ReverieHaptics.lightFeedback()
                    }
                }
                dragStart = nil
                dragCurrent = nil
            }
    }

    private var actionBar: some View {
        HStack(spacing: 12) {
            Button {
                isFullPageExtraction = true
                extractAndShowPreview(fullPage: true)
            } label: {
                HStack(spacing: 6) {
                    if isExtracting && isFullPageExtraction {
                        ProgressView().scaleEffect(0.8)
                    } else {
                        Image(systemName: "doc.text").font(.system(size: 14))
                    }
                    Text(localization.localize("pdf.fullPage"))
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.15))
                )
            }
            .buttonStyle(.plain)
            .disabled(isExtracting)

            Button {
                isFullPageExtraction = false
                extractAndShowPreview(fullPage: false)
            } label: {
                HStack(spacing: 6) {
                    if isExtracting && !isFullPageExtraction {
                        ProgressView().scaleEffect(0.8).tint(.white)
                    } else {
                        Image(systemName: "text.viewfinder").font(.system(size: 14))
                    }
                    Text(localization.localize("pdf.extractSelected"))
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(selectionRect != nil ? Color.white : Color.sageGreen.opacity(0.5))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(selectionRect != nil ?
                              Color.sageGreen :
                              Color.sageGreen.opacity(colorScheme == .dark ? 0.15 : 0.1))
                )
            }
            .buttonStyle(.plain)
            .disabled(selectionRect == nil || isExtracting)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.08))
    }

    private func extractAndShowPreview(fullPage: Bool) {
        guard let pdfURL = pdf.fileURL else { return }

        isExtracting = true

        var pdfRect: CGRect? = nil
        if !fullPage, let selection = selectionRect, pageSize != .zero {
            pdfRect = convertToPDFCoordinates(selection)
        }

        Task {
            let hierarchicalTasks = PDFTodoExtractor.shared.extractHierarchicalTodos(
                from: pdfURL,
                pageIndex: pageIndex,
                selectionRect: fullPage ? nil : pdfRect
            )

            await MainActor.run {
                previewTasks = hierarchicalTasks
                isExtracting = false
                showPreview = true
                ReverieHaptics.lightFeedback()
            }
        }
    }

    private func convertToPDFCoordinates(_ viewRect: CGRect) -> CGRect {
        guard let pdfURL = pdf.fileURL,
              let document = PDFDocument(url: pdfURL),
              let page = document.page(at: pageIndex) else {
            return viewRect
        }

        let pageBounds = page.bounds(for: .mediaBox)

        guard renderedPDFFrame.width > 0 && renderedPDFFrame.height > 0 else {
            let scaleX = pageBounds.width / pageSize.width
            let scaleY = pageBounds.height / pageSize.height
            return CGRect(
                x: viewRect.origin.x * scaleX,
                y: (pageSize.height - viewRect.origin.y - viewRect.height) * scaleY,
                width: viewRect.width * scaleX,
                height: viewRect.height * scaleY
            )
        }

        let clippedRect = viewRect.intersection(renderedPDFFrame)
        guard clippedRect.width > 0 && clippedRect.height > 0 else { return .zero }

        let relativeX = clippedRect.origin.x - renderedPDFFrame.origin.x
        let relativeY = clippedRect.origin.y - renderedPDFFrame.origin.y
        let scaleX = pageBounds.width / renderedPDFFrame.width
        let scaleY = pageBounds.height / renderedPDFFrame.height

        return CGRect(
            x: relativeX * scaleX,
            y: (renderedPDFFrame.height - relativeY - clippedRect.height) * scaleY,
            width: clippedRect.width * scaleX,
            height: clippedRect.height * scaleY
        )
    }

    private func updateRenderedPDFFrame(for geometrySize: CGSize) {
        guard pageSize.width > 0 && pageSize.height > 0 else { return }

        let pdfAspect = pageSize.width / pageSize.height
        let viewAspect = geometrySize.width / geometrySize.height

        var renderedWidth: CGFloat
        var renderedHeight: CGFloat

        if pdfAspect > viewAspect {
            renderedWidth = geometrySize.width
            renderedHeight = geometrySize.width / pdfAspect
        } else {
            renderedHeight = geometrySize.height
            renderedWidth = geometrySize.height * pdfAspect
        }

        let originX = (geometrySize.width - renderedWidth) / 2
        let originY = (geometrySize.height - renderedHeight) / 2

        renderedPDFFrame = CGRect(x: originX, y: originY, width: renderedWidth, height: renderedHeight)
    }

    private func calculatePageSize() {
        guard let pdfURL = pdf.fileURL,
              let document = PDFDocument(url: pdfURL),
              let page = document.page(at: pageIndex) else { return }

        let bounds = page.bounds(for: .mediaBox)
        pageSize = CGSize(width: bounds.width, height: bounds.height)
    }
}

// MARK: - Selection Rectangle View (for append)

private struct SelectionRectangleView: View {
    let rect: CGRect
    let colorScheme: ColorScheme

    var body: some View {
        Rectangle()
            .fill(Color.sageGreen.opacity(0.15))
            .frame(width: rect.width, height: rect.height)
            .overlay(
                Rectangle()
                    .strokeBorder(
                        Color.sageGreen,
                        style: StrokeStyle(lineWidth: 2, dash: [6, 4])
                    )
            )
            .position(x: rect.midX, y: rect.midY)
    }
}

// MARK: - Append Preview Sheet

private struct AppendPreviewSheet: View {
    @Binding var previewTasks: [PDFTodoExtractor.HierarchicalTask]
    let onSave: () -> Void
    let onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var localization = LocalizationManager.shared

    private var totalTaskCount: Int {
        previewTasks.reduce(0) { $0 + 1 + $1.subtasks.count }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: previewTasks.isEmpty ? "exclamationmark.circle" : "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(previewTasks.isEmpty ? Color.orange : Color.sageGreen)

                        Text(previewTasks.isEmpty ?
                             localization.localize("pdf.preview.noTasksFound") :
                             String(format: localization.localize("pdf.preview.tasksFound"), totalTaskCount))
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(previewTasks.isEmpty ? Color.orange : Color.timeAdaptivePrimary(colorScheme: colorScheme))
                    }
                    .padding(.vertical, 12)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.1))

                if previewTasks.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.5))
                        Text(localization.localize("pdf.preview.noTasksMessage"))
                            .font(.system(size: 14))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        Spacer()

                        Button {
                            onCancel()
                            dismiss()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.counterclockwise")
                                Text(localization.localize("pdf.preview.tryAgain"))
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.sageGreen)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.sageGreen.opacity(colorScheme == .dark ? 0.15 : 0.1))
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                } else {
                    // Task list
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(Array(previewTasks.enumerated()), id: \.offset) { index, task in
                                AppendTaskPreviewCard(
                                    task: task,
                                    colorScheme: colorScheme,
                                    onDelete: {
                                        withAnimation(.snappy) {
                                            _ = previewTasks.remove(at: index)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(16)
                    }

                    // Add button
                    Button {
                        onSave()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                            Text(localization.localize("pdf.addToList"))
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.sageGreen)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .background(ReverieWeaverBackground())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(localization.localize("common.cancel")) {
                        onCancel()
                        dismiss()
                    }
                    .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme))
                }

                ToolbarItem(placement: .principal) {
                    Text(localization.localize("pdf.preview.title"))
                        .font(.system(size: 16, weight: .semibold))
                        .fontDesign(.serif)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                }
            }
        }
    }
}

// MARK: - Append Task Preview Card

private struct AppendTaskPreviewCard: View {
    let task: PDFTodoExtractor.HierarchicalTask
    let colorScheme: ColorScheme
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: task.isHeader ? "folder.fill" : "circle.fill")
                .font(.system(size: task.isHeader ? 14 : 6))
                .foregroundStyle(task.isHeader ? Color.sageGreen : Color.timeAdaptiveSecondary(colorScheme: colorScheme))

            VStack(alignment: .leading, spacing: 4) {
                Text(task.text)
                    .font(.system(size: task.isHeader ? 14 : 13, weight: task.isHeader ? .semibold : .regular))
                    .foregroundStyle(Color.timeAdaptivePrimary(colorScheme: colorScheme))

                if task.isHeader && !task.subtasks.isEmpty {
                    Text("\(task.subtasks.count) \(LocalizationManager.shared.localize("pdf.preview.subtasks"))")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.4))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .reverieCardStyle(colorScheme: colorScheme)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(
                    task.isHeader ? Color.sageGreen.opacity(0.3) : Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.15),
                    lineWidth: task.isHeader ? 1 : 0.5
                )
        )
    }
}

// MARK: - Task Added Confirmation Toast

private struct TaskAddedConfirmationToast: View {
    let taskCount: Int
    let colorScheme: ColorScheme

    @ObservedObject private var localization = LocalizationManager.shared

    var body: some View {
        HStack(spacing: 12) {
            // Success checkmark icon
            ZStack {
                Circle()
                    .fill(Color.sageGreen.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.sageGreen)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(localization.localize("pdf.addedToToday.title"))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.primary)

                Text(String(format: localization.localize("pdf.addedToToday.message"), taskCount))
                    .font(.system(size: 12))
                    .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme))
            }

            Spacer()

            // Small loom icon to indicate destination
            Image(systemName: "sparkles")
                .font(.system(size: 16))
                .foregroundStyle(Color.sageGreen.opacity(0.6))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(colorScheme == .dark ?
                      Color(.systemGray6) :
                      Color.white)
                .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.sageGreen.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }
}
