//
// FavoritesTimelineView.swift
// Reverie Weaver
//
//

import SwiftUI
import SwiftData

struct FavoritesTimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Queries
    @Query(
        filter: #Predicate<HabitCompletion> { completion in
            completion.reflection != nil && completion.reflection?.isFavorite == true
        },
        sort: \HabitCompletion.completedAt,
        order: .reverse
    )
    private var allFavorites: [HabitCompletion]
    
    @Query private var allHabits: [Habit]
    
    // MARK: - State
    @State private var currentDate = Date()
    @State private var showMonthPicker = false
    @State private var selectedCategory: String? = nil
    @State private var showPhotosOnly = false
    @State private var showDeleteAlert = false
    @State private var itemToDelete: HabitCompletion? = nil
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    // MARK: - Optimization
    private var habitMap: [String: Habit] {
        Dictionary(uniqueKeysWithValues: allHabits.map { ($0.name, $0) })
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                headerSection
                
                categoryFilterSection
                
                dottedDivider
                    .padding(.horizontal, 24)
                
                if filteredFavorites.isEmpty {
                    emptyStateView
                } else {
                    LazyVStack(spacing: 24) {
                        ForEach(sortedWeeks, id: \.self) { week in
                            if let weekFavorites = groupedFilteredFavorites[week] {
                                weekSection(week, entries: weekFavorites)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 100)
                }
            }
            .padding(.top, 20)
        }
        .background(ReverieWeaverBackground().ignoresSafeArea())
        .sheet(isPresented: $showMonthPicker) {
            WeekCalendarSheet(currentDate: $currentDate)
                .presentationDetents([.medium])
                .presentationCornerRadius(24)
        }
        .alert("Remove Favorite", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                if let item = itemToDelete {
                    unfavoriteItem(item)
                }
            }
        } message: {
            Text("This will remove the favorite status from this reflection.")
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 6) {
            Text("Favorite Reflections")
                .font(.system(size: 16, weight: .semibold, design: .serif))
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
            
            Button {
                showMonthPicker = true
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Text(monthYearString)
                    .font(.system(size: 12, weight: .medium, design: .serif))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    .padding(.vertical, 2)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Category Filter
    
    private var categoryFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                categoryChip(category: nil, label: "All")
                
                ForEach(availableCategories, id: \.self) { category in
                    categoryChip(category: category, label: category)
                }
                
                photosOnlyChip
            }
            .padding(.horizontal, 24)
        }
    }
    
    private func categoryChip(category: String?, label: String) -> some View {
        Button {
            withAnimation {
                selectedCategory = (selectedCategory == category) ? nil : category
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .serif))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(selectedCategory == category ?
                              Color.terracottaRose.opacity(0.2) :
                              Color.clear)
                )
                .overlay(
                    Capsule()
                        .strokeBorder(
                            selectedCategory == category ?
                            Color.terracottaRose :
                            Color.inkSecondary.opacity(0.25),
                            lineWidth: 0.5
                        )
                )
                .foregroundStyle(
                    selectedCategory == category ?
                    Color.terracottaRose :
                    Color.inkSecondary
                )
        }
    }
    
    private var photosOnlyChip: some View {
        Button {
            withAnimation { showPhotosOnly.toggle() }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "photo.fill")
                    .font(.system(size: 11))
                Text("With Photos")
                    .font(.system(size: 11, weight: .medium, design: .serif))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(showPhotosOnly ? Color.dustyBlue.opacity(0.2) : Color.clear)
            )
            .overlay(
                Capsule()
                    .strokeBorder(
                        showPhotosOnly ? Color.dustyBlue : Color.inkSecondary.opacity(0.25),
                        lineWidth: 0.5
                    )
            )
            .foregroundStyle(showPhotosOnly ? Color.dustyBlue : Color.inkSecondary)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Text(emptyStateMessage)
                .font(.system(size: 13, weight: .regular, design: .serif))
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                .multilineTextAlignment(.center)
            
            if selectedCategory != nil || showPhotosOnly {
                Button {
                    withAnimation {
                        selectedCategory = nil
                        showPhotosOnly = false
                    }
                } label: {
                    Text("Clear Filters")
                        .font(.system(size: 12, weight: .medium, design: .serif))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .strokeBorder(Color.terracottaRose.opacity(0.5), lineWidth: 0.5)
                        )
                        .foregroundStyle(Color.terracottaRose)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, 40)
        .padding(.top, 80)
    }
    
    private var emptyStateMessage: String {
        if showPhotosOnly && selectedCategory != nil {
            return "No favorites with photos in this category."
        } else if showPhotosOnly {
            return "No favorites with photos this month.\nAdd photos to your reflections to see them here!"
        } else if selectedCategory != nil {
            return "No favorites in this category."
        } else {
            return "No favorite reflections this month."
        }
    }
    
    // MARK: - Week Section
    
    private func weekSection(_ week: Int, entries: [HabitCompletion]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.terracottaRose)
                
                // Using first entry to accurately determine week start/end label
                if let firstEntry = entries.first {
                    Text(weekTitle(for: firstEntry.completedAt))
                        .font(.system(size: 13, weight: .medium, design: .serif))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                }
                
                Spacer()
                
                if weekPhotoCount(entries) > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "photo.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.dustyBlue)
                        Text("\(weekPhotoCount(entries))")
                            .font(.system(size: 11, weight: .bold, design: .serif))
                            .foregroundStyle(Color.dustyBlue)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.dustyBlue.opacity(0.1)))
                }
                
                Text("\(entries.count)")
                    .font(.system(size: 11, weight: .bold, design: .serif))
                    .foregroundStyle(Color.terracottaRose)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.terracottaRose.opacity(0.1)))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(entries.sorted(by: { $0.completedAt > $1.completedAt }), id: \.id) { entry in
                    if let reflection = entry.reflection {
                        favoriteEntryCard(entry: entry, reflection: reflection)
                    }
                }
            }
            
            dottedDivider
                .padding(.top, 6)
        }
    }
    
    private func weekPhotoCount(_ entries: [HabitCompletion]) -> Int {
        entries.reduce(0) { count, entry in
            count + (entry.reflection?.photosData.count ?? 0)
        }
    }
    
    // MARK: - Entry Card
    
    private func favoriteEntryCard(entry: HabitCompletion, reflection: Reflection) -> some View {
        Button {
            openLoom(for: entry)
        } label: {
            HStack(spacing: 10) {
                // 1. Photo Thumbnail
                if !reflection.photosData.isEmpty,
                   let firstPhotoData = reflection.photosData.first,
                   let uiImage = UIImage(data: firstPhotoData) {
                    ZStack(alignment: .bottomTrailing) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        if reflection.photosData.count > 1 {
                            Text("\(reflection.photosData.count)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.black.opacity(0.7)))
                                .padding(3)
                        }
                    }
                }
                
                // 2. Content
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(reflection.habitName)
                            .font(.system(size: 12, weight: .medium, design: .serif))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                        
                        if !reflection.photosData.isEmpty && reflection.photosData.count == 1 {
                             Image(systemName: "photo.fill")
                                 .font(.system(size: 11))
                                 .foregroundStyle(Color.dustyBlue.opacity(0.6))
                        }
                    }
                    
                    if !reflection.notes.isEmpty {
                        Text("\"\(reflection.notes)\"")
                            .font(.system(size: 11, design: .serif))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                            .lineLimit(2)
                    }
                    
                    HStack(spacing: 6) {
                        Text(shortDate(entry.completedAt))
                            .font(.system(size: 11, weight: .medium))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        
                        Text("· \(reflection.mood)")
                            .font(.system(size: 11, weight: .medium))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 3. Action Button
                Button {
                    itemToDelete = entry
                    showDeleteAlert = true
                } label: {
                    Image(systemName: "heart.slash.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.terracottaRose.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(colorScheme == .dark ? 0.05 : 0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.inkSecondary.opacity(0.25), lineWidth: 0.4)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Actions
    private func unfavoriteItem(_ entry: HabitCompletion) {
        guard let reflection = entry.reflection else { return }
        
        let impact = UIImpactFeedbackGenerator(style: .soft)
        impact.impactOccurred()
        
        do {
            reflection.isFavorite = false
            try modelContext.save()
        } catch {
            errorMessage = "Failed to remove favorite: \(error.localizedDescription)"
            showErrorAlert = true
        }
    }
    
    private func openLoom(for completion: HabitCompletion) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        // TODO: Navigate to LoomDayView(date: completion.completedAt)
    }
    
    // MARK: - Divider
    private var dottedDivider: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(height: 0.5)
            .overlay(
                Color.inkSecondary.opacity(0.25)
                    .frame(height: 0.5)
                    .mask(Rectangle().stroke(style: StrokeStyle(lineWidth: 0.5, dash: [2])))
            )
    }

    // MARK: - Date & Logic
    
    private var monthStart: Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: currentDate))!
    }
    
    private var nextMonthStart: Date {
        Calendar.current.date(byAdding: .month, value: 1, to: monthStart)!
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentDate)
    }
    
    private var favoritesThisMonth: [HabitCompletion] {
        allFavorites.filter {
            $0.completedAt >= monthStart && $0.completedAt < nextMonthStart
        }
    }
    
    private var filteredFavorites: [HabitCompletion] {
        var filtered = favoritesThisMonth
        
        if let category = selectedCategory {
            filtered = filtered.filter { completion in
                guard let name = completion.reflection?.habitName else { return false }
                return habitMap[name]?.category == category
            }
        }
        
        if showPhotosOnly {
            filtered = filtered.filter { completion in
                !(completion.reflection?.photosData.isEmpty ?? true)
            }
        }
        
        return filtered
    }
    
    private var groupedFilteredFavorites: [Int: [HabitCompletion]] {
        Dictionary(grouping: filteredFavorites) { completion in
            Calendar.current.component(.weekOfYear, from: completion.completedAt)
        }
    }
    
    private var sortedWeeks: [Int] {
        groupedFilteredFavorites.keys.sorted(by: >)
    }
    
    private var availableCategories: [String] {
        let categories = Set(favoritesThisMonth.compactMap { completion -> String? in
            guard let name = completion.reflection?.habitName else { return nil }
            return habitMap[name]?.category
        })
        return Array(categories).sorted()
    }
    
    private func weekTitle(for date: Date) -> String {
        let calendar = Calendar.current
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: date) else {
            return "Week of \(shortDate(date))"
        }
        
        let weekStart = weekInterval.start
        let weekEnd = weekInterval.end.addingTimeInterval(-1)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "Week \(calendar.component(.weekOfYear, from: weekStart)) · \(formatter.string(from: weekStart)) – \(formatter.string(from: weekEnd))"
    }
    
    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

#Preview {
    FavoritesTimelineView()
        .preferredColorScheme(.light)
}
