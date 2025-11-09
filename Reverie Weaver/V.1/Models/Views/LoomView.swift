//
// LoomView.swift
// ReverieWeaver
//
// The Loom - Daily tracker and timeline with consistent dark mode
// FULLY UPDATED with Archive-style navigation and custom alerts
//

import SwiftUI
import SwiftData
import AudioToolbox  // Add this line after import SwiftData
import Combine  // ← NEW: Required for Timer.autoconnect()
import UIKit

struct LoomView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme  // ← Add this line
    @Query(sort: \Habit.order) private var habits: [Habit]
    @Query private var completions: [HabitCompletion]
    @Query private var profiles: [UserProfile]
    @Query private var allPriorityTasks: [PriorityTask]
    @Query private var pomodoroSessions: [PomodoroSession]
    @Query private var microHabitCompletions: [MicroHabitCompletion]
    
    @State private var selectedDate = Date()
    @State private var lastCheckedDay: Date = Date()

    @State private var showReflection: HabitCompletion?
    @State private var showAddTask = false
    @State private var showEditTask: PriorityTask?
    @State private var showCarryOverAlert = false
    @State private var taskToComplete: PriorityTask?
    @State private var showLimitAlert = false
    @State private var showDatePicker = false  // ✅ NEW: For calendar picker
    @State private var currentDate = Date()
    @State private var showCompletedTasks = false  // ✅ NEW: For collapsible completed section
    @State private var showOngoingWeaves = false
    
    // Pomodoro Timer
    @State private var currentTime = Date()
    @State private var timerManager = PomodoroTimerManager()
    
    private var weekStartsOnSunday: Bool {
        profiles.first?.weekStartsOnSunday ?? true
    }
    
    private var selectedDayCompletions: [HabitCompletion] {
        let calendar = Calendar.current
        let selectedDay = calendar.startOfDay(for: selectedDate)
        
        return completions
            .filter { completion in
                let completionDay = calendar.startOfDay(for: completion.completedAt)
                return completionDay == selectedDay
            }
            .sorted { $0.completedAt < $1.completedAt }
    }
    
    private var selectedDayPomodoros: [PomodoroSession] {
        let cal = {
            var c = Calendar(identifier: .gregorian)
            c.timeZone = .current
            return c
        }()

        return pomodoroSessions
            .filter { cal.isDate($0.completedAt, inSameDayAs: selectedDate) }
            .sorted { $0.completedAt < $1.completedAt }
    }
    
    private var selectedDayMicroHabits: [MicroHabitCompletion] {
        let cal = {
            var c = Calendar(identifier: .gregorian)
            c.timeZone = .current
            return c
        }()

        return microHabitCompletions
            .filter { cal.isDate($0.completedAt, inSameDayAs: selectedDate) }
            .sorted { $0.completedAt < $1.completedAt }
    }
    
    // ✅ ADD THESE THREE
    /// Tasks that start TODAY (count toward 3 limit)
    private var todaysPriorityTasks: [PriorityTask] {
        allPriorityTasks
            .filter { task in
                !task.isCompleted &&
                task.isActive(on: selectedDate) &&
                task.startsOn(selectedDate)  // 👈 NEW: Only tasks starting today
            }
            .sorted { $0.createdAt < $1.createdAt }
    }

    /// Tasks that started BEFORE today but are still active
    private var ongoingPriorityTasks: [PriorityTask] {
        allPriorityTasks
            .filter { task in
                !task.isCompleted &&
                task.isActive(on: selectedDate) &&
                !task.startsOn(selectedDate)  // 👈 NEW: Tasks NOT starting today
            }
            .sorted { $0.startDate < $1.startDate }
    }

    /// All active tasks combined (for the 3-task limit check)
    private var allActiveTasks: [PriorityTask] {
        todaysPriorityTasks + ongoingPriorityTasks
    }
    
    private var completedPriorityTasks: [PriorityTask] {
        allPriorityTasks
            .filter { task in
                guard task.isCompleted, let completedAt = task.completedAt else { return false }
                return isSameLocalDay(completedAt, selectedDate)
            }
            .sorted { $0.completedAt ?? Date() > $1.completedAt ?? Date() }
    }
    
    private var weekDates: [Date] {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: selectedDate)
        
        let startDay: Date
        if weekStartsOnSunday {
            let daysFromSunday = weekday - 1
            startDay = calendar.date(byAdding: .day, value: -daysFromSunday, to: selectedDate)!
        } else {
            let daysFromMonday = (weekday == 1) ? 6 : weekday - 2
            startDay = calendar.date(byAdding: .day, value: -daysFromMonday, to: selectedDate)!
        }
        
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startDay) }
    }
    
    // Check if any sheet is presented
        private var isAnySheetPresented: Bool {
            showReflection != nil || showAddTask || showEditTask != nil || showDatePicker || showCarryOverAlert
        }
    
    var body: some View {
        NavigationStack {
            ZStack {
                ReverieWeaverBackground()  // ← ADD THIS LINE
                ScrollView {
                    VStack(spacing: 24) {
                    headerSection
                    weekCalendarWithTasks
                    priorityTasksSection
                    timelineSection
                }
                    .padding(.bottom, 100) // Extra padding for floating timer
                .dismissKeyboardOnBackgroundTap()
            }
                .background(Color.clear)
                
                // Floating Pomodoro Timer
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        FloatingPomodoroTimer(timerManager: timerManager)
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, 100) // Above tab bar
                }
                .opacity(isAnySheetPresented ? 0 : 1)
                .allowsHitTesting(!isAnySheetPresented)
            }
            // Put this AFTER the ScrollView and floating timer, but BEFORE the closing }
            .overlay {
                if timerManager.showCompletionToast {
                    HybridCompletionToast(
                        sessionType: timerManager.timerState,
                        sessionCount: timerManager.sessionCount,
                        onStartBreak: {
                            timerManager.startBreakFromToast()
                        },
                        onDismiss: {
                            timerManager.dismissToast()
                        }
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(999)
                }
            }
            .sheet(item: $showReflection) { completion in
                if let habit = habits.first(where: { $0.id == completion.habitId }) {
                    ReflectionSheet(habit: habit, completion: completion) {
                        showReflection = nil
                    }
                }
            }
            .sheet(isPresented: $showAddTask) {
                AddPriorityTaskSheet(selectedDate: selectedDate)
            }
            .sheet(item: $showEditTask) { task in
                EditPriorityTaskSheet(task: task)
            }
            // ✅ NEW: Calendar Picker Sheet
            .sheet(isPresented: $showDatePicker) {
                WeekCalendarSheet(currentDate: $selectedDate)
                    .presentationDetents([.medium])
                    .presentationCornerRadius(24)
            }

            // ✅ UPDATED: Custom Carry Over Sheet (replaces .alert)
            .sheet(isPresented: $showCarryOverAlert) {
                CustomCarryOverSheet(
                    taskToComplete: taskToComplete,
                    onComplete: { carryOver in
                        if let task = taskToComplete {
                            completeTask(task, carryOver: carryOver)
                        }
                        showCarryOverAlert = false
                    },
                    onCancel: {
                        taskToComplete = nil
                        showCarryOverAlert = false
                    }
                )
            }
            .onAppear {
                timerManager.setContext(modelContext)
                
                // Force refresh all data when view appears
                Task { @MainActor in
                    do {
                        _ = try modelContext.fetch(FetchDescriptor<HabitCompletion>())
                        _ = try modelContext.fetch(FetchDescriptor<PomodoroSession>())
                        _ = try modelContext.fetch(FetchDescriptor<MicroHabitCompletion>())
                    } catch {
                        print("⚠️ LoomView data fetch failed: \(error)")
                    }
                }
            }
            
            .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
                currentTime = Date()
                checkForDayChange()
            }

            // 🧩 Force re-fetch SwiftData whenever user changes day
            .onChange(of: selectedDate) { oldDate, newDate in
                // Force refresh all SwiftData queries
                Task { @MainActor in
                    do {
                        // Explicit fetch to trigger SwiftData refresh
                        let completionDescriptor = FetchDescriptor<HabitCompletion>()
                        _ = try modelContext.fetch(completionDescriptor)
                        
                        let pomodoroDescriptor = FetchDescriptor<PomodoroSession>()
                        _ = try modelContext.fetch(pomodoroDescriptor)
                        
                        let microHabitDescriptor = FetchDescriptor<MicroHabitCompletion>()
                        _ = try modelContext.fetch(microHabitDescriptor)
                        
                        print("✅ LoomView data refreshed for date: \(newDate)")
                        print("   Completions for this day: \(selectedDayCompletions.count)")
                    } catch {
                        print("⚠️ Failed to refresh Loom data: \(error)")
                    }
                }
            }


            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                // App going to background - save timestamp
                timerManager.handleAppWillResignActive()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                // App returning to foreground - sync elapsed time
                timerManager.handleAppDidBecomeActive()
            }
                    }
                }
    
    // MARK: - Header (SWIPEABLE WEEK DATE)
       private var headerSection: some View {
           VStack(spacing: 12) {
               HStack {
                   Text("The Loom")
                       .font(.system(size: 23, weight: .regular))
                       .fontDesign(.serif)
                       .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                   
                   Spacer()
                   
                   // Calendar picker button only
                   Button {
                       showDatePicker = true
                   } label: {
                       Image(systemName: "calendar")
                           .font(.system(size: 16))
                           .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                           .frame(width: 44, height: 44)
                           .contentShape(Rectangle())
                   }
                   .buttonStyle(.plain)
               }
               
               // Swipeable week range display
               Text("\(weekDates.first?.formatted(.dateTime.month(.abbreviated).day()) ?? "") - \(weekDates.last?.formatted(.dateTime.month(.abbreviated).day()) ?? "")")
                   .font(.system(size: 12, weight: .regular))
                   .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                   .tracking(0.5)
                   .frame(maxWidth: .infinity, alignment: .leading)
                   .contentShape(Rectangle())
                   .gesture(
                       DragGesture(minimumDistance: 30)
                           .onEnded { value in
                               if value.translation.width < 0 {
                                   // Swipe left = next week
                                   changeWeek(by: 1)
                               } else if value.translation.width > 0 {
                                   // Swipe right = previous week
                                   changeWeek(by: -1)
                               }
                           }
                   )
           }
           .padding(.horizontal)
           .padding(.top, 8)
       }
        
    // MARK: - Week Calendar with Task Indicators
    private var weekCalendarWithTasks: some View {
        VStack(spacing: 8) {
            // Calendar row
            HStack(spacing: 8) {
                ForEach(weekDates, id: \.self) { date in
                    let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                    let isToday = Calendar.current.isDateInToday(date)
                    
                    VStack(spacing: 6) {
                        VStack(spacing: 4) {
                            Text(date.formatted(.dateTime.weekday(.abbreviated)))
                                .font(.system(size: 12, weight: .regular))
                                .adaptiveSecondaryText(colorScheme: colorScheme)
                                .opacity(isSelected ? 0.9 : (isToday ? 0.95 : 0.8))

                            Text("\(Calendar.current.component(.day, from: date))")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(
                                    isSelected
                                    ? .white
                                    : (isToday
                                    ? Color.sageGreen.opacity(colorScheme == .dark ? 0.95 : 0.85)
                                    : Color.dynamicSecondaryLabel)
                            )
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                               RoundedRectangle(cornerRadius: 12)
                                   .fill(
                                       // 🌤 Adaptive paper-like background
                                       isSelected
                                       ? Color.sageGreen
                                       : (
                                           colorScheme == .dark
                                           ? Color.white.opacity(isToday ? 0.10 : 0.06)  // subtle highlight in dark mode
                                           : Color.white.opacity(isToday ? 0.35 : 0.18)  // light paper glow
                                       )
                                   )
                                   .overlay(
                                       // ✏️ Soft ink border for paper outline
                                       RoundedRectangle(cornerRadius: 12)
                                           .strokeBorder(
                                               isSelected
                                               ? Color.sageGreen.opacity(0.6)
                                               : Color.inkSecondary.opacity(isToday ? 0.45 : 0.3),
                                               lineWidth: 0.6
                                           )
                                   )
                                   .shadow(
                                       color: Color.black.opacity(colorScheme == .dark ? 0.15 : 0.05),
                                       radius: isSelected ? 2 : 0.8,
                                       y: isSelected ? 1 : 0
                                   )
                           )
                    }
                    .onTapGesture {
                        selectedDate = date
                    }
                }
                .animation(
                    .spring(response: 0.35, dampingFraction: 0.75, blendDuration: 0.2),
                    value: selectedDate
                )
            }
            // Task indicators row
                    GeometryReader { geometry in
                        let dayWidth = geometry.size.width / 7
                        let calendar = Calendar.current
                        let incompleteTasks = allPriorityTasks.filter { !$0.isCompleted }
                        
                        ForEach(Array(incompleteTasks.enumerated()), id: \.element.id) { index, task in
                            let taskStartDay = calendar.startOfDay(for: task.startDate)
                            let taskEndDay = task.endDate != nil ? calendar.startOfDay(for: task.endDate!) : taskStartDay
                            
                            // Find which days in the week this task covers
                            let coveredDays = weekDates.enumerated().filter { idx, weekDate in
                                let weekDay = calendar.startOfDay(for: weekDate)
                                return weekDay >= taskStartDay && weekDay <= taskEndDay
                            }
                            
                            if let firstDay = coveredDays.first?.offset, let lastDay = coveredDays.last?.offset {
                                let startX = CGFloat(firstDay) * dayWidth
                                let span = CGFloat(lastDay - firstDay + 1)
                                let width = (span * dayWidth) - 8
                                let rowOffset = CGFloat(index % 3) * 5
                                
                                RoundedRectangle(cornerRadius: 1.5)
                                    .fill(Color(hex: task.colorHex))
                                    .frame(width: width, height: 3)
                                    .offset(x: startX + 4, y: rowOffset)
                            }
                        }
                    }
                    .frame(height: 15)
                    .padding(.horizontal, 4)
                    }
                    .padding(.horizontal)
                }
        
    // MARK: - Helper Functions for Calendar Display
    private func getTaskStartIndex(_ task: PriorityTask) -> Int? {
        let calendar = Calendar.current
        let taskStart = calendar.startOfDay(for: task.startDate)
        
        // Find which day in the week this task starts
        for (index, weekDate) in weekDates.enumerated() {
            let weekDay = calendar.startOfDay(for: weekDate)
            
            // If task starts on or before this day, and is active on this day
            if taskStart <= weekDay && task.isActive(on: weekDay) {
                return index
            }
        }
        
        // If task started before this week but is still active, start from day 0
        if taskStart < calendar.startOfDay(for: weekDates[0]) && task.isActive(on: weekDates[0]) {
            return 0
        }
        
        return nil
    }
    
    private func getTaskEndIndex(_ task: PriorityTask) -> Int? {
        let calendar = Calendar.current
        
        // Determine the actual end date
        let taskEnd: Date
        if let endDate = task.endDate {
            taskEnd = calendar.startOfDay(for: endDate)
        } else {
            // If no end date, extend to the end of the week
            taskEnd = calendar.startOfDay(for: weekDates.last ?? Date())
        }
        
        // Find the last day in the week where the task is active
        for (index, weekDate) in weekDates.enumerated().reversed() {
            let weekDay = calendar.startOfDay(for: weekDate)
            
            // If task ends on or after this day, and is active on this day
            if taskEnd >= weekDay && task.isActive(on: weekDay) {
                return index
            }
        }
        
        // If task extends beyond this week, end at the last day
        if let lastWeekDay = weekDates.last,
           taskEnd > calendar.startOfDay(for: lastWeekDay) && task.isActive(on: lastWeekDay) {
            return weekDates.count - 1
        }
        
        return nil
    }
    
    private func getTaskRowIndex(_ task: PriorityTask) -> Int {
        // Stack tasks vertically if they overlap
        let taskIndex = allPriorityTasks.filter { !$0.isCompleted }
            .sorted { $0.createdAt < $1.createdAt }
            .firstIndex { $0.id == task.id } ?? 0
        return taskIndex % 3 // Max 3 rows
    }

    private func checkForDayChange() {
        let calendar = Calendar.current
        let currentDay = calendar.startOfDay(for: currentTime)
        let lastDay = calendar.startOfDay(for: lastCheckedDay)

        // Check if we've crossed midnight
        if currentDay != lastDay {
            print("🌅 Day changed from \(lastDay) to \(currentDay)")
            
            // Update last checked day
            lastCheckedDay = currentTime
            
            // Force SwiftData to refresh all queries
            Task { @MainActor in
                do {
                    _ = try modelContext.fetch(FetchDescriptor<HabitCompletion>())
                    _ = try modelContext.fetch(FetchDescriptor<PomodoroSession>())
                    _ = try modelContext.fetch(FetchDescriptor<MicroHabitCompletion>())
                    print("✅ Midnight data refresh complete")
                } catch {
                    print("⚠️ Midnight refresh failed: \(error)")
                }
            }
            
            // Auto-update to today if user was viewing today or yesterday
            if calendar.isDateInToday(selectedDate) ||
               calendar.isDate(selectedDate, equalTo: calendar.date(byAdding: .day, value: -1, to: Date())!, toGranularity: .day) {
                withAnimation {
                    selectedDate = Date()
                }
            }
        }
    }
    
    //ensures late-night completions near midnight are counted under your local date.
    private func isSameLocalDay(_ d1: Date, _ d2: Date) -> Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar.isDate(d1, inSameDayAs: d2)
    }

    // MARK: - Enhanced Priority Tasks Section

    private var priorityTasksSection: some View {
        let activeCount = allActiveTasks.count
        let canAddMore = activeCount < 3
        
        return VStack(spacing: 16) {
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // HEADER
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            HStack {
                Text("Daily Top 3 Weaves")
                    .font(.system(size: 13, weight: .regular))
                    .fontDesign(.serif)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                
                Spacer()
                
                Button {
                    if canAddMore {
                        showAddTask = true
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: canAddMore ? "plus" : "checkmark.circle.fill")
                            .font(.system(size: 11, weight: .semibold))
                        Text(canAddMore ? "Add" : "3/3")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(canAddMore ? Color.sageGreen : Color.sageGreen.opacity(0.2))
                    .foregroundStyle(canAddMore ? .white : Color.sageGreen)
                    .clipShape(Capsule())
                }
                .disabled(!canAddMore)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // EMPTY STATE
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            if todaysPriorityTasks.isEmpty && ongoingPriorityTasks.isEmpty && completedPriorityTasks.isEmpty {
                VStack(spacing: 12) {
                    Text("Set your top 3 priorities")
                        .font(.system(size: 11, weight: .regular))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    
                    Button {
                        showAddTask = true
                    } label: {
                        Text("Add Priority Task")
                            .font(.system(size: 10, weight: .regular))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.adaptiveSectionBackground(colorScheme: colorScheme))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(
                                                Color.adaptiveBorder(colorScheme: colorScheme).opacity(0.6),
                                                lineWidth: 0.5
                                            )
                                    )
                            )
                            .foregroundStyle(.white)
                            .opacity(0.5)
                            .clipShape(Capsule())
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .reverieCardStyle(colorScheme: colorScheme)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // CONTENT
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            else {
                VStack(spacing: 12) {
                    // ═══════════════════════════════════════════════
                    // TODAY'S TASKS (Starting Today)
                    // ═══════════════════════════════════════════════
                    ForEach(todaysPriorityTasks.prefix(3)) { task in
                        PriorityTaskRow(
                            task: task,
                            selectedDate: selectedDate,
                            modelContext: modelContext,
                            onToggle: {
                                toggleTaskCompletion(task)
                            },
                            onEdit: {
                                showEditTask = task
                            },
                            onDelete: {
                                deleteTask(task)
                            }
                        )
                        .id(task.id)
                    }
                    
                    // ═══════════════════════════════════════════════
                    // ONGOING WEAVES (Started Before Today)
                    // ═══════════════════════════════════════════════
                    if !ongoingPriorityTasks.isEmpty {
                        VStack(spacing: 8) {
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    showOngoingWeaves.toggle()
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: showOngoingWeaves ? "chevron.down" : "chevron.right")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(Color.dustyBlue)
                                    
                                    Text("Ongoing Weaves")
                                        .font(.system(size: 12, weight: .medium))
                                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                                    
                                    Text("(\(ongoingPriorityTasks.count))")
                                        .font(.system(size: 11, weight: .medium))
                                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                                    
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                            
                            if showOngoingWeaves {
                                ForEach(ongoingPriorityTasks) { task in
                                    PriorityTaskRow(
                                        task: task,
                                        selectedDate: selectedDate,
                                        modelContext: modelContext,
                                        onToggle: {
                                            toggleTaskCompletion(task)
                                        },
                                        onEdit: {
                                            showEditTask = task
                                        },
                                        onDelete: {
                                            deleteTask(task)
                                        }
                                    )
                                    .id(task.id)
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                    
                    // ═══════════════════════════════════════════════
                    // COMPLETED SECTION
                    // ═══════════════════════════════════════════════
                    if !completedPriorityTasks.isEmpty {
                        VStack(spacing: 8) {
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    showCompletedTasks.toggle()
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: showCompletedTasks ? "chevron.down" : "chevron.right")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(Color.sageGreen)
                                    
                                    Text("Completed")
                                        .font(.system(size: 12, weight: .medium))
                                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                                    
                                    Text("(\(completedPriorityTasks.count))")
                                        .font(.system(size: 11, weight: .medium))
                                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                                    
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                            
                            if showCompletedTasks {
                                ForEach(completedPriorityTasks) { task in
                                    CompletedTaskRow(
                                        task: task,
                                        onDelete: {
                                            deleteTask(task)
                                        }
                                    )
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                    
                    // ═══════════════════════════════════════════════
                    // 3/3 INFO MESSAGE
                    // ═══════════════════════════════════════════════
                    if activeCount == 3 {
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.dustyBlue)
                            
                            Text("Focus on these 3 tasks today. Complete or remove one to add more.")
                                .font(.system(size: 11, weight: .regular))
                                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                                .lineLimit(2)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.dustyBlue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
        .padding(20)
        .reverieCardStyle(colorScheme: colorScheme)
        .padding(.horizontal)
    }
    
    // MARK: - Timeline Section (ADHD-Friendly with Time Blocks)
       private var timelineSection: some View {
           VStack(alignment: .leading, spacing: 16) {
               // Header
               Text("Timeline")
                   .font(.system(size: 13, weight: .regular))
                   .fontDesign(.serif)
                   .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                   .padding(.horizontal)
               
               if selectedDayCompletions.isEmpty && selectedDayPomodoros.isEmpty && selectedDayMicroHabits.isEmpty {
                   // Minimalist empty state
                   VStack(spacing: 16) {
                       Image(systemName: "moon.stars")
                           .font(.system(size: 32))
                           .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                       
                       VStack(spacing: 6) {
                           Text("No threads woven yet")
                               .font(.system(size: 12, weight: .medium))
                               .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                           Text("Complete habits on your Desk or Start a focus session to see your loom")
                               .font(.system(size: 11, weight: .regular))
                               .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                               .multilineTextAlignment(.center)
                       }
                   }
                   .frame(maxWidth: .infinity)
                   .padding(.vertical, 30)
                   .reverieCardStyle(colorScheme: colorScheme)
                   .clipShape(RoundedRectangle(cornerRadius: 20))
                   .padding(.horizontal)
               } else {
                   VStack(spacing: 20) {
                       // Day Progress Bar
                       circularDayProgress
                       
                       // Time Blocks
                       VStack(spacing: 24) {
                                  timeBlockSection(period: .night)      // ✅ ADD THIS - 12 AM - 6 AM
                                  timeBlockSection(period: .morning)    // 6 AM - 12 PM
                                  timeBlockSection(period: .afternoon)  // 12 PM - 6 PM
                                  timeBlockSection(period: .evening)    // 6 PM - 12 AM
                       }
                       
                       // Time Left Indicator
                       timeLeftIndicator
                   }
               }
           }
       }
       
    // ✅ Progress Bar with Hour Markers (6 AM - 12 AM only)
    private var circularDayProgress: some View {
        var calendar = Calendar.current
        calendar.timeZone = .current
        
        let currentHour = calendar.component(.hour, from: currentTime)
        let currentMinute = calendar.component(.minute, from: currentTime)
        
        // ✅ Calculate progress for 6 AM - 12 AM (18-hour window)
        let progress: CGFloat = {
            if currentHour < 6 {
                // Before 6 AM - show at start (0%)
                return 0.0
            } else if currentHour >= 24 {
                // After midnight (shouldn't happen, but safeguard)
                return 1.0
            } else {
                // Between 6 AM and midnight
                // Convert current time to minutes since 6 AM
                let minutesSince6AM = (currentHour - 6) * 60 + currentMinute
                // 18 hours = 1080 minutes (6 AM to 12 AM)
                let totalMinutesInWindow = 18 * 60
                return CGFloat(minutesSince6AM) / CGFloat(totalMinutesInWindow)
            }
        }()
        
        let currentPeriod = getTimePeriod(for: currentTime)
        
        return VStack(spacing: 12) {
            // Hour Progress Bar with markers
            VStack(spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background bar
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.45))
                        
                        // Progress fill (shows time passed since 6 AM)
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.sageGreen.opacity(0.3),      // Morning (6 AM)
                                        Color.dustyBlue.opacity(0.8),      // Afternoon
                                        Color.terracottaRose.opacity(0.3), // Evening
                                        Color.paleMauve.opacity(0.8)       // Night (approaching 12 AM)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progress)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        // Hour markers - 18 sections (1-hour intervals from 6 AM to 12 AM)
                        HStack(spacing: 0) {
                            ForEach(0..<18) { index in
                                if index > 0 {
                                    Rectangle()
                                        .fill(Color.white.opacity(0.45))
                                        .frame(width: 1.5)
                                }
                                if index < 17 {
                                    Spacer()
                                }
                            }
                        }
                        
                        // ✅ Only show current time indicator if between 6 AM and 12 AM
                        if currentHour >= 6 {
                            // Current time indicator - JUST THE DOT
                            Circle()
                                .fill(Color.dynamicLabel)
                                .foregroundStyle(Color.dynamicSecondaryLabel.opacity(0.75))
                                .frame(width: 12, height: 12)
                                .offset(x: min(geometry.size.width * progress - 6, geometry.size.width - 12))
                        }
                    }
                    .overlay(alignment: .leading) {
                        // ✅ Only show icon if between 6 AM and 12 AM
                        if currentHour >= 6 {
                            // Icon ABOVE the dot - positioned outside
                            Image(systemName: currentPeriod.icon)
                                .font(.system(size: 13))
                                .foregroundStyle(currentPeriod.color)
                                .offset(x: min(geometry.size.width * progress - 6, geometry.size.width - 12))
                                .offset(y: -18)
                        }
                    }
                }
                .frame(height: 12)
                
                // Time labels
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "sunrise.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.sageGreen)
                        Text("6 AM")
                            .font(.system(size: 9, weight: .regular))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    }
                    
                    Spacer()
                    
                    // ✅ Show current period if between 6 AM and 12 AM, otherwise show "NIGHT"
                    Text(currentHour >= 6 ? currentPeriod.displayName.uppercased() : "NIGHT")
                        .font(.system(size: 9, weight: .semibold))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                        .tracking(0.5)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Text("12 AM")
                            .font(.system(size: 9, weight: .regular))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.paleMauve)
                    }
                }
            }
            
            // Minute Dots (2 rows of 30) - 95% width
            // ✅ Only show minute progress if between 6 AM and 12 AM
            if currentHour >= 6 {
                VStack(spacing: 4) {
                    // First row (0-29 minutes)
                    HStack(spacing: 0) {
                        ForEach(0..<6) { group in
                            HStack(spacing: 2) {
                                ForEach(0..<5) { dot in
                                    let minute = group * 5 + dot
                                    Circle()
                                        .fill(minute < currentMinute
                                              ? currentPeriod.color
                                              : Color.black.opacity(0.20))
                                        .frame(width: 8, height: 8)
                                }
                            }
                            
                            if group < 5 {
                                Spacer()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, UIScreen.main.bounds.width * 0.025)
                    
                    // Second row (30-59 minutes)
                    HStack(spacing: 0) {
                        ForEach(0..<6) { group in
                            HStack(spacing: 2) {
                                ForEach(0..<5) { dot in
                                    let minute = 30 + group * 5 + dot
                                    Circle()
                                        .fill(minute < currentMinute
                                              ? currentPeriod.color
                                              : Color.black.opacity(0.20))
                                        .frame(width: 8, height: 8)
                                }
                            }
                            
                            if group < 5 {
                                Spacer()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, UIScreen.main.bounds.width * 0.025)
                }
                .padding(.horizontal, UIScreen.main.bounds.width * 0.025)
                .padding(.vertical, 8)
            } else {
                // ✅ Show "Resting" message for night hours (12 AM - 6 AM)
                VStack(spacing: 6) {
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.paleMauve)
                    
                    Text("Rest hours (12 AM - 6 AM)")
                        .font(.system(size: 10, weight: .regular))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        .italic()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
        }
        .padding(.horizontal)
    }
    
    //Mark: timeblocksection
    private func timeBlockSection(period: TimePeriod) -> some View {
        // Filter completions for this time period
        let completionsInPeriod = selectedDayCompletions.filter { completion in
            period.contains(date: completion.completedAt)
        }
        
        // ✅ DEBUG: Print what we found
        print("📍 \(period.displayName): \(completionsInPeriod.count) completions")
        
        let pomodorosInPeriod = selectedDayPomodoros.filter { pomodoro in
            period.contains(date: pomodoro.completedAt)
        }
        
        let microHabitsInPeriod = selectedDayMicroHabits.filter { microHabit in
            period.contains(date: microHabit.completedAt)
        }
        
        // Combined entries
        let allEntries: [(Date, TimelineEntryType)] =
            completionsInPeriod.map { ($0.completedAt, .habit($0)) }
        let sortedEntries = allEntries.sorted { $0.0 < $1.0 }
        
        // ✅ DEBUG: Check if we have entries
        print("   Sorted entries: \(sortedEntries.count)")
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: period.icon)
                    .font(.system(size: 12))
                    .foregroundStyle(period.color)
                
                Text(period.displayName.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    .tracking(1)
                
                Text(period.timeRange)
                    .font(.system(size: 10, weight: .regular))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
            }
            .padding(.leading, 20)
            
            // ✅ CRITICAL FIX: Check all three arrays, not just sortedEntries
            if completionsInPeriod.isEmpty && pomodorosInPeriod.isEmpty && microHabitsInPeriod.isEmpty {
                Text("No threads woven yet")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Color.dynamicSecondaryLabel.opacity(0.6))
                    .italic()
                    .padding(.leading, 28)
            } else {
                ZStack(alignment: .leading) {
                    // Continuous vertical line
                    Rectangle()
                        .fill(Color.habitCardBorder.opacity(0.5))
                        .frame(width: 1.5)
                        .padding(.leading, 40)
                    
                    // Timeline entries
                    VStack(spacing: 0) {
                        ForEach(Array(sortedEntries.enumerated()), id: \.offset) { index, entry in
                            TimelineEntryRow(
                                entry: entry.1,
                                habit: entry.1.habit(from: habits),
                                isFirst: index == 0,
                                isLast: index == sortedEntries.count - 1,
                                onTap: {
                                    if case .habit(let completion) = entry.1 {
                                        showReflection = completion
                                    }
                                }
                            )
                        }
                        
                        // Micro Habits Summary
                        if !microHabitsInPeriod.isEmpty {
                            MicroHabitSummaryRow(
                                count: microHabitsInPeriod.count,
                                isFirst: sortedEntries.isEmpty,
                                isLast: pomodorosInPeriod.isEmpty
                            )
                        }
                        
                        // Pomodoro Summary
                        if !pomodorosInPeriod.isEmpty {
                            PomodoroSummaryRow(
                                sessions: pomodorosInPeriod,
                                count: pomodorosInPeriod.count,
                                totalMinutes: pomodorosInPeriod.reduce(0) { $0 + $1.duration },
                                isFirst: sortedEntries.isEmpty && microHabitsInPeriod.isEmpty,
                                isLast: true
                            )
                        }
                    }
                }
            }
        }
    }
    // MARK: - Timeline Entry Type
        enum TimelineEntryType {
            case habit(HabitCompletion)
            case pomodoro(PomodoroSession)
            case microHabit(MicroHabitCompletion)
            
            func habit(from habits: [Habit]) -> Habit? {
                if case .habit(let completion) = self {
                    return habits.first { $0.id == completion.habitId }
                }
                return nil
            }
        }
    // MARK: - Time Left Indicator
       private var timeLeftIndicator: some View {
           let now = Date()
           let calendar = Calendar.current
           let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now) ?? now
           let timeLeft = calendar.dateComponents([.hour, .minute], from: now, to: endOfDay)
           let hoursLeft = timeLeft.hour ?? 0
           
           return HStack(spacing: 8) {
               Image(systemName: "clock")
                   .font(.system(size: 12))
                   .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
               
               Text("\(hoursLeft) hours remaining today")
                   .font(.system(size: 12, weight: .regular))
                   .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
           }
           .padding(.leading, 20)
           .padding(.top, 8)
       }
        
    // MARK: - Time Period Helpers (4 EQUAL PERIODS)
       enum TimePeriod {
           case morning, afternoon, evening, night
           
           var icon: String {
               switch self {
               case .morning: return "sunrise.fill"
               case .afternoon: return "sun.max.fill"
               case .evening: return "sunset.fill"
               case .night: return "moon.stars.fill"
               }
           }
           
           var displayName: String {
               switch self {
               case .morning: return "Morning"
               case .afternoon: return "Afternoon"
               case .evening: return "Evening"
               case .night: return "Night"
               }
           }
           
           var timeRange: String {
               switch self {
               case .morning: return "(6 AM - 12 PM)"
               case .afternoon: return "(12 PM - 6 PM)"
               case .evening: return "(6 PM - 12 AM)"
               case .night: return "(12 AM - 6 AM)"
               }
           }
           
           var color: Color {
               switch self {
               case .morning: return .sageGreen
               case .afternoon: return .dustyBlue
               case .evening: return .terracottaRose
               case .night: return .paleMauve
               }
           }
           
           // ✅ NEW: Check hour directly instead of date
              func containsHour(_ hour: Int) -> Bool {
                  switch self {
                  case .morning: return hour >= 6 && hour < 12
                  case .afternoon: return hour >= 12 && hour < 18
                  case .evening: return hour >= 18 && hour < 24
                  case .night: return hour >= 0 && hour < 6
                  }
              }
           
           func contains(date: Date) -> Bool {
               // ✅ CRITICAL: Use local timezone, not UTC
               var calendar = Calendar.current
               calendar.timeZone = .current  // Force local timezone
               let hour = calendar.component(.hour, from: date)
               
               // ✅ DEBUG: Print what hour we're checking
               print("🕐 Checking hour \(hour) for \(self.displayName)")
               
               switch self {
               case .morning: return hour >= 6 && hour < 12
               case .afternoon: return hour >= 12 && hour < 18
               case .evening: return hour >= 18 && hour < 24
               case .night: return hour >= 0 && hour < 6
               }
           }
       }
       
       private func getTimePeriod(for date: Date) -> TimePeriod {
           let hour = Calendar.current.component(.hour, from: date)
           if hour >= 6 && hour < 12 {
               return .morning
           } else if hour >= 12 && hour < 18 {
               return .afternoon
           } else if hour >= 18 && hour < 24 {
               return .evening
           } else {
               return .night
           }
       }
       
       private func relativeTime(from date: Date) -> String {
           let now = Date()
           let components = Calendar.current.dateComponents([.minute, .hour], from: date, to: now)
           
           if let hours = components.hour, hours > 0 {
               return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
           } else if let minutes = components.minute, minutes > 0 {
               if minutes < 5 {
                   return "Just now"
               } else {
                   return "\(minutes) min ago"
               }
           } else {
               return "Just now"
           }
       }
    
    private func changeWeek(by weeks: Int) {
        if let newDate = Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: selectedDate) {
            selectedDate = newDate
        }
    }
    
    private func toggleTaskCompletion(_ task: PriorityTask) {
        if task.isCompleted {
            // Uncomplete task
            task.isCompleted = false
            task.completedAt = nil
        } else {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let taskEnd = task.endDate != nil ? calendar.startOfDay(for: task.endDate!) : calendar.startOfDay(for: task.startDate)
            
            // Smart Carry-Over Logic
            if today >= taskEnd {
                // Task ends today or has ended - just complete it
                task.isCompleted = true
                task.completedAt = Date()
            } else {
                // Task continues into future - show carry-over prompt
                taskToComplete = task
                showCarryOverAlert = true
            }
        }
    }
    
    private func completeTask(_ task: PriorityTask, carryOver: Bool) {
        if carryOver {
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
            let newTask = PriorityTask(
                title: task.title,
                taskDescription: task.taskDescription,
                startDate: tomorrow,
                endDate: task.endDate,
                colorHex: task.colorHex
            )
            modelContext.insert(newTask)
        }
        
        task.isCompleted = true
        task.completedAt = Date()
        taskToComplete = nil
    }
    
    private func deleteTask(_ task: PriorityTask) {
        modelContext.delete(task)
    }
}

// MARK: - Timeline Entry Row
struct TimelineEntryRow: View {
    @Environment(\.colorScheme) private var colorScheme  // ← Add this line

    let entry: LoomView.TimelineEntryType
    let habit: Habit?
    let isFirst: Bool
    let isLast: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Timeline indicator (dot only - line is handled by continuous background)
                Circle()
                    .fill(entryColor)
                    .frame(width: 9, height: 9)
                    .padding(.leading, 20)  // Match timeline line position
                
                // Entry info
                HStack(spacing: 6) {
                    Text(entryTitle)
                        .font(.system(size: 12, weight: .medium))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    
                    if case .habit(let completion) = entry, let reflection = completion.reflection {
                        Text("•")
                            .font(.system(size: 11))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        
                        Image(systemName: getMoodIcon(for: reflection.mood))
                            .font(.system(size: 11))
                                .foregroundStyle(getMoodColor(for: reflection.mood).opacity(colorScheme == .dark ? 0.9 : 0.8))
                        
                        Text(reflection.mood)
                            .font(.system(size: 11, weight: .regular))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        
                        if reflection.isFavorite {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(Color.terracottaRose.opacity(colorScheme == .dark ? 0.9 : 0.8))
                                .padding(.leading, 2)
                        }
                    }
                }
                .offset(y: 0.5)
                
                Spacer()
                
                // Relative timestamp
                Text(relativeTime)
                    .font(.system(size: 11, weight: .regular))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    .offset(y: 0.5)
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }
    
    private var entryColor: Color {
        switch entry {
        case .habit(let completion):
            if let live = habit { return Color(hex: live.colorHex) }
            if let snap = completion.snapshotColorHex { return Color(hex: snap) }
            return .sageGreen // safe fallback
        case .pomodoro:
            return .sageGreen
        case .microHabit:
            return .terracottaRose
        }
    }
    
    private var entryTitle: String {
        switch entry {
        case .habit(let completion):
            let title = habit?.name ?? completion.snapshotName ?? "Completed habit"
                return title
        case .pomodoro(let session):
            return "🍅 Focus: \(session.duration) min"
        case .microHabit(let completion):
            return "⚡ \(completion.title)"
        }
    }
    
    private var relativeTime: String {
        let date: Date
        switch entry {
        case .habit(let completion):
            date = completion.completedAt
        case .pomodoro(let session):
            date = session.completedAt
        case .microHabit(let completion):
            date = completion.completedAt
        }
        
        let now = Date()
        let components = Calendar.current.dateComponents([.minute, .hour], from: date, to: now)
        
        if let hours = components.hour, hours > 0 {
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        } else if let minutes = components.minute, minutes > 0 {
            if minutes < 5 {
                return "Just now"
            } else {
                return "\(minutes) min ago"
            }
        } else {
            return "Just now"
        }
    }
    
    // MARK: - Updated SF Symbol Moods (Matches Reflection Sheet)
    private func getMoodIcon(for mood: String) -> String {
        switch mood {
        case "Energized": return "bolt.fill"
        case "Calm": return "leaf.fill"
        case "Neutral": return "circle.fill"
        case "Tired": return "moon.fill"
        case "Stressed": return "cloud.fill"
        default: return "circle"
        }
    }

    private func getMoodColor(for mood: String) -> Color {
        switch mood {
        case "Energized": return .terracottaRose
        case "Calm": return .sageGreen
        case "Neutral": return .gray
        case "Tired": return .dustyBlue
        case "Stressed": return .paleMauve
        default: return .gray.opacity(0.5)
        }
    }
}

    // MARK: - Micro Habit Summary Row
    struct MicroHabitSummaryRow: View {
        @Environment(\.colorScheme) private var colorScheme  // ← Add this line

        let count: Int
        let isFirst: Bool
        let isLast: Bool
        
        var body: some View {
            HStack(spacing: 12) {
                // Timeline indicator (dot only - line is handled by continuous background)
                Circle()
                    .fill(Color.terracottaRose)
                    .frame(width: 9, height: 9)
                    .padding(.leading, 20)  // Match timeline line position
                
                // Summary text
                HStack(spacing: 6) {
                    Text("⚡")
                        .font(.system(size: 12))
                    
                    Text("\(count) Quick Action\(count == 1 ? "" : "s") completed")
                        .font(.system(size: 12, weight: .medium))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                }
                .offset(y: 0.5)
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
        }
    }

    // MARK: - Pomodoro Summary Row
    struct PomodoroSummaryRow: View {
        @Environment(\.colorScheme) private var colorScheme  // ← Add this line
        let sessions: [PomodoroSession]  // ✅ NEW: Receive actual sessions
        let count: Int
        let totalMinutes: Int
        let isFirst: Bool
        let isLast: Bool

        // ✅ NEW: Get unique categories from sessions
            private var uniqueCategories: [FocusCategory] {
                let categoryStrings = sessions.compactMap { $0.category }
                let unique = Array(Set(categoryStrings))
                return unique.compactMap { FocusCategory(rawValue: $0) }
      }
        var body: some View {
            HStack(spacing: 12) {
                // Timeline indicator (dot only - line is handled by continuous background)
                Circle()
                    .fill(Color.sageGreen)
                    .frame(width: 9, height: 9)
                    .padding(.leading, 20)  // Match timeline line position
                
                // Summary text
                HStack(spacing: 6) {
                    Text("🔮")
                        .font(.system(size: 12))
                    
                    Text("\(count) Focus Session\(count == 1 ? "" : "s") • \(totalMinutes) min")
                        .font(.system(size: 12, weight: .medium))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    // ✅ NEW: Display focus category icons
                    if !uniqueCategories.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(uniqueCategories, id: \.self) { category in
                                ZStack {
                                    Circle()
                                        .fill(category.color.opacity(colorScheme == .dark ? 0.15 : 0.12))
                                        .frame(width: 20, height: 20)

                                    Image(systemName: category.icon)
                                        .font(.system(size: 9))
                                        .foregroundStyle(category.color.opacity(colorScheme == .dark ? 0.9 : 0.75))
                                }
                            }
                        }
                    }
                }
                .offset(y: 0.5)
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
        }
    }
    
