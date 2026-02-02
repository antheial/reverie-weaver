//
// WeekCalendarSheet.swift
// Reverie Weaver
//
// Calendar with navigation and PDF schedule overview
//

import SwiftUI
import SwiftData

struct WeekCalendarSheet: View {
    @Binding var currentDate: Date
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var displayedMonth: Date = Date()
    @State private var selectedViewMode: CalendarViewMode = .calendar

    // State for task viewer sheet
    @State private var selectedPDFForTasks: ImportedPDF?

    // Query scheduled PDFs
    @Query(sort: \ImportedPDF.startDate)
    private var allPDFs: [ImportedPDF]

    enum CalendarViewMode: String, CaseIterable {
        case calendar = "Calendar"
        case schedule = "Schedule"
    }

    var body: some View {
        ZStack {
            ReverieWeaverBackground()

            VStack(spacing: 0) {
                // MARK: - Custom Toolbar
                HStack {
                    Spacer()
                    
                    Capsule()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(width: 36, height: 5)
                        .padding(.top, 6)
                        .offset(x: 24)
                    
                    Spacer()
                    
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.sageGreen)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                    }
                }
                .frame(height: 50)
                .background(Color.clear)

                // MARK: - View Mode Picker
                Picker("View Mode", selection: $selectedViewMode) {
                    ForEach(CalendarViewMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 24)
                .padding(.top, 8)

                // MARK: - Content
                if selectedViewMode == .calendar {
                    calendarView
                } else {
                    scheduleOverviewView
                }
            }
        }
        // Ensure calendar opens to the currently selected date, not "Today"
        .onAppear {
            displayedMonth = currentDate
        }
        // Sheet for viewing tasks
        .sheet(item: $selectedPDFForTasks) { pdf in
            PDFTasksQuickViewSheet(pdf: pdf)
        }
    }

    // MARK: - Calendar View

    private var calendarView: some View {
        VStack(spacing: 20) {
            HStack {
                Button {
                    changeMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }

                Spacer()

                Text(monthYearString)
                    .font(.system(size: 17, weight: .semibold))
                    .fontDesign(.serif)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    .animation(.none, value: displayedMonth)

                Spacer()

                Button {
                    changeMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .medium))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
            }
            .padding(.horizontal, 16)

            VStack(spacing: 12) {
                HStack(spacing: 0) {
                    ForEach(weekDayHeaders, id: \.self) { day in
                        Text(day)
                            .font(.system(size: 11, weight: .semibold))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                            .frame(maxWidth: .infinity)
                    }
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
                    ForEach(Array(daysInMonth.enumerated()), id: \.offset) { index, date in
                        if let date = date {
                            Button {
                                selectWeek(containing: date)
                            } label: {
                                dayCell(for: date)
                            }
                            .buttonStyle(.plain)
                        } else {
                            Color.clear.frame(height: 40)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .padding(.top, 10)
    }

    // MARK: - Schedule Overview View

    private var scheduleOverviewView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Today's Focus Section
                if !todaysPDFs.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                            Text("Today's Focus")
                                .font(.system(size: 15, weight: .semibold))
                                .fontDesign(.serif)
                        }
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

                        ForEach(todaysPDFs, id: \.id) { pdf in
                            PDFScheduleCard(pdf: pdf, isToday: true) {
                                selectedPDFForTasks = pdf
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }

                // Overdue Section
                if !overduePDFs.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text("Overdue")
                                .font(.system(size: 15, weight: .semibold))
                                .fontDesign(.serif)
                        }
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

                        ForEach(overduePDFs, id: \.id) { pdf in
                            PDFScheduleCard(pdf: pdf, isOverdue: true) {
                                selectedPDFForTasks = pdf
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }

                // Upcoming Section
                if !upcomingPDFs.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundStyle(.blue)
                            Text("Upcoming")
                                .font(.system(size: 15, weight: .semibold))
                                .fontDesign(.serif)
                        }
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

                        ForEach(upcomingPDFs, id: \.id) { pdf in
                            PDFScheduleCard(pdf: pdf) {
                                selectedPDFForTasks = pdf
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }

                // Upcoming Preview (Tomorrow & This Week)
                if !scheduledPDFs.isEmpty {
                    upcomingPreviewSection
                }

                // No scheduled PDFs
                if scheduledPDFs.isEmpty {
                    ContentUnavailableView(
                        "No Scheduled PDFs",
                        systemImage: "calendar.badge.plus",
                        description: Text("Set dates on your PDFs to see them here")
                    )
                    .padding(.top, 40)
                }

                Spacer(minLength: 40)
            }
            .padding(.top, 16)
        }
    }

    // MARK: - Component Builders

    private func dayCell(for date: Date) -> some View {
        let isToday = Calendar.current.isDateInToday(date)
        let isSelected = isCurrentWeek(date)
        let hasSchedule = hasPDFScheduled(on: date)
        let scheduledPDFsForDay = pdfsForDate(date)
        let hasOverdue = scheduledPDFsForDay.contains { $0.isOverdue }

        return VStack(spacing: 2) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 15, weight: isSelected || isToday ? .semibold : .regular))
                .foregroundStyle(
                    isToday ? Color.sageGreen :
                    isSelected ? Color.white :
                    Color.dynamicLabel
                )
                .frame(width: 40, height: 36)
                .background(
                    Circle()
                        .fill(
                            isToday ? Color.sageGreen.opacity(0.15) :
                            isSelected ? Color.dustyBlue :
                            Color.clear
                        )
                )

            // PDF schedule indicator dots
            if hasSchedule && !isSelected {
                HStack(spacing: 2) {
                    ForEach(Array(scheduledPDFsForDay.prefix(3).enumerated()), id: \.offset) { _, pdf in
                        Circle()
                            .fill(hasOverdue ? Color.red : pdf.priority.color)
                            .frame(width: 4, height: 4)
                    }
                    if scheduledPDFsForDay.count > 3 {
                        Text("+")
                            .font(.system(size: 6, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Color.clear.frame(height: 4)
            }
        }
        .frame(height: 44)
    }

    // MARK: - Helpers

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }

    private var weekDayHeaders: [String] {
        var calendar = Calendar.current
        calendar.locale = Locale.current
        return calendar.shortWeekdaySymbols
    }

    private var daysInMonth: [Date?] {
        let calendar = Calendar.current
        
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth) else { return [] }
        let monthStart = monthInterval.start
        
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let firstWeekdayOffset = firstWeekday - calendar.firstWeekday
        let emptyDayCount = firstWeekdayOffset >= 0 ? firstWeekdayOffset : firstWeekdayOffset + 7
        
        var days: [Date?] = Array(repeating: nil, count: emptyDayCount)
        
        if let range = calendar.range(of: .day, in: .month, for: monthStart) {
            for day in range {
                if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                    days.append(date)
                }
            }
        }
        
        return days
    }

    private func changeMonth(by months: Int) {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        
        if let newMonth = Calendar.current.date(byAdding: .month, value: months, to: displayedMonth) {
            withAnimation(.snappy(duration: 0.25)) {
                displayedMonth = newMonth
            }
        }
    }

    private func selectWeek(containing date: Date) {
        currentDate = date
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        dismiss()
    }

    private func isCurrentWeek(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(date, equalTo: currentDate, toGranularity: .weekOfYear)
    }

    // MARK: - PDF Schedule Filters

    /// PDFs with scheduled dates
    private var scheduledPDFs: [ImportedPDF] {
        allPDFs.filter { $0.hasSchedule }
    }

    /// PDFs active today
    private var todaysPDFs: [ImportedPDF] {
        scheduledPDFs.filter { $0.isActive && !$0.isOverdue && !$0.isFullyCompleted }
            .sorted { $0.priority.sortOrder < $1.priority.sortOrder }
    }

    /// Overdue PDFs
    private var overduePDFs: [ImportedPDF] {
        scheduledPDFs.filter { $0.isOverdue }
            .sorted { ($0.daysRemaining ?? 0) < ($1.daysRemaining ?? 0) }
    }

    /// Upcoming PDFs (not started yet)
    private var upcomingPDFs: [ImportedPDF] {
        let today = Calendar.current.startOfDay(for: Date())
        return scheduledPDFs.filter { pdf in
            guard let start = pdf.startDate else { return false }
            return Calendar.current.startOfDay(for: start) > today
        }
        .sorted { ($0.startDate ?? Date.distantFuture) < ($1.startDate ?? Date.distantFuture) }
    }

    /// Check if a date has any PDF scheduled
    private func hasPDFScheduled(on date: Date) -> Bool {
        let checkDate = Calendar.current.startOfDay(for: date)
        return scheduledPDFs.contains { pdf in
            guard let start = pdf.startDate else { return false }
            let startDay = Calendar.current.startOfDay(for: start)
            if let end = pdf.endDate {
                let endDay = Calendar.current.startOfDay(for: end)
                return checkDate >= startDay && checkDate <= endDay
            }
            return checkDate == startDay
        }
    }

    /// Get PDFs scheduled for a specific date
    private func pdfsForDate(_ date: Date) -> [ImportedPDF] {
        let checkDate = Calendar.current.startOfDay(for: date)
        return scheduledPDFs.filter { pdf in
            guard let start = pdf.startDate else { return false }
            let startDay = Calendar.current.startOfDay(for: start)
            if let end = pdf.endDate {
                let endDay = Calendar.current.startOfDay(for: end)
                return checkDate >= startDay && checkDate <= endDay
            }
            return checkDate == startDay
        }
    }

    /// PDFs active tomorrow
    private var tomorrowPDFs: [ImportedPDF] {
        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) else { return [] }
        return pdfsForDate(tomorrow).filter { !$0.isFullyCompleted }
    }

    /// Count of PDFs remaining this week
    private var thisWeekRemainingCount: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let weekEnd = calendar.date(byAdding: .day, value: 7 - calendar.component(.weekday, from: today), to: today) else { return 0 }

        return scheduledPDFs.filter { pdf in
            guard let start = pdf.startDate, !pdf.isFullyCompleted else { return false }
            let startDay = calendar.startOfDay(for: start)
            let endDay = pdf.endDate.map { calendar.startOfDay(for: $0) } ?? startDay
            return endDay <= weekEnd && endDay >= today
        }.count
    }

    // MARK: - Upcoming Preview Section

    @ViewBuilder
    private var upcomingPreviewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Preview")
                .font(.system(size: 13, weight: .semibold))
                .fontDesign(.serif)
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)

            VStack(spacing: 6) {
                if !tomorrowPDFs.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "sunrise.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.orange)

                        Text("Tomorrow:")
                            .font(.system(size: 12))
                            .fontDesign(.serif)
                            .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

                        Text("\(tomorrowPDFs.count) list\(tomorrowPDFs.count == 1 ? "" : "s")")
                            .font(.system(size: 12))
                            .fontDesign(.serif)
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)

                        Spacer()
                    }
                }

                if thisWeekRemainingCount > 0 {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12))
                            .foregroundStyle(.blue)

                        Text("This Week:")
                            .font(.system(size: 12))
                            .fontDesign(.serif)
                            .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

                        Text("\(thisWeekRemainingCount) list\(thisWeekRemainingCount == 1 ? "" : "s") remaining")
                            .font(.system(size: 12))
                            .fontDesign(.serif)
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)

                        Spacer()
                    }
                }
            }
            .padding(12)
            .reverieCardStyle(colorScheme: colorScheme)
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }
}

