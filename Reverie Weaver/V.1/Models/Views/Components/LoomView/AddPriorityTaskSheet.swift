//
//  AddPriorityTaskSheet.swift
//  Reverie Weaver
//
//
//

import SwiftUI
import SwiftData

// MARK: - Add Priority Task Sheet
struct AddPriorityTaskSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let selectedDate: Date

    // Form State
    @State private var title = ""
    @State private var taskDescription = ""
    @State private var hasEndDate = false
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var selectedColor = "C9D2B5"
    
    // Logic State
    @State private var subTasks: [String] = []
    @State private var newSubTaskText = ""
    @State private var repeatOption = "none"
    @State private var customRepeatDays: Set<Int> = []
    @State private var showLimitAlert = false
    
    // Queries
    @Query private var allPriorityTasks: [PriorityTask]

    // Constants
    private let colors = [
        ("Sage Green", "C9D2B5"),
        ("Dusty Blue", "B8C7D6"),
        ("Terracotta Rose", "D9A58A"),
        ("Pale Mauve", "E6D7D2")
    ]

    private let repeatOptions = [
         ("none", "Once", "✓"),
         ("daily", "Daily", "∞"),
         ("weekly", "Weekly", "↻"),
         ("weekdays", "Weekdays", "⋯"),
         ("custom", "Custom", "⚙️")
     ]

    private let weekdays = [
        (1, "Sun"), (2, "Mon"), (3, "Tue"), (4, "Wed"),
        (5, "Thu"), (6, "Fri"), (7, "Sat")
    ]

    var body: some View {
            NavigationStack {
                ZStack {
                    ReverieWeaverBackground().ignoresSafeArea()

                    ScrollView {
                        VStack(spacing: 24) {
                            // 1. Title Section
                            titleSection

                            // 2. Description Section
                            descriptionSection

                            // 3. Repeat Options Section
                            repeatSection

                            // 4. Timeline Section
                            timelineSection

                            // 5. Sub-tasks Section
                            subTasksSection

                            // 6. Color Section
                            colorSection
                        }
                        .padding(24)
                    }
                    .scrollDismissesKeyboard(.interactively)
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("New Priority Task")
                            .font(.system(size: 13, weight: .semibold))
                            .fontDesign(.serif)
                            .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    }
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                            .font(.system(size: 13))
                            .fontDesign(.serif)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") { addTask() }
                            .font(.system(size: 13, weight: .medium))
                            .fontDesign(.serif)
                            .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .presentationBackground(.clear)
                .presentationDetents([.fraction(0.75)])
                .onAppear {
                    startDate = selectedDate
                    endDate = selectedDate
                }
                .alert("Daily Limit Reached", isPresented: $showLimitAlert) {
                    Button("OK") { }
                } message: {
                    Text("You can only have 3 active priority tasks per day. Complete or remove an existing task first.")
                }
            }
        }

        // MARK: - Extracted View Components

        @ViewBuilder
        private var titleSection: some View {
            sectionHeader(icon: "star.fill", title: "Priority Task", accent: selectedColor, colorScheme: colorScheme)

            TextField("What's your priority?", text: $title)
                .multilingualTextField()
                .font(.system(size: 13))
                .fontDesign(.serif)
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                .padding(16)
                .reverieCardStyle(colorScheme: colorScheme)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }

        @ViewBuilder
        private var descriptionSection: some View {
            sectionHeader(icon: "text.alignleft", title: "Description (optional)", colorScheme: colorScheme)

            TextField("Add more details about this task", text: $taskDescription, axis: .vertical)
                .multilingualTextField()
                .font(.system(size: 12))
                .fontDesign(.serif)
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                .padding(16)
                .reverieCardStyle(colorScheme: colorScheme)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .lineLimit(3...5)
        }

        @ViewBuilder
        private var repeatSection: some View {
            sectionHeader(icon: "repeat", title: "Repeat", colorScheme: colorScheme)

            VStack(spacing: 10) {
                ForEach(repeatOptions, id: \.0) { option in
                    Button {
                        withAnimation(.snappy) {
                            repeatOption = option.0
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Text(option.2)
                                .font(.system(size: 16))
                                .timeAdaptiveText(colorScheme: colorScheme, style: .accent)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(option.1)
                                    .font(.system(size: 13, weight: .medium))
                                    .fontDesign(.serif)
                                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

                                // Contextual helper text
                                switch option.0 {
                                case "daily":
                                    Text("Every day")
                                        .font(.system(size: 11))
                                        .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                                case "weekly":
                                    Text("Every week on \(startDate.formatted(.dateTime.weekday(.wide)))")
                                        .font(.system(size: 11))
                                        .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                                case "weekdays":
                                    Text("Monday through Friday")
                                        .font(.system(size: 11))
                                        .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                                default:
                                    EmptyView()
                                }
                            }

                            Spacer()

                            if repeatOption == option.0 {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(Color(hex: selectedColor))
                            }
                        }
                        .padding(14)
                        .reverieCardStyle(colorScheme: colorScheme)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(
                                    repeatOption == option.0
                                    ? Color(hex: selectedColor)
                                    : Color.clear,
                                    lineWidth: 1.5
                                )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }

            // Custom Day Selector
            if repeatOption == "custom" {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Select days")
                        .font(.system(size: 12))
                        .fontDesign(.serif)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                    HStack(spacing: 8) {
                        ForEach(weekdays, id: \.0) { day in
                            Button {
                                if customRepeatDays.contains(day.0) {
                                    customRepeatDays.remove(day.0)
                                } else {
                                    customRepeatDays.insert(day.0)
                                }
                            } label: {
                                Text(day.1)
                                    .font(.system(size: 12, weight: .medium))
                                    .fontDesign(.serif)
                                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .reverieCardStyle(colorScheme: colorScheme)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .strokeBorder(
                                                customRepeatDays.contains(day.0)
                                                ? Color(hex: selectedColor)
                                                : Color.clear,
                                                lineWidth: 1.5
                                            )
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }

        @ViewBuilder
        private var timelineSection: some View {
            sectionHeader(icon: "calendar", title: "Timeline", colorScheme: colorScheme)

            VStack(spacing: 8) {
                dateRow(label: "Start Date", selection: $startDate, colorScheme: colorScheme)
                    .onChange(of: startDate) { _, newValue in
                        if hasEndDate && endDate < newValue {
                            endDate = newValue
                        }
                    }

                Toggle(isOn: $hasEndDate.animation()) {
                    Text("Set End Date")
                        .font(.system(size: 13))
                        .fontDesign(.serif)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                }
                .tint(Color(hex: "C9D2B5"))
                .padding(10)
                .reverieCardStyle(colorScheme: colorScheme)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                if hasEndDate {
                    dateRow(label: "End Date", selection: $endDate, colorScheme: colorScheme)
                        .onChange(of: endDate) { _, newValue in
                            if newValue < startDate {
                                startDate = newValue
                            }
                        }
                }
            }
        }

    @ViewBuilder
        private var subTasksSection: some View {
            sectionHeader(icon: "checklist", title: "Sub-tasks (optional)", colorScheme: colorScheme)

            VStack(spacing: 8) {
                // We use Array(subTasks.enumerated()) to get the index safely
                ForEach(Array(subTasks.enumerated()), id: \.offset) { index, subTask in
                    HStack(spacing: 12) {
                        Image(systemName: "circle")
                            .font(.system(size: 13))
                            .foregroundStyle(Color(hex: selectedColor))

                        Text(subTask)
                            .font(.system(size: 13))
                            .fontDesign(.serif)
                            .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

                        Spacer()

                        Button {
                            deleteSubTask(at: index)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 15))
                                .foregroundStyle(Color.red.opacity(0.6))
                        }
                    }
                    .padding(10)
                    .reverieCardStyle(colorScheme: colorScheme)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                HStack(spacing: 12) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: selectedColor))

                    TextField("Add a sub-task", text: $newSubTaskText)
                        .multilingualTextField()
                        .font(.system(size: 13))
                        .fontDesign(.serif)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                        .onSubmit { addSubTask() }

                    if !newSubTaskText.trimmingCharacters(in: .whitespaces).isEmpty {
                        Button("Add") { addSubTask() }
                            .font(.system(size: 13, weight: .medium))
                            .fontDesign(.serif)
                            .foregroundStyle(Color(hex: selectedColor))
                    }
                }
                .padding(10)
                .reverieCardStyle(colorScheme: colorScheme)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }

        @ViewBuilder
        private var colorSection: some View {
            sectionHeader(icon: "paintpalette.fill", title: "Thread Color", colorScheme: colorScheme)

            HStack(spacing: 12) {
                ForEach(colors, id: \.1) { color in
                    Button {
                        selectedColor = color.1
                    } label: {
                        VStack(spacing: 6) {
                            Circle()
                                .fill(Color(hex: color.1))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle().strokeBorder(
                                        selectedColor == color.1
                                        ? Color.dynamicLabel.opacity(0.9)
                                        : .clear,
                                        lineWidth: 2
                                    )
                                )
                            if selectedColor == color.1 {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color(hex: color.1))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 6)
        }

    // MARK: - Actions
    private func addSubTask() {
        let trimmed = newSubTaskText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            withAnimation {
                subTasks.append(trimmed)
                newSubTaskText = ""
            }
        }
    }
    
    private func deleteSubTask(at index: Int) {
            withAnimation {
                if subTasks.indices.contains(index) {
                    subTasks.remove(at: index)
                }
            }
        }

    private func addTask() {
        let activeTasks = allPriorityTasks.filter { $0.isActive(on: selectedDate) && !$0.isCompleted }

        if activeTasks.count >= 3 {
            showLimitAlert = true
            return
        }

        let task = PriorityTask(
            title: title,
            taskDescription: taskDescription,
            startDate: startDate,
            endDate: hasEndDate ? endDate : nil,
            colorHex: selectedColor,
            repeatType: repeatOption,
            customRepeatDays: Array(customRepeatDays).sorted()
        )
        
        #if DEBUG
        AppLog.info("━━━ Creating New Priority Task ━━━", category: "task.create")
        AppLog.info("  Title: '\(title)'", category: "task.create")
        AppLog.info("  RepeatType: \(repeatOption)", category: "task.create")
        AppLog.info("  CustomDays: \(Array(customRepeatDays).sorted())", category: "task.create")
        AppLog.info("  StartDate: \(startDate.formatted(.dateTime.month().day().year()))", category: "task.create")
        if let end = task.endDate {
            AppLog.info("  EndDate: \(end.formatted(.dateTime.month().day().year()))", category: "task.create")
        }
        AppLog.info("  Color: #\(selectedColor)", category: "task.create")
        AppLog.info("  SubTasks: \(subTasks.count)", category: "task.create")
        #endif

        for subTaskText in subTasks {
            let subTask = SubTask(title: subTaskText)
            modelContext.insert(subTask)
            if task.subTasks == nil { task.subTasks = [] }
            task.subTasks?.append(subTask)
        }

        modelContext.insert(task)
        
        #if DEBUG
        AppLog.info("✅ Task created and inserted successfully", category: "task.create")
        #endif
        
        dismiss()
    }
}

// MARK: - Edit Priority Task Sheet

struct EditPriorityTaskSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let task: PriorityTask

    @State private var title = ""
    @State private var taskDescription = ""
    @State private var hasEndDate = false
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var selectedColor = "C9D2B5"
    @State private var repeatOption = "none"
    @State private var customRepeatDays: Set<Int> = []
    
    struct TempSubTask: Identifiable, Equatable {
        let id = UUID()
        var originalObject: SubTask?
        var title: String
    }
    
    @State private var tempSubTasks: [TempSubTask] = []
    @State private var newSubTaskText = ""

    private let colors = [
        ("Sage Green", "C9D2B5"),
        ("Dusty Blue", "B8C7D6"),
        ("Terracotta Rose", "D9A58A"),
        ("Pale Mauve", "E6D7D2")
    ]
    
    private let repeatOptions = [
        ("none", "Once", "✓"),
        ("daily", "Daily", "∞"),
        ("weekly", "Weekly", "↻"),
        ("weekdays", "Weekdays", "⋯"),
        ("custom", "Custom", "⚙️")
    ]

    private let weekdays = [
        (1, "Sun"), (2, "Mon"), (3, "Tue"), (4, "Wed"),
        (5, "Thu"), (6, "Fri"), (7, "Sat")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                ReverieWeaverBackground().ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // MARK: - Priority Task
                        sectionHeader(icon: "star.fill", title: "Priority Task", accent: selectedColor, colorScheme: colorScheme)

                        TextField("What's your priority?", text: $title)
                            .multilingualTextField()
                            .font(.system(size: 13))
                            .fontDesign(.serif)
                            .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                            .padding(16)
                            .reverieCardStyle(colorScheme: colorScheme)
                            .clipShape(RoundedRectangle(cornerRadius: 14))

                        // MARK: - Description (optional)
                        sectionHeader(icon: "text.alignleft", title: "Description (optional)", colorScheme: colorScheme)

                        TextField("Add more details about this task", text: $taskDescription, axis: .vertical)
                            .multilingualTextField()
                            .font(.system(size: 12))
                            .fontDesign(.serif)
                            .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                            .padding(16)
                            .reverieCardStyle(colorScheme: colorScheme)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .lineLimit(3...5)

                        // MARK: - Repeat Options
                        sectionHeader(icon: "repeat", title: "Repeat", colorScheme: colorScheme)

                        VStack(spacing: 10) {
                            ForEach(repeatOptions, id: \.0) { option in
                                Button {
                                    withAnimation(.snappy) {
                                        repeatOption = option.0
                                    }
                                } label: {
                                    HStack(spacing: 12) {
                                        Text(option.2)
                                            .font(.system(size: 16))
                                            .timeAdaptiveText(colorScheme: colorScheme, style: .accent)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(option.1)
                                                .font(.system(size: 13, weight: .medium))
                                                .fontDesign(.serif)
                                                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

                                            // Contextual helper text
                                            switch option.0 {
                                            case "daily":
                                                Text("Every day")
                                                    .font(.system(size: 11))
                                                    .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                                            case "weekly":
                                                Text("Every week on \(startDate.formatted(.dateTime.weekday(.wide)))")
                                                    .font(.system(size: 11))
                                                    .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                                            case "weekdays":
                                                Text("Monday through Friday")
                                                    .font(.system(size: 11))
                                                    .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                                            default:
                                                EmptyView()
                                            }
                                        }

                                        Spacer()

                                        if repeatOption == option.0 {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 16))
                                                .foregroundStyle(Color(hex: selectedColor))
                                        }
                                    }
                                    .padding(12)
                                    .reverieCardStyle(colorScheme: colorScheme)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .strokeBorder(
                                                repeatOption == option.0
                                                    ? Color(hex: selectedColor).opacity(0.5)
                                                    : Color.clear,
                                                lineWidth: 1.5
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }

                            // Custom weekday selector
                            if repeatOption == "custom" {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Select Days")
                                        .font(.system(size: 12, weight: .medium))
                                        .fontDesign(.serif)
                                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)

                                    HStack(spacing: 6) {
                                        ForEach(weekdays, id: \.0) { day in
                                            Button {
                                                if customRepeatDays.contains(day.0) {
                                                    customRepeatDays.remove(day.0)
                                                } else {
                                                    customRepeatDays.insert(day.0)
                                                }
                                            } label: {
                                                Text(day.1)
                                                    .font(.system(size: 12, weight: .medium))
                                                    .fontDesign(.serif)
                                                    .foregroundStyle(
                                                        customRepeatDays.contains(day.0)
                                                            ? .white
                                                            : Color.dynamicLabel.opacity(0.6)
                                                    )
                                                    .frame(maxWidth: .infinity)
                                                    .padding(.vertical, 8)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .fill(
                                                                customRepeatDays.contains(day.0)
                                                                    ? Color(hex: selectedColor)
                                                                    : Color.adaptiveSectionBackground(colorScheme: colorScheme)
                                                            )
                                                    )
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                                .padding(12)
                                .reverieCardStyle(colorScheme: colorScheme)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }

                        // MARK: - Timeline
                        sectionHeader(icon: "calendar", title: "Timeline", colorScheme: colorScheme)

                        VStack(spacing: 8) {
                            dateRow(label: "Start Date", selection: $startDate, colorScheme: colorScheme)
                                .onChange(of: startDate) { _, newValue in
                                    if hasEndDate && endDate < newValue { endDate = newValue }
                                }

                            Toggle(isOn: $hasEndDate.animation()) {
                                Text("Set End Date")
                                    .font(.system(size: 13))
                                    .fontDesign(.serif)
                                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                            }
                            .tint(Color(hex: "C9D2B5"))
                            .padding(10)
                            .reverieCardStyle(colorScheme: colorScheme)
                            .clipShape(RoundedRectangle(cornerRadius: 14))

                            if hasEndDate {
                                dateRow(label: "End Date", selection: $endDate, colorScheme: colorScheme)
                                    .onChange(of: endDate) { _, newValue in
                                        if newValue < startDate { startDate = newValue }
                                    }
                            }
                        }

                        // MARK: - Sub-tasks (optional)
                        sectionHeader(icon: "checklist", title: "Sub-tasks (optional)", colorScheme: colorScheme)

                        VStack(spacing: 8) {
                            ForEach(tempSubTasks) { subTask in
                                HStack(spacing: 12) {
                                    Image(systemName: "circle")
                                        .font(.system(size: 13))
                                        .foregroundStyle(Color(hex: selectedColor))

                                    Text(subTask.title)
                                        .font(.system(size: 13))
                                        .fontDesign(.serif)
                                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

                                    Spacer()

                                    Button {
                                        deleteSubTask(subTask.id)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 15))
                                            .foregroundStyle(Color.red.opacity(0.6))
                                    }
                                }
                                .padding(10)
                                .reverieCardStyle(colorScheme: colorScheme)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }

                            HStack(spacing: 12) {
                                Image(systemName: "plus.circle")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color(hex: selectedColor))

                                TextField("Add a sub-task", text: $newSubTaskText)
                                    .multilingualTextField()
                                    .font(.system(size: 13))
                                    .fontDesign(.serif)
                                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                                    .onSubmit { addSubTask() }

                                if !newSubTaskText.trimmingCharacters(in: .whitespaces).isEmpty {
                                    Button("Add") { addSubTask() }
                                        .font(.system(size: 13, weight: .medium))
                                        .fontDesign(.serif)
                                        .foregroundStyle(Color(hex: selectedColor))
                                }
                            }
                            .padding(10)
                            .reverieCardStyle(colorScheme: colorScheme)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        // MARK: - Thread Color
                        sectionHeader(icon: "paintpalette.fill", title: "Thread Color", colorScheme: colorScheme)

                        HStack(spacing: 12) {
                            ForEach(colors, id: \.1) { color in
                                Button {
                                    selectedColor = color.1
                                } label: {
                                    VStack(spacing: 6) {
                                        Circle()
                                            .fill(Color(hex: color.1))
                                            .frame(width: 34, height: 34)
                                            .overlay(
                                                Circle().strokeBorder(
                                                    selectedColor == color.1
                                                    ? Color.dynamicLabel.opacity(0.9)
                                                    : .clear,
                                                    lineWidth: 2
                                                )
                                            )
                                        if selectedColor == color.1 {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 11))
                                                .foregroundStyle(Color(hex: color.1))
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(24)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Edit Priority Task")
            .navigationBarTitleDisplayMode(.inline)
            .presentationBackground(.clear)
            .presentationDetents([.fraction(0.75)])
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .font(.system(size: 13))
                        .fontDesign(.serif)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveChanges() }
                        .font(.system(size: 13, weight: .medium))
                        .fontDesign(.serif)
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear { loadTaskData() }
        }
    }

    // MARK: - Actions
    
    private func addSubTask() {
        let trimmed = newSubTaskText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        withAnimation {
            let new = TempSubTask(originalObject: nil, title: trimmed)
            tempSubTasks.append(new)
            newSubTaskText = ""
        }
    }

    private func deleteSubTask(_ id: UUID) {
        withAnimation {
            if let index = tempSubTasks.firstIndex(where: { $0.id == id }) {
                tempSubTasks.remove(at: index)
            }
        }
    }

    private func loadTaskData() {
        title = task.title
        taskDescription = task.taskDescription
        startDate = task.startDate
        endDate = task.endDate ?? Date()
        hasEndDate = task.endDate != nil
        selectedColor = task.colorHex
        repeatOption = task.repeatType
        customRepeatDays = Set(task.customRepeatDays)
        
        // Load existing subtasks into Temp structures
        if let existing = task.subTasks {
            // Sort by creation time if possible, or another stable sort
            let sorted = existing.sorted(by: { $0.createdAt < $1.createdAt })
            tempSubTasks = sorted.map { TempSubTask(originalObject: $0, title: $0.title) }
        }
        
        #if DEBUG
        AppLog.info("Loaded task data for editing:", category: "task.edit")
        AppLog.info("  - Title: '\(task.title)'", category: "task.edit")
        AppLog.info("  - RepeatType: \(task.repeatType)", category: "task.edit")
        AppLog.info("  - CustomDays: \(task.customRepeatDays)", category: "task.edit")
        #endif
    }

    private func saveChanges() {
        // 1. Update main properties
        task.title = title
        task.taskDescription = taskDescription
        task.startDate = startDate
        task.endDate = hasEndDate ? endDate : nil
        task.colorHex = selectedColor
        task.repeatType = repeatOption
        task.customRepeatDays = Array(customRepeatDays).sorted()
        
        #if DEBUG
        AppLog.info("Saving task changes:", category: "task.edit")
        AppLog.info("  - Title: '\(title)'", category: "task.edit")
        AppLog.info("  - RepeatType: \(repeatOption)", category: "task.edit")
        AppLog.info("  - CustomDays: \(Array(customRepeatDays).sorted())", category: "task.edit")
        #endif
        
        // 2. Reconcile SubTasks
        
        // A. Identify IDs currently in the UI
        let currentOriginalObjects = Set(tempSubTasks.compactMap { $0.originalObject })
        
        // B. Identify objects to delete (were in task.subTasks, but not in UI anymore)
        if let existing = task.subTasks {
            for subObj in existing {
                if !currentOriginalObjects.contains(subObj) {
                    // Remove relationship
                    if let idx = task.subTasks?.firstIndex(of: subObj) {
                        task.subTasks?.remove(at: idx)
                    }
                    modelContext.delete(subObj)
                }
            }
        }
        
        // C. Add new objects or Update existing
        for temp in tempSubTasks {
            if let original = temp.originalObject {
                // Update existing
                original.title = temp.title
            } else {
                // Create new
                let newSub = SubTask(title: temp.title)
                modelContext.insert(newSub)
                if task.subTasks == nil { task.subTasks = [] }
                task.subTasks?.append(newSub)
            }
        }
        
        // 3. Save
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Shared Helpers
fileprivate func fieldBackground(_ colorScheme: ColorScheme) -> some View {
    RoundedRectangle(cornerRadius: 12)
        .fill(Color.adaptiveSectionBackground(colorScheme: colorScheme).opacity(0.75))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.adaptiveBorder(colorScheme: colorScheme), lineWidth: 1)
        )
}

fileprivate func sectionHeader(icon: String, title: String, accent: String? = nil, colorScheme: ColorScheme) -> some View {
    HStack(spacing: 6) {
        Image(systemName: icon)
            .font(.system(size: 13))
            .foregroundStyle(accent != nil ? Color(hex: accent!) : Color.paleMauve)
        Text(title)
            .font(.system(size: 13, weight: .medium))
            .fontDesign(.serif)
            .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
        Spacer()
    }
}

fileprivate func dateRow(label: String, selection: Binding<Date>, colorScheme: ColorScheme) -> some View {
    HStack {
        Text(label)
            .font(.system(size: 13))
            .fontDesign(.serif)
            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
        Spacer()
        DatePicker("", selection: selection, displayedComponents: .date)
            .labelsHidden()
            .transformEffect(.init(scaleX: 0.85, y: 0.85))
            .frame(height: 26)
    }
    .padding(10)
    .reverieCardStyle(colorScheme: colorScheme)
    .clipShape(RoundedRectangle(cornerRadius: 12))
}