// MARK: - Simplified Floating Pomodoro Timer (ADHD-Optimized)
struct FloatingPomodoroTimer: View {
    @Bindable var timerManager: PomodoroTimerManager
    @Environment(\.colorScheme) private var colorScheme  // ← Add this line

    var body: some View {
        Group {
            if timerManager.isExpanded {
                expandedView
            } else {
                collapsedView
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: timerManager.isExpanded)
    }
    private var collapsedView: some View {
            Button {
                withAnimation {
                    timerManager.isExpanded = true
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(timerManager.timerState == .idle ? Color.habitCardBackground : timerManager.crystalBallColor.opacity(0.2))
                        .frame(width: 48, height: 48)
                        .shadow(color: Color.shadowColor, radius: 6, y: 2)
                        .overlay(
                            Circle()
                                .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                        )
                    
                    if timerManager.timerState != .idle {
                        Circle()
                            .trim(from: 0, to: timerManager.progress)
                            .stroke(timerManager.crystalBallColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 48, height: 48)
                            .rotationEffect(.degrees(-90))
                    }
                    
                    if timerManager.timerState == .idle {
                        Image(systemName: "hourglass")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.sageGreen)
                    } else {
                        Text(timerManager.formattedMinutes)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(timerManager.crystalBallColor)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    
    private var expandedView: some View {
            ZStack(alignment: .topTrailing) {
                // Crystal Orb Timer
                VStack(spacing: 12) {
                    // Header (without close button now)
                    // Header with Tappable Category Label
                    HStack {
                        Button {
                            // Tap category to change it
                            timerManager.showCategoryPicker = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: timerManager.timerState.icon)
                                    .font(.system(size: 10))
                                    .foregroundStyle(timerManager.crystalBallColor)
                                
                                Text(timerManager.timerState.displayName)
                                    .font(.system(size: 10, weight: .medium))
                                    .fontDesign(.serif)
                                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                                
                                // Small indicator that it's tappable
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 8))
                                    .foregroundStyle(Color.dynamicSecondaryLabel.opacity(0.5))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.dynamicSecondaryBackground.opacity(0.3))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity) // Take full width
                
                // Duration Quick Select (Compact)
                VStack(spacing: 6) {
                    Text("DURATION")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Color.dynamicSecondaryLabel.opacity(0.6))
                        .tracking(1)
                    
                    HStack(spacing: 6) {
                        ForEach([15, 25, 45, 60], id: \.self) { duration in
                            Button {
                                let impact = UIImpactFeedbackGenerator(style: .light)
                                impact.impactOccurred()
                                
                                timerManager.setWorkDuration(duration)
                            } label: {
                                VStack(spacing: 2) {
                                    Text("\(duration)")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(timerManager.workDuration == duration ? .white : Color.dynamicLabel)
                                    Text("min")
                                        .font(.system(size: 6, weight: .regular))
                                        .foregroundStyle(timerManager.workDuration == duration ? .white.opacity(0.8) : Color.dynamicSecondaryLabel)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(timerManager.workDuration == duration ? timerManager.crystalBallColor : Color.dynamicSecondaryBackground.opacity(0.3))
                                )
                            }
                            .buttonStyle(.plain)
                            // Duration can be changed anytime - will restart timer if running
                        }
                    }
                }
                
                // Timer Circle with Animated Progress Dot
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(Color.dynamicSecondaryBackground.opacity(0.4), lineWidth: 5)
                        .frame(width: 110, height: 110)
                    
                    // Progress arc
                    Circle()
                        .trim(from: 0, to: timerManager.progress)
                        .stroke(timerManager.crystalBallColor.opacity(0.7), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 110, height: 110)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: timerManager.progress)
                    
                    // Animated traveling dot (ADHD visual feedback)
                    if timerManager.timerState != .idle {
                        Circle()
                            .fill(timerManager.crystalBallColor)
                            .frame(width: 10, height: 10)
                            .shadow(color: timerManager.crystalBallColor.opacity(0.8), radius: 4, x: 0, y: 0)
                            .offset(y: -55) // Radius of the circle
                            .rotationEffect(.degrees(timerManager.progress * 360 - 90))
                            .animation(.linear(duration: 1), value: timerManager.progress)
                    }
                    
                    // Time and session display
                    VStack(spacing: 4) {
                        Text(timerManager.formattedTime)
                            .font(.system(size: 36, weight: .bold))
                            .fontDesign(.rounded)
                            .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                        
                        if timerManager.sessionCount > 0 {
                            HStack(spacing: 2) {
                                ForEach(0..<min(timerManager.sessionCount, 4), id: \.self) { _ in
                                    Text("🍅")
                                        .font(.system(size: 10))
                                }
                            }
                        }
                    }
                }
                
                
                // Controls with Sound Toggle
                HStack(spacing: 20) {
                    // Play/Pause
                    Button {
                        if timerManager.timerState == .idle || timerManager.timerState == .paused {
                            if timerManager.timerState == .paused {
                                timerManager.resumeTimer()
                            } else {
                                timerManager.showCategoryPicker = true
                            }
                        } else {
                            timerManager.pauseTimer()
                        }
                    } label: {
                        Image(systemName: timerManager.timerState == .running ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 23))
                            .foregroundStyle(timerManager.crystalBallColor.opacity(0.8))
                    }
                    
                    // Restart (NEW - only show when active)
                        if timerManager.timerState != .idle {
                            Button {
                                timerManager.restartTimer()
                            } label: {
                                Image(systemName: "arrow.counterclockwise.circle.fill")
                                    .font(.system(size: 23))
                                    .foregroundStyle(Color.terracottaRose.opacity(0.6))
                            }
                        }
                        
                        // Skip to Break
                        if timerManager.timerState != .idle {
                            Button {
                                timerManager.skipToBreak()
                            } label: {
                                Image(systemName: "forward.circle.fill")
                                    .font(.system(size: 23))
                                    .foregroundStyle(Color.dynamicSecondaryLabel.opacity(0.6))
                            }
                        }
                        
                    // Sound Alert Toggle (Inline!)
                    Button {
                        // Haptic feedback
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        
                        timerManager.chimeEnabled.toggle()
                    } label: {
                        Image(systemName: timerManager.chimeEnabled ? "bell.fill" : "bell.slash.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(timerManager.chimeEnabled ? timerManager.crystalBallColor : Color.dynamicSecondaryLabel.opacity(0.4))
                    }
                }
                
                // Break info
            }
            .padding(20)
            .frame(width: 280, height: 300) // Taller to fit close button at top
            .background(
                ZStack {
                    // Main glossy orb background
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.dynamicBackground.opacity(0.98),
                                    Color.dynamicBackground.opacity(0.96),
                                    Color.dynamicBackground.opacity(0.92)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 140
                            )
                        )
                        .blur(radius: 1)
                    
