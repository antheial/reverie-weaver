//
//  AddPriorityTaskSheet.swift
//  Reverie Weaver
//
//  Updated 10/29/25 — Clean adaptive version, minimal boxing, muted tones
//

import SwiftUI
import SwiftData

// MARK: - Add Priority Task Sheet
struct AddPriorityTaskSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let selectedDate: Date

    @State private var title = ""
    @State private var taskDescription = ""
    @State private var hasEndDate = false
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var selectedColor = "C9D2B5"
    @State private var subTasks: [String] = []
    @State private var newSubTaskText = ""
    @State private var repeatOption = "none"
    @State private var customRepeatDays: Set<Int> = []
    @State private var showLimitAlert = false
    @Query private var allPriorityTasks: [PriorityTask]

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
                        sectionHeader(icon: "star.fill", title: "Priority Task", accent: selectedColor)

                        TextField("What's your priority?", text: $title)
                            .multilingualTextField()
                            .font(.system(size: 12))
                            .fontDesign(.serif)
                            .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                            .padding(16)
                            .background(fieldBackground(colorScheme))
                            .clipShape(RoundedRectangle(cornerRadius: 14))

                        // MARK: - Description (optional)
                        sectionHeader(icon: "text.alignleft", title: "Description (optional)")

                        TextField("Add more details about this task", text: $taskDescription, axis: .vertical)
                            .multilingualTextField()
                            .font(.system(size: 12))
                            .fontDesign(.serif)
                            .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                            .padding(16)
                            .background(fieldBackground(colorScheme))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .lineLimit(3...5)

                        // MARK: - Repeat
                        sectionHeader(icon: "repeat", title: "Repeat")

                        VStack(spacing: 10) {
                            ForEach(repeatOptions, id: \.0) { option in
                                Button {
                                    repeatOption = option.0
                                } label: {
                                    HStack(spacing: 12) {
                                        Text(option.2)
                                            .font(.system(size: 16))
                                            .timeAdaptiveText(colorScheme: colorScheme, style: .accent)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(option.1)
                                                .font(.system(size: 12, weight: .medium))
                                                .fontDesign(.serif)
                                                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

                                            switch option.0 {
                                            case "daily":
                                                Text("Every day")
                                                    .font(.system(size: 10))
                                                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                                            case "weekly":
                                                Text("Every week on \(startDate.formatted(.dateTime.weekday(.wide)))")
                                                    .font(.system(size: 10))
                                                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                                            case "weekdays":
                                                Text("Monday through Friday")
                                                    .font(.system(size: 10))
                                                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
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
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(repeatOption == option.0
                                                  ? Color(hex: selectedColor).opacity(0.10)
                                                  : Color.adaptiveSectionBackground(colorScheme: colorScheme))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(
                                                repeatOption == option.0
                                                ? Color(hex: selectedColor)
                                                : Color.adaptiveBorder(colorScheme: colorScheme),
                                                lineWidth: 1
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        // Custom day selector
                        if repeatOption == "custom" {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Select days")
                                    .font(.system(size: 11))
                                    .fontDesign(.serif)
                                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
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
                                                .font(.system(size: 11, weight: .medium))
                                                .fontDesign(.serif)
                                                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 8)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .fill(customRepeatDays.contains(day.0)
                                                              ? Color(hex: selectedColor).opacity(0.25)
                                                              : Color.adaptiveSectionBackground(colorScheme: colorScheme))
                                                )
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .strokeBorder(
                                                            customRepeatDays.contains(day.0)
                                                            ? Color(hex: selectedColor)
                                                            : Color.adaptiveBorder(colorScheme: colorScheme),
                                                            lineWidth: 1
                                                        )
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }

                        // MARK: - Timeline
                        sectionHeader(icon: "calendar", title: "Timeline")

                        VStack(spacing: 8) {
                            dateRow(label: "Start Date", selection: $startDate, colorScheme: colorScheme)

                            Toggle(isOn: $hasEndDate) {
                                Text("Set End Date")
                                    .font(.system(size: 12))
                                    .fontDesign(.serif)
                                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                            }
                            .tint(Color(hex: "C9D2B5"))              // muted app color (no bright green)
                            .padding(8)
                            .background(fieldBackground(colorScheme))
                            .clipShape(RoundedRectangle(cornerRadius: 14))

                            if hasEndDate {
                                dateRow(label: "End Date", selection: $endDate, colorScheme: colorScheme)
                            }
                        }

                        // MARK: - Sub-tasks (optional)
                        sectionHeader(icon: "checklist", title: "Sub-tasks (optional)")

                        VStack(spacing: 8) {
                            ForEach(Array(subTasks.enumerated()), id: \.offset) { index, subTask in
                                HStack(spacing: 12) {
                                    Image(systemName: "circle")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color(hex: selectedColor))

                                    Text(subTask)
                                        .font(.system(size: 12))
                                        .fontDesign(.serif)
                                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

                                    Spacer()

                                    Button {
                                        subTasks.remove(at: index)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 15))
                                            .foregroundStyle(Color.red.opacity(0.6)) // softer red
                                    }
                                }
                                .padding(10)
                                .background(fieldBackground(colorScheme))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }

                            // Add new subtask
                            HStack(spacing: 12) {
                                Image(systemName: "plus.circle")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color(hex: selectedColor))

                                TextField("Add a sub-task", text: $newSubTaskText)
                                    .multilingualTextField()
                                    .font(.system(size: 12))
                                    .fontDesign(.serif)
                                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                                    .onSubmit { addSubTask() }

                                if !newSubTaskText.isEmpty {
                                    Button("Add") { addSubTask() }
                                        .font(.system(size: 12, weight: .medium))
                                        .fontDesign(.serif)
                                        .foregroundStyle(Color(hex: selectedColor))
                                }
                            }
                            .padding(10)
                            .background(fieldBackground(colorScheme))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        // MARK: - Thread Color
                        sectionHeader(icon: "paintpalette.fill", title: "Thread Color")

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
                                                .font(.system(size: 11))
                                                .foregroundStyle(Color(hex: color.1))
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                    .padding(24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("New Priority Task")
                        .font(.system(size: 13, weight: .semibold))
                        .fontDesign(.serif)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                }
            }
            .presentationBackground(.clear)
            .presentationDetents([.fraction(0.75)]) // open at 75% height
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .font(.system(size: 12))
                        .fontDesign(.serif)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addTask() }
                        .font(.system(size: 12, weight: .medium))
                        .fontDesign(.serif)
                        .disabled(title.isEmpty)
                }
            }
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

    // MARK: - Actions
    private func addSubTask() {
        if !newSubTaskText.isEmpty {
            subTasks.append(newSubTaskText)
            newSubTaskText = ""
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
            customRepeatDays: Array(customRepeatDays)
        )

        for subTaskText in subTasks {
            let subTask = SubTask(title: subTaskText)
            modelContext.insert(subTask)
            if task.subTasks == nil { task.subTasks = [] }
            task.subTasks?.append(subTask)
        }

        modelContext.insert(task)
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
    @State private var subTasks: [SubTask] = []
    @State private var newSubTaskText = ""

    private let colors = [
        ("Sage Green", "C9D2B5"),
        ("Dusty Blue", "B8C7D6"),
        ("Terracotta Rose", "D9A58A"),
        ("Pale Mauve", "E6D7D2")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                ReverieWeaverBackground().ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // MARK: - Priority Task
                        sectionHeader(icon: "star.fill", title: "Priority Task", accent: selectedColor)

                        TextField("What's your priority?", text: $title)
                            .multilingualTextField()
                            .font(.system(size: 12))
                            .fontDesign(.serif)
                            .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                            .padding(16)
                            .background(fieldBackground(colorScheme))
                            .clipShape(RoundedRectangle(cornerRadius: 14))

                        // MARK: - Description (optional)
                        sectionHeader(icon: "text.alignleft", title: "Description (optional)")

                        TextField("Add more details about this task", text: $taskDescription, axis: .vertical)
                            .multilingualTextField()
                            .font(.system(size: 12))
                            .fontDesign(.serif)
                            .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                            .padding(16)
                            .background(fieldBackground(colorScheme))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .lineLimit(3...5)

                        // MARK: - Timeline
                        sectionHeader(icon: "calendar", title: "Timeline")

                        VStack(spacing: 8) {
                            dateRow(label: "Start Date", selection: $startDate, colorScheme: colorScheme)

                            Toggle(isOn: $hasEndDate) {
                                Text("Set End Date")
                                    .font(.system(size: 12))
                                    .fontDesign(.serif)
                                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                            }
                            .tint(Color(hex: "C9D2B5"))
                            .padding(10)
                            .background(fieldBackground(colorScheme))
                            .clipShape(RoundedRectangle(cornerRadius: 14))

                            if hasEndDate {
                                dateRow(label: "End Date", selection: $endDate, colorScheme: colorScheme)
                            }
                        }

                        // MARK: - Sub-tasks (optional)
                        sectionHeader(icon: "checklist", title: "Sub-tasks (optional)")

                        VStack(spacing: 8) {
                            ForEach(subTasks.sorted(by: { $0.createdAt < $1.createdAt }), id: \.id) { subTask in
                                HStack(spacing: 12) {
                                    Image(systemName: "circle")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color(hex: selectedColor))

                                    Text(subTask.title)
                                        .font(.system(size: 12))
                                        .fontDesign(.serif)
                                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

                                    Spacer()

                                    Button {
                                        deleteSubTask(subTask)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 15))
                                            .foregroundStyle(Color.red.opacity(0.6))
                                    }
                                }
                                .padding(10)
                                .background(fieldBackground(colorScheme))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }

                            // Add new subtask
                            HStack(spacing: 12) {
                                Image(systemName: "plus.circle")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color(hex: selectedColor))

                                TextField("Add a sub-task", text: $newSubTaskText)
                                    .multilingualTextField()
                                    .font(.system(size: 12))
                                    .fontDesign(.serif)
                                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                                    .onSubmit { addSubTask() }

                                if !newSubTaskText.isEmpty {
                                    Button("Add") { addSubTask() }
                                        .font(.system(size: 12, weight: .medium))
                                        .fontDesign(.serif)
                                        .foregroundStyle(Color(hex: selectedColor))
                                }
                            }
                            .padding(10)
                            .background(fieldBackground(colorScheme))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        // MARK: - Thread Color
                        sectionHeader(icon: "paintpalette.fill", title: "Thread Color")

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
                                                .font(.system(size: 10))
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
            }
            .navigationTitle("Edit Priority Task")
            .navigationBarTitleDisplayMode(.inline)
            .presentationBackground(.clear)
            .presentationDetents([.fraction(0.75)])
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .font(.system(size: 12))
                        .fontDesign(.serif)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveChanges() }
                        .font(.system(size: 12, weight: .medium))
                        .fontDesign(.serif)
                        .disabled(title.isEmpty)
                }
            }
            .onAppear { loadTaskData() }
        }
    }

    // MARK: - Actions
    private func addSubTask() {
        guard !newSubTaskText.isEmpty else { return }
        let new = SubTask(title: newSubTaskText)
        subTasks.append(new)
        newSubTaskText = ""
    }

    private func deleteSubTask(_ subTask: SubTask) {
        if let index = subTasks.firstIndex(where: { $0.id == subTask.id }) {
            modelContext.delete(subTasks[index])
            subTasks.remove(at: index)
        }
    }

    private func loadTaskData() {
        title = task.title
        taskDescription = task.taskDescription
        startDate = task.startDate
        endDate = task.endDate ?? Date()
        hasEndDate = task.endDate != nil
        selectedColor = task.colorHex
        subTasks = Array(task.subTasks ?? [])
    }

    private func saveChanges() {
        task.title = title
        task.taskDescription = taskDescription
        task.startDate = startDate
        task.endDate = hasEndDate ? endDate : nil
        task.colorHex = selectedColor
        task.subTasks = subTasks
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Shared Helpers (kept local in this file)
fileprivate func fieldBackground(_ colorScheme: ColorScheme) -> some View {
    RoundedRectangle(cornerRadius: 12)
        .fill(Color.adaptiveSectionBackground(colorScheme: colorScheme).opacity(0.75))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.adaptiveBorder(colorScheme: colorScheme), lineWidth: 1)
        )
}

fileprivate func sectionHeader(icon: String, title: String, accent: String? = nil) -> some View {
    HStack(spacing: 6) {
        Image(systemName: icon)
            .font(.system(size: 12))
            .foregroundStyle(accent != nil ? Color(hex: accent!) : Color.paleMauve)
        Text(title)
            .font(.system(size: 12, weight: .medium))
            .fontDesign(.serif)
            .timeAdaptiveText(colorScheme: UITraitCollection.current.userInterfaceStyle == .dark ? .dark : .light,
                              style: .primary)
        Spacer()
    }
}

fileprivate func dateRow(label: String, selection: Binding<Date>, colorScheme: ColorScheme) -> some View {
    HStack {
        Text(label)
            .font(.system(size: 12))
            .fontDesign(.serif)
            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
        Spacer()
        DatePicker("", selection: selection, displayedComponents: .date)
            .labelsHidden()
            .transformEffect(.init(scaleX: 0.85, y: 0.85))
            .frame(height: 26)
    }
    .padding(10)
    .background(fieldBackground(colorScheme))
    .clipShape(RoundedRectangle(cornerRadius: 12))
}
