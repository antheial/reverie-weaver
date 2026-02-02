//
//  PDFSelectionView.swift
//  Reverie Weaver
//
//  View for selecting an area on a PDF page to extract todos
//

import SwiftUI
import SwiftData
import PDFKit

struct PDFSelectionView: View {
    let pdf: ImportedPDF
    let pageIndex: Int
    let onComplete: (PDFTaskList) -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var localization = LocalizationManager.shared

    @State private var selectionRect: CGRect?
    @State private var dragStart: CGPoint?
    @State private var dragCurrent: CGPoint?
    @State private var pageSize: CGSize = .zero           // PDF page's actual mediaBox dimensions
    @State private var renderedPDFFrame: CGRect = .zero   // The frame where the PDF is actually rendered in the view
    @State private var listName: String = ""
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
                            // PDF Page (user interaction disabled to allow gesture passthrough)
                            PDFPageView(
                                pdfURL: pdf.fileURL,
                                pageIndex: pageIndex
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                            .allowsHitTesting(false) // Ensure touches pass through

                            // Transparent gesture capture layer
                            Color.clear
                                .contentShape(Rectangle())
                                .gesture(dragGesture)

                            // Current selection rectangle (drawn on top)
                            if let rect = currentSelectionRect {
                                SelectionRectangle(rect: rect, colorScheme: colorScheme)
                                    .allowsHitTesting(false) // Don't block gestures
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onAppear {
                            // Calculate page size on appear to avoid state modification during view update
                            calculatePageSize()
                            // Calculate the actual rendered PDF frame within this geometry
                            updateRenderedPDFFrame(for: geometry.size)
                        }
                        .onChange(of: geometry.size) { _, newSize in
                            // Update rendered frame when geometry changes
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
                HierarchicalPreviewSheet(
                    previewTasks: $previewTasks,
                    listName: $listName,
                    pageIndex: pageIndex,
                    isFullPage: isFullPageExtraction,
                    onSave: {
                        createTaskListFromHierarchicalPreview()
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

    // MARK: - Current Selection Rect

    private var currentSelectionRect: CGRect? {
        if let rect = selectionRect {
            return rect
        }

        guard let start = dragStart, let current = dragCurrent else {
            return nil
        }

        let minX = min(start.x, current.x)
        let minY = min(start.y, current.y)
        let width = abs(current.x - start.x)
        let height = abs(current.y - start.y)

        return CGRect(x: minX, y: minY, width: width, height: height)
    }

    // MARK: - Instruction Bar

    private var instructionBar: some View {
        HStack(spacing: 10) {
            Image(systemName: selectionRect == nil ? "rectangle.dashed" : "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(selectionRect == nil ? Color.timeAdaptiveSecondary(colorScheme: colorScheme) : Color.sageGreen)

            Text(selectionRect == nil ?
                 localization.localize("pdf.drawRectangle") :
                 localization.localize("pdf.selectionReady"))
                .font(.system(size: 12))
                .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme))

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .reverieCardStyle(colorScheme: colorScheme)
    }

    // MARK: - Drag Gesture

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                if dragStart == nil {
                    dragStart = value.startLocation
                }
                dragCurrent = value.location
            }
            .onEnded { value in
                if let start = dragStart {
                    let minX = min(start.x, value.location.x)
                    let minY = min(start.y, value.location.y)
                    let width = abs(value.location.x - start.x)
                    let height = abs(value.location.y - start.y)

                    // Only save if selection is large enough
                    if width > 30 && height > 30 {
                        selectionRect = CGRect(x: minX, y: minY, width: width, height: height)
                        ReverieHaptics.lightFeedback()
                    }
                }

                dragStart = nil
                dragCurrent = nil
            }
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        HStack(spacing: 12) {
            // Full Page button
            Button {
                isFullPageExtraction = true
                listName = String(format: localization.localize("pdf.pageNumber"), pageIndex + 1)
                extractAndShowPreview(fullPage: true)
            } label: {
                HStack(spacing: 6) {
                    if isExtracting && isFullPageExtraction {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "doc.text")
                            .font(.system(size: 14))
                    }

                    Text(localization.localize("pdf.fullPage"))
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(colorScheme == .dark ? 0.12 : 0.08))
                )
            }
            .buttonStyle(.plain)
            .disabled(isExtracting)

            // Extract Selected button
            Button {
                isFullPageExtraction = false
                listName = String(format: localization.localize("pdf.pageNumber"), pageIndex + 1) + " Selection"
                extractAndShowPreview(fullPage: false)
            } label: {
                HStack(spacing: 6) {
                    if isExtracting && !isFullPageExtraction {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Image(systemName: "text.viewfinder")
                            .font(.system(size: 14))
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
        .reverieCardStyle(colorScheme: colorScheme)
    }

    // MARK: - Extract and Show Preview

    private func extractAndShowPreview(fullPage: Bool) {
        guard let pdfURL = pdf.fileURL else {
            #if DEBUG
            print("PDFSelectionView: No PDF URL available")
            #endif
            return
        }

        #if DEBUG
        print("PDFSelectionView: Starting extraction for preview")
        print("  - PDF URL: \(pdfURL)")
        print("  - Page index: \(pageIndex)")
        print("  - Full page: \(fullPage)")
        print("  - Selection rect (view coords): \(String(describing: selectionRect))")
        print("  - Page size (PDF dimensions): \(pageSize)")
        print("  - Rendered PDF frame: \(renderedPDFFrame)")
        #endif

        isExtracting = true

        // Convert selection rect to PDF coordinates if needed
        var pdfRect: CGRect? = nil
        if !fullPage, let selection = selectionRect, pageSize != .zero {
            pdfRect = convertToPDFCoordinates(selection)
            #if DEBUG
            print("  - Converted PDF rect: \(pdfRect!)")
            #endif
        }

        // Perform extraction on background thread to avoid UI freeze
        Task {
            let hierarchicalTasks = PDFTodoExtractor.shared.extractHierarchicalTodos(
                from: pdfURL,
                pageIndex: pageIndex,
                selectionRect: fullPage ? nil : pdfRect
            )

            await MainActor.run {
                #if DEBUG
                let totalTasks = hierarchicalTasks.reduce(0) { $0 + 1 + $1.subtasks.count }
                print("PDFSelectionView: Extracted \(hierarchicalTasks.count) items (\(totalTasks) total tasks) for preview")
                #endif

                previewTasks = hierarchicalTasks
                isExtracting = false
                showPreview = true
                ReverieHaptics.lightFeedback()
            }
        }
    }

    // MARK: - Create Task List from Hierarchical Preview

    private func createTaskListFromHierarchicalPreview() {
        guard !previewTasks.isEmpty else { return }

        // Convert selection rect to PDF coordinates if needed
        var pdfRect: CGRect? = nil
        if !isFullPageExtraction, let selection = selectionRect, pageSize != .zero {
            pdfRect = convertToPDFCoordinates(selection)
        }

        // Create task list
        let taskList = PDFTaskList(
            name: listName.isEmpty ? "Page \(pageIndex + 1)" : listName,
            pageNumber: pageIndex,
            extractionRect: pdfRect,
            status: .backlog
        )

        // Create extracted tasks from hierarchical preview
        var createdTasks: [ExtractedTask] = []
        var allTasks: [ExtractedTask] = []
        var orderIndex = 0

        for hierarchicalTask in previewTasks {
            // Create the main task (header or standalone)
            let mainTask = ExtractedTask(
                text: hierarchicalTask.text,
                order: orderIndex,
                isHeader: hierarchicalTask.isHeader
            )
            mainTask.parentList = taskList
            createdTasks.append(mainTask)
            allTasks.append(mainTask)
            orderIndex += 1

            // Create subtasks if this is a header
            if hierarchicalTask.isHeader && !hierarchicalTask.subtasks.isEmpty {
                var subtaskList: [ExtractedTask] = []
                for subtaskText in hierarchicalTask.subtasks {
                    let subtask = ExtractedTask(
                        text: subtaskText,
                        order: orderIndex,
                        isHeader: false
                    )
                    subtask.parentList = taskList
                    subtask.parentTask = mainTask
                    subtaskList.append(subtask)
                    allTasks.append(subtask)
                    orderIndex += 1
                }
                mainTask.subtasks = subtaskList
            }
        }

        taskList.tasks = createdTasks  // Only top-level tasks in the main list

        // Link to PDF
        taskList.parentPDF = pdf
        if pdf.taskLists == nil {
            pdf.taskLists = []
        }
        pdf.taskLists?.append(taskList)

        // Save - insert taskList first, then all tasks (including subtasks)
        modelContext.insert(taskList)
        for task in allTasks {
            modelContext.insert(task)
        }

        #if DEBUG
        let totalCount = allTasks.count
        print("PDFSelectionView: Created task list '\(taskList.name)' with \(createdTasks.count) top-level tasks (\(totalCount) total)")
        #endif

        // Clear preview and complete
        previewTasks = []
        onComplete(taskList)
    }

    private func convertToPDFCoordinates(_ viewRect: CGRect) -> CGRect {
        // Convert from view coordinates (where user drew selection) to PDF page coordinates
        // The PDF is rendered with .aspectRatio(contentMode: .fit), so we need to account for
        // the actual rendered position within the view
        guard let pdfURL = pdf.fileURL,
              let document = PDFDocument(url: pdfURL),
              let page = document.page(at: pageIndex) else {
            return viewRect
        }

        let pageBounds = page.bounds(for: .mediaBox)

        // If we don't have a valid rendered frame, fall back to simple scaling
        guard renderedPDFFrame.width > 0 && renderedPDFFrame.height > 0 else {
            #if DEBUG
            print("convertToPDFCoordinates: Invalid renderedPDFFrame, using fallback")
            #endif
            let scaleX = pageBounds.width / pageSize.width
            let scaleY = pageBounds.height / pageSize.height
            return CGRect(
                x: viewRect.origin.x * scaleX,
                y: (pageSize.height - viewRect.origin.y - viewRect.height) * scaleY,
                width: viewRect.width * scaleX,
                height: viewRect.height * scaleY
            )
        }

        // Step 1: Clip the selection rect to the rendered PDF frame
        let clippedRect = viewRect.intersection(renderedPDFFrame)

        // If selection doesn't intersect with PDF, return empty
        guard clippedRect.width > 0 && clippedRect.height > 0 else {
            #if DEBUG
            print("convertToPDFCoordinates: Selection doesn't intersect with PDF frame")
            #endif
            return .zero
        }

        // Step 2: Convert view coordinates to coordinates relative to the rendered PDF frame
        let relativeX = clippedRect.origin.x - renderedPDFFrame.origin.x
        let relativeY = clippedRect.origin.y - renderedPDFFrame.origin.y

        // Step 3: Calculate scale from rendered frame to actual PDF dimensions
        let scaleX = pageBounds.width / renderedPDFFrame.width
        let scaleY = pageBounds.height / renderedPDFFrame.height

        // Step 4: Convert to PDF coordinates (flip Y axis for PDF coordinate system)
        let pdfX = relativeX * scaleX
        let pdfY = (renderedPDFFrame.height - relativeY - clippedRect.height) * scaleY
        let pdfWidth = clippedRect.width * scaleX
        let pdfHeight = clippedRect.height * scaleY

        #if DEBUG
        print("convertToPDFCoordinates:")
        print("  - View selection: \(viewRect)")
        print("  - Rendered PDF frame: \(renderedPDFFrame)")
        print("  - Clipped rect: \(clippedRect)")
        print("  - Relative position: (\(relativeX), \(relativeY))")
        print("  - Scale: (\(scaleX), \(scaleY))")
        print("  - PDF result: (\(pdfX), \(pdfY), \(pdfWidth), \(pdfHeight))")
        #endif

        return CGRect(x: pdfX, y: pdfY, width: pdfWidth, height: pdfHeight)
    }

    /// Calculate the actual rendered frame of the PDF within the view
    /// Since PDFPageView uses .aspectRatio(contentMode: .fit), the PDF may not fill the entire geometry
    private func updateRenderedPDFFrame(for geometrySize: CGSize) {
        guard pageSize.width > 0 && pageSize.height > 0 else { return }

        // Calculate the aspect ratios
        let pdfAspect = pageSize.width / pageSize.height
        let viewAspect = geometrySize.width / geometrySize.height

        var renderedWidth: CGFloat
        var renderedHeight: CGFloat

        if pdfAspect > viewAspect {
            // PDF is wider than view - constrained by width
            renderedWidth = geometrySize.width
            renderedHeight = geometrySize.width / pdfAspect
        } else {
            // PDF is taller than view - constrained by height
            renderedHeight = geometrySize.height
            renderedWidth = geometrySize.height * pdfAspect
        }

        // Center the PDF in the view (this is what .fit does)
        let originX = (geometrySize.width - renderedWidth) / 2
        let originY = (geometrySize.height - renderedHeight) / 2

        let newFrame = CGRect(x: originX, y: originY, width: renderedWidth, height: renderedHeight)

        if renderedPDFFrame != newFrame {
            renderedPDFFrame = newFrame
            #if DEBUG
            print("Updated renderedPDFFrame: \(newFrame) for geometry: \(geometrySize), pageSize: \(pageSize)")
            #endif
        }
    }

    /// Calculate page size from PDF directly - called from onAppear to avoid
    /// modifying state during view update in UIViewRepresentable
    private func calculatePageSize() {
        guard let pdfURL = pdf.fileURL,
              let document = PDFDocument(url: pdfURL),
              let page = document.page(at: pageIndex) else {
            return
        }

        let bounds = page.bounds(for: .mediaBox)
        let newSize = CGSize(width: bounds.width, height: bounds.height)

        if pageSize != newSize {
            pageSize = newSize
        }
    }
}

// MARK: - Selection Rectangle View

private struct SelectionRectangle: View {
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
            .position(
                x: rect.midX,
                y: rect.midY
            )
    }
}

// MARK: - PDF Page View

/// Pure SwiftUI PDF page view that renders PDF as an image
/// This avoids all UIViewRepresentable state modification warnings
struct PDFPageView: View {
    let pdfURL: URL?
    let pageIndex: Int

    var body: some View {
        PDFPageImageLoader(pdfURL: pdfURL, pageIndex: pageIndex)
    }
}

/// Internal view that handles async image loading without state modification warnings
/// Uses a separate struct to isolate the state management
private struct PDFPageImageLoader: View {
    let pdfURL: URL?
    let pageIndex: Int

    @State private var pageImage: UIImage?
    @State private var loadState: LoadState = .idle

    private enum LoadState {
        case idle
        case loading
        case loaded
        case failed
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                switch loadState {
                case .idle, .loading:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .loaded:
                    if let image = pageImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                case .failed:
                    VStack(spacing: 8) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(Color.gray.opacity(0.5))
                        Text(LocalizationManager.shared.localize("pdf.unableToLoadPage"))
                            .font(.system(size: 12))
                            .foregroundStyle(Color.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .onAppear {
                // Start loading when view appears, not during body evaluation
                if loadState == .idle {
                    Task {
                        await loadPageImage(targetWidth: geometry.size.width)
                    }
                }
            }
            .onChange(of: pdfURL) { _, _ in
                // Reload if URL changes
                Task {
                    await loadPageImage(targetWidth: geometry.size.width)
                }
            }
        }
    }

    /// Render PDF page to UIImage on background thread
    @MainActor
    private func loadPageImage(targetWidth: CGFloat) async {
        loadState = .loading

        guard let url = pdfURL else {
            loadState = .failed
            return
        }

        // Capture values for detached task
        let pageIdx = pageIndex
        let width = max(targetWidth, 300)

        // Render on background thread (completely detached from main actor)
        let image: UIImage? = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = Self.renderPDFPage(url: url, pageIndex: pageIdx, targetWidth: width)
                continuation.resume(returning: result)
            }
        }

        // Update state
        if let image = image {
            self.pageImage = image
            self.loadState = .loaded
        } else {
            self.loadState = .failed
        }
    }

    /// Render a PDF page to UIImage (thread-safe, static to avoid actor issues)
    private static func renderPDFPage(url: URL, pageIndex: Int, targetWidth: CGFloat) -> UIImage? {
        guard let document = PDFDocument(url: url),
              let page = document.page(at: pageIndex) else {
            return nil
        }

        let pageRect = page.bounds(for: .mediaBox)
        let scale = targetWidth / pageRect.width
        let renderSize = CGSize(
            width: pageRect.width * scale,
            height: pageRect.height * scale
        )

        let renderer = UIGraphicsImageRenderer(size: renderSize)
        return renderer.image { context in
            // White background
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: renderSize))

            // Transform for PDF coordinate system (origin at bottom-left)
            context.cgContext.translateBy(x: 0, y: renderSize.height)
            context.cgContext.scaleBy(x: scale, y: -scale)

            // Draw PDF page
            page.draw(with: .mediaBox, to: context.cgContext)
        }
    }
}

// MARK: - Hierarchical Preview Sheet

private struct HierarchicalPreviewSheet: View {
    @Binding var previewTasks: [PDFTodoExtractor.HierarchicalTask]
    @Binding var listName: String
    let pageIndex: Int
    let isFullPage: Bool
    let onSave: () -> Void
    let onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var localization = LocalizationManager.shared

