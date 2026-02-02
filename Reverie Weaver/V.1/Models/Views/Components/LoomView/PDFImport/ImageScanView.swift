//
//  ImageScanView.swift
//  Reverie Weaver
//
//  View for selecting an image from Photos and extracting todos via OCR
//  Supports optional cropping before extraction
//

import SwiftUI
import SwiftData
import PhotosUI

struct ImageScanView: View {
    let onComplete: (PDFTaskList) -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var localization = LocalizationManager.shared

    // Photo selection state
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isLoadingImage = false

    // Selection/cropping state
    @State private var selectionRect: CGRect?
    @State private var dragStart: CGPoint?
    @State private var dragCurrent: CGPoint?
    @State private var renderedImageFrame: CGRect = .zero

    // Extraction state
    @State private var listName: String = ""
    @State private var isExtracting = false
    @State private var showPreview = false
    @State private var previewTasks: [PDFTodoExtractor.HierarchicalTask] = []
    @State private var isFullImageExtraction = false

    var body: some View {
        NavigationStack {
            ZStack {
                ReverieWeaverBackground()

                if let image = selectedImage {
                    // Image selection/crop view
                    imageSelectionView(image: image)
                } else {
                    // Photo picker prompt
                    photoPickerPrompt
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(localization.localize("common.cancel")) {
                        dismiss()
                    }
                    .foregroundStyle(Color.secondary)
                }

                ToolbarItem(placement: .principal) {
                    Text(localization.localize("image.scanTitle"))
                        .font(.system(size: 16, weight: .semibold))
                        .fontDesign(.serif)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if selectedImage != nil {
                        // Clear selection or pick new image
                        if selectionRect != nil {
                            Button {
                                selectionRect = nil
                            } label: {
                                Text(localization.localize("common.clear"))
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.secondary)
                            }
                        } else {
                            // Option to pick a different image
                            PhotosPicker(
                                selection: $selectedPhotoItem,
                                matching: .images
                            ) {
                                Image(systemName: "photo.badge.plus")
                                    .font(.system(size: 16))
                                    .foregroundStyle(Color.sageGreen)
                            }
                        }
                    }
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                loadSelectedImage(from: newItem)
            }
            .sheet(isPresented: $showPreview) {
                ImagePreviewSheet(
                    previewTasks: $previewTasks,
                    listName: $listName,
                    thumbnailImage: selectedImage,
                    onSave: {
                        createTaskListFromPreview()
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

    // MARK: - Photo Picker Prompt

    private var photoPickerPrompt: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundStyle(Color.sageGreen.opacity(0.6))

            // Instructions
            VStack(spacing: 8) {
                Text(localization.localize("image.selectPrompt"))
                    .font(.system(size: 18, weight: .semibold))
                    .fontDesign(.serif)

                Text(localization.localize("image.selectDescription"))
                    .font(.system(size: 14))
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            // Photo picker button
            PhotosPicker(
                selection: $selectedPhotoItem,
                matching: .images
            ) {
                HStack(spacing: 10) {
                    if isLoadingImage {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Image(systemName: "photo.fill")
                            .font(.system(size: 16))
                    }

                    Text(localization.localize("image.selectButton"))
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(Color.white)
                .frame(width: 200)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.sageGreen)
                )
            }
            .buttonStyle(.plain)
            .disabled(isLoadingImage)

            Spacer()

            // Hint text
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.orange.opacity(0.8))

                Text(localization.localize("image.tipText"))
                    .font(.system(size: 12))
                    .foregroundStyle(Color.secondary)
            }
            .padding(.bottom, 30)
        }
    }

    // MARK: - Image Selection View

    private func imageSelectionView(image: UIImage) -> some View {
        VStack(spacing: 0) {
            // Instructions
            instructionBar

            // Image with selection overlay
            GeometryReader { geometry in
                ZStack {
                    // Display the image
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        .allowsHitTesting(false)

                    // Transparent gesture capture layer
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(dragGesture)

                    // Current selection rectangle
                    if let rect = currentSelectionRect {
                        SelectionRectangleView(rect: rect, colorScheme: colorScheme)
                            .allowsHitTesting(false)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    updateRenderedImageFrame(for: geometry.size, imageSize: image.size)
                }
                .onChange(of: geometry.size) { _, newSize in
                    updateRenderedImageFrame(for: newSize, imageSize: image.size)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // Bottom actions
            actionBar
        }
    }

    // MARK: - Instruction Bar

    private var instructionBar: some View {
        HStack(spacing: 10) {
            Image(systemName: selectionRect == nil ? "rectangle.dashed" : "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(selectionRect == nil ? Color.secondary : Color.sageGreen)

            Text(selectionRect == nil ?
                 localization.localize("image.drawRectangle") :
                 localization.localize("image.selectionReady"))
                .font(.system(size: 12))
                .foregroundStyle(Color.secondary)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.secondary.opacity(colorScheme == .dark ? 0.08 : 0.05))
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
            // Full Image button
            Button {
                isFullImageExtraction = true
                listName = localization.localize("image.defaultListName")
                extractAndShowPreview(fullImage: true)
            } label: {
                HStack(spacing: 6) {
                    if isExtracting && isFullImageExtraction {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "photo")
                            .font(.system(size: 14))
                    }

                    Text(localization.localize("image.fullImage"))
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundStyle(Color.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.secondary.opacity(colorScheme == .dark ? 0.12 : 0.08))
                )
            }
            .buttonStyle(.plain)
            .disabled(isExtracting)

            // Extract Selected button
            Button {
                isFullImageExtraction = false
                listName = localization.localize("image.defaultListName") + " Selection"
                extractAndShowPreview(fullImage: false)
            } label: {
                HStack(spacing: 6) {
                    if isExtracting && !isFullImageExtraction {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Image(systemName: "text.viewfinder")
                            .font(.system(size: 14))
                    }

                    Text(localization.localize("image.extractSelected"))
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
        .background(Color.secondary.opacity(colorScheme == .dark ? 0.05 : 0.03))
    }

    // MARK: - Load Selected Image

    private func loadSelectedImage(from item: PhotosPickerItem?) {
        guard let item = item else { return }

        isLoadingImage = true
        selectedImage = nil
        selectionRect = nil

        Task {
            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        selectedImage = image
                        isLoadingImage = false
                        listName = localization.localize("image.defaultListName")
                    }
                } else {
                    await MainActor.run {
                        isLoadingImage = false
                    }
                }
            } catch {
                #if DEBUG
                print("ImageScanView: Failed to load image: \(error)")
                #endif
                await MainActor.run {
                    isLoadingImage = false
                }
            }
        }
    }

    // MARK: - Update Rendered Image Frame

    private func updateRenderedImageFrame(for geometrySize: CGSize, imageSize: CGSize) {
        guard imageSize.width > 0 && imageSize.height > 0 else { return }

        // Calculate aspect ratios
        let imageAspect = imageSize.width / imageSize.height
        let viewAspect = geometrySize.width / geometrySize.height

        var renderedWidth: CGFloat
        var renderedHeight: CGFloat

        if imageAspect > viewAspect {
            // Image is wider than view - constrained by width
            renderedWidth = geometrySize.width
            renderedHeight = geometrySize.width / imageAspect
        } else {
            // Image is taller than view - constrained by height
            renderedHeight = geometrySize.height
            renderedWidth = geometrySize.height * imageAspect
        }

        // Center the image in the view
        let originX = (geometrySize.width - renderedWidth) / 2
        let originY = (geometrySize.height - renderedHeight) / 2

        renderedImageFrame = CGRect(x: originX, y: originY, width: renderedWidth, height: renderedHeight)
    }

    // MARK: - Convert to Image Coordinates

    private func convertToImageCoordinates(_ viewRect: CGRect, imageSize: CGSize) -> CGRect {
        guard renderedImageFrame.width > 0 && renderedImageFrame.height > 0 else {
            return viewRect
        }

        // Clip the selection rect to the rendered image frame
        let clippedRect = viewRect.intersection(renderedImageFrame)

        guard clippedRect.width > 0 && clippedRect.height > 0 else {
            return .zero
        }

        // Convert view coordinates to coordinates relative to the rendered image frame
        let relativeX = clippedRect.origin.x - renderedImageFrame.origin.x
        let relativeY = clippedRect.origin.y - renderedImageFrame.origin.y

        // Calculate scale from rendered frame to actual image dimensions
        let scaleX = imageSize.width / renderedImageFrame.width
        let scaleY = imageSize.height / renderedImageFrame.height

        // Convert to image coordinates
        let imageX = relativeX * scaleX
        let imageY = relativeY * scaleY
        let imageWidth = clippedRect.width * scaleX
        let imageHeight = clippedRect.height * scaleY

        return CGRect(x: imageX, y: imageY, width: imageWidth, height: imageHeight)
    }

    // MARK: - Extract and Show Preview

    private func extractAndShowPreview(fullImage: Bool) {
        guard let image = selectedImage else { return }

        #if DEBUG
        print("ImageScanView: Starting extraction")
        print("  - Full image: \(fullImage)")
        print("  - Selection rect (view): \(String(describing: selectionRect))")
        #endif

        isExtracting = true

        // Convert selection rect to image coordinates if needed
        var imageRect: CGRect? = nil
        if !fullImage, let selection = selectionRect {
            imageRect = convertToImageCoordinates(selection, imageSize: image.size)
            #if DEBUG
            print("  - Converted image rect: \(imageRect!)")
            #endif
        }

        // Perform extraction on background thread
        Task {
            let hierarchicalTasks = ImageTodoExtractor.shared.extractHierarchicalTodos(
                from: image,
                cropRect: fullImage ? nil : imageRect
            )

            await MainActor.run {
                #if DEBUG
                let totalTasks = hierarchicalTasks.reduce(0) { $0 + 1 + $1.subtasks.count }
                print("ImageScanView: Extracted \(hierarchicalTasks.count) items (\(totalTasks) total tasks)")
                #endif

                previewTasks = hierarchicalTasks
                isExtracting = false
                showPreview = true
                ReverieHaptics.lightFeedback()
            }
        }
    }

    // MARK: - Create Task List from Preview

    private func createTaskListFromPreview() {
        guard !previewTasks.isEmpty, let image = selectedImage else { return }

        // Convert selection rect to image coordinates for cropping
        var cropRect: CGRect? = nil
        if !isFullImageExtraction, let selection = selectionRect {
            cropRect = convertToImageCoordinates(selection, imageSize: image.size)
        }

        // Create thumbnail from the extracted area
        let thumbnailData: Data?
        if let rect = cropRect, let croppedImage = ImageTodoExtractor.shared.cropImage(image, to: rect) {
            thumbnailData = ImageTodoExtractor.shared.createThumbnail(from: croppedImage)
        } else {
            thumbnailData = ImageTodoExtractor.shared.createThumbnail(from: image)
        }

        // Create task list (image source, no parent PDF)
        let taskList = PDFTaskList(
            name: listName.isEmpty ? localization.localize("image.defaultListName") : listName,
            pageNumber: 0,  // Always 0 for image sources
            extractionRect: nil,
            status: .backlog,
            sourceType: .image,
            thumbnailData: thumbnailData
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

        // Save to model context
        modelContext.insert(taskList)
        for task in allTasks {
            modelContext.insert(task)
        }

        #if DEBUG
        let totalCount = allTasks.count
        print("ImageScanView: Created image task list '\(taskList.name)' with \(createdTasks.count) top-level tasks (\(totalCount) total)")
        #endif

        // Clear preview and complete
        previewTasks = []
        onComplete(taskList)
    }
}

// MARK: - Selection Rectangle View

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
            .position(
                x: rect.midX,
                y: rect.midY
            )
    }
}

// MARK: - Image Preview Sheet

private struct ImagePreviewSheet: View {
    @Binding var previewTasks: [PDFTodoExtractor.HierarchicalTask]
    @Binding var listName: String
    let thumbnailImage: UIImage?
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
                // Header with count and thumbnail
                headerSection

                if previewTasks.isEmpty {
                    // Empty state
                    emptyStateView
                } else {
                    // Task list
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
                    .foregroundStyle(Color.secondary)
                }

                ToolbarItem(placement: .principal) {
                    Text(localization.localize("image.preview.title"))
                        .font(.system(size: 16, weight: .semibold))
                        .fontDesign(.serif)
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            // Thumbnail preview (if available)
            if let image = thumbnailImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
            }

            // Task count badge
            HStack(spacing: 8) {
                Image(systemName: previewTasks.isEmpty ? "exclamationmark.circle" : "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(previewTasks.isEmpty ? Color.orange : Color.sageGreen)

                Text(previewTasks.isEmpty ?
                     localization.localize("image.preview.noTasksFound") :
                     String(format: localization.localize("image.preview.tasksFound"), totalTaskCount))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(previewTasks.isEmpty ? Color.orange : Color.primary)
            }

            // Edit hint
            if !previewTasks.isEmpty {
                Text(localization.localize("image.preview.editHint"))
                    .font(.system(size: 11))
                    .foregroundStyle(Color.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.secondary.opacity(colorScheme == .dark ? 0.08 : 0.05))
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(Color.secondary.opacity(0.5))

            Text(localization.localize("image.preview.noTasksMessage"))
                .font(.system(size: 14))
                .foregroundStyle(Color.secondary)
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
                    Text(localization.localize("image.preview.tryAgain"))
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
                    ImageTaskCard(
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
                .fill(Color.secondary.opacity(0.2))
                .frame(height: 1)

            // Name field
            VStack(alignment: .leading, spacing: 6) {
                Text(localization.localize("image.nameTaskList"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.secondary)

                TextField(localization.localize("image.taskListPlaceholder"), text: $listName)
                    .font(.system(size: 15))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.secondary.opacity(colorScheme == .dark ? 0.12 : 0.08))
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
                    Text(localization.localize("image.preview.saveList"))
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
        .background(Color.secondary.opacity(colorScheme == .dark ? 0.03 : 0.02))
    }
}

// MARK: - Image Task Card

private struct ImageTaskCard: View {
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
                    .foregroundStyle(task.isHeader ? Color.sageGreen : Color.secondary)

                // Task text
                Text(task.text)
                    .font(.system(size: task.isHeader ? 15 : 14, weight: task.isHeader ? .semibold : .regular))
                    .foregroundStyle(Color.primary)
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
                        .foregroundStyle(Color.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.secondary.opacity(0.1))
                        )
                    }
                    .buttonStyle(.plain)
                }

                // Delete button
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.secondary.opacity(0.4))
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
                                .foregroundStyle(Color.secondary.opacity(0.6))

                            Text(subtask)
                                .font(.system(size: 13))
                                .foregroundStyle(Color.primary.opacity(0.85))
                                .frame(maxWidth: .infinity, alignment: .leading)

                            // Delete subtask button
                            Button {
                                onDeleteSubtask(subtaskIndex)
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10))
                                    .foregroundStyle(Color.secondary.opacity(0.4))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Color.secondary.opacity(colorScheme == .dark ? 0.04 : 0.02)
                        )

                        if subtaskIndex < task.subtasks.count - 1 {
                            Divider()
                                .padding(.leading, 32)
                        }
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ?
                      Color.white.opacity(task.isHeader ? 0.06 : 0.03) :
                      Color.white.opacity(task.isHeader ? 0.8 : 0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    task.isHeader ? Color.sageGreen.opacity(0.3) : Color.secondary.opacity(0.1),
                    lineWidth: task.isHeader ? 1 : 0.5
                )
        )
    }
}