                    // Top glossy highlight (simulates light reflection)
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.5),
                                    Color.white.opacity(0.2),
                                    Color.clear
                                ],
                                center: UnitPoint(x: 0.5, y: 0.3),
                                startRadius: 0,
                                endRadius: 110
                            )
                        )
                        .blur(radius: 4)
                    
                    // Subtle inner glow (TIME-BASED COLOR!)
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    timerManager.crystalBallColor.opacity(0.12),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 90,
                                endRadius: 140
                            )
                        )
                }
            )
            .overlay(
                // Glossy rim with gradient border (TIME-BASED COLOR!)
                Circle()
                    .strokeBorder(
                        AngularGradient(
                            colors: [
                                Color.white.opacity(0.4),
                                timerManager.crystalBallColor.opacity(0.25),
                                Color.white.opacity(0.15),
                                timerManager.crystalBallColor.opacity(0.3),
                                Color.white.opacity(0.4)
                            ],
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        ),
                        lineWidth: 2
                    )
                    .blur(radius: 0.3)
            )
            .shadow(color: timerManager.crystalBallColor.opacity(0.25), radius: 30, x: 0, y: 12)
            .shadow(color: Color.black.opacity(0.2), radius: 18, x: 0, y: 6)
            .shadow(color: Color.white.opacity(0.15), radius: 5, x: 0, y: -2)
            
            // Close Button - OUTSIDE the crystal orb
            Button {
                withAnimation {
                    timerManager.isExpanded = false
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.dynamicSecondaryLabel.opacity(0.55))
                    .background(
                        Circle()
                            .fill(Color.dynamicBackground.opacity(0.5))
                            .frame(width: 25, height: 25)
                    )
            }
            .offset(x: -8, y: 8) // Position in top-right corner
            }
            .sheet(isPresented: $timerManager.showCategoryPicker) {
                FocusCategoryPicker(
                    timerManager: timerManager,
                    onStart: {
                        timerManager.startTimerWithCategory()
                    },
                    onCancel: {
                        timerManager.showCategoryPicker = false
                    }
                )
                .presentationDetents([.height(520)])
            }
        }
}