    /// Total count of all tasks including subtasks
    private var totalTaskCount: Int {
        previewTasks.reduce(0) { $0 + 1 + $1.subtasks.count }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with count
                headerSection

                if previewTasks.isEmpty {
                    // Empty state
                    emptyStateView
                } else {
                    // Hierarchical task list
                    taskListView

                    // Name field and save button
                    saveSection
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

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 8) {
            // Task count badge
            HStack(spacing: 8) {
                Image(systemName: previewTasks.isEmpty ? "exclamationmark.circle" : "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(previewTasks.isEmpty ? Color.orange : Color.sageGreen)

                Text(previewTasks.isEmpty ?
                     localization.localize("pdf.preview.noTasksFound") :
                     String(format: localization.localize("pdf.preview.tasksFound"), totalTaskCount))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(previewTasks.isEmpty ? Color.orange : Color.primary)
            }
            .padding(.vertical, 12)

            // Edit hint (only if there are tasks)
            if !previewTasks.isEmpty {
                Text(localization.localize("pdf.preview.editHint"))
                    .font(.system(size: 11))
                    .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .reverieCardStyle(colorScheme: colorScheme)
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.5))

            Text(localization.localize("pdf.preview.noTasksMessage"))
                .font(.system(size: 14))
                .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            // Try Again button
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
    }

    // MARK: - Task List View

    private var taskListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(Array(previewTasks.enumerated()), id: \.offset) { index, task in
                    HierarchicalTaskCard(
                        task: task,
                        index: index,
                        colorScheme: colorScheme,
                        onDelete: {
                            withAnimation(.snappy) {
                                _ = previewTasks.remove(at: index)
                            }
                            ReverieHaptics.lightFeedback()
                        },
                        onDeleteSubtask: { subtaskIndex in
                            withAnimation(.snappy) {
                                _ = previewTasks[index].subtasks.remove(at: subtaskIndex)
                            }
                            ReverieHaptics.lightFeedback()
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    // MARK: - Save Section

    private var saveSection: some View {
        VStack(spacing: 12) {
            // Divider
            Rectangle()
                .fill(Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.2))
                .frame(height: 1)

            // Name field
            VStack(alignment: .leading, spacing: 6) {
                Text(localization.localize("pdf.nameTaskList"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme))

                TextField(localization.localize("pdf.taskListPlaceholder"), text: $listName)
                    .font(.system(size: 15))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(colorScheme == .dark ? 0.12 : 0.08))
                    )
            }
            .padding(.horizontal, 20)

            // Save button
            Button {
                onSave()
                dismiss()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                    Text(localization.localize("pdf.preview.saveList"))
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
        .reverieCardStyle(colorScheme: colorScheme)
    }
}

// MARK: - Hierarchical Task Card

private struct HierarchicalTaskCard: View {
    let task: PDFTodoExtractor.HierarchicalTask
    let index: Int
    let colorScheme: ColorScheme
    let onDelete: () -> Void
    let onDeleteSubtask: (Int) -> Void

    @State private var isExpanded: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main task row
            HStack(spacing: 12) {
                // Icon based on type
                Image(systemName: task.isHeader ? "folder.fill" : "circle.fill")
                    .font(.system(size: task.isHeader ? 14 : 6))
                    .foregroundStyle(task.isHeader ? Color.sageGreen : Color.timeAdaptiveSecondary(colorScheme: colorScheme))

                // Task text
                Text(task.text)
                    .font(.system(size: task.isHeader ? 15 : 14, weight: task.isHeader ? .semibold : .regular))
                    .foregroundStyle(Color.timeAdaptivePrimary(colorScheme: colorScheme))
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Subtask count badge (for headers)
                if task.isHeader && !task.subtasks.isEmpty {
                    Button {
                        withAnimation(.snappy) {
                            isExpanded.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("\(task.subtasks.count)")
                                .font(.system(size: 11, weight: .medium))

                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 10))
                        }
                        .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.1))
                        )
                    }
                    .buttonStyle(.plain)
                }

