//
//  DeskView 2.swift
//  Reverie Weaver
//
//  Created by Antheia Li on 10/14/25.
//


//
// DeskView.swift
// ReverieWeaver
//
// Main "Desk" home screen with consistent dark mode
//

import SwiftUI
import SwiftData

struct DeskView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.order) private var habits: [Habit]
    @Query private var completions: [HabitCompletion]
    @Query private var intentions: [DailyIntention]
    @Query private var allAchievements: [Achievement]
    
    @State private var showCreateHabit = false
    @State private var showEditHabit: Habit?
    @State private var showReflection: HabitCompletion?
    @State private var intentionText = ""
    @State private var intentionMood = "Peaceful"
    @State private var showPerfectDayCelebration = false
    
    private var todayCompletions: [HabitCompletion] {
        completions.filter { $0.isToday }
    }
    
    private var todayIntention: DailyIntention? {
        intentions.first { Calendar.current.isDateInToday($0.date) }
    }
    
    private var completedCount: Int {
        habits.filter { habit in
            todayCompletions.contains { $0.habitId == habit.id }
        }.count
    }
    
    private var currentStreak: Int {
        var streak = 0
        var date = Calendar.current.startOfDay(for: Date())
        
        while true {
            let dayCompletions = completions.filter {
                Calendar.current.isDate($0.completedAt, inSameDayAs: date)
            }
            if dayCompletions.isEmpty {
                break
            }
            streak += 1
            date = Calendar.current.date(byAdding: .day, value: -1, to: date)!
        }
        
        return streak
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header Section
                    VStack(spacing: 16) {
                        headerSection
                        
                        Text(todayDisplay)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(Color.dynamicSecondaryLabel)
                            .tracking(0.5)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Daily Quote
                        quoteCard
                        
                        // Daily Intention
                        intentionCard
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 32)
                    .background(Color.dynamicBackground)
                    
                    // Main Content
                    VStack(spacing: 26) {
                        // Today's Weave Progress
                        if habits.count > 0 {
                            progressCard
                        }
                        
                        // Daily Habits
                        habitsSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
                
                .dismissKeyboardOnBackgroundTap() // Add this
            }
            .background(Color.dynamicBackground)
            .sheet(isPresented: $showCreateHabit) {
                CreateHabitSheet()
            }
            .sheet(item: $showEditHabit) { habit in
                EditHabitSheet(habit: habit)
            }
            .alert("Perfect Day!", isPresented: $showPerfectDayCelebration) {
                Button("Amazing!") { }
            } message: {
                Text("You completed all your habits today! 🎉")
            }
            .onAppear {
                loadTodayIntention()
            }
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack(alignment: .center, spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: greetingIcon)
                    .foregroundStyle(Color.dynamicSecondaryLabel)
                    .font(.system(size: 23, weight: .thin))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(greeting)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.dynamicSecondaryLabel)
                        .tracking(0.3)
                    Text(dayName)
                        .font(.system(size: 23, weight: .regular))
                        .fontDesign(.serif)
                        .foregroundStyle(Color.dynamicLabel)
                }
            }
            
            Spacer()
            
            // Streak counter
            if currentStreak > 0 {
                VStack(spacing: 4) {
                    Text("\(currentStreak)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Color.sageGreen)
                    Text("DAY STREAK")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(Color.dynamicSecondaryLabel)
                        .tracking(0.8)
                }
                .padding(.horizontal, 13)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.habitCardBackground)
                        .shadow(color: Color.shadowColor, radius: 8, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.habitCardBorder, lineWidth: 1)
                )
            }
        }
    }
    
    // MARK: - Quote Card
    private var quoteCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "sparkles")
                .foregroundStyle(Color.terracottaRose)
                .font(.system(size: 18, weight: .regular))
            Text(dailyQuote)
                .font(.system(size: 12, weight: .regular))
                .italic()
                .foregroundStyle(Color.dynamicLabel)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.habitCardBackground)
                .shadow(color: Color.shadowColor, radius: 8, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(Color.habitCardBorder, lineWidth: 1)
        )
    }
    
    // MARK: - Intention Card
    private var intentionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "heart.fill")
                    .foregroundStyle(Color.paleMauve)
                    .font(.system(size: 13))
                Text("What will you weave today?")
                    .font(.system(size: 13, weight: .regular))
                    .fontDesign(.serif)
                    .foregroundStyle(Color.dynamicLabel)
            }
            
            ZStack(alignment: .topLeading) {
                if intentionText.isEmpty {
                    Text("Set your intention for the day... what matters most to you today?")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color.dynamicSecondaryLabel)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                }
                
                TextEditor(text: $intentionText)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.dynamicLabel)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 80)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
            }
            .background(Color.dynamicSecondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            HStack(spacing: 12) {
                Menu {
                    ForEach(["🕊️ Peaceful", "⚡️ Energized", "🎯 Focused", "🙏 Grateful", "☀️ Hopeful","🔥 Action"], id: \.self) { mood in
                        Button(mood) {
                            intentionMood = mood
                        }
                    }
                } label: {
                    HStack {
                        Text(intentionMood)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(Color.dynamicLabel)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.dynamicSecondaryLabel)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(Color.dynamicSecondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Button("Save") {
                    saveIntention()
                    hideKeyboard() // Also dismiss keyboard when saving
                }
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.sageGreen)
                .foregroundStyle(.white)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.habitCardBackground)
                .shadow(color: Color.shadowColor, radius: 8, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(Color.habitCardBorder, lineWidth: 1)
        )
    }
    
    // MARK: - Progress Card
    private var progressCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Today's Weave")
                    .font(.system(size: 13, weight: .semibold))
                    .fontDesign(.serif)
                    .foregroundStyle(Color.dynamicLabel)
                Spacer()
                Text("\(completedCount) / \(habits.count)")
                    .font(.system(size: 12, weight: .medium))
                    .fontDesign(.serif)
                    .foregroundStyle(Color.dynamicSecondaryLabel)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.dynamicSecondaryBackground)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [.sageGreen, .dustyBlue, .terracottaRose],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress)
                        .animation(.spring(response: 0.7, dampingFraction: 0.8), value: progress)
                }
            }
            .frame(height: 10)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.habitCardBackground)
                .shadow(color: Color.shadowColor, radius: 8, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(Color.habitCardBorder, lineWidth: 1)
        )
    }
    
    // MARK: - Habits Section
    private var habitsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Daily Habits")
                    .font(.system(size: 14, weight: .semibold))
                    .fontDesign(.serif)
                    .foregroundStyle(Color.dynamicLabel)
                Spacer()
                Button {
                    showCreateHabit = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Add")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color.sageGreen)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                    .shadow(color: Color.shadowColor, radius: 4, y: 2)
                }
            }
            
            if habits.isEmpty {
                VStack(spacing: 12) {
                    Text("🌱")
                        .font(.system(size: 40))
                    Text("Begin your journey by creating your first habit")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(Color.dynamicSecondaryLabel)
                        .multilineTextAlignment(.center)
                    Button {
                        showCreateHabit = true
                    } label: {
                        Text("Create First Habit")
                            .font(.system(size: 13, weight: .medium))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.sageGreen)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.habitCardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .strokeBorder(Color.habitCardBorder, style: StrokeStyle(lineWidth: 2, dash: [8]))
                        )
                )
            } else {
                ForEach(habits) { habit in
                    HabitCard(
                        habit: habit,
                        isCompleted: isCompleted(habit),
                        onToggle: {
                            toggleHabit(habit)
                        }
                    )
                    .contextMenu {
                        Button {
                            showEditHabit = habit
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive) {
                            deleteHabit(habit)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helpers
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<21: return "Good Evening"
        default: return "Good Night"
        }
    }
    
    private var greetingIcon: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<6: return "moon"
        case 6..<12: return "sunrise"
        case 12..<17: return "sun.max"
        case 17..<21: return "sunset"
        default: return "moon.stars"
        }
    }
    
    private var dayName: String {
        Date().formatted(.dateTime.weekday(.wide))
    }
    
    private var todayDisplay: String {
        Date().formatted(.dateTime.weekday(.wide).month(.wide).day().year())
    }
    
    private var dailyQuote: String {
        let quotes: [String] = [ // ✅ Add explicit type
            "Embrace each moment; it's in stillness that we truly find ourselves.",
            "Embrace the present moment; it is where your heart truly blossoms.",
            "Every small step weaves the fabric of your journey.",
            "In mindful repetition, transformation takes root.",
            "Each day is a thread --- gentle or bold --- that weaves the story of who you're becoming.",
            "Time doesn't pass; it gathers quietly within you.",
            "Your days are fabric --- woven by choices, colored by intention.",
            "You are both the weaver and the tapestry.",
            "Presence is the art of seeing the quiet beauty already here.",
            "When you slow down, time opens like a page waiting to be written on.",
            "Small rituals, practiced often, bloom into transformation.",
            "You don't have to rush; even the moon takes time to become whole.",
            "Gentle persistence shapes the soul more than grand ambition."
        ]
        
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        return quotes[dayOfYear % quotes.count]
    }
    
    private var progress: CGFloat {
        guard habits.count > 0 else { return 0 }
        return CGFloat(completedCount) / CGFloat(habits.count)
    }
    
    private func isCompleted(_ habit: Habit) -> Bool {
        todayCompletions.contains { $0.habitId == habit.id }
    }
    
    private func toggleHabit(_ habit: Habit) {
        if let existing = todayCompletions.first(where: { $0.habitId == habit.id }) {
            modelContext.delete(existing)
            try? modelContext.save()
        } else {
            // TO:
            let completion = HabitCompletion(habitId: habit.id)
            modelContext.insert(completion)
            try? modelContext.save() // ✅ Save first so completion has an ID
            
            do {
                try modelContext.save()
                print("✅ Completion saved for habit: \(habit.name)")
            } catch {
                print("❌ Error saving completion: \(error)")
            }
            
            let achievementManager = AchievementManager(modelContext: modelContext)
            achievementManager.checkAchievements(habits: habits, completions: completions)
            
            checkPerfectDayAchievement()
        }
    }
    
    private func deleteHabit(_ habit: Habit) {
        modelContext.delete(habit)
    }
    
    private func checkPerfectDayAchievement() {
        let allCompleted = habits.allSatisfy { habit in
            todayCompletions.contains { $0.habitId == habit.id }
        }
        
        guard allCompleted && habits.count > 0 else { return }
        
        let today = Date()
        let calendar = Calendar.current
        let todayComponents = calendar.dateComponents([.year, .month, .day], from: today)
        
        let descriptor = FetchDescriptor<Achievement>(
            predicate: #Predicate<Achievement> { achievement in
                achievement.type == "perfect_day"
            }
        )
        
        if let existingAchievements = try? modelContext.fetch(descriptor) {
            let earnedToday = existingAchievements.contains { achievement in
                let achievementComponents = calendar.dateComponents([.year, .month, .day], from: achievement.earnedDate)
                return todayComponents.year == achievementComponents.year &&
                    todayComponents.month == achievementComponents.month &&
                    todayComponents.day == achievementComponents.day
            }
            
            if !earnedToday {
                let achievement = Achievement(
                    type: "perfect_day",
                    title: "Perfect Day",
                    achievementDescription: "Completed all habits in one day",
                    iconName: "star.fill"
                )
                modelContext.insert(achievement)
                showPerfectDayCelebration = true
            }
        }
    }
    
    private func loadTodayIntention() {
        if let intention = todayIntention {
            intentionText = intention.text
            intentionMood = intention.mood
        }
    }
    
    private func saveIntention() {
        if let existing = todayIntention {
            existing.text = intentionText
            existing.mood = intentionMood
        } else {
            let intention = DailyIntention(text: intentionText, mood: intentionMood)
            modelContext.insert(intention)
        }
    }
}