// MARK: - PDF Schedule Card

struct PDFScheduleCard: View {
    let pdf: ImportedPDF
    var isToday: Bool = false
    var isOverdue: Bool = false
    var onViewTasks: (() -> Void)? = nil

    @Environment(\.colorScheme) private var colorScheme

    /// Estimated time based on remaining tasks (~5 min per task)
    private var estimatedTimeString: String {
        let remainingTasks = pdf.totalTaskCount - pdf.completedTaskCount
        guard remainingTasks > 0 else { return "Done" }

        let minutes = remainingTasks * 5  // ~5 min per task estimate
        if minutes < 60 {
            return "~\(minutes)m"
        } else {
            let hours = Double(minutes) / 60.0
            if hours == floor(hours) {
                return "~\(Int(hours))h"
            } else {
                return String(format: "~%.1fh", hours)
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Priority indicator
                Circle()
                    .fill(pdf.priority.color)
                    .frame(width: 10, height: 10)

                VStack(alignment: .leading, spacing: 4) {
                    // Title with series indicator
                    HStack(spacing: 6) {
                        Text(pdf.title)
                            .font(.system(size: 14, weight: .medium))
                            .fontDesign(.serif)
                            .lineLimit(1)

                        if pdf.isPartOfSeries, let desc = pdf.seriesDescription {
                            Text(desc)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }

                    // Progress and dates
                    HStack(spacing: 8) {
                        // Category tag
                        HStack(spacing: 4) {
                            Image(systemName: pdf.category.icon)
                                .font(.caption2)
                            Text(pdf.categoryDisplayName)
                                .font(.caption2)
                        }
                        .foregroundStyle(pdf.category.color)

                        Text("•")
                            .foregroundStyle(.secondary)

                        // Progress
                        Text("\(pdf.completedTaskCount)/\(pdf.totalTaskCount)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        // Estimated time
                        HStack(spacing: 2) {
                            Image(systemName: "clock")
                                .font(.system(size: 9))
                            Text(estimatedTimeString)
                                .font(.caption)
                        }
                        .foregroundStyle(isToday ? Color.sageGreen : .secondary)

                        // Date info
                        if isOverdue, let days = pdf.daysRemaining {
                            Text("\(abs(days))d overdue")
                                .font(.caption)
                                .foregroundStyle(.red)
                        } else if let days = pdf.daysRemaining {
                            Text("\(days)d left")
                                .font(.caption)
                                .foregroundStyle(days <= 2 ? .orange : .secondary)
                        }
                    }
                }

                Spacer()

                // Progress ring
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 3)

                    Circle()
                        .trim(from: 0, to: pdf.progressPercentage)
                        .stroke(
                            isOverdue ? Color.red : pdf.priority.color,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: 28, height: 28)
            }
            .padding(12)

            // View Tasks button (only shown when callback provided)
            if let onViewTasks = onViewTasks {
                Divider()
                    .opacity(0.3)

                Button(action: onViewTasks) {
                    HStack(spacing: 6) {
                        Image(systemName: "checklist")
                            .font(.system(size: 12))
                        Text("View Tasks")
                            .font(.system(size: 13, weight: .medium))
                            .fontDesign(.serif)
                    }
                    .foregroundStyle(isToday ? Color.sageGreen : Color.dustyBlue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    isOverdue ? Color.red.opacity(0.08) :
                    isToday ? Color.sageGreen.opacity(0.08) :
                    Color.secondary.opacity(0.06)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isOverdue ? Color.red.opacity(0.3) :
                    isToday ? Color.sageGreen.opacity(0.3) :
                    Color.clear,
                    lineWidth: 1
                )
        )
    }
}

// MARK: - PDF Tasks Quick View Sheet

/// A lightweight sheet for quickly viewing and completing tasks from the schedule view
struct PDFTasksQuickViewSheet: View {
    let pdf: ImportedPDF
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            ZStack {
                ReverieWeaverBackground()

                ScrollView {
                    VStack(spacing: 16) {
                        // Header with progress
                        headerSection

                        // Task lists
                        if let taskLists = pdf.taskLists, !taskLists.isEmpty {
                            ForEach(taskLists, id: \.id) { taskList in
                                taskListSection(taskList)
                            }
                        } else {
                            noTasksView
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle(pdf.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontDesign(.serif)
                    .foregroundStyle(Color.sageGreen)
                }
            }
        }
    }

    // MARK: - Header Section

    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 12) {
            // Progress overview
            HStack(spacing: 16) {
                // Progress ring
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 6)

                    Circle()
                        .trim(from: 0, to: pdf.progressPercentage)
                        .stroke(
                            pdf.priority.color,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 0) {
                        Text("\(Int(pdf.progressPercentage * 100))%")
                            .font(.system(size: 18, weight: .bold))
                            .fontDesign(.rounded)
                        Text("done")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 70, height: 70)

                VStack(alignment: .leading, spacing: 6) {
                    // Task count
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.sageGreen)
                        Text("\(pdf.completedTaskCount) of \(pdf.totalTaskCount) tasks")
                            .font(.system(size: 14))
                            .fontDesign(.serif)
                    }

                    // Days remaining
                    if let days = pdf.daysRemaining {
                        HStack(spacing: 4) {
                            Image(systemName: days < 0 ? "exclamationmark.triangle.fill" : "clock")
                                .foregroundStyle(days < 0 ? .red : days <= 2 ? .orange : .secondary)
                            Text(days < 0 ? "\(abs(days)) days overdue" : "\(days) days remaining")
                                .font(.system(size: 14))
                                .fontDesign(.serif)
                                .foregroundStyle(days < 0 ? .red : days <= 2 ? .orange : .secondary)
                        }
                    }

                    // Category & Priority
                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(pdf.priority.color)
                                .frame(width: 8, height: 8)
                            Text(pdf.priority.rawValue.capitalized)
                                .font(.caption)
                        }

                        HStack(spacing: 4) {
                            Image(systemName: pdf.category.icon)
                                .font(.caption2)
                            Text(pdf.categoryDisplayName)
                                .font(.caption)
                        }
                        .foregroundStyle(pdf.category.color)
                    }
                }

