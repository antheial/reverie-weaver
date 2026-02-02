//
// HabitFormSheet.swift
// ReverieWeaver
//
//

import SwiftUI
import SwiftData
import UserNotifications

struct HabitFormSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Habit.order) private var habits: [Habit]
    @StateObject private var localization = LocalizationManager.shared
    
    let habitToEdit: Habit?
    
    @State private var name = ""
    @State private var description = ""
    @State private var completionMessage = ""
    @State private var category = "Morning Rituals"
    @State private var icon = "sunrise.fill"
    @State private var colorHex = "C9D2B5"
    @State private var frequency = "Daily"
    
    // Schedule mode and selected days
    @State private var scheduleMode: ScheduleMode = .daily
    @State private var selectedDays: Set<Int> = [1, 2, 3, 4, 5, 6, 7]
    
    // Reminder State
    @State private var hasReminder = false
    @State private var reminderTime = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()
    @State private var showPermissionAlert = false
    @State private var permissionDenied = false
    
    #if DEBUG
    @State private var showTestingTip = false
    #endif
    
    // Store program tracking as immutable
    @State private var programTag: String?
    @State private var programLevel: Int?
    
    // Schedule mode enum
    enum ScheduleMode {
        case daily
        case custom
    }
    
    // Computed property to determine mode
    private var isEditMode: Bool {
        habitToEdit != nil
    }
    
    // Validation for save button
    private var canSave: Bool {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        if scheduleMode == .custom && selectedDays.isEmpty {
            return false
        }
        return true
    }
    
    private var isProtectedHabit: Bool {
        habitToEdit?.isProgramHabit ?? false
    }
    
    private var categories: [(String, String, String)] {
        [
            ("Morning Rituals", "sunrise.fill", "category.MorningRituals"),
            ("Health Foundations", "heart.fill", "category.HealthFoundations"),
            ("Mindful Living", "leaf.fill", "category.MindfulLiving"),
            ("Creative Practice", "paintbrush.fill", "category.CreativePractice"),
            ("Connection", "person.2.fill", "category.Connection")
        ]
    }
    
    private let icons = [
        ("sunrise.fill", "Sunrise"),
        ("figure.mind.and.body", "Meditation"),
        ("drop.fill", "Water"),
        ("figure.walk", "Walking"),
        ("dumbbell", "Exercise"),
        ("book.fill", "Book"),
        ("carrot.fill", "Food"),
        ("moon.stars", "Night"),
        ("bed.double.fill", "Bed"),
        ("lightbulb.fill", "Idea"),
        ("leaf.fill", "Nature"),
        ("heart.fill", "Health"),
        ("sparkles", "Magic"),
        ("paintbrush.fill", "Creative")
    ]
    
    private let colors = [
        ("Sage Green", "C9D2B5"),
        ("Dusty Blue", "B8C7D6"),
        ("Terracotta Rose", "D9A58A"),
        ("Pale Mauve", "E6D7D2")
    ]
    
    private let dayOptions: [(short: String, long: String, value: Int)] = [
        ("Sun", "Sunday", 1),
        ("Mon", "Monday", 2),
        ("Tue", "Tuesday", 3),
        ("Wed", "Wednesday", 4),
        ("Thu", "Thursday", 5),
        ("Fri", "Friday", 6),
        ("Sat", "Saturday", 7)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header prompt - changes based on mode
                    Text(isEditMode ? localization.localize("habit.editPrompt") : localization.localize("habit.createPrompt"))
                        .font(.system(size: 13, weight: .regular))
                        .fontDesign(.serif)
                        .italic()
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Program Habit Badge (shows when editing program habits)
                    if isEditMode, let tag = programTag {
                        programHabitBadge(tag: tag, level: programLevel)
                    }
                    
                    // Habit Name
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "pencil")
                                .font(.system(size: 13))
                                .foregroundStyle(Color(hex: colorHex))
                            Text(localization.localize("habit.name"))
                                .font(.system(size: 13, weight: .regular))
                                .fontDesign(.serif)
                                 .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                        }
                        
                        TextField(localization.localize("habit.namePlaceholder"), text: $name)
                            .multilingualTextField()
                            .textFieldStyle(.plain)
                            .font(.system(size: 12, weight: .regular))
                            .fontDesign(.serif)
                             .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                            .padding(16)
                            .reverieCardStyle(colorScheme: colorScheme)
                    }
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "text.alignleft")
                                .font(.system(size: 13))
                                 .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                            Text(localization.localize("habit.description"))
                                .font(.system(size: 12, weight: .regular))
                                .fontDesign(.serif)
                                 .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                        }
                        
                        TextField(localization.localize("habit.descPlaceholder"), text: $description, axis: .vertical)
                            .multilingualTextField()
                            .textFieldStyle(.plain)
                            .font(.system(size: 12, weight: .regular))
                            .fontDesign(.serif)
                             .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                            .padding(16)
                            .reverieCardStyle(colorScheme: colorScheme)
                            .lineLimit(3...5)
                    }
                    
                    // Completion Message
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 13))
                                 .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                            Text(localization.localize("habit.completionMessage"))
                                .font(.system(size: 13, weight: .regular))
                                .fontDesign(.serif)
                                 .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                        }
                        
                        TextField(localization.localize("habit.messagePlaceholder"), text: $completionMessage, axis: .vertical)
                            .multilingualTextField()
                            .textFieldStyle(.plain)
                            .font(.system(size: 12, weight: .regular))
                            .fontDesign(.serif)
                             .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                            .padding(16)
                            .reverieCardStyle(colorScheme: colorScheme)
                            .lineLimit(2...4)
                    }
                    
                    // Category Selector
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: "folder")
                                .font(.system(size: 13))
                                .foregroundStyle(Color(hex: colorHex))
                            Text(localization.localize("habit.category"))
                                .font(.system(size: 13, weight: .regular))
                                .fontDesign(.serif)
                                 .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                        }
                        
                        VStack(spacing: 8) {
                            ForEach(categories, id: \.0) { cat in
                                Button {
                                    category = cat.0
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: cat.1)
                                            .font(.system(size: 16))
                                            .foregroundStyle(Color(hex: colorHex))
                                        
                                        Text(localization.localize(cat.2))
                                            .font(.system(size: 13, weight: .medium))
                                            .fontDesign(.serif)
                                             .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                                        
                                        Spacer()
                                        
                                        if category == cat.0 {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 16))
                                                .foregroundStyle(Color(hex: colorHex))
                                        }
                                    }
                                    .padding(14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(category == cat.0 ? Color(hex: colorHex).opacity(0.1) : Color.white.opacity(0.2))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(
                                                category == cat.0 ? Color(hex: colorHex) : Color.clear,
                                                lineWidth: 1.5
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // Icon Selector
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: "face.smiling")
                                .font(.system(size: 13))
                                .foregroundStyle(Color(hex: colorHex))
                            Text(localization.localize("habit.icon"))
                                .font(.system(size: 13, weight: .regular))
                                .fontDesign(.serif)
                                 .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                        }
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                            ForEach(icons, id: \.0) { iconPair in
                                Button {
                                    icon = iconPair.0
                                } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: iconPair.0)
                                            .font(.system(size: 24))
                                            .foregroundStyle(Color(hex: colorHex))
                                        
                                        Text(iconPair.1)
                                            .font(.system(size: 11, weight: .regular))
                                             .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(icon == iconPair.0 ? Color(hex: colorHex).opacity(0.1) : Color.white.opacity(0.2))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(
                                                icon == iconPair.0 ? Color(hex: colorHex) : Color.clear,
                                                lineWidth: 1.5
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // Color Selector
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: "paintbrush.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(Color(hex: colorHex))
                            Text(localization.localize("habit.threadColor"))
                                .font(.system(size: 13, weight: .regular))
                                .fontDesign(.serif)
                                 .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                        }
                        
                        HStack(spacing: 12) {
                            ForEach(colors, id: \.1) { color in
                                Button {
                                    colorHex = color.1
                                } label: {
                                    VStack(spacing: 6) {
                                        Circle()
                                            .fill(Color(hex: color.1))
                                            .frame(width: 36, height: 36)
                                            .overlay(
                                                Circle()
                                                    .strokeBorder(
                                                        colorHex == color.1 ? Color.dynamicLabel : Color.clear,
                                                        lineWidth: 2
                                                    )
                                            )
                                            .shadow(color: Color.shadowColor, radius: 2, y: 1)
                                        
                                        if colorHex == color.1 {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 13))
                                                .foregroundStyle(Color(hex: color.1))
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    // Frequency Selector
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.system(size: 13))
                                 .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                            Text(localization.localize("habit.frequency"))
                                .font(.system(size: 13, weight: .regular))
                                .fontDesign(.serif)
                                 .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                        }
                        
                        // Schedule Mode Toggle
                        HStack(spacing: 6) {
                            Button {
                                withAnimation {
                                    scheduleMode = .daily
                                    selectedDays = [1, 2, 3, 4, 5, 6, 7]
                                }
                            } label: {
                                if scheduleMode == .daily {
                                    HStack(spacing: 6) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 12))
                                        Text(localization.localize("habit.daily"))
                                            .font(.system(size: 12, weight: .medium))
                                            .fontDesign(.serif)
                                    }
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 9)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color(hex: colorHex))
                                    )
                                } else {
                                    HStack(spacing: 6) {
                                        Image(systemName: "circle")
                                            .font(.system(size: 12))
                                        Text(localization.localize("habit.daily"))
                                            .font(.system(size: 12, weight: .medium))
                                            .fontDesign(.serif)
                                    }
                                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 9)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.white.opacity(0.2))
                                    )
                                }
                            }
                            .buttonStyle(.plain)

                            Button {
                                withAnimation {
                                    scheduleMode = .custom
                                }
                            } label: {
                                if scheduleMode == .custom {
                                    HStack(spacing: 6) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 12))
                                        Text(localization.localize("habit.custom"))
                                            .font(.system(size: 12, weight: .medium))
                                            .fontDesign(.serif)
                                    }
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 9)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color(hex: colorHex))
                                    )
                                } else {
                                    HStack(spacing: 6) {
                                        Image(systemName: "circle")
                                            .font(.system(size: 12))
                                        Text(localization.localize("habit.custom"))
                                            .font(.system(size: 12, weight: .medium))
                                            .fontDesign(.serif)
                                    }
                                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 9)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.white.opacity(0.2))
                                    )
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        
                        // Custom Day Selector
                        if scheduleMode == .custom {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(localization.localize("habit.selectDays"))
                                    .font(.system(size: 12, weight: .medium))
                                    .fontDesign(.serif)
                                     .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 5), spacing: 6) {
                                    ForEach(dayOptions, id: \.value) { day in
                                        Button {
                                            withAnimation(.spring(response: 0.3)) {
                                                if selectedDays.contains(day.value) {
                                                    selectedDays.remove(day.value)
                                                } else {
                                                    selectedDays.insert(day.value)
                                                }
                                            }
                                        } label: {
                                            if selectedDays.contains(day.value) {
                                                VStack(spacing: 4) {
                                                    Text(day.short)
                                                        .font(.system(size: 12, weight: .semibold))
                                                        .fontDesign(.serif)
                                                        .foregroundStyle(.white)

                                                    Image(systemName: "checkmark.circle.fill")
                                                        .font(.system(size: 11))
                                                        .foregroundStyle(Color.white.opacity(0.8))
                                                }
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 10)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 16)
                                                        .fill(Color(hex: colorHex))
                                                )
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 16)
                                                        .strokeBorder(
                                                            Color(hex: colorHex).opacity(0.5),
                                                            lineWidth: 1
                                                        )
                                                )
                                            } else {
                                                VStack(spacing: 4) {
                                                    Text(day.short)
                                                        .font(.system(size: 12, weight: .semibold))
                                                        .fontDesign(.serif)
                                                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                                                }
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 10)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 16)
                                                        .fill(Color.white.opacity(0.2))
                                                )
                                            }
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                
                                // Selected days count
                                if !selectedDays.isEmpty {
                                    Text("\(selectedDays.count) \(localization.localize(selectedDays.count == 1 ? "habit.dayPerWeek" : "habit.daysPerWeek"))")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(Color(hex: colorHex))
                                } else {
                                    Text(localization.localize("habit.selectAtLeastOneDay"))
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(Color.terracottaRose)
                                }
                            }
                            .padding(.top, 8)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }

                    reminderSection
                }
                .padding(24)
                .dismissKeyboardOnBackgroundTap()
            }
            .background(ReverieWeaverBackground())
            .navigationTitle(isEditMode ? localization.localize("habit.edit") : localization.localize("habit.create"))
            .navigationBarTitleDisplayMode(.inline)
            .keyboardDismissToolbar()
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(isEditMode ? localization.localize("habit.edit") : localization.localize("habit.create"))
                        .font(.system(size: 13, weight: .semibold))
                        .fontDesign(.serif)
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button(localization.localize("habit.cancel")) {
                        dismiss()
                    }
                    .font(.system(size: 13, weight: .regular))
                    .fontDesign(.serif)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditMode ? localization.localize("habit.save") : localization.localize("habit.create.button")) {
                        saveHabit()
                    }
                    .font(.system(size: 13, weight: .medium))
                    .fontDesign(.serif)
                    .foregroundStyle(canSave ? Color.sageGreen : Color.dynamicSecondaryLabel.opacity(0.5))
                    .disabled(!canSave)
                }
            }
        }
        .presentationDetents([.fraction(0.85)])
        .presentationDragIndicator(.visible)
        .onAppear {
            loadHabitData()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            if permissionDenied {
                recheckNotificationPermission()
            }
        }
    }
    
    // MARK: - Reminder Section View
    
    @ViewBuilder
    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 13))
                     .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                Text(localization.localize("habit.reminders"))
                    .font(.system(size: 13, weight: .regular))
                    .fontDesign(.serif)
                     .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
            }
            
            Button {
                handleReminderToggle()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: hasReminder ? "bell.badge.fill" : "bell.slash")
                        .font(.system(size: 14))
                        .foregroundStyle(hasReminder ? Color(hex: colorHex) : Color.dynamicSecondaryLabel)
                        .contentTransition(.symbolEffect(.replace))
                    
                    Text(hasReminder ? localization.localize("habit.reminderOn") : localization.localize("habit.reminderOff"))
                        .font(.system(size: 13, weight: .semibold))
                        .fontDesign(.serif)
                         .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    
                    Spacer()
                    
                    ZStack {
                        Capsule()
                            .fill(hasReminder ? Color(hex: colorHex) : Color.dynamicSecondaryLabel.opacity(0.3))
                            .frame(width: 44, height: 26)
                        
                        Circle()
                            .fill(Color.white)
                            .frame(width: 22, height: 22)
                            .shadow(color: .black.opacity(0.2), radius: 1, y: 1)
                            .offset(x: hasReminder ? 9 : -9)
                    }
                    .animation(.spring(response: 0.3), value: hasReminder)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(hasReminder ? Color(hex: colorHex).opacity(0.1) : Color.white.opacity(0.2))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(hasReminder ? Color(hex: colorHex).opacity(0.3) : Color.clear, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            
            // Time Picker (Slides in when active)
            if hasReminder {
                HStack {
                    Text(localization.localize("habit.atTime"))
                        .font(.system(size: 13, weight: .medium))
                        .fontDesign(.serif)
                         .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    
                    Spacer()

                    DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .tint(Color(hex: colorHex))
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.2))
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // Permission denied warning with action
            if showPermissionAlert {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.terracottaRose)
                    
                    Text(localization.localize("habit.enableNotificationsInSettings"))
                        .font(.system(size: 11))
                        .foregroundStyle(Color.terracottaRose)
                    
                    Spacer()
                    
                    Button {
                        openAppSettings()
                    } label: {
                        Text(localization.localize("habit.openSettings"))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color(hex: colorHex))
                    }
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.terracottaRose.opacity(0.1))
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.spring(response: 0.35), value: hasReminder)
        .animation(.easeInOut(duration: 0.25), value: showPermissionAlert)
    }
    
    // MARK: - Reminder Logic
    
    private func handleReminderToggle() {
        if hasReminder {
            // Turning OFF - simple
            withAnimation {
                hasReminder = false
                showPermissionAlert = false
            }
        } else {
            // Turning ON - check permissions first
            checkNotificationPermissions()
        }
    }
    
    private func checkNotificationPermissions() {
        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            
            await MainActor.run {
                switch settings.authorizationStatus {
                case .authorized, .provisional, .ephemeral:
                    withAnimation {
                        self.hasReminder = true
                        self.showPermissionAlert = false
                        self.permissionDenied = false
                    }
                case .denied:
                    withAnimation {
                        self.hasReminder = false
                        self.showPermissionAlert = true
                        self.permissionDenied = true
                    }
                case .notDetermined:
                    break
                @unknown default:
                    break
                }
            }
        }
    }
    
    private func requestNotificationAccess() {
        Task {
            do {
                let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
                
                await MainActor.run {
                    withAnimation {
                        if granted {
                            self.hasReminder = true
                            self.showPermissionAlert = false
                            self.permissionDenied = false
                            
                            #if DEBUG
                            print("✅ Notification permission granted (from HabitFormSheet)")
                            #endif
                        } else {
                            self.hasReminder = false
                            self.showPermissionAlert = true
                            self.permissionDenied = true
                            
                            #if DEBUG
                            print("❌ Notification permission denied (from HabitFormSheet)")
                            #endif
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    withAnimation {
                        self.hasReminder = false
                        self.showPermissionAlert = true
                        self.permissionDenied = true
                    }
                }
                
                #if DEBUG
                print("⚠️ Notification permission error: \(error.localizedDescription)")
                #endif
            }
        }
    }
    
    private func recheckNotificationPermission() {
        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            
            await MainActor.run {
                if settings.authorizationStatus == .authorized {
                    withAnimation {
                        self.showPermissionAlert = false
                        self.permissionDenied = false
                    }
                }
            }
        }
    }
    
    private func openAppSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
    
    // MARK: - Notification Scheduling
    
    private func scheduleNotification(for habit: Habit) {
        habit.scheduleNotifications()
    }
    
    private func cancelNotifications(for habit: Habit) {
        habit.cancelNotifications()
    }
    
    // MARK: - Protected Habit View
    @ViewBuilder
    var protectedHabitView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 80, height: 80)
                Image(systemName: "lock.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.red.opacity(0.7))
            }
            
            VStack(spacing: 12) {
                Text(localization.localize("habit.cannotEditProgram"))
                    .font(.system(size: 20, weight: .semibold))
                    .fontDesign(.serif)
                
                Text(localization.localize("habit.programHabitInfo"))
                    .font(.system(size: 14))
                     .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Text(localization.localize("habit.close"))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.sageGreen)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
    
    @ViewBuilder
    private func programHabitBadge(tag: String, level: Int?) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: programIcon(for: tag))
                    .font(.system(size: 13))
                    .foregroundStyle(programColor(for: tag))
                
                Text(programDisplayName(for: tag, level: level))
                    .font(.system(size: 13, weight: .medium))
                    .fontDesign(.serif)
                     .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                
                Spacer()
                
                Image(systemName: "lock.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.dynamicSecondaryLabel.opacity(0.5))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(programColor(for: tag).opacity(0.1))
                    .shadow(color: Color.shadowColor.opacity(0.1), radius: 3, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(programColor(for: tag).opacity(0.3), lineWidth: 1)
            )
            
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.dustyBlue)
                
                Text(localization.localize("habit.programEditInfo"))
                    .font(.system(size: 11, weight: .regular))
                    .fontDesign(.serif)
                     .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.dustyBlue.opacity(0.08))
            )
        }
    }
    
    
    // MARK: - Helper Functions
    
    private func loadHabitData() {
        guard let habit = habitToEdit else { return }
        
        name = habit.name
        description = habit.habitDescription
        completionMessage = habit.completionMessage
        category = habit.category
        icon = habit.icon
        colorHex = habit.colorHex
        frequency = habit.frequency.capitalized
        
        programTag = habit.programTag
        programLevel = habit.programLevel
        
        // Load scheduled days
        if let days = habit.scheduledDays, !days.isEmpty {
            scheduleMode = .custom
            selectedDays = Set(days)
        } else {
            scheduleMode = .daily
            selectedDays = [1, 2, 3, 4, 5, 6, 7]
        }
        
        // Load reminder data
        hasReminder = habit.hasReminder
        if let time = habit.reminderTime {
            reminderTime = time
        }
    }
    
    private func saveHabit() {
            let categoryData = categories.first { $0.0 == category }
            let categoryIcon = categoryData?.1 ?? "sunrise.fill"
            
            if let habit = habitToEdit {
                // Edit mode - update existing habit
                habit.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
                habit.habitDescription = description
                habit.completionMessage = completionMessage
                habit.category = category
                habit.categoryIcon = categoryIcon
                habit.icon = icon
                habit.colorHex = colorHex
                habit.frequency = frequency.lowercased()
                
                // ✨ Save scheduled days
                habit.scheduledDays = scheduleMode == .custom ? Array(selectedDays).sorted() : nil
                
                // Save reminder data
                habit.hasReminder = hasReminder
                habit.reminderTime = hasReminder ? reminderTime : nil
                
                do {
                    try modelContext.save()
                } catch {
                    #if DEBUG
                    print("⚠️ Failed to save habit: \(error.localizedDescription)")
                    #endif
                }

                scheduleNotification(for: habit)
                
                #if DEBUG
                if habit.programTag != programTag {
                    print("⚠️ WARNING: programTag mismatch detected!")
                }
                if habit.programLevel != programLevel {
                    print("⚠️ WARNING: programLevel mismatch detected!")
                }
                
                print("✅ Habit edited: \(habit.name)")
                print("   hasReminder: \(habit.hasReminder)")
                if habit.hasReminder, let time = habit.reminderTime {
                    let formatter = DateFormatter()
                    formatter.timeStyle = .short
                    print("   reminderTime: \(formatter.string(from: time))")
                }
                if let days = habit.scheduledDays {
                    print("   scheduledDays: \(days)")
                } else {
                    print("   scheduledDays: daily (all days)")
                }
                #endif
            } else {
                // Create mode - insert new habit
                let newHabit = Habit(
                    name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                    description: description,
                    category: category,
                    categoryIcon: categoryIcon,
                    icon: icon,
                    colorHex: colorHex,
                    completionMessage: completionMessage.isEmpty ? "Thread woven - you've honored your commitment." : completionMessage,
                    frequency: frequency.lowercased(),
                    order: habits.count,
                    scheduledDays: scheduleMode == .custom ? Array(selectedDays).sorted() : nil,
                    // Pass reminder data to initializer
                    hasReminder: hasReminder,
                    reminderTime: hasReminder ? reminderTime : nil
                )
                
                modelContext.insert(newHabit)
                
                do {
                    try modelContext.save()
                } catch {
                    #if DEBUG
                    print("⚠️ Failed to save new habit: \(error.localizedDescription)")
                    #endif
                    
                    dismiss()
                    return
                }
                
                // Schedule notifications for new habit (only after successful save)
                scheduleNotification(for: newHabit)
                
                #if DEBUG
                print("✅ Habit created: \(newHabit.name)")
                print("   hasReminder: \(newHabit.hasReminder)")
                if newHabit.hasReminder, let time = newHabit.reminderTime {
                    let formatter = DateFormatter()
                    formatter.timeStyle = .short
                    print("   reminderTime: \(formatter.string(from: time))")
                }
                if let days = newHabit.scheduledDays {
                    print("   scheduledDays: \(days)")
                } else {
                    print("   scheduledDays: daily (all days)")
                }
                #endif
            }
            
            // Haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            
            #if DEBUG
            // Show testing tip if reminder was enabled
            if hasReminder {
                showTestingTip = true
                // Auto-dismiss after showing
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    dismiss()
                }
            } else {
                dismiss()
            }
            #else
            dismiss()
            #endif
        }
    
    private func programIcon(for tag: String) -> String {
        if tag == "P50" {
            return "chart.line.uptrend.xyaxis"
        } else if tag.starts(with: "C7-") {
            return "bolt.fill"
        } else if tag.starts(with: "TW-") {
            return "calendar.badge.clock"
        } else {
            return "star.fill"
        }
    }
    
    private func programColor(for tag: String) -> Color {
        if tag == "P50" {
            return Color.dustyBlue
        } else if tag.starts(with: "C7-") {
            return Color.terracottaRose
        } else if tag.starts(with: "TW-") {
            return Color.paleMauve
        } else {
            return Color.sageGreen
        }
    }
    
    private func programDisplayName(for tag: String, level: Int?) -> String {
        if tag == "P50" {
            if let level = level {
                return "Project 50 - Level \(level)"
            }
            return "Project 50"
        } else if tag.starts(with: "C7-") {
            let challengeName = String(tag.dropFirst(3))
            return "Challenge: \(challengeName)"
        } else if tag.starts(with: "TW-") {
            let weekName = String(tag.dropFirst(3))
            return "Theme Week: \(weekName)"
        } else {
            return "Program Habit"
        }
    }
}

// MARK: - Convenience Initializers
extension HabitFormSheet {
    // For creating new habit
    init() {
        self.habitToEdit = nil
    }
    
    // For editing existing habit
    init(habit: Habit) {
        self.habitToEdit = habit
    }
}

#Preview {
    HabitFormSheet()
        .modelContainer(for: [Habit.self])
}
