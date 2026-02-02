//
// LoomView.swift
// ReverieWeaver
//
// The Loom - Daily tracker and timeline with consistent dark mode
//

import SwiftUI
import SwiftData
import Combine
import AudioToolbox
import UIKit
import AVFoundation
import MediaPlayer
import os.log

// MARK: - Pomodoro Session Grouping Helper

extension PomodoroSession {
    var startTime: Date {
        completedAt.addingTimeInterval(TimeInterval(-duration * 60))
    }
}

struct LoomView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase
    
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
    @State private var showDatePicker = false
    @State private var currentDate = Date()
    @State private var showCompletedTasks = false
    @State private var showOngoingWeaves = false
    @State private var isCompletingTask = false
    @State private var isDeletingEntry = false
    
    // User-facing error handling
    @State private var errorAlert: ErrorAlert?
    
    // Pomodoro Timer
    @State private var currentTime = Date()
    @State private var timerManager = PomodoroTimerManager()
    @State private var soundscapePlayer = SoundscapePlayer()
    @State private var showLandscapeTimer = false
    @State private var showPDFLibrary = false

    // Conditional timer management
    @State private var midnightCheckTimer: Timer?
    
    // MARK: - Error Alert Model
    
    struct ErrorAlert: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }
    
    private var weekStartsOnSunday: Bool {
        profiles.first?.weekStartsOnSunday ?? true
    }
    
    // 1. selectedDayCompletions - Optimized Deduplication & Filtering
    private var selectedDayCompletions: [HabitCompletion] {
        let calendar = Calendar.current
        
        // 1. Filter first: Check date match directly without creating new Date objects if possible
        let dayCompletions = completions.filter { completion in
            calendar.isDate(completion.completedAt, inSameDayAs: selectedDate)
        }
        
        // 2. Sort once (Earliest first)
        let sorted = dayCompletions.sorted { $0.completedAt < $1.completedAt }
        
        // 3. Deduplicate: Keep only the FIRST completion per habit per day
        var seenHabitIds = Set<UUID>()
        var uniqueCompletions: [HabitCompletion] = []
        
        for completion in sorted {
            // .insert() returns (inserted: Bool, memberAfterInsert: Element)
            // If inserted is true, it means we haven't seen this ID yet
            if seenHabitIds.insert(completion.habitId).inserted {
                uniqueCompletions.append(completion)
            } else {
#if DEBUG
            // Log duplicate filtering in debug builds only
            AppLog.warn("Filtered duplicate completion for habit \(completion.habitId)", category: "loom.data")
#endif
            }
        }
        
        return uniqueCompletions
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
    
    // Tasks that start TODAY (count toward 3 limit)
    private var todaysPriorityTasks: [PriorityTask] {
        allPriorityTasks
            .filter { task in
                !task.isCompleted &&
                task.isActive(on: selectedDate) &&
                task.startsOn(selectedDate)
            }
            .sorted { $0.createdAt < $1.createdAt }
    }
    
    // Tasks that started BEFORE today but are still active
    private var ongoingPriorityTasks: [PriorityTask] {
        allPriorityTasks
            .filter { task in
                !task.isCompleted &&
                task.isActive(on: selectedDate) &&
                !task.startsOn(selectedDate)
            }
            .sorted { $0.startDate < $1.startDate }
    }
    
    // All active tasks combined (for the 3-task limit check)
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
            startDay = calendar.date(byAdding: .day, value: -daysFromSunday, to: selectedDate) ?? selectedDate
        } else {
            let daysFromMonday = (weekday == 1) ? 6 : weekday - 2
            startDay = calendar.date(byAdding: .day, value: -daysFromMonday, to: selectedDate) ?? selectedDate
        }
        
        return (0..<7).compactMap {
            calendar.date(byAdding: .day, value: $0, to: startDay)
        }
    }
    
    // Check if any sheet is presented
    private var isAnySheetPresented: Bool {
        showReflection != nil || showAddTask || showEditTask != nil || showDatePicker || showCarryOverAlert
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                ReverieWeaverBackground()
                ScrollView {
                    VStack(spacing: 24) {
                        headerSection
                        weekCalendarWithTasks
                        priorityTasksSection
                        timelineSection
                    }
                    .padding(.bottom, 100)
                    .dismissKeyboardOnBackgroundTap()
                }
                .background(Color.clear)
                
                // Floating Pomodoro Timer
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        FloatingPomodoroTimer(
                            timerManager: timerManager,
                            soundscapePlayer: soundscapePlayer
                        )
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, 100)
                }
                .opacity(isAnySheetPresented ? 0 : 1)
                .allowsHitTesting(!isAnySheetPresented)
            }
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
            //  Connect soundscape to timer on appear
            .onAppear {
                timerManager.setContext(modelContext)
                timerManager.soundscapePlayer = soundscapePlayer
                
                Task { @MainActor in
                    do {
                        _ = try modelContext.fetch(FetchDescriptor<HabitCompletion>())
                        _ = try modelContext.fetch(FetchDescriptor<PomodoroSession>())
                        _ = try modelContext.fetch(FetchDescriptor<MicroHabitCompletion>())
                        AppLog.debug("Initial data fetch completed", category: "loom.data")
                    } catch {
                        // Only log critical startup errors
                        AppLog.error("Data fetch failed on view load: \(error.localizedDescription)", category: "loom.data")
                        // Don't show user alert on initial load
                    }
                }
            }
            .alert(errorAlert?.title ?? "Error", isPresented: .constant(errorAlert != nil)) {
                Button("OK") { errorAlert = nil }
            } message: {
                if let errorAlert = errorAlert {
                    Text(errorAlert.message)
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
            
            //   Calendar Picker Sheet
            .sheet(isPresented: $showDatePicker) {
                WeekCalendarSheet(currentDate: $selectedDate)
                    .presentationDetents([.medium])
                    .presentationCornerRadius(24)
            }

            // PDF Task Library Sheet
            .sheet(isPresented: $showPDFLibrary) {
                PDFLibraryView()
            }

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
            
            // Ready to Focus Sheet
            .sheet(isPresented: $timerManager.showReadyToFocusSheet) {
                ReadyToFocusSheet(
                    timerManager: timerManager,
                    soundscapePlayer: soundscapePlayer,
                    onStart: {
                        timerManager.startFullPomodoroSession()
                    },
                    onCancel: {
                        timerManager.showReadyToFocusSheet = false
                    }
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
            
            // Category Picker (for tapping category badge in expanded timer)
            .sheet(isPresented: $timerManager.showCategoryPicker) {
                FocusCategoryPicker(
                    timerManager: timerManager,
                    onStart: {
                        timerManager.showCategoryPicker = false
                    },
                    onCancel: {
                        timerManager.showCategoryPicker = false
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            
            // Landscape Full-Screen Timer
            .fullScreenCover(isPresented: $showLandscapeTimer) {
                LandscapeTimerView(
                    timerManager: timerManager,
                    soundscapePlayer: soundscapePlayer
                )
            }
            .onRotate { orientation in
                if orientation.isLandscape && timerManager.timerState == .running {
                    showLandscapeTimer = true
                } else if orientation.isPortrait {
                    showLandscapeTimer = false
                }
            }
            .onAppear {
                startMidnightCheckTimer()
            }
            .onDisappear {
                stopMidnightCheckTimer()
            }
            .onChange(of: timerManager.timerState) { oldState, newState in
                // Update currentTime when timer state changes
                if newState == .running {
                    currentTime = Date()
                }
            }
            
            .onChange(of: selectedDate) { _, newDate in
                Task { @MainActor in
                    // Silent refresh - only log failures
                    do {
                        _ = try modelContext.fetch(FetchDescriptor<HabitCompletion>())
                        _ = try modelContext.fetch(FetchDescriptor<PomodoroSession>())
                        _ = try modelContext.fetch(FetchDescriptor<MicroHabitCompletion>())
                        AppLog.debug("Date change data refresh complete", category: "loom.calendar")
                    } catch {
                        AppLog.error("Date change data refresh failed: \(error.localizedDescription)", category: "loom.data")
                    }
                }
            }
            //   Scene phase handling for background/foreground transitions
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    currentTime = Date()
                    checkForDayChange()
                    timerManager.handleAppDidBecomeActive()
                    AppLog.debug("Scene became active", category: "loom.lifecycle")
                } else if newPhase == .background {
                    // App went to background
                    timerManager.handleAppWillResignActive()
                    AppLog.debug("Scene entered background", category: "loom.lifecycle")
                }
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

                // PDF Task Library button
                Button {
                    showPDFLibrary = true
                } label: {
                    Image(systemName: "doc.text.viewfinder")
                        .font(.system(size: 15))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                        .frame(width: 40, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open task library")
                .accessibilityHint("Import PDFs and extract task lists")
                .accessibilityAddTraits(.isButton)

                // Calendar picker button
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
                .accessibilityLabel("Open calendar picker")
                .accessibilityHint("Choose a different date to view your weaves")
                .accessibilityAddTraits(.isButton)
            }
            
            // Swipeable week range display
            Text("\(weekDates.first?.formatted(.dateTime.month(.abbreviated).day()) ?? "") - \(weekDates.last?.formatted(.dateTime.month(.abbreviated).day()) ?? "")")
                .font(.system(size: 13, weight: .regular))
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                .tracking(0.5)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .accessibilityLabel("Current week: \(weekDates.first?.formatted(.dateTime.month(.wide).day()) ?? "") to \(weekDates.last?.formatted(.dateTime.month(.wide).day()) ?? "")")
                .accessibilityHint("Swipe left for next week, swipe right for previous week")
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
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                ForEach(weekDates, id: \.self) { date in
                    let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                    let isToday = Calendar.current.isDateInToday(date)
                    
                    VStack(spacing: 6) {
                        VStack(spacing: 4) {
                            if isSelected {
                                Text(date.formatted(.dateTime.weekday(.abbreviated)))
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(.white)
                            } else {
                                Text(date.formatted(.dateTime.weekday(.abbreviated)))
                                    .font(.system(size: 11, weight: .medium))
                                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                            }

                            if isSelected {
                                Text("\(Calendar.current.component(.day, from: date))")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(.white)
                            } else {
                                Text("\(Calendar.current.component(.day, from: date))")
                                    .font(.system(size: 18, weight: .semibold))
                                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            Group {
                                if isSelected {
                                    // Selected: Solid sage green (matches "+ Add" button)
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.sageGreen)
                                        .shadow(color: Color.sageGreen.opacity(0.3), radius: 4, y: 2)
                                } else {
                                    // Unselected: Subtle glass effect for visibility & tap detection
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            Color.adaptiveSectionBackground(colorScheme: colorScheme)
                                                .opacity(0.15)  // Very subtle background
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .strokeBorder(
                                                    isToday ? Color.sageGreen.opacity(0.4) :
                                                    (colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.08)),
                                                    lineWidth: 1
                                                )
                                        )
                                        .shadow(
                                            color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.04),
                                            radius: colorScheme == .dark ? 4 : 6,
                                            y: 2
                                        )
                                }
                            }
                        )
                        .contentShape(Rectangle())  // Ensure full tap area
                    }
                    .accessibilityLabel("\(date.formatted(.dateTime.weekday(.wide))) \(date.formatted(.dateTime.month(.wide).day()))")
                    .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
                    .accessibilityHint(isSelected ? "Currently viewing this date" : "Tap to view weaves for this date")
                    .onTapGesture {
                        selectedDate = date
                        
                        let generator = UISelectionFeedbackGenerator()
                        generator.selectionChanged()
                    }
                }
                .animation(
                    .spring(response: 0.35, dampingFraction: 0.75, blendDuration: 0.2),
                    value: selectedDate
                )
            }

            // Task indicator bars
            GeometryReader { geometry in
                let dayWidth = geometry.size.width / 7
                let incompleteTasks = allPriorityTasks.filter { !$0.isCompleted }
                
                #if DEBUG
                let _ = {
                    AppLog.info("━━━ Week Calendar Task Indicators ━━━", category: "loom.calendar")
                    AppLog.info("Week dates: \(weekDates.map { $0.formatted(.dateTime.month().day()) }.joined(separator: ", "))", category: "loom.calendar")
                    AppLog.info("Total incomplete tasks: \(incompleteTasks.count)", category: "loom.calendar")
                    for task in incompleteTasks {
                        AppLog.info("  Task: '\(task.title)'", category: "loom.calendar")
                        AppLog.info("    - Repeat: \(task.repeatType)", category: "loom.calendar")
                        AppLog.info("    - Color: #\(task.colorHex)", category: "loom.calendar")
                        AppLog.info("    - Start: \(task.startDate.formatted(.dateTime.month().day()))", category: "loom.calendar")
                        if let end = task.endDate {
                            AppLog.info("    - End: \(end.formatted(.dateTime.month().day()))", category: "loom.calendar")
                        }
                    }
                }()
                #endif
                
                ForEach(Array(incompleteTasks.enumerated()), id: \.element.id) { index, task in
                    // Use isActive(on:) to check if task should appear on each day
                    let coveredDays = weekDates.enumerated().filter { idx, weekDate in
                        task.isActive(on: weekDate)
                    }
                    
                    #if DEBUG
                    let _ = {
                        let activeDays = coveredDays.map { weekDates[$0.offset].formatted(.dateTime.weekday(.abbreviated)) }.joined(separator: ", ")
                        AppLog.info("  '\(task.title)' active on: [\(activeDays)]", category: "loom.calendar")
                    }()
                    #endif
                    
                    if let firstDay = coveredDays.first?.offset, let lastDay = coveredDays.last?.offset {
                        let startX = CGFloat(firstDay) * dayWidth
                        let span = CGFloat(lastDay - firstDay + 1)
                        let width = (span * dayWidth) - 8
                        let rowOffset = CGFloat(index % 3) * 5
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(hex: task.colorHex))
                            .frame(width: width, height: 3)
                            .offset(x: startX + 4, y: rowOffset)
                            .shadow(color: Color(hex: task.colorHex).opacity(0.4), radius: 1, y: 1)
                    }
                }
            }
            .frame(height: 18)
            .padding(.horizontal, 4)
        }
        .padding(.horizontal)
    }
    
    
    // MARK: - Day Change Detection
    
    private func checkForDayChange() {
        let calendar = Calendar.current
        let currentDay = calendar.startOfDay(for: currentTime)
        let lastDay = calendar.startOfDay(for: lastCheckedDay)
        
        if currentDay != lastDay {
            #if DEBUG
            AppLog.info("Day changed from \(lastDay.formatted(.dateTime.month().day())) to \(currentDay.formatted(.dateTime.month().day()))", category: "loom")
            #endif
            
            lastCheckedDay = currentTime
            
            Task { @MainActor in
                var refreshErrors: [String] = []
                
                do {
                    _ = try modelContext.fetch(FetchDescriptor<HabitCompletion>())
                } catch {
                    refreshErrors.append("HabitCompletion")
                    AppLog.error("HabitCompletion refresh failed: \(error.localizedDescription)", category: "loom.data")
                }
                
                do {
                    _ = try modelContext.fetch(FetchDescriptor<PomodoroSession>())
                } catch {
                    refreshErrors.append("PomodoroSession")
                    AppLog.error("PomodoroSession refresh failed: \(error.localizedDescription)", category: "loom.data")
                }
                
                do {
                    _ = try modelContext.fetch(FetchDescriptor<MicroHabitCompletion>())
                } catch {
                    refreshErrors.append("MicroHabitCompletion")
                    AppLog.error("MicroHabitCompletion refresh failed: \(error.localizedDescription)", category: "loom.data")
                }
                
                if refreshErrors.isEmpty {
                    #if DEBUG
                    AppLog.info("Midnight data refresh complete", category: "loom")
                    #endif
                } else {
                    AppLog.error("Midnight refresh failed for: \(refreshErrors.joined(separator: ", "))", category: "loom")
                }
            }
            
            // Auto-update to today if user was viewing today or yesterday
            if calendar.isDateInToday(selectedDate) ||
                (calendar.date(byAdding: .day, value: -1, to: Date()).map {
                    calendar.isDate(selectedDate, equalTo: $0, toGranularity: .day)
                } ?? false) {
                withAnimation {
                    selectedDate = Date()
                }
            }
        }
    }
    
    // Ensures late-night completions near midnight are counted (local date)
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
                            .font(.system(size: 12, weight: .semibold))
                        Text(canAddMore ? "Add" : "3/3")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(canAddMore ? Color.sageGreen : Color.sageGreen.opacity(0.2))
                    .foregroundStyle(canAddMore ? .white : Color.sageGreen)
                    .clipShape(Capsule())
                }
                .disabled(!canAddMore)
                .accessibilityLabel(canAddMore ? "Add priority task" : "Maximum 3 tasks reached")
                .accessibilityHint(canAddMore ? "Add a new priority task to your daily weaves" : "Complete or remove a task to add more")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // EMPTY STATE
            if todaysPriorityTasks.isEmpty && ongoingPriorityTasks.isEmpty && completedPriorityTasks.isEmpty {
                VStack(spacing: 12) {
                    Text("Set your top 3 priorities")
                        .font(.system(size: 12, weight: .regular))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    
                    Button {
                        showAddTask = true
                    } label: {
                        Text("Add Priority Task")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Color.sageGreen)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.sageGreen.opacity(0.12))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .strokeBorder(Color.sageGreen, lineWidth: 0.2)
                            )
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .reverieCardStyle(colorScheme: colorScheme)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            else {
                VStack(spacing: 12) {
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
                            },
                            onSubTaskToggle: { subTask in
                                toggleSubTaskCompletion(subTask)
                            }
                        )
                        .id(task.id)
                    }
                    
                    if !ongoingPriorityTasks.isEmpty {
                        VStack(spacing: 8) {
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    showOngoingWeaves.toggle()
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: showOngoingWeaves ? "chevron.down" : "chevron.right")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(Color.dustyBlue)
                                    
                                    Text("Ongoing Weaves")
                                        .font(.system(size: 13, weight: .medium))
                                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                                    
                                    Text("(\(ongoingPriorityTasks.count))")
                                        .font(.system(size: 12, weight: .medium))
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
                                        },
                                        onSubTaskToggle: { subTask in
                                            toggleSubTaskCompletion(subTask)
                                        }
                                    )
                                    .id(task.id)
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                    
                    if !completedPriorityTasks.isEmpty {
                        VStack(spacing: 8) {
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    showCompletedTasks.toggle()
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: showCompletedTasks ? "chevron.down" : "chevron.right")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(Color.sageGreen)
                                    
                                    Text("Completed")
                                        .font(.system(size: 13, weight: .medium))
                                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                                    
                                    Text("(\(completedPriorityTasks.count))")
                                        .font(.system(size: 12, weight: .medium))
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
                    
                    if activeCount == 3 {
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.dustyBlue)
                            
                            Text("Focus on these 3 tasks today. Complete or remove one to add more.")
                                .font(.system(size: 12, weight: .regular))
                                .timeAdaptiveText(colorScheme: colorScheme, style: .accent)
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

    // MARK: - Timeline Section

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Text("Timeline")
                .font(.system(size: 13, weight: .regular))
                .fontDesign(.serif)
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                .padding(.horizontal)
            
            if selectedDayCompletions.isEmpty && selectedDayPomodoros.isEmpty && selectedDayMicroHabits.isEmpty {
                
                VStack(spacing: 16) {
                    Image(systemName: "moon.stars")
                        .font(.system(size: 32))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                    
                    VStack(spacing: 6) {
                        Text("No threads woven yet")
                            .font(.system(size: 13, weight: .medium))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                        Text("Complete habits on your Desk or Start a focus session to see your loom")
                            .font(.system(size: 11.5, weight: .regular))
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
                
                // MARK: - Active Timeline Content
                
                VStack(spacing: 20) {
                    
                    circularDayProgress
                    
                    VStack(spacing: 24) {
                        if hasEntries(for: .night) {
                            timeBlockSection(period: .night)
                                .transition(.opacity)
                        }
                        
                        if hasEntries(for: .morning) {
                            timeBlockSection(period: .morning)
                                .transition(.opacity)
                        }
                        
                        if hasEntries(for: .afternoon) {
                            timeBlockSection(period: .afternoon)
                                .transition(.opacity)
                        }
                        
                        if hasEntries(for: .evening) {
                            timeBlockSection(period: .evening)
                                .transition(.opacity)
                        }
                    }
                    .animation(.easeInOut, value: selectedDayCompletions.count)
                    
                    timeLeftIndicator
                }
            }
        }
    }
    
    private func hasEntries(for period: TimePeriod) -> Bool {
        // Check Habits
        let hasCompletions = selectedDayCompletions.contains { period.contains(date: $0.completedAt) }
        if hasCompletions { return true }
        
        // Check Pomodoros
        let hasPomodoros = selectedDayPomodoros.contains { period.contains(date: $0.completedAt) }
        if hasPomodoros { return true }
        
        // Check Micro Habits
        let hasMicro = selectedDayMicroHabits.contains { period.contains(date: $0.completedAt) }
        if hasMicro { return true }
        
        return false
    }
    
    // MARK: - Final Progress (Black Circle Needle + Big Dots)
    
    private var circularDayProgress: some View {
        var calendar = Calendar.current
        calendar.timeZone = .current
        
        let currentHour = calendar.component(.hour, from: currentTime)
        let currentMinute = calendar.component(.minute, from: currentTime)
        
        // 18-hour window (6 AM to 12 AM)
        let progress: CGFloat = {
            if currentHour < 6 { return 0.0 }
            else if currentHour >= 24 { return 1.0 }
            else {
                let minutesSince6AM = (currentHour - 6) * 60 + currentMinute
                let totalMinutesInWindow = 18 * 60
                return CGFloat(minutesSince6AM) / CGFloat(totalMinutesInWindow)
            }
        }()
        
        let currentPeriod = getTimePeriod(for: currentTime)
        
        return VStack(spacing: 24) {
            
            // MARK: - 1. Hour Progress Bar
            
            VStack(spacing: 8) {
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.secondary.opacity(0.1))
                            
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.sageGreen.opacity(0.5),
                                            Color.dustyBlue.opacity(0.8),
                                            Color.terracottaRose.opacity(0.5),
                                            Color.paleMauve.opacity(0.8)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(0, geometry.size.width * progress))
                            
                            // White Separators
                            HStack(spacing: 0) {
                                ForEach(0..<18) { index in
                                    if index > 0 {
                                        Rectangle()
                                            .fill(Color.white.opacity(0.4))
                                            .frame(width: 1)
                                    }
                                    Spacer()
                                }
                            }
                        }
                        .frame(height: 12)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                        
                        if currentHour >= 6 {
                            ZStack {
                                // 1. Period Icon Floating Above
                                Image(systemName: currentPeriod.icon)
                                    .font(.system(size: 13))
                                    .foregroundStyle(currentPeriod.color)
                                    .offset(y: -16)
                                
                                // 2. The Black Circle (Knob)
                                Circle()
                                    .fill(Color.black)
                                    .frame(width: 11, height: 11)
                                    .shadow(color: .white.opacity(0.5), radius: 2, x: 0, y: 0)
                            }
                            // Vertical Center
                            .position(x: min(max(6, geometry.size.width * progress), geometry.size.width - 6),
                                      y: geometry.size.height / 2)
                        }
                    }
                }
                .frame(height: 20)
                
                // MARK: - 2. Time Labels & Fixed Text
                
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "sunrise.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.sageGreen)
                        Text("6 AM")
                            .font(.system(size: 11, weight: .regular))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    }
                    
                    Spacer()
                    
                    Text(currentHour >= 6 ? currentPeriod.displayName.uppercased() : "NIGHT")
                        .font(.system(size: 11, weight: .semibold))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                        .tracking(0.5)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Text("12 AM")
                            .font(.system(size: 11, weight: .regular))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.paleMauve)
                    }
                }
            }
            
            // MARK: - 3. Minute Dots
            
            if currentHour >= 6 {
                VStack(spacing: 8) {
                    // Minute Dots
                    VStack(spacing: 4) {
                        // Row 1
                        HStack(spacing: 0) {
                            ForEach(0..<6) { group in
                                HStack(spacing: 2) {
                                    ForEach(0..<5) { dot in
                                        let minute = group * 5 + dot
                                        Circle()
                                            .fill(minute < currentMinute
                                                  ? currentPeriod.color
                                                  : Color.secondary.opacity(0.15))
                                            .frame(width: 7.2, height: 7.2) //dot size
                                    }
                                }
                                if group < 5 { Spacer() }
                            }
                        }
                        
                        // Row 2
                        HStack(spacing: 0) {
                            ForEach(0..<6) { group in
                                HStack(spacing: 2) {
                                    ForEach(0..<5) { dot in
                                        let minute = 30 + group * 5 + dot
                                        Circle()
                                            .fill(minute < currentMinute
                                                  ? currentPeriod.color
                                                  : Color.secondary.opacity(0.15))
                                            .frame(width: 7.2, height: 7.2) //dot size
                                    }
                                }
                                if group < 5 { Spacer() }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 4)
                    
                    // Time Left
                    HStack(spacing: 4) {
                        Image(systemName: "hourglass")
                            .font(.system(size: 11))
                        Text("\(60 - currentMinute) min left in this hour")
                            .font(.system(size: 11, weight: .regular))
                    }
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    .padding(.top, 2)
                }
            } else {
                // Night State
                VStack(spacing: 6) {
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.paleMauve)
                    
                    Text("Rest hours (12 AM - 6 AM)")
                        .font(.system(size: 11, weight: .regular))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        .italic()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Time Block Section (WITH SUBJECT GROUPING)
    
    private func timeBlockSection(period: TimePeriod) -> some View {
        // 1. Filter Data
        let completionsInPeriod = selectedDayCompletions.filter { period.contains(date: $0.completedAt) }
        let sortedHabits = completionsInPeriod.sorted { $0.completedAt < $1.completedAt }
        
        let pomodorosInPeriod = selectedDayPomodoros.filter { period.contains(date: $0.completedAt) }
        let microHabitsInPeriod = selectedDayMicroHabits.filter { period.contains(date: $0.completedAt) }
        
        // Group Pomodoro sessions by subject
        let groupedPomodoros = groupPomodoroSessions(pomodorosInPeriod)
        
        // 2. Check Empty State
        let isEmpty = completionsInPeriod.isEmpty && pomodorosInPeriod.isEmpty && microHabitsInPeriod.isEmpty
        
        return VStack(alignment: .leading, spacing: 12) {
        
            HStack(spacing: 8) {
                Image(systemName: period.icon)
                    .font(.system(size: 13))
                    .foregroundStyle(period.color)
                
                Text(period.displayName.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    .tracking(1)
                
                Text(period.timeRange)
                    .font(.system(size: 11, weight: .regular))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
            }
            .padding(.leading, 20)
            
            if isEmpty {
                Text("No threads woven yet")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.gray.opacity(0.6))
                    .italic()
                    .padding(.leading, 28)
            } else {
                ZStack(alignment: .leading) {
                    // Continuous Thread Line
                    Rectangle()
                        .fill(Color.habitCardBorder.opacity(colorScheme == .dark ? 0.3 : 0.35))
                        .frame(width: 1.2)
                        .padding(.leading, 40)
                        .padding(.vertical, 6)
                    
                    VStack(spacing: 0) {
                        
                        // 1. Habits
                        ForEach(Array(sortedHabits.enumerated()), id: \.element.id) { index, completion in
                            TimelineEntryRow(
                                entry: .habit(completion),
                                habit: habits.first { $0.id == completion.habitId },
                                isFirst: index == 0,
                                isLast: index == sortedHabits.count - 1 && microHabitsInPeriod.isEmpty && groupedPomodoros.isEmpty,
                                onTap: { showReflection = completion },
                                onDelete: { deleteHabitCompletion(completion) }
                            )
                        }
                        
                        // 2. Micro Habits
                        if !microHabitsInPeriod.isEmpty {
                            MicroHabitSummaryRow(
                                count: microHabitsInPeriod.count,
                                isFirst: sortedHabits.isEmpty,
                                isLast: groupedPomodoros.isEmpty
                            )
                        }
                        
                        // 3. Focus Sessions
                        ForEach(Array(groupedPomodoros.enumerated()), id: \.element.id) { index, group in
                            PomodoroSummaryRow(
                                id: group.id,
                                sessions: group.sessions,
                                count: group.count,
                                totalMinutes: group.totalMinutes,
                                isFirst: sortedHabits.isEmpty && microHabitsInPeriod.isEmpty && index == 0,
                                isLast: index == groupedPomodoros.count - 1
                            )
                            .id(group.id)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Pomodoro Grouping
    
    private func groupPomodoroSessions(_ sessions: [PomodoroSession]) -> [PomodoroGroup] {
        // Calculate anchor times (first occurrence of each subject)
        var anchorTimes: [String: Date] = [:]
        let sortedByStart = sessions.sorted { $0.startTime < $1.startTime }
        
        for session in sortedByStart {
            guard let rawSubject = session.note,
                  !rawSubject.trimmingCharacters(in: .whitespaces).isEmpty else {
                continue
            }
            
            let normalizedSubject = rawSubject.trimmingCharacters(in: .whitespaces).lowercased()
            
            // Record anchor time on FIRST occurrence only
            if anchorTimes[normalizedSubject] == nil {
                anchorTimes[normalizedSubject] = session.startTime
            }
        }
        
        // Group sessions by their stable group key
        let grouped = Dictionary(grouping: sessions) { session -> String in
            guard let rawSubject = session.note,
                  !rawSubject.trimmingCharacters(in: .whitespaces).isEmpty else {
                return "NO_SUBJECT_\(UUID().uuidString)" // Unique key for no-subject sessions
            }
            
            let normalizedSubject = rawSubject.trimmingCharacters(in: .whitespaces).lowercased()
            return normalizedSubject
        }
        
        let groups = grouped.compactMap { key, items -> PomodoroGroup? in
            
            // Skip no-subject groups
            guard !key.hasPrefix("NO_SUBJECT_") else { return nil }
            
            // Get the display subject from first item
            guard let displaySubject = items.first?.note?.trimmingCharacters(in: .whitespaces) else {
                return nil
            }
            
            // Get category from first item
            let categoryString = items.first?.category ?? "uncategorized"
            let category = FocusCategory(rawValue: categoryString) ?? .uncategorized
            
            // Get anchor time for this group (fallback to first session's start time)
            let anchorTime = anchorTimes[key] ?? items.first?.startTime ?? Date()
            
            return PomodoroGroup(
                id: key,
                category: category,
                subject: displaySubject,
                sessions: items,
                anchorTime: anchorTime
            )
        }
            .sorted { $0.anchorTime < $1.anchorTime }
        
        return groups
    }
    
    struct PomodoroGroup: Identifiable {
        let id: String
        let category: FocusCategory
        let subject: String?
        let sessions: [PomodoroSession]
        let anchorTime: Date
        
        var count: Int { sessions.count }
        var totalMinutes: Int { sessions.reduce(0) { $0 + $1.duration } }
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
                .font(.system(size: 13))
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
            
            Text("\(hoursLeft) hours remaining today")
                .font(.system(size: 13, weight: .regular))
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
        }
        .padding(.leading, 20)
        .padding(.top, 8)
    }
    
    // MARK: - Time Period Helpers (4 EQUAL PERIODS)
    
    enum TimePeriod: String, CaseIterable, Hashable {
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
        
        //   Check hour directly instead of date
        func containsHour(_ hour: Int) -> Bool {
            switch self {
            case .morning: return hour >= 6 && hour < 12
            case .afternoon: return hour >= 12 && hour < 18
            case .evening: return hour >= 18 && hour < 24
            case .night: return hour >= 0 && hour < 6
            }
        }
        
        func contains(date: Date) -> Bool {
            var calendar = Calendar.current
            calendar.timeZone = .current
            let hour = calendar.component(.hour, from: date)
            
            switch self {
            case .morning: return hour >= 6 && hour < 12
            case .afternoon: return hour >= 12 && hour < 18
            case .evening: return hour >= 18 && hour < 24
            case .night: return hour >= 0 && hour < 6
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func getTimePeriod(for date: Date) -> TimePeriod {
        var calendar = Calendar.current
        calendar.timeZone = .current
        let hour = calendar.component(.hour, from: date)
        
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
    
    // MARK: - Helper: Relative Time Display
    
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
    
    // Timer Management
    private func startMidnightCheckTimer() {

        currentTime = Date()
        checkForDayChange()
        
        midnightCheckTimer?.invalidate()
        midnightCheckTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            self.currentTime = Date()
            self.checkForDayChange()
        }
        
        AppLog.debug("Midnight check timer started (60s interval)", category: "loom.battery")
    }
    
    private func stopMidnightCheckTimer() {
        midnightCheckTimer?.invalidate()
        midnightCheckTimer = nil
        AppLog.debug("Midnight check timer stopped", category: "loom.battery")
    }
    
    private func changeWeek(by weeks: Int) {
        let calendar = Calendar.current
        
        guard let newDate = calendar.date(byAdding: .weekOfYear, value: weeks, to: selectedDate) else {
            AppLog.warn("Failed to calculate week change", category: "loom.calendar")
            
            errorAlert = ErrorAlert(
                title: "Navigation Error",
                message: "Unable to navigate to the requested week. Please try again."
            )
            return
        }
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            selectedDate = newDate
        }
        
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
        
        AppLog.debug("Week changed by \(weeks) week(s)", category: "loom.calendar")
    }
    
    // MARK: - Deletion Helpers
    
    private func toggleTaskCompletion(_ task: PriorityTask) {
        
        guard !isCompletingTask else {
            AppLog.warn("Task toggle ignored - operation in progress", category: "loom.task")
            return
        }
        
        isCompletingTask = true
        defer { isCompletingTask = false }
        
        if task.isCompleted {
            task.isCompleted = false
            task.completedAt = nil
            
            do {
                try modelContext.save()
            } catch {
                modelContext.rollback()
                AppLog.error("Task uncheck failed", category: "loom.task")
                errorAlert = ErrorAlert(
                    title: "Update Failed",
                    message: "Unable to update task status. Please try again."
                )
            }
        } else {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            
            let taskEnd: Date
            if let endDate = task.endDate {
                taskEnd = calendar.startOfDay(for: endDate)
            } else {
                taskEnd = calendar.startOfDay(for: task.startDate)
            }
            
            // Smart Carry-Over Logic
            if today >= taskEnd {
                task.isCompleted = true
                task.completedAt = Date()
                
                do {
                    try modelContext.save()
                } catch {
                    modelContext.rollback()
                    AppLog.error("Task completion failed", category: "loom.task")
                    errorAlert = ErrorAlert(
                        title: "Save Failed",
                        message: "Unable to complete task. Please try again."
                    )
                }
            } else {
                taskToComplete = task
                showCarryOverAlert = true
            }
        }
    }
    
    private func toggleSubTaskCompletion(_ subTask: SubTask) {
        subTask.isCompleted.toggle()
        
        do {
            try modelContext.save()
            #if DEBUG
            AppLog.info("Sub-task '\(subTask.title)' toggled to \(subTask.isCompleted ? "completed" : "incomplete")", category: "loom.task")
            #endif
        } catch {
            // Rollback the toggle on error
            subTask.isCompleted.toggle()
            modelContext.rollback()
            
            AppLog.error("Sub-task toggle failed: \(error.localizedDescription)", category: "loom.task")
            errorAlert = ErrorAlert(
                title: "Update Failed",
                message: "Unable to update sub-task status. Please try again."
            )
        }
    }
    
    private func completeTask(_ task: PriorityTask, carryOver: Bool) {
        
        guard !isCompletingTask else {
            AppLog.warn("Task completion ignored - already processing", category: "loom.task")
            return
        }
        
        isCompletingTask = true
        defer {
            isCompletingTask = false
            taskToComplete = nil
        }
        
        guard !task.isCompleted else {
            AppLog.warn("Task already completed", category: "loom.task")
            return
        }
        
        if carryOver {
            guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) else {
                errorAlert = ErrorAlert(
                    title: "Unable to Carry Over",
                    message: "Could not create tomorrow's task. Please try again."
                )
                return
            }
            
            // Copy task with subtasks preserved
            let newTask = PriorityTask(
                title: task.title,
                taskDescription: task.taskDescription,
                startDate: tomorrow,
                endDate: task.endDate,
                colorHex: task.colorHex
            )
            
            if let subtasks = task.subTasks {
                for subtask in subtasks where !subtask.isCompleted {
                    let newSubtask = SubTask(title: subtask.title)
                    modelContext.insert(newSubtask)
                    if newTask.subTasks == nil {
                        newTask.subTasks = []
                    }
                    newTask.subTasks?.append(newSubtask)
                }
            }
            
            modelContext.insert(newTask)
        }
        
        task.isCompleted = true
        task.completedAt = Date()
        
        do {
            try modelContext.save()
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
        } catch {
            modelContext.rollback()
            AppLog.error("Task completion save failed: \(error.localizedDescription)", category: "loom.task")
            errorAlert = ErrorAlert(
                title: "Save Failed",
                message: "Unable to save task completion. Please try again."
            )
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }
    
    private func deleteTask(_ task: PriorityTask) {
        modelContext.delete(task)
        
        do {
            try modelContext.save()
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
        } catch {
            modelContext.rollback()
            AppLog.error("Task deletion failed: \(error.localizedDescription)", category: "loom.task")
            errorAlert = ErrorAlert(
                title: "Delete Failed",
                message: "Unable to delete task. Please try again."
            )
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }
    
    private func deleteHabitCompletion(_ completion: HabitCompletion) {
        guard !isDeletingEntry else {
            AppLog.warn("Delete ignored - operation in progress", category: "loom.habit")
            return
        }
        
        isDeletingEntry = true
        defer { isDeletingEntry = false }
        
        let habitId = completion.habitId
        let completionDate = completion.completedAt
        let calendar = Calendar.current
        
        let dayCompletions = completions.filter {
            $0.habitId == habitId &&
            calendar.isDate($0.completedAt, inSameDayAs: completionDate)
        }
        
        guard !dayCompletions.isEmpty else {
            AppLog.warn("No completions found to delete", category: "loom.habit")
            return
        }
        
        AppLog.debug("Deleting \(dayCompletions.count) completion(s) for habit", category: "loom.habit")
        
        withAnimation {
            for duplicate in dayCompletions {
                modelContext.delete(duplicate)
            }
        }
        
        do {
            try modelContext.save()
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            Task { @MainActor in
                let current = selectedDate
                selectedDate = current
            }
            
            AppLog.success("Habit completion deleted", category: "loom.habit")
        } catch {
            modelContext.rollback()
            AppLog.error("Habit deletion failed: \(error.localizedDescription)", category: "loom.habit")
            errorAlert = ErrorAlert(
                title: "Delete Failed",
                message: "Unable to delete habit entry. Please try again."
            )
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }
}

// MARK: - Timeline Entry Row

struct TimelineEntryRow: View {
    @Environment(\.colorScheme) private var colorScheme

    let entry: LoomView.TimelineEntryType
    let habit: Habit?
    let isFirst: Bool
    let isLast: Bool
    let onTap: () -> Void
    let onDelete: (() -> Void)?
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {

                Circle()
                    .fill(entryColor)
                    .frame(width: 9, height: 9)
                    .padding(.leading, 20)
                
                HStack(spacing: 6) {
                    Text(entryTitle)
                        .font(.system(size: 13, weight: .medium))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    
                    if case .habit(let completion) = entry, let reflection = completion.reflection {
                        Text("•")
                            .font(.system(size: 12))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        
                        Image(systemName: getMoodIcon(for: reflection.mood))
                            .font(.system(size: 12))
                                .foregroundStyle(getMoodColor(for: reflection.mood).opacity(colorScheme == .dark ? 0.9 : 0.8))
                        
                        Text(reflection.mood)
                            .font(.system(size: 12, weight: .regular))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        
                        if reflection.isFavorite {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.terracottaRose.opacity(colorScheme == .dark ? 0.9 : 0.8))
                                .padding(.leading, 2)
                        }
                    }
                }
                .offset(y: 0.5)
                
                Spacer()
                
                Text(relativeTime)
                    .font(.system(size: 12, weight: .regular))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    .offset(y: 0.5)
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        
        .contextMenu {
                if let onDelete = onDelete {
                    Button(role: .destructive, action: onDelete) {
                    Label("Delete Entry", systemImage: "trash")
                }
            }
        }
    }
    
    private var entryColor: Color {
        switch entry {
        case .habit(let completion):
            if let live = habit { return Color(hex: live.colorHex) }
            if let snap = completion.snapshotColorHex { return Color(hex: snap) }
            return .sageGreen
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
    @Environment(\.colorScheme) private var colorScheme
    let count: Int
    let isFirst: Bool
    let isLast: Bool
    
    var body: some View {
        HStack(spacing: 12) {
          
            ZStack {
               
                Circle()
                    .fill(Color.terracottaRose.opacity(colorScheme == .dark ? 0.2 : 0.15))
                    .frame(width: 14, height: 14)
                
                Image(systemName: "bolt.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.terracottaRose)
            }
            .padding(.leading, 18)
            
            HStack(spacing: 6) {
                Text("\(count) Quick Action\(count == 1 ? "" : "s") completed")
                    .font(.system(size: 13, weight: .medium))
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
    @Environment(\.colorScheme) private var colorScheme
    
    let id: String?
    let sessions: [PomodoroSession]
    let count: Int
    let totalMinutes: Int
    let isFirst: Bool
    let isLast: Bool

    init(id: String? = nil, sessions: [PomodoroSession], count: Int, totalMinutes: Int, isFirst: Bool, isLast: Bool) {
        self.id = id
        self.sessions = sessions
        self.count = count
        self.totalMinutes = totalMinutes
        self.isFirst = isFirst
        self.isLast = isLast
    }

    // MARK: Get unique Categories & Subject from sessions
    
    private var uniqueCategories: [FocusCategory] {
        let categoryStrings = sessions.compactMap { $0.category }
        let unique = Array(Set(categoryStrings))
        return unique.compactMap { FocusCategory(rawValue: $0) }
    }
    
    private var uniqueSubjects: [String] {
        let subjects = sessions.compactMap { session -> String? in
            guard let note = session.note else { return nil }
            let trimmed = note.trimmingCharacters(in: .whitespaces)
            return trimmed.isEmpty ? nil : trimmed
        }
        
        var seen = Set<String>()
        var unique: [String] = []
        
        for subject in subjects {
            let lowercase = subject.lowercased()
            if !seen.contains(lowercase) {
                seen.insert(lowercase)
                unique.append(subject)
            }
        }
        
        return unique
    }
    
    var body: some View {
        HStack(spacing: 12) {
     
            ZStack {
           
                Circle()
                    .fill(Color.sageGreen.opacity(colorScheme == .dark ? 0.2 : 0.15))
                    .frame(width: 14, height: 14)
                
                Image(systemName: "target")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.sageGreen)
            }
            .padding(.leading, 18)
            
            HStack(spacing: 6) {
                Text("⌛︎")
                    .font(.system(size: 20))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    .offset(y: -2)
                
                if uniqueSubjects.isEmpty {
                    // No subjects - show standard format
                    Text("\(count) Focus Session\(count == 1 ? "" : "s") • \(totalMinutes) min")
                        .font(.system(size: 13, weight: .medium))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                } else {
                    // Has subjects - show with subjects
                    Text("\(count) Focus Session\(count == 1 ? "" : "s") • \(subjectsText) • \(totalMinutes) min")
                        .font(.system(size: 13, weight: .medium))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                }
                
                // Focus category icons
                if !uniqueCategories.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(uniqueCategories, id: \.self) { category in
                            ZStack {
                                Circle()
                                    .fill(category.color.opacity(colorScheme == .dark ? 0.15 : 0.12))
                                    .frame(width: 20, height: 20)

                                Image(systemName: category.icon)
                                    .font(.system(size: 11, weight: .medium))
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
    
    private var subjectsText: String {
        uniqueSubjects.joined(separator: ", ")
    }
}
    
// MARK: - "The Weaver's Glass"

struct FloatingPomodoroTimer: View {
    @Bindable var timerManager: PomodoroTimerManager
    var soundscapePlayer: SoundscapePlayer
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Group {
            if timerManager.isExpanded {
                expandedView
            } else {
                collapsedView
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.75), value: timerManager.isExpanded)
        .onChange(of: timerManager.chimeEnabled) { _, _ in
            // Let manager handle audio state
            timerManager.updateAudioState()
        }
        .onChange(of: timerManager.timerState) { _, _ in
            timerManager.updateAudioState()
        }
        .onChange(of: timerManager.backgroundMusicVolume) { _, newVolume in
            timerManager.setBackgroundMusicVolume(newVolume)
        }
    }
    
    // MARK: - 1. Collapsed View
    
    private var collapsedView: some View {
        Button {
            withAnimation { timerManager.isExpanded = true }
        } label: {
            ZStack {
                // Subtle glow in background (matching DeskView FAB)
                Circle()
                    .fill(Color.sageGreen.opacity(0.3))
                    .frame(width: 54, height: 54)
                    .blur(radius: 4)

                // Main circle with gradient (matching DeskView FAB)
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.sageGreen, Color.dustyBlue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                    .shadow(color: Color.shadowColor.opacity(0.3), radius: 4, y: 3)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                    )

                // Progress ring when timer is active
                if timerManager.timerState != .idle {
                    Circle()
                        .trim(from: 0, to: timerManager.progress)
                        .stroke(
                            Color.white.opacity(0.8),
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                        )
                        .frame(width: 52, height: 52)
                        .rotationEffect(.degrees(-90))
                }

                if timerManager.timerState == .idle {
                    Image(systemName: "hourglass")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                } else {
                    Text(timerManager.formattedMinutes)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - 2. Expanded View
    
        private var expandedView: some View {
            ZStack(alignment: .topTrailing) {
                
                ZStack {

                    ZStack {
                        // Frosted glass backdrop - obscures content behind
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 260, height: 260)

                        // Subtle glow background
                        Circle()
                            .fill(Color.sageGreen.opacity(0.2))
                            .frame(width: 280, height: 280)
                            .blur(radius: 10)

                        // Main circle with muted gradient fill (no material)
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.sageGreen.opacity(0.35),
                                        Color.dustyBlue.opacity(0.6)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 260, height: 260)
                            .shadow(color: Color.shadowColor.opacity(0.25), radius: 15, y: 8)
                            // White strokeBorder with glow
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                            )
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.28)
                                    .shadow(color: Color.white.opacity(0.16), radius: 6, x: 0, y: 0)
                            )
                    }
                    
                    Group {
                        Circle()
                            .stroke(Color.primary.opacity(0.05), lineWidth: 2)
                        
                        Circle()
                            .trim(from: 0, to: timerManager.progress)
                            .stroke(
                                AngularGradient(colors: [Color.sageGreen, Color.paleMauve], center: .center),
                                style: StrokeStyle(lineWidth: 4, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 1), value: timerManager.progress)
                        
                        if timerManager.timerState != .idle {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 10, height: 10)
                                .shadow(color: Color.sageGreen.opacity(0.6), radius: 6)
                                .overlay(Circle().stroke(Color.sageGreen.opacity(0.5), lineWidth: 1))
                                .offset(y: -130) // Radius of 260 circle
                                .rotationEffect(.degrees(timerManager.progress * 360))
                                .animation(.linear(duration: 1), value: timerManager.progress)
                        }
                    }
                    .frame(width: 260, height: 260)
                    
                    VStack(spacing: 16) {
                        Button {
                            timerManager.showReadyToFocusSheet = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: timerManager.timerState.icon)
                                    .font(.system(size: 11))
                                    .foregroundStyle(timerManager.crystalBallColor)
                                
                                Text(timerManager.timerState.displayName)
                                    .font(.system(size: 11, weight: .medium))
                                    .fontDesign(.serif)
                                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                                
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color.secondary)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(Color.primary.opacity(0.03)))
                        }
                        .buttonStyle(.plain)
                        
                        VStack(spacing: 6) {
                            Text("DURATION")
                                .font(.system(size: 11, weight: .semibold))
                                .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                                .tracking(1)
                            
                            HStack(spacing: 8) {
                                ForEach([15, 25, 45, 60], id: \.self) { duration in
                                    Button {
                                        let impact = UIImpactFeedbackGenerator(style: .light)
                                        impact.impactOccurred()
                                        timerManager.setWorkDuration(duration)
                                    } label: {
                                        VStack(spacing: 0) {
                                            if timerManager.workDuration == duration {
                                                Text("\(duration)")
                                                    .font(.system(size: 13, weight: .bold))
                                                    .foregroundStyle(.white)
                                                Text("min")
                                                    .font(.system(size: 11, weight: .regular))
                                                    .foregroundStyle(.white.opacity(0.8))
                                            } else {
                                                Text("\(duration)")
                                                    .font(.system(size: 13, weight: .bold))
                                                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                                                Text("min")
                                                    .font(.system(size: 11, weight: .regular))
                                                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                                            }
                                        }
                                        .frame(width: 38, height: 38)
                                        .background(
                                            Circle()
                                                .fill(timerManager.workDuration == duration
                                                      ? timerManager.crystalBallColor
                                                      : Color.primary.opacity(0.04))
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        
                        // Time Display
                        VStack(spacing: 2) {
                            Text(timerManager.formattedTime)
                                .font(.system(size: 36, weight: .bold))
                                .fontDesign(.rounded)
                                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                            
                            if timerManager.sessionCount > 0 {
                                HStack(spacing: 2) {
                                    ForEach(0..<min(timerManager.sessionCount, 4), id: \.self) { _ in
                                        Text("🍅").font(.system(size: 11))
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                        
                        HStack(spacing: 20) {
                            Button {
                                if timerManager.timerState == .idle || timerManager.timerState == .paused {
                                    if timerManager.timerState == .paused { timerManager.resumeTimer() }
                                    else { timerManager.showCategoryPicker = true }
                                } else {
                                    timerManager.pauseTimer()
                                }
                            } label: {
                                Image(systemName: timerManager.timerState == .running ? "pause.circle.fill" : "play.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(timerManager.crystalBallColor.opacity(0.8))
                            }
                            
                                if timerManager.timerState != .idle {
                                    Button {
                                        if timerManager.timerState == .shortBreak || timerManager.timerState == .longBreak {
                                // BREAK MODE: Stop/Cancel
                                            let impact = UINotificationFeedbackGenerator()
                                            impact.notificationOccurred(.warning)
                                            timerManager.stopTimer()
                                        } else {
                                // FOCUS MODE: Restart
                                            timerManager.restartTimer()
                                        }
                                    } label: {
                                        Image(systemName: (timerManager.timerState == .shortBreak || timerManager.timerState == .longBreak)
                                              ? "stop.circle.fill"
                                              : "arrow.counterclockwise.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundStyle((timerManager.timerState == .shortBreak || timerManager.timerState == .longBreak)
                                                             ? Color.terracottaRose.opacity(0.8)
                                                             : Color.terracottaRose.opacity(0.6))
                                    }
                                    .transition(.scale.combined(with: .opacity))
                                }
                            
                            // Skip
                            if timerManager.timerState != .idle {
                                Button { timerManager.skipToBreak() } label: {
                                    Image(systemName: "forward.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundStyle(Color.secondary.opacity(0.6))
                                }
                            }
                            
                            // Sound
                            Button {
                                let impact = UIImpactFeedbackGenerator(style: .light)
                                impact.impactOccurred()
                                timerManager.chimeEnabled.toggle()
                            } label: {
                                Image(systemName: timerManager.chimeEnabled ? "bell.fill" : "bell.slash.fill")
                                    .font(.system(size: 22))
                                    .foregroundStyle(timerManager.chimeEnabled ? timerManager.crystalBallColor : Color.secondary.opacity(0.4))
                            }
                        }
                    }
                }
                .frame(width: 280, height: 280)
                
                Button {
                    withAnimation { timerManager.isExpanded = false }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.secondary.opacity(0.6))
                        .padding(10)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .offset(x: 0, y: 0)
            }
        }
}

// MARK: - Priority Task Row Component

struct PriorityTaskRow: View {
    @Environment(\.colorScheme) private var colorScheme

    let task: PriorityTask
    let selectedDate: Date
    let modelContext: ModelContext
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onSubTaskToggle: (SubTask) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Button(action: onToggle) {
                    ZStack {
                        Circle()
                            .strokeBorder(
                                task.isCompleted
                                    ? Color(hex: task.colorHex)
                                    : (colorScheme == .dark ? Color.white.opacity(0.5) : Color.black.opacity(0.5)),
                                lineWidth: 2
                            )
                            .frame(width: 20, height: 20)
                        
                        if task.isCompleted {
                            Circle()
                                .fill(Color(hex: task.colorHex))
                                .frame(width: 20, height: 20)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
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
                        .timeAdaptiveText(
                            colorScheme: colorScheme,
                            style: .primary,
                            isCompleted: task.isCompleted
                        )
                    
                    HStack(spacing: 4) {
                        Text(dateDisplayText)
                            .font(.system(size: 11, weight: .regular))
                            .fontDesign(.serif)
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        
                        // Show "Day X/Y" badge on days 2+
                        if let progress = task.getDayProgress(for: selectedDate),
                           progress.current > 1 {
                            Text("Day \(progress.current)/\(progress.total)")
                                .font(.system(size: 11, weight: .medium))
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
                            .font(.system(size: 12, weight: .regular))
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
                                onSubTaskToggle(subTask)
                            }) {
                                Image(systemName: subTask.isCompleted ? "checkmark.square.fill" : "square")
                                    .font(.system(size: 14))
                                    .fontDesign(.serif)
                                    .foregroundStyle(
                                        subTask.isCompleted
                                            ? Color(hex: task.colorHex)
                                            : (colorScheme == .dark ? Color.white.opacity(0.5) : Color.black.opacity(0.5))
                                    )
                            }
                            .buttonStyle(.plain)
                            
                            Text(subTask.title)
                                .font(.system(size: 13, weight: .regular))
                                .fontDesign(.serif)
                                .strikethrough(subTask.isCompleted)
                                .timeAdaptiveText(
                                    colorScheme: colorScheme,
                                    style: .secondary,
                                    isCompleted: subTask.isCompleted
                                )
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

// MARK: - Custom Carry Over Sheet

struct CustomCarryOverSheet: View {
    @Environment(\.colorScheme) private var colorScheme

    let taskToComplete: PriorityTask?
    let onComplete: (Bool) -> Void
    let onCancel: () -> Void
    
    // Smart logic to determine primary action
    private var shouldPrioritizeCarryOver: Bool {
        guard let task = taskToComplete else { return false }
        
        // Check if has uncompleted subtasks
        let hasUncompletedSubtasks = task.subTasks?.contains(where: { !$0.isCompleted }) ?? false
        
        // Check end date distance
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let endDate = task.endDate {
            let end = calendar.startOfDay(for: endDate)
            let daysUntilEnd = calendar.dateComponents([.day], from: today, to: end).day ?? 0
            
            // Prioritize carry over if:
            // 1. Has uncompleted subtasks, OR
            // 2. End date is 2+ days away
            return hasUncompletedSubtasks || daysUntilEnd >= 2
        }
        
        // No end date but has uncompleted subtasks
        return hasUncompletedSubtasks
    }
    
    private var tomorrowDate: String {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        return tomorrow.formatted(.dateTime.month(.abbreviated).day())
    }
    
    var body: some View {
        ZStack {
            ReverieWeaverBackground().ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with task context
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        if let task = taskToComplete {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(Color(hex: task.colorHex))
                                    .frame(width: 8, height: 8)
                                
                                Text(task.title)
                                    .font(.system(size: 16, weight: .semibold))
                                    .fontDesign(.serif)
                                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                            }
                            
                            Text("Completed")
                                .font(.system(size: 13, weight: .regular))
                                .fontDesign(.serif)
                                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        }
                    }
                    .padding(.top, 24)
                    
                    // Context info card
                    if let task = taskToComplete {
                        VStack(alignment: .leading, spacing: 6) {
                            // End date info
                            if let endDate = task.endDate {
                                HStack(spacing: 6) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 11))
                                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                                    
                                    Text("Runs until \(endDate.formatted(date: .abbreviated, time: .omitted))")
                                        .font(.system(size: 12))
                                        .fontDesign(.serif)
                                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                                }
                            }
                            
                            // Subtasks progress
                            if let subtasks = task.subTasks, !subtasks.isEmpty {
                                let completed = subtasks.filter { $0.isCompleted }.count
                                let total = subtasks.count
                                
                                HStack(spacing: 6) {
                                    Image(systemName: "checklist")
                                        .font(.system(size: 11))
                                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                                    
                                    Text("\(completed) of \(total) subtasks completed")
                                        .font(.system(size: 12))
                                        .fontDesign(.serif)
                                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                                }
                            }
                            
                            // Repeat pattern
                            if task.repeatType != "none" {
                                HStack(spacing: 6) {
                                    Image(systemName: "repeat")
                                        .font(.system(size: 11))
                                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                                    
                                    Text(task.repeatDescription)
                                        .font(.system(size: 12))
                                        .fontDesign(.serif)
                                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .reverieCardStyle(colorScheme: colorScheme)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                
                // Action buttons with smart hierarchy
                VStack(spacing: 10) {
                    if shouldPrioritizeCarryOver {
                        // Primary: Continue Tomorrow
                        continueButton(isPrimary: true)
                        // Secondary: Complete & Archive
                        completeButton(isPrimary: false)
                    } else {
                        // Primary: Complete & Archive
                        completeButton(isPrimary: true)
                        // Secondary: Continue Tomorrow
                        continueButton(isPrimary: false)
                    }
                    
                    // Cancel button
                    Button {
                        onCancel()
                    } label: {
                        Text("Cancel")
                            .font(.system(size: 14, weight: .medium))
                            .fontDesign(.serif)
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .presentationDetents([.height(480)])
        .presentationDragIndicator(.visible)
        .presentationBackground(.clear)
    }
    
    
    // MARK: - Button Components
    
    @ViewBuilder
    private func completeButton(isPrimary: Bool) -> some View {
        Button {
            onComplete(false)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "archivebox")
                    .font(.system(size: 14))
                
                Text("Complete & Archive")
                    .font(.system(size: 14, weight: .semibold))
                    .fontDesign(.serif)
            }
            .foregroundStyle(isPrimary ? .white : Color.sageGreen)
            .frame(maxWidth: .infinity)
            .padding(.vertical, isPrimary ? 14 : 12)
            .background(
                Group {
                    if isPrimary {
                        Color.sageGreen
                    } else {
                        Color.sageGreen.opacity(0.15)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        isPrimary ? Color.clear : Color.sageGreen.opacity(0.3),
                        lineWidth: 1
                    )
            )
        }
    }
    
    @ViewBuilder
    private func continueButton(isPrimary: Bool) -> some View {
        Button {
            onComplete(true)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 14))
                
                Text("Continue Tomorrow (\(tomorrowDate))")
                    .font(.system(size: 14, weight: .semibold))
                    .fontDesign(.serif)
            }
            .foregroundStyle(isPrimary ? .white : Color.dustyBlue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, isPrimary ? 14 : 12)
            .background(
                Group {
                    if isPrimary {
                        Color.dustyBlue
                    } else {
                        Color.dustyBlue.opacity(0.15)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        isPrimary ? Color.clear : Color.dustyBlue.opacity(0.3),
                        lineWidth: 1
                    )
            )
        }
    }
}

// MARK: - Completed Task Row Component

struct CompletedTaskRow: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let task: PriorityTask
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
             
                ZStack {
                    Circle()
                        .fill(Color(hex: task.colorHex))
                        .frame(width: 20, height: 20)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
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
                        Text("Completed \(formatRelativeTime(from: completedAt))")
                            .font(.system(size: 11, weight: .regular))
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
    
    private func formatRelativeTime(from date: Date) -> String {
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
}

// MARK: - Device Rotation Detection

extension View {
    func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
        self.modifier(DeviceRotationViewModifier(action: action))
    }
}

struct DeviceRotationViewModifier: ViewModifier {
    let action: (UIDeviceOrientation) -> Void
    
    @State private var orientationObserver: NSObjectProtocol?

    func body(content: Content) -> some View {
        content
            .onAppear {
                UIDevice.current.beginGeneratingDeviceOrientationNotifications()
                
                orientationObserver = NotificationCenter.default.addObserver(
                    forName: UIDevice.orientationDidChangeNotification,
                    object: nil,
                    queue: .main
                ) { _ in
                    let orientation = UIDevice.current.orientation
                    guard orientation.isValidInterfaceOrientation else { return }
                    action(orientation)
                }
            }
            .onDisappear {
                if let observer = orientationObserver {
                    NotificationCenter.default.removeObserver(observer)
                    orientationObserver = nil
                }
                UIDevice.current.endGeneratingDeviceOrientationNotifications()
            }
    }
}

private extension UIDeviceOrientation {
    var isValidInterfaceOrientation: Bool {
        switch self {
        case .portrait, .portraitUpsideDown, .landscapeLeft, .landscapeRight:
            return true
        default:
            return false
        }
    }
}

#Preview {
    LoomView()
        .modelContainer(for: [Habit.self, HabitCompletion.self, UserProfile.self, PriorityTask.self, SubTask.self, PomodoroSession.self, MicroHabitCompletion.self])
}