// ================================================================
// PRIORITYTASKROW - MINIMAL DATE DISPLAY UPDATE
// ================================================================
// Only the date display changes - everything else stays the same
// ================================================================

// MARK: - Priority Task Row Component (MINIMAL UPDATE)
struct PriorityTaskRow: View {
    @Environment(\.colorScheme) private var colorScheme

    let task: PriorityTask
    let selectedDate: Date  // ✨ ADD THIS - needed for day calculation
    let modelContext: ModelContext
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Button(action: onToggle) {
                    ZStack {
                        Circle()
                            .strokeBorder(task.isCompleted ? Color(hex: task.colorHex) : Color.habitCardBorder, lineWidth: 2)
                            .frame(width: 20, height: 20)
                        
                        if task.isCompleted {
                            Circle()
                                .fill(Color(hex: task.colorHex))
                                .frame(width: 20, height: 20)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .fontDesign(.serif)
                                .foregroundStyle(.white)
                        }
                    }
                }
                .buttonStyle(.plain)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.system(size: 13, weight: .medium))
                        .fontDesign(.serif)
                        .strikethrough(task.isCompleted)
                        .foregroundStyle(task.isCompleted ? Color.dynamicSecondaryLabel : Color.dynamicLabel)
                    
                    // ✨ UPDATED: Enhanced date display with day progress
                    HStack(spacing: 4) {
                        Text(dateDisplayText)
                            .font(.system(size: 10, weight: .regular))
                            .fontDesign(.serif)
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        
                        // ✨ NEW: Show "Day X/Y" badge on days 2+
                        if let progress = task.getDayProgress(for: selectedDate),
                           progress.current > 1 {
                            Text("Day \(progress.current)/\(progress.total)")
                                .font(.system(size: 9, weight: .medium))
                                .fontDesign(.serif)
                                .foregroundStyle(Color(hex: task.colorHex))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color(hex: task.colorHex).opacity(0.12))
                                )
                        }
                    }
                    
                    if !task.taskDescription.isEmpty {
                        Text(task.taskDescription)
                            .font(.system(size: 11, weight: .regular))
                            .fontDesign(.serif)
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                Circle()
                    .fill(Color(hex: task.colorHex))
                    .frame(width: 8, height: 8)
            }
            
            if let subTasks = task.subTasks, !subTasks.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(subTasks.sorted(by: { $0.createdAt < $1.createdAt }), id: \.id) { subTask in
                        HStack(spacing: 8) {
                            Button(action: {
                                subTask.isCompleted.toggle()
                            }) {
                                Image(systemName: subTask.isCompleted ? "checkmark.square.fill" : "square")
                                    .font(.system(size: 14))
                                    .fontDesign(.serif)
                                    .foregroundStyle(subTask.isCompleted ? Color(hex: task.colorHex) : Color.habitCardBorder)
                            }
                            .buttonStyle(.plain)
                            
                            Text(subTask.title)
                                .font(.system(size: 12, weight: .regular))
                                .fontDesign(.serif)
                                .strikethrough(subTask.isCompleted)
                                .foregroundStyle(subTask.isCompleted ? Color.dynamicSecondaryLabel : Color.dynamicLabel)
                        }
                    }
                }
                .padding(.leading, 32)
            }
        }
        .padding(14)
        .reverieCardStyle(colorScheme: colorScheme)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contextMenu {
            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    // ✨ NEW: Helper for date display
    private var dateDisplayText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        // If multi-day task, show range
        if let endDate = task.endDate {
            let startText = formatter.string(from: task.startDate)
            let endText = formatter.string(from: endDate)
            return "\(startText) - \(endText)"
        } else {
            // Single day
            return formatter.string(from: task.startDate)
        }
    }
}

