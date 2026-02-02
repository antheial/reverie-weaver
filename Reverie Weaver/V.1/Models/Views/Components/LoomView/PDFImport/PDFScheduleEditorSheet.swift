//
//  PDFScheduleEditorSheet.swift
//  Reverie Weaver
//
//  Sheet for editing PDF schedule, priority, category, and linked PDFs
//

import SwiftUI
import SwiftData

struct PDFScheduleEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    @Bindable var pdf: ImportedPDF

    // Local state for editing
    @State private var editedTitle: String = ""
    @State private var hasStartDate: Bool = false
    @State private var startDate: Date = Date()
    @State private var hasEndDate: Bool = false
    @State private var endDate: Date = Date()
    @State private var isSelectingEndDate: Bool = false  // Toggle between selecting start vs end date
    @State private var selectedPriority: PDFPriority = .medium
    @State private var selectedCategory: PDFCategory = .personal
    @State private var customCategoryName: String = ""

    // Series linking
    @State private var showLinkPDFSheet: Bool = false
    @State private var linkedPDFIds: Set<UUID> = []

    // Available PDFs for linking
    @Query(sort: \ImportedPDF.importedAt, order: .reverse)
    private var allPDFs: [ImportedPDF]

    // Accent color based on priority
    private var accentColor: Color {
        selectedPriority.color
    }

    var body: some View {
        ZStack {
            ReverieWeaverBackground()

            VStack(spacing: 0) {
                // Custom header - no NavigationStack toolbar
                customHeader

                ScrollView {
                    VStack(spacing: 24) {
                        // Header prompt
                        Text("Organize your reading plan")
                            .font(.system(size: 13, weight: .regular))
                            .fontDesign(.serif)
                            .italic()
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // MARK: - Title Section
                        VStack(alignment: .leading, spacing: 8) {
                            sectionHeader(icon: "textformat", title: "Display Title")

                            TextField("Custom title (optional)", text: $editedTitle)
                                .textFieldStyle(.plain)
                                .font(.system(size: 13, weight: .regular))
                                .fontDesign(.serif)
                                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                                .padding(16)
                                .reverieCardStyle(colorScheme: colorScheme)

                            Text("Leave empty to use: \(pdf.fileName)")
                                .font(.system(size: 11))
                                .fontDesign(.serif)
                                .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                                .padding(.horizontal, 4)
                        }

                        // MARK: - Priority Section
                        VStack(alignment: .leading, spacing: 12) {
                            sectionHeader(icon: "flag.fill", title: "Priority")

                            HStack(spacing: 10) {
                                ForEach(PDFPriority.allCases, id: \.self) { priority in
                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedPriority = priority
                                        }
                                    } label: {
                                        VStack(spacing: 8) {
                                            ZStack {
                                                Circle()
                                                    .fill(priority.color.opacity(0.15))
                                                    .frame(width: 44, height: 44)

                                                Image(systemName: priority.icon)
                                                    .font(.system(size: 18, weight: .medium))
                                                    .foregroundStyle(priority.color)
                                            }
                                            .overlay {
                                                if selectedPriority == priority {
                                                    Circle()
                                                        .strokeBorder(priority.color, lineWidth: 2)
                                                        .frame(width: 44, height: 44)
                                                }
                                            }

                                            Text(priority.displayName)
                                                .font(.system(size: 11, weight: selectedPriority == priority ? .semibold : .regular))
                                                .fontDesign(.serif)
                                                .foregroundStyle(selectedPriority == priority ? priority.color : Color.timeAdaptiveSecondary(colorScheme: colorScheme))
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(16)
                            .reverieCardStyle(colorScheme: colorScheme)
                        }

                        // MARK: - Category Section
                        VStack(alignment: .leading, spacing: 12) {
                            sectionHeader(icon: "folder.fill", title: "Category")

                            VStack(spacing: 8) {
                                ForEach(PDFCategory.allCases, id: \.self) { category in
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedCategory = category
                                        }
                                    } label: {
                                        HStack(spacing: 12) {
                                            Image(systemName: category.icon)
                                                .font(.system(size: 16))
                                                .foregroundStyle(category.color)
                                                .frame(width: 24)

                                            Text(category.displayName)
                                                .font(.system(size: 13, weight: .medium))
                                                .fontDesign(.serif)
                                                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

                                            Spacer()

                                            if selectedCategory == category {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 16))
                                                    .foregroundStyle(category.color)
                                            }
                                        }
                                        .padding(14)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(selectedCategory == category ? category.color.opacity(0.1) : Color.clear)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .strokeBorder(
                                                    selectedCategory == category ? category.color.opacity(0.5) : Color.clear,
                                                    lineWidth: 1.5
                                                )
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }

                                // Custom category name field
                                if selectedCategory == .custom {
                                    TextField("Custom category name", text: $customCategoryName)
                                        .textFieldStyle(.plain)
                                        .font(.system(size: 13, weight: .regular))
                                        .fontDesign(.serif)
                                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                                        .padding(14)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.12))
                                        )
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
                            .padding(12)
                            .reverieCardStyle(colorScheme: colorScheme)
                        }

                        // MARK: - Schedule Section
                        VStack(alignment: .leading, spacing: 12) {
                            sectionHeader(icon: "calendar", title: "Schedule")

                            VStack(spacing: 12) {
                                // Start Date Toggle
                                HStack {
                                    Image(systemName: "play.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundStyle(Color.sageGreen)

                                    Text("Start Date")
                                        .font(.system(size: 13, weight: .medium))
                                        .fontDesign(.serif)
                                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

                                    Spacer()

                                    Toggle("", isOn: $hasStartDate.animation(.easeInOut(duration: 0.2)))
                                        .labelsHidden()
                                        .tint(Color.sageGreen)
                                }

                                if hasStartDate {
                                    // Date Selection Mode Picker (only when end date is enabled)
                                    if hasEndDate {
                                        HStack(spacing: 8) {
                                            // Start Date Button
                                            Button {
                                                withAnimation(.easeInOut(duration: 0.2)) {
                                                    isSelectingEndDate = false
                                                }
                                                ReverieHaptics.lightFeedback()
                                            } label: {
                                                HStack(spacing: 6) {
                                                    Image(systemName: "play.circle.fill")
                                                        .font(.system(size: 12))
                                                    Text("Start")
                                                        .font(.system(size: 12, weight: .medium))
                                                        .fontDesign(.serif)
                                                }
                                                .foregroundStyle(!isSelectingEndDate ? Color.white : Color.sageGreen)
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 8)
                                                .background(
                                                    Capsule()
                                                        .fill(!isSelectingEndDate ? Color.sageGreen : Color.sageGreen.opacity(0.15))
                                                )
                                            }
                                            .buttonStyle(.plain)

                                            // End Date Button
                                            Button {
                                                withAnimation(.easeInOut(duration: 0.2)) {
                                                    isSelectingEndDate = true
                                                }
                                                ReverieHaptics.lightFeedback()
                                            } label: {
                                                HStack(spacing: 6) {
                                                    Image(systemName: "flag.checkered")
                                                        .font(.system(size: 12))
                                                    Text("End")
                                                        .font(.system(size: 12, weight: .medium))
                                                        .fontDesign(.serif)
                                                }
                                                .foregroundStyle(isSelectingEndDate ? Color.white : Color.terracottaRose)
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 8)
                                                .background(
                                                    Capsule()
                                                        .fill(isSelectingEndDate ? Color.terracottaRose : Color.terracottaRose.opacity(0.15))
                                                )
                                            }
                                            .buttonStyle(.plain)

                                            Spacer()
                                        }
                                        .padding(.vertical, 4)
                                    }

                                    // Unified Calendar - force dark mode for readable text on dark gradient background
                                    if hasEndDate && isSelectingEndDate {
                                        // End Date Calendar
                                        DatePicker("",
                                                   selection: $endDate,
                                                   in: startDate...,
                                                   displayedComponents: .date)
                                            .datePickerStyle(.graphical)
                                            .tint(Color.terracottaRose)
                                            .colorScheme(.dark)
                                            .transition(.opacity.combined(with: .scale(scale: 0.98)))
                                    } else {
                                        // Start Date Calendar
                                        DatePicker("", selection: $startDate, displayedComponents: .date)
                                            .datePickerStyle(.graphical)
                                            .tint(Color.sageGreen)
                                            .colorScheme(.dark)
                                            .transition(.opacity.combined(with: .scale(scale: 0.98)))
                                            .onChange(of: startDate) { _, newValue in
                                                // Auto-switch to end date selection after picking start
                                                if hasEndDate {
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                        withAnimation(.easeInOut(duration: 0.2)) {
                                                            isSelectingEndDate = true
                                                        }
                                                    }
                                                    // Ensure end date is not before start date
                                                    if endDate < newValue {
                                                        endDate = newValue
                                                    }
                                                }
                                            }
                                    }

                                    // Date Summary Pills
                                    HStack(spacing: 12) {
                                        // Start Date Pill
                                        HStack(spacing: 6) {
                                            Image(systemName: "play.circle.fill")
                                                .font(.system(size: 11))
                                            Text(startDate.formatted(.dateTime.month(.abbreviated).day()))
                                                .font(.system(size: 12, weight: .medium))
                                                .fontDesign(.serif)
                                        }
                                        .foregroundStyle(Color.sageGreen)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule()
                                                .fill(Color.sageGreen.opacity(0.12))
                                        )

                                        if hasEndDate {
                                            // Arrow
                                            Image(systemName: "arrow.right")
                                                .font(.system(size: 10, weight: .semibold))
                                                .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.5))

                                            // End Date Pill
                                            HStack(spacing: 6) {
                                                Image(systemName: "flag.checkered")
                                                    .font(.system(size: 11))
                                                Text(endDate.formatted(.dateTime.month(.abbreviated).day()))
                                                    .font(.system(size: 12, weight: .medium))
                                                    .fontDesign(.serif)
                                            }
                                            .foregroundStyle(Color.terracottaRose)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(
                                                Capsule()
                                                    .fill(Color.terracottaRose.opacity(0.12))
                                            )

                                            Spacer()

                                            // Duration Badge
                                            let days = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
                                            HStack(spacing: 4) {
                                                Image(systemName: "clock.fill")
                                                    .font(.system(size: 10))
                                                Text("\(days + 1) days")
                                                    .font(.system(size: 11, weight: .medium))
                                                    .fontDesign(.serif)
                                            }
                                            .foregroundStyle(Color.dustyBlue)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 5)
                                            .background(
                                                Capsule()
                                                    .fill(Color.dustyBlue.opacity(0.12))
                                            )
                                        } else {
                                            Spacer()
                                        }
                                    }
                                    .padding(.top, 4)

                                    Divider()
                                        .opacity(0.5)

                                    // End Date Toggle (moved below calendar)
                                    HStack {
                                        Image(systemName: "flag.checkered")
                                            .font(.system(size: 16))
                                            .foregroundStyle(Color.terracottaRose)

                                        Text("Set End Date")
                                            .font(.system(size: 13, weight: .medium))
                                            .fontDesign(.serif)
                                            .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

                                        Spacer()

                                        Toggle("", isOn: Binding(
                                            get: { hasEndDate },
                                            set: { newValue in
                                                withAnimation(.easeInOut(duration: 0.2)) {
                                                    hasEndDate = newValue
                                                    if newValue {
                                                        // Auto-switch to end date selection when enabling
                                                        isSelectingEndDate = true
                                                        // Default end date to start date if not set
                                                        if endDate < startDate {
                                                            endDate = startDate
                                                        }
                                                    } else {
                                                        isSelectingEndDate = false
                                                    }
                                                }
                                            }
                                        ))
                                        .labelsHidden()
                                        .tint(Color.terracottaRose)
                                    }
                                }
                            }
                            .padding(16)
                            .reverieCardStyle(colorScheme: colorScheme)
                        }

                        // MARK: - Linked PDFs Section
                        VStack(alignment: .leading, spacing: 12) {
                            sectionHeader(icon: "link", title: "Linked PDFs (Series)")

                            VStack(spacing: 10) {
                                if !linkedPDFIds.isEmpty {
                                    // Current PDF
                                    linkedPDFRow(
                                        title: pdf.title,
                                        subtitle: "Part 1",
                                        isCurrent: true,
                                        priority: pdf.priority
                                    )

                                    // Linked PDFs
                                    ForEach(Array(linkedPDFIds.enumerated()), id: \.element) { index, linkedId in
                                        if let linkedPDF = allPDFs.first(where: { $0.id == linkedId }) {
                                            linkedPDFRow(
                                                title: linkedPDF.title,
                                                subtitle: "Part \(index + 2)",
                                                isCurrent: false,
                                                priority: linkedPDF.priority
                                            )
                                        }
                                    }

                                    Divider()
                                        .opacity(0.5)
                                }

                                Button {
                                    showLinkPDFSheet = true
                                } label: {
                                    HStack(spacing: 10) {
                                        Image(systemName: "link.badge.plus")
                                            .font(.system(size: 16))
                                            .foregroundStyle(Color.dustyBlue)

                                        Text(!linkedPDFIds.isEmpty ? "Manage Linked PDFs" : "Link PDFs Together")
                                            .font(.system(size: 13, weight: .medium))
                                            .fontDesign(.serif)
                                            .foregroundStyle(Color.dustyBlue)

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.6))
                                    }
                                    .padding(14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.dustyBlue.opacity(0.08))
                                    )
                                }
                                .buttonStyle(.plain)

                                Text("Group related PDFs as a series (e.g., Week 1, Week 2, Week 3)")
                                    .font(.system(size: 11))
                                    .fontDesign(.serif)
                                    .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(16)
                            .reverieCardStyle(colorScheme: colorScheme)
                        }

                        // MARK: - Progress Section
                        VStack(alignment: .leading, spacing: 12) {
                            sectionHeader(icon: "chart.bar.fill", title: "Progress")

                            VStack(spacing: 12) {
                                // Task counts
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Total Tasks")
                                            .font(.system(size: 11))
                                            .fontDesign(.serif)
                                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                                        Text("\(pdf.totalTaskCount)")
                                            .font(.system(size: 20, weight: .semibold))
                                            .fontDesign(.serif)
                                            .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("Completed")
                                            .font(.system(size: 11))
                                            .fontDesign(.serif)
                                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                                        Text("\(pdf.completedTaskCount)")
                                            .font(.system(size: 20, weight: .semibold))
                                            .fontDesign(.serif)
                                            .foregroundStyle(Color.sageGreen)
                                    }
                                }

                                // Progress bar
                                if pdf.totalTaskCount > 0 {
                                    GeometryReader { geometry in
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.2))
                                                .frame(height: 8)

                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(pdf.isOverdue ? Color.red : Color.sageGreen)
                                                .frame(width: geometry.size.width * pdf.progressPercentage, height: 8)
                                        }
                                    }
                                    .frame(height: 8)

                                    Text("\(Int(pdf.progressPercentage * 100))% complete")
                                        .font(.system(size: 11))
                                        .fontDesign(.serif)
                                        .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                }

                                // Status indicator
                                if pdf.isOverdue {
                                    HStack(spacing: 8) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundStyle(.red)
                                        Text("Overdue")
                                            .fontWeight(.medium)
                                            .foregroundStyle(.red)
                                        Spacer()
                                        if let days = pdf.daysRemaining {
                                            Text("\(abs(days)) days past deadline")
                                                .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme))
                                        }
                                    }
                                    .font(.system(size: 12))
                                    .fontDesign(.serif)
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.red.opacity(0.1))
                                    )
                                } else if let days = pdf.daysRemaining, days > 0 {
                                    HStack(spacing: 8) {
                                        Image(systemName: "calendar.badge.clock")
                                            .foregroundStyle(Color.dustyBlue)
                                        Text("\(days) days remaining")
                                            .foregroundStyle(Color.dustyBlue)
                                    }
                                    .font(.system(size: 12, weight: .medium))
                                    .fontDesign(.serif)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                }
                            }
                            .padding(16)
                            .reverieCardStyle(colorScheme: colorScheme)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 100)
                }
            }
        }
        .sheet(isPresented: $showLinkPDFSheet) {
            LinkPDFsSheet(
                currentPDF: pdf,
                allPDFs: allPDFs,
                linkedPDFIds: $linkedPDFIds
            )
        }
        .onAppear {
            loadCurrentValues()
        }
    }

    // MARK: - Custom Header (no navigation bar styling)
    private var customHeader: some View {
        HStack {
            // Cancel button
            Text("Cancel")
                .font(.system(size: 15))
                .fontDesign(.serif)
                .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .strokeBorder(Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.3), lineWidth: 1)
                )
                .onTapGesture {
                    dismiss()
                }

            Spacer()

            // Title
            Text("Edit Schedule")
                .font(.system(size: 16, weight: .semibold))
                .fontDesign(.serif)
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

            Spacer()

            // Save button
            Text("Save")
                .font(.system(size: 15, weight: .semibold))
                .fontDesign(.serif)
                .foregroundStyle(Color.sageGreen)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .strokeBorder(Color.sageGreen.opacity(0.3), lineWidth: 1)
                )
                .onTapGesture {
                    ReverieHaptics.lightFeedback()
                    saveChanges()
                    dismiss()
                }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    // MARK: - Helper Views

    @ViewBuilder
    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(accentColor)
            Text(title)
                .font(.system(size: 13, weight: .regular))
                .fontDesign(.serif)
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
        }
    }

    @ViewBuilder
    private func linkedPDFRow(title: String, subtitle: String, isCurrent: Bool, priority: PDFPriority) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(priority.color.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: isCurrent ? "doc.fill" : "doc")
                    .font(.system(size: 14))
                    .foregroundStyle(isCurrent ? priority.color : Color.timeAdaptiveSecondary(colorScheme: colorScheme))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: isCurrent ? .semibold : .regular))
                    .fontDesign(.serif)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.system(size: 11))
                    .fontDesign(.serif)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
            }

            Spacer()

            if isCurrent {
                Text("Current")
                    .font(.system(size: 10, weight: .medium))
                    .fontDesign(.serif)
                    .foregroundStyle(priority.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(priority.color.opacity(0.12))
                    )
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isCurrent ? priority.color.opacity(0.05) : Color.clear)
        )
    }

    // MARK: - Methods

    private func loadCurrentValues() {
        editedTitle = pdf.displayTitle ?? ""
        selectedPriority = pdf.priority
        selectedCategory = pdf.category
        customCategoryName = pdf.customCategoryName ?? ""

        if let start = pdf.startDate {
            hasStartDate = true
            startDate = start
        }

        if let end = pdf.endDate {
            hasEndDate = true
            endDate = end
        }

        linkedPDFIds = Set(pdf.linkedPDFIds)
    }

    private func saveChanges() {
        pdf.displayTitle = editedTitle.isEmpty ? nil : editedTitle
        pdf.priority = selectedPriority
        pdf.category = selectedCategory
        pdf.customCategoryName = selectedCategory == .custom ? customCategoryName : nil
        pdf.startDate = hasStartDate ? startDate : nil
        pdf.endDate = hasEndDate ? endDate : nil

        updateLinkedPDFs()

        try? modelContext.save()
    }

    private func updateLinkedPDFs() {
        let selectedIds = linkedPDFIds.filter { $0 != pdf.id }

        for oldLinkedId in pdf.linkedPDFIds {
            if let oldLinked = allPDFs.first(where: { $0.id == oldLinkedId }) {
                oldLinked.parentSeriesPDFId = nil
                oldLinked.seriesOrder = nil
            }
        }

        pdf.linkedPDFIds = Array(selectedIds)
        pdf.seriesOrder = selectedIds.isEmpty ? nil : 1

        for (index, linkedId) in selectedIds.enumerated() {
            if let linkedPDF = allPDFs.first(where: { $0.id == linkedId }) {
                linkedPDF.parentSeriesPDFId = pdf.id
                linkedPDF.seriesOrder = index + 2
            }
        }
    }
}

