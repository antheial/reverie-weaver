//
//  PDFPageBrowserView.swift
//  Reverie Weaver
//
//  Browse PDF pages and select one for todo extraction
//

import SwiftUI
import PDFKit

struct PDFPageBrowserView: View {
    let pdf: ImportedPDF
    let onSelectTaskList: (PDFTaskList) -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var localization = LocalizationManager.shared

    @State private var pageThumbnails: [Int: UIImage] = [:]
    @State private var isLoading = true
    @State private var selectedPageIndex: Int?
    @State private var showSelectionView = false
    @State private var createdTaskList: PDFTaskList?
    @State private var loadedPageCount = 0
    @State private var loadingProgress: Double = 0

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    // Batch loading configuration
    private let thumbnailBatchSize = 20
    private let maxConcurrentLoads = 6

    var body: some View {
        NavigationStack {
            ZStack {
                ReverieWeaverBackground()

                if isLoading {
                    loadingView
                } else if pdf.pageCount == 0 || pdf.fileURL == nil {
                    // Empty/error state
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 48, weight: .light))
                            .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.5))

                        Text(localization.localize("pdf.unableToLoadPDF"))
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme))

                        #if DEBUG
                        Text("pageCount: \(pdf.pageCount), fileURL: \(pdf.fileURL?.path ?? "nil")")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.orange)
                        #endif
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Instructions
                            instructionCard

                            // Page grid
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(0..<pdf.pageCount, id: \.self) { pageIndex in
                                    PageThumbnailCard(
                                        pageIndex: pageIndex,
                                        thumbnail: pageThumbnails[pageIndex],
                                        isSelected: selectedPageIndex == pageIndex,
                                        colorScheme: colorScheme
                                    ) {
                                        selectedPageIndex = pageIndex
                                        showSelectionView = true
                                    }
                                }
                            }
                            .padding(.horizontal, 16)

                            Spacer(minLength: 100)
                        }
                        .padding(.top, 16)
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
                    VStack(spacing: 2) {
                        Text(localization.localize("pdf.selectPage"))
                            .font(.system(size: 16, weight: .semibold))
                            .fontDesign(.serif)
                            .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

                        Text(pdf.fileName)
                            .font(.system(size: 11))
                            .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme))
                    }
                }
            }
            .task {
                await loadThumbnails()
            }
            .sheet(isPresented: $showSelectionView) {
                if let pageIndex = selectedPageIndex {
                    PDFSelectionView(
                        pdf: pdf,
                        pageIndex: pageIndex
                    ) { taskList in
                        createdTaskList = taskList
                        showSelectionView = false
                        onSelectTaskList(taskList)
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            if pdf.pageCount > thumbnailBatchSize {
                // Show progress for large PDFs
                ProgressView(value: loadingProgress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color.sageGreen))
                    .frame(width: 200)

                Text(String(format: localization.localize("pdf.loadingProgress"), loadedPageCount, pdf.pageCount))
                    .font(.system(size: 14))
                    .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme))
            } else {
                ProgressView()
                    .scaleEffect(1.2)

                Text(localization.localize("pdf.loadingPages"))
                    .font(.system(size: 14))
                    .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme))
            }
        }
    }

    // MARK: - Instruction Card

    private var instructionCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "hand.tap.fill")
                .font(.system(size: 20))
                .foregroundStyle(Color.sageGreen)

            VStack(alignment: .leading, spacing: 2) {
                Text(localization.localize("pdf.tapToExtract"))
                    .font(.system(size: 13, weight: .medium))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

                Text(localization.localize("pdf.selectAreaOrFull"))
                    .font(.system(size: 11))
                    .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme))
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.sageGreen.opacity(colorScheme == .dark ? 0.1 : 0.06))
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Load Thumbnails

    private func loadThumbnails() async {
        guard let pdfURL = pdf.fileURL else {
            await MainActor.run {
                isLoading = false
            }
            return
        }

        let pageCount = pdf.pageCount
        let storageManager = PDFStorageManager.shared

        // For small PDFs, load all at once
        if pageCount <= thumbnailBatchSize {
            await loadThumbnailsBatch(
                pdfURL: pdfURL,
                pageIndices: Array(0..<pageCount),
                storageManager: storageManager
            )
        } else {
            // For large PDFs, load in batches to prevent memory spikes
            var currentIndex = 0
            while currentIndex < pageCount {
                let endIndex = min(currentIndex + thumbnailBatchSize, pageCount)
                let batchIndices = Array(currentIndex..<endIndex)

                await loadThumbnailsBatch(
                    pdfURL: pdfURL,
                    pageIndices: batchIndices,
                    storageManager: storageManager
                )

                // Update progress on main thread
                await MainActor.run {
                    loadedPageCount = endIndex
                    loadingProgress = Double(endIndex) / Double(pageCount)
                }

                currentIndex = endIndex

                // Small delay between batches to allow UI updates and reduce memory pressure
                if currentIndex < pageCount {
                    try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
                }
            }
        }

        await MainActor.run {
            isLoading = false
        }
    }

    private func loadThumbnailsBatch(
        pdfURL: URL,
        pageIndices: [Int],
        storageManager: PDFStorageManager
    ) async {
        // Use limited concurrency to prevent memory spikes
        await withTaskGroup(of: (Int, UIImage?).self) { group in
            var pendingIndices = pageIndices
            var activeCount = 0

            while !pendingIndices.isEmpty || activeCount > 0 {
                // Add tasks up to concurrency limit
                while activeCount < maxConcurrentLoads && !pendingIndices.isEmpty {
                    let pageIndex = pendingIndices.removeFirst()
                    activeCount += 1
                    group.addTask {
                        let image = storageManager.generatePageThumbnail(
                            for: pdfURL,
                            pageIndex: pageIndex,
                            targetWidth: 120
                        )
                        return (pageIndex, image)
                    }
                }

                // Wait for one task to complete
                if let (index, image) = await group.next() {
                    activeCount -= 1
                    if let image = image {
                        await MainActor.run {
                            pageThumbnails[index] = image
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Page Thumbnail Card

private struct PageThumbnailCard: View {
    let pageIndex: Int
    let thumbnail: UIImage?
    let isSelected: Bool
    let colorScheme: ColorScheme
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Thumbnail
                if let image = thumbnail {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.1))
                        .frame(height: 140)
                        .overlay(
                            ProgressView()
                        )
                }

                // Page number
                Text("Page \(pageIndex + 1)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(isSelected ? Color.sageGreen : Color.timeAdaptiveSecondary(colorScheme: colorScheme))
            }
            .padding(8)
            .reverieCardStyle(colorScheme: colorScheme)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        isSelected ? Color.sageGreen : Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.1),
                        lineWidth: isSelected ? 2 : 0.5
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