// MARK: - Custom Carry Over Sheet (SMART LOGIC)
struct CustomCarryOverSheet: View {
    @Environment(\.colorScheme) private var colorScheme  // ← Add this line

    let taskToComplete: PriorityTask?
    let onComplete: (Bool) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                // ✅ CHANGED: Checkmark icon instead of arrow
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.sageGreen)  // ✅ CHANGED: Solid green instead of gradient
                    .padding(.top, 32)
                
                // ✅ CHANGED: Title from "Carry Over Task?" to "Task Completed!"
                Text("Task Completed!")
                    .font(.system(size: 20, weight: .semibold))
                    .fontDesign(.serif)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                
                if let task = taskToComplete {
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color(hex: task.colorHex))
                                .frame(width: 8, height: 8)
                            
                            Text(task.title)
                                .font(.system(size: 14, weight: .medium))
                                .fontDesign(.serif)
                                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                        }
                        
                        // ✅ NEW: Show end date to explain why asking
                        if let endDate = task.endDate {
                            Text("This task runs until \(endDate.formatted(date: .abbreviated, time: .omitted))")
                                .font(.system(size: 13, weight: .regular))
                                .fontDesign(.serif)
                                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                            
                            Text("Would you like to carry it over to tomorrow?")
                                .font(.system(size: 13, weight: .regular))
                                .fontDesign(.serif)
                                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
            .padding(.bottom, 32)
            
            // Action Buttons
            VStack(spacing: 12) {
                // ✅ CHANGED: "Complete for Today" → "Complete for Good"
                Button {
                    onComplete(false)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                        
                        Text("Complete for Good")  // ✅ CHANGED
                            .font(.system(size: 15, weight: .semibold))
                            .fontDesign(.serif)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.sageGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                
                // Carry Over to Tomorrow
                Button {
                    onComplete(true)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.forward.circle.fill")
                            .font(.system(size: 16))
                        
                        Text("Carry Over to Tomorrow")
                            .font(.system(size: 15, weight: .semibold))
                            .fontDesign(.serif)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.dustyBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                
                // Cancel
                Button {
                    onCancel()
                } label: {
                    Text("Cancel")
                        .font(.system(size: 15, weight: .medium))
                        .fontDesign(.serif)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.dynamicSecondaryBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Color.clear)
        .presentationDetents([.height(480)])  // ✅ CHANGED: Increased from 420 to fit end date text
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Completed Task Row Component
struct CompletedTaskRow: View {
    @Environment(\.colorScheme) private var colorScheme  // ← Add this line
    
    let task: PriorityTask
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                // Checkmark (static, already completed)
                ZStack {
                    Circle()
                        .fill(Color(hex: task.colorHex))
                        .frame(width: 20, height: 20)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .fontDesign(.serif)
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.system(size: 13, weight: .medium))
                        .fontDesign(.serif)
                        .strikethrough()
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    
                    if let completedAt = task.completedAt {
                        Text("Completed \(relativeTimeString(from: completedAt))")
                            .font(.system(size: 10, weight: .regular))
                            .fontDesign(.serif)
                            .foregroundStyle(Color.dynamicSecondaryLabel.opacity(0.7))
                    }
                }
                
                Spacer()
                
                Circle()
                    .fill(Color(hex: task.colorHex).opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    private func relativeTimeString(from date: Date) -> String {
        let now = Date()
        let components = Calendar.current.dateComponents([.minute, .hour], from: date, to: now)
        
        if let hours = components.hour, hours > 0 {
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        } else if let minutes = components.minute, minutes > 0 {
            if minutes < 5 {
                return "just now"
            } else {
                return "\(minutes) min ago"
            }
        } else {
            return "just now"
        }
    }
}

#Preview {
    LoomView()
        .modelContainer(for: [Habit.self, HabitCompletion.self, UserProfile.self, PriorityTask.self, SubTask.self, PomodoroSession.self, MicroHabitCompletion.self])
}