                Spacer()
            }
            .padding(16)
            .reverieCardStyle(colorScheme: colorScheme)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Task List Section

    @ViewBuilder
    private func taskListSection(_ taskList: PDFTaskList) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // List header
            HStack {
                Text(taskList.name)
                    .font(.system(size: 14, weight: .semibold))
                    .fontDesign(.serif)

                Spacer()

                let (completed, total) = taskList.progress
                Text("\(completed)/\(total)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

            // Tasks
            VStack(spacing: 0) {
                if let tasks = taskList.tasks {
                    ForEach(tasks, id: \.id) { task in
                        TaskQuickRow(task: task) {
                            toggleTask(task)
                        }

                        if task.id != tasks.last?.id {
                            Divider()
                                .opacity(0.3)
                        }
                    }
                }
            }
            .reverieCardStyle(colorScheme: colorScheme)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - No Tasks View

    private var noTasksView: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(.secondary.opacity(0.5))

            Text("No tasks extracted yet")
                .font(.system(size: 15))
                .fontDesign(.serif)
                .foregroundStyle(.secondary)

            Text("Open the PDF Library to extract tasks")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 40)
    }

    // MARK: - Actions

    private func toggleTask(_ task: ExtractedTask) {
        withAnimation(.spring(response: 0.3)) {
            task.isCompleted.toggle()
            task.completedAt = task.isCompleted ? Date() : nil

            // Haptic feedback
            let impact = UIImpactFeedbackGenerator(style: task.isCompleted ? .medium : .light)
            impact.impactOccurred()

            try? modelContext.save()
        }
    }
}

// MARK: - Task Quick Row

private struct TaskQuickRow: View {
    let task: ExtractedTask
    let onToggle: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                // Completion checkbox
                ZStack {
                    Circle()
                        .stroke(task.isCompleted ? Color.sageGreen : Color.secondary.opacity(0.4), lineWidth: 1.5)
                        .frame(width: 22, height: 22)

                    if task.isCompleted {
                        Circle()
                            .fill(Color.sageGreen)
                            .frame(width: 22, height: 22)

                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }

                // Task text
                Text(task.text)
                    .font(.system(size: 14))
                    .fontDesign(.serif)
                    .strikethrough(task.isCompleted, color: .secondary)
                    .foregroundStyle(task.isCompleted ? .secondary : Color.dynamicLabel)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)

                Spacer()
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