#Preview {
    DeskView()
        .modelContainer(for: [Habit.self, HabitCompletion.self, DailyIntention.self, Achievement.self])
}

struct EditHabitSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var localization = LocalizationManager.shared
    
    let habit: Habit
    
    @State private var name = ""
    @State private var description = ""
    @State private var completionMessage = ""
    @State private var category = "Wellbeing"
    @State private var icon = "sunrise"
    @State private var colorHex = "C9D2B5"
    @State private var frequency = "Daily"
    
    // Category data with localization keys
    private var categories: [(String, String, String)] {
        [
            ("Wellbeing", "🕊", "category.wellbeing"),
            ("Growth", "🌱", "category.growth"),
            ("Creativity", "✨", "category.creativity"),
            ("Connection", "💛", "category.connection"),
            ("Rest", "🌙", "category.rest")
        ]
    }
    
    private let icons = [
        ("sunrise", "☀️"),
        ("feather", "🪶"),
        ("dumbbell", "🏋️"),
        ("book", "📖"),
        ("lightbulb", "💡"),
        ("apple", "🍎"),
        ("clipboard", "📋")
    ]
    
    private let colors = [
        ("Sage Green", "C9D2B5"),
        ("Dusty Blue", "B8C7D6"),
        ("Terracotta Rose", "D9A58A"),
        ("Pale Mauve", "E6D7D2")
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header prompt
                    Text("Refine the thread in your tapestry")
                        .font(.system(size: 13, weight: .regular))
                        .fontDesign(.serif)
                        .italic()
                        .foregroundStyle(Color.dynamicSecondaryLabel)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Habit Name
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "pencil")
                                .font(.system(size: 12))
                                .foregroundStyle(Color(hex: colorHex))
                            Text(localization.localize("habit.name"))
                                .font(.system(size: 12, weight: .regular))
                                .fontDesign(.serif)
                                .foregroundStyle(Color.dynamicLabel)
                        }
                        
                        TextField(localization.localize("habit.namePlaceholder"), text: $name)
                            .multilingualTextField()
                            .textFieldStyle(.plain)
                            .font(.system(size: 12, weight: .regular))
                            .fontDesign(.serif)
                            .foregroundStyle(Color.dynamicLabel)
                            .padding(16)
                            .background(Color.dynamicSecondaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "text.alignleft")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.dynamicSecondaryLabel)
                            Text(localization.localize("habit.description"))
                                .font(.system(size: 12, weight: .regular))
                                .fontDesign(.serif)
                                .foregroundStyle(Color.dynamicLabel)
                        }
                        
                        TextField(localization.localize("habit.descPlaceholder"), text: $description, axis: .vertical)
                            .multilingualTextField()
                            .textFieldStyle(.plain)
                            .font(.system(size: 12, weight: .regular))
                            .fontDesign(.serif)
                            .foregroundStyle(Color.dynamicLabel)
                            .padding(16)
                            .background(Color.dynamicSecondaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .lineLimit(3...5)
                    }
                    
                    // Completion Message
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.dynamicSecondaryLabel)
                            Text(localization.localize("habit.completionMessage"))
                                .font(.system(size: 12, weight: .regular))
                                .fontDesign(.serif)
                                .foregroundStyle(Color.dynamicLabel)
                        }
                        
                        TextField(localization.localize("habit.messagePlaceholder"), text: $completionMessage, axis: .vertical)
                            .multilingualTextField()
                            .textFieldStyle(.plain)
                            .font(.system(size: 12, weight: .regular))
                            .fontDesign(.serif)
                            .foregroundStyle(Color.dynamicLabel)
                            .padding(16)
                            .background(Color.dynamicSecondaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .lineLimit(2...4)
                    }
                    
                    // Category Selector
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: "folder")
                                .font(.system(size: 12))
                                .foregroundStyle(Color(hex: colorHex))
                            Text(localization.localize("habit.category"))
                                .font(.system(size: 12, weight: .regular))
                                .fontDesign(.serif)
                                .foregroundStyle(Color.dynamicLabel)
                        }
                        
                        VStack(spacing: 8) {
                            ForEach(categories, id: \.0) { cat in
                                Button {
                                    category = cat.0
                                } label: {
                                    HStack(spacing: 12) {
                                        Text(cat.1)
                                            .font(.system(size: 16))
                                        
                                        Text(localization.localize(cat.2))
                                            .font(.system(size: 12, weight: .medium))
                                            .fontDesign(.serif)
                                            .foregroundStyle(Color.dynamicLabel)
                                        
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
                                            .fill(category == cat.0 ? Color(hex: colorHex).opacity(0.1) : Color.dynamicSecondaryBackground)
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
                                .font(.system(size: 12))
                                .foregroundStyle(Color(hex: colorHex))
                            Text(localization.localize("habit.icon"))
                                .font(.system(size: 12, weight: .regular))
                                .fontDesign(.serif)
                                .foregroundStyle(Color.dynamicLabel)
                        }
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                            ForEach(icons, id: \.0) { iconPair in
                                Button {
                                    icon = iconPair.0
                                } label: {
                                    Text(iconPair.1)
                                        .font(.system(size: 28))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(icon == iconPair.0 ? Color(hex: colorHex).opacity(0.1) : Color.dynamicSecondaryBackground)
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
                                .font(.system(size: 12))
                                .foregroundStyle(Color(hex: colorHex))
                            Text(localization.localize("habit.threadColor"))
                                .font(.system(size: 12, weight: .regular))
                                .fontDesign(.serif)
                                .foregroundStyle(Color.dynamicLabel)
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
                                                .font(.system(size: 12))
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
                                .font(.system(size: 12))
                                .foregroundStyle(Color.dynamicSecondaryLabel)
                            Text(localization.localize("habit.frequency"))
                                .font(.system(size: 12, weight: .regular))
                                .fontDesign(.serif)
                                .foregroundStyle(Color.dynamicLabel)
                        }
                        
                        HStack(spacing: 10) {
                            ForEach([("Daily", "habit.daily"), ("Weekly", "habit.weekly")], id: \.0) { freq in
                                Button {
                                    frequency = freq.0
                                } label: {
                                    Text(localization.localize(freq.1))
                                        .font(.system(size: 12, weight: .medium))
                                        .fontDesign(.serif)
                                        .foregroundStyle(frequency == freq.0 ? Color.white : Color.dynamicLabel)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(frequency == freq.0 ? Color(hex: colorHex) : Color.dynamicSecondaryBackground)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(24)
                .dismissKeyboardOnBackgroundTap()
            }
            .background(Color.dynamicBackground)
            .navigationTitle("Edit Habit")
            .navigationBarTitleDisplayMode(.inline)
            .keyboardDismissToolbar()
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Edit Habit")
                        .font(.system(size: 13, weight: .semibold))
                        .fontDesign(.serif)
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button(localization.localize("habit.cancel")) {
                        dismiss()
                    }
                    .font(.system(size: 12, weight: .regular))
                    .fontDesign(.serif)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .font(.system(size: 12, weight: .medium))
                    .fontDesign(.serif)
                    .disabled(name.isEmpty)
                }
            }
        }
        .presentationDetents([.fraction(0.8)])
        .presentationDragIndicator(.visible)
        .onAppear {
            name = habit.name
            description = habit.habitDescription
            completionMessage = habit.completionMessage
            category = habit.category
            icon = getIconName(from: habit.icon)
            colorHex = habit.colorHex
            frequency = habit.frequency.capitalized
        }
    }
    
    // MARK: - Helper Functions
    
    private func saveChanges() {
        habit.name = name
        habit.habitDescription = description
        habit.completionMessage = completionMessage
        habit.category = category
        habit.categoryIcon = categories.first { $0.0 == category }?.1 ?? "🕊"
        habit.icon = icons.first { $0.0 == icon }?.1 ?? "⭐"
        habit.colorHex = colorHex
        habit.frequency = frequency.lowercased()
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        dismiss()
    }
    
    private func getIconName(from emoji: String) -> String {
        switch emoji {
        case "☀️": return "sunrise"
        case "🪶": return "feather"
        case "🏋️": return "dumbbell"
        case "📖": return "book"
        case "💡": return "lightbulb"
        case "🍎": return "apple"
        case "📋": return "clipboard"
        default: return "sunrise"
        }
    }
}

#Preview {
    EditHabitSheet(habit: Habit(
        name: "Morning Meditation",
        description: "Start the day mindfully",
        category: "Wellbeing",
        categoryIcon: "🕊",
        icon: "☀️",
        colorHex: "C9D2B5",
        completionMessage: "Thread woven",
        frequency: "daily",
        order: 0
    ))
}