                // Delete button
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.4))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            // Subtasks (for headers)
            if task.isHeader && !task.subtasks.isEmpty && isExpanded {
                VStack(spacing: 0) {
                    ForEach(Array(task.subtasks.enumerated()), id: \.offset) { subtaskIndex, subtask in
                        HStack(spacing: 10) {
                            // Indent + bullet
                            Rectangle()
                                .fill(Color.sageGreen.opacity(0.3))
                                .frame(width: 2)
                                .padding(.leading, 6)

                            Image(systemName: "circle.fill")
                                .font(.system(size: 5))
                                .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.6))

                            Text(subtask)
                                .font(.system(size: 13))
                                .foregroundStyle(Color.timeAdaptivePrimary(colorScheme: colorScheme).opacity(0.85))
                                .frame(maxWidth: .infinity, alignment: .leading)

                            // Delete subtask button
                            Button {
                                onDeleteSubtask(subtaskIndex)
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10))
                                    .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.4))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(colorScheme == .dark ? 0.04 : 0.02)
                        )

                        if subtaskIndex < task.subtasks.count - 1 {
                            Divider()
                                .padding(.leading, 32)
                        }
                    }
                }
            }
        }
        .reverieCardStyle(colorScheme: colorScheme)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    task.isHeader ? Color.sageGreen.opacity(0.3) : Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.1),
                    lineWidth: task.isHeader ? 1 : 0.5
                )
        )
    }
}