// MARK: - Link PDFs Sheet

struct LinkPDFsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let currentPDF: ImportedPDF
    let allPDFs: [ImportedPDF]
    @Binding var linkedPDFIds: Set<UUID>

    var availablePDFs: [ImportedPDF] {
        allPDFs.filter { $0.id != currentPDF.id }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ReverieWeaverBackground()

                ScrollView {
                    contentView
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 40)
                }
            }
            .navigationTitle("Link PDFs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .fontDesign(.serif)
                }
            }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        VStack(spacing: 20) {
            if availablePDFs.isEmpty {
                emptyStateView
            } else {
                pdfListView
            }
        }
    }

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.5))

            Text("No Other PDFs")
                .font(.system(size: 17, weight: .semibold))
                .fontDesign(.serif)
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

            Text("Import more PDFs to link them together as a series")
                .font(.system(size: 13))
                .fontDesign(.serif)
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    @ViewBuilder
    private var pdfListView: some View {
        Text("Select PDFs to link with \"\(currentPDF.title)\"")
            .font(.system(size: 13))
            .fontDesign(.serif)
            .italic()
            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
            .frame(maxWidth: .infinity, alignment: .leading)

        VStack(spacing: 8) {
            ForEach(availablePDFs, id: \.id) { pdf in
                pdfRowButton(for: pdf)
            }
        }
        .padding(12)
        .reverieCardStyle(colorScheme: colorScheme)
    }

    @ViewBuilder
    private func pdfRowButton(for pdf: ImportedPDF) -> some View {
        let isSelected = linkedPDFIds.contains(pdf.id)

        Button {
            ReverieHaptics.lightFeedback()
            toggleSelection(pdf)
        } label: {
            HStack(spacing: 14) {
                selectionIndicator(isSelected: isSelected)
                pdfInfoColumn(pdf: pdf)
                Spacer()
                priorityIndicator(color: pdf.priority.color)
            }
            .padding(14)
            .background(rowBackground(isSelected: isSelected))
            .overlay(rowBorder(isSelected: isSelected))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func selectionIndicator(isSelected: Bool) -> some View {
        ZStack {
            Circle()
                .strokeBorder(
                    isSelected ? Color.sageGreen : Color.timeAdaptiveSecondary(colorScheme: colorScheme).opacity(0.4),
                    lineWidth: 2
                )
                .frame(width: 24, height: 24)

            if isSelected {
                Circle()
                    .fill(Color.sageGreen)
                    .frame(width: 24, height: 24)

                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
    }

    @ViewBuilder
    private func pdfInfoColumn(pdf: ImportedPDF) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(pdf.title)
                .font(.system(size: 14, weight: .medium))
                .fontDesign(.serif)
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                .lineLimit(1)

            HStack(spacing: 8) {
                Label("\(pdf.totalTaskCount) tasks", systemImage: "checklist")
                if pdf.hasSchedule {
                    Label("Scheduled", systemImage: "calendar")
                }
            }
            .font(.system(size: 11))
            .fontDesign(.serif)
            .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
        }
    }

    @ViewBuilder
    private func priorityIndicator(color: Color) -> some View {
        Circle()
            .fill(color)
            .frame(width: 10, height: 10)
    }

    private func rowBackground(isSelected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(isSelected ? Color.sageGreen.opacity(0.08) : Color.clear)
    }

    private func rowBorder(isSelected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .strokeBorder(
                isSelected ? Color.sageGreen.opacity(0.3) : Color.clear,
                lineWidth: 1
            )
    }

    private func toggleSelection(_ pdf: ImportedPDF) {
        if linkedPDFIds.contains(pdf.id) {
            linkedPDFIds.remove(pdf.id)
        } else {
            linkedPDFIds.insert(pdf.id)
        }
    }
}

// MARK: - Preview

#Preview {
    Text("PDFScheduleEditorSheet Preview")
        .sheet(isPresented: .constant(true)) {
            Text("Preview requires SwiftData context")
        }
}
