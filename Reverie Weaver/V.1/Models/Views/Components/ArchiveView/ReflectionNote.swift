//
//  ReflectionNote.swift
//  Reverie Weaver
//
//  THE REVERIE JOURNAL – Newspaper-Style Edition
//
//

import SwiftUI
import SwiftData

// MARK: - Data Model
@Model
final class ReflectionNote {
    var id: UUID
    var type: String
    var label: String
    var title: String
    var startDate: Date
    var endDate: Date?
    var content: String
    var author: String?
    var lastEdited: Date
    
    // MARK: - Theme Week Metadata (for type="daily" entries only)
    var themeWeekTag: String?      // e.g., "ConnectionClarityW1"
    var themeWeekDay: Int?         // e.g., 3 (for Day 3)
    var themeWeekTier: String?     // e.g., "sprout"
    var themeWeekSessionID: String?  // NEW: Unique ID for each week run (e.g., "ConnectionClarityW1_2024-12-20")

    // MARK: - Mini Challenge Metadata (for challenge reflections)
    var challengeTag: String?      // e.g., "FeiStrengthW1" - links reflection to specific challenge

    init(type: String,
         label: String,
         title: String = "",
         startDate: Date,
         endDate: Date? = nil,
         content: String = "",
         author: String? = nil,
         themeWeekTag: String? = nil,
         themeWeekDay: Int? = nil,
         themeWeekTier: String? = nil,
         themeWeekSessionID: String? = nil,
         challengeTag: String? = nil) {
        self.id = UUID()
        self.type = type
        self.label = label
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.content = content
        self.author = author
        self.lastEdited = Date()
        self.themeWeekTag = themeWeekTag
        self.themeWeekDay = themeWeekDay
        self.themeWeekTier = themeWeekTier
        self.themeWeekSessionID = themeWeekSessionID
        self.challengeTag = challengeTag
    }
    
    // MARK: - Computed Properties

    /// Returns true if this is a Theme Week daily entry
    var isThemeWeekEntry: Bool {
        type == "daily" && themeWeekTag != nil && themeWeekDay != nil
    }

    /// Returns true if this is a Mini Challenge reflection
    var isChallengeReflection: Bool {
        type == "challenge" && challengeTag != nil
    }
}

// MARK: - Main View
struct ReflectionNoteView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \ReflectionNote.startDate, order: .reverse)
    private var reflections: [ReflectionNote]

    // MARK: - State
    @State private var showAddSheet = false
    @State private var isEditingID: UUID? = nil
    @State private var editedText = ""
    @State private var editedTitle = ""
    @State private var editedAuthor = ""

    @State private var currentMonth: Date =
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date())) ?? Date()
    @State private var scrollToID: UUID? = nil

    // Entry state
    @State private var newType: String? = nil
    @State private var newTitle: String = ""
    @State private var newContent: String = ""
    @State private var newLabel: String = ""
    @State private var newDateRange: String = ""
    @State private var newAuthor: String = ""

    // Duplicate detection state
    @State private var showDuplicateAlert = false
    @State private var pendingDuplicateNote: ReflectionNote? = nil
    @State private var pendingReflectionType: String? = nil
    
    // Error handling
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    // Search state
    @State private var searchText = ""
    @State private var showSearchSheet = false
    @State private var showThemeWeekEntries = false  // NEW: Toggle for Theme Week entries
    
    // Delete confirmation
    @State private var showDeleteAlert = false
    @State private var noteToDelete: ReflectionNote? = nil
    
    // Pull to refresh
    @State private var isRefreshing = false
    
    // Auto-save draft
    @State private var draftTimer: Timer? = nil

    @Namespace private var scrollSpace

    // MARK: - Computed Data
    private var filteredNotes: [ReflectionNote] {
        let monthFiltered = reflections.filter {
            // ✅ EXCLUDE daily Theme Week entries from main journal view
            // ✅ INCLUDE challenge reflections (type == "challenge")
            $0.type != "daily" &&
            Calendar.current.compare($0.startDate, to: currentMonth, toGranularity: .month) == .orderedSame
        }

        // Apply search filter if active
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return monthFiltered
        } else {
            let query = searchText.lowercased()
            return monthFiltered.filter {
                $0.title.lowercased().contains(query) ||
                $0.content.lowercased().contains(query) ||
                $0.author?.lowercased().contains(query) == true ||
                $0.label.lowercased().contains(query) ||
                $0.challengeTag?.lowercased().contains(query) == true
            }
        }
    }

    private var weeklyNotes: [ReflectionNote]  { filteredNotes.filter { $0.type == "weekly" } }
    private var monthlyNotes: [ReflectionNote] { filteredNotes.filter { $0.type == "monthly" } }
    private var challengeNotes: [ReflectionNote] { filteredNotes.filter { $0.type == "challenge" } }
    
    // Search results across all reflections
    private var searchResults: [ReflectionNote] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }
        let query = searchText.lowercased()
        
        // When Theme Week toggle is on, include daily entries
        return reflections.filter {
            let matchesSearch = $0.title.lowercased().contains(query) ||
                               $0.content.lowercased().contains(query) ||
                               $0.author?.lowercased().contains(query) == true ||
                               $0.label.lowercased().contains(query)
            
            if showThemeWeekEntries {
                // Include all entries when toggle is on
                return matchesSearch
            } else {
                // Exclude daily Theme Week entries when toggle is off
                return matchesSearch && $0.type != "daily"
            }
        }
    }
    
    // NEW: Get all Theme Week entries grouped by session (not just program)
    private var themeWeekEntriesBySession: [(sessionID: String, programTag: String, entries: [ReflectionNote])] {
        let themeWeekEntries = reflections.filter { $0.isThemeWeekEntry }
        
        // Group by sessionID
        let grouped = Dictionary(grouping: themeWeekEntries) { $0.themeWeekSessionID ?? "Unknown" }
        
        // Sort by most recent first
        return grouped.map { (sessionID: $0.key, programTag: $0.value.first?.themeWeekTag ?? "", entries: $0.value) }
            .sorted { ($0.entries.first?.startDate ?? Date()) > ($1.entries.first?.startDate ?? Date()) }
    }

    private var availableMonths: [Date] {
        Array(Set(reflections.compactMap {
            Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: $0.startDate))
        })).sorted(by: >)
    }

    private var currentMonthLabel: String {
        let f = DateFormatter(); f.dateFormat = "MMMM yyyy"
        return f.string(from: currentMonth)
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            ReverieWeaverBackground()

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        header
                        motto

                        // Empty state when no entries
                        if weeklyNotes.isEmpty && monthlyNotes.isEmpty && challengeNotes.isEmpty {
                            emptyStateView
                        } else {
                            if !weeklyNotes.isEmpty {
                                sectionHeader("Weekly Edition")
                                articleList(for: weeklyNotes)
                            }

                            if !monthlyNotes.isEmpty {
                                sectionHeader("Monthly Edition")
                                articleList(for: monthlyNotes, isFeature: true)
                            }

                            if !challengeNotes.isEmpty {
                                sectionHeader("Challenge Reflections")
                                articleList(for: challengeNotes, isChallenge: true)
                            }
                        }

                        footer
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 80)
                    .onChange(of: scrollToID) { _, id in
                        if let id = id {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                proxy.scrollTo(id, anchor: .top)
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                scrollToID = nil
                            }
                        }
                    }
                }
                .refreshable {
                    await performRefresh()
                }
            }
        }
        .sheet(isPresented: $showAddSheet) { addReflectionSheet }
        .sheet(isPresented: $showSearchSheet) { searchSheet }
        .alert("Entry Already Exists", isPresented: $showDuplicateAlert) {
            Button("Edit Existing") {
                if let existing = pendingDuplicateNote {
                    scrollToID = existing.id
                }
                pendingDuplicateNote = nil
                pendingReflectionType = nil
                showAddSheet = false
            }
            Button("Create New Anyway") {
                if let type = pendingReflectionType {
                    continueWithNewReflection(type: type)
                }
                pendingDuplicateNote = nil
                pendingReflectionType = nil
            }
            Button("Cancel", role: .cancel) {
                pendingDuplicateNote = nil
                pendingReflectionType = nil
                showAddSheet = false
            }
        } message: {
            if let existing = pendingDuplicateNote {
                Text("You already have a \(existing.type) entry for \(existing.label). Would you like to edit it or create a new one?")
            }
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .alert("Delete Entry", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let note = noteToDelete {
                    deleteNote(note)
                }
                noteToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                noteToDelete = nil
            }
        } message: {
            if let note = noteToDelete {
                Text("Are you sure you want to delete \"\(note.title.isEmpty ? note.label : note.title)\"? This action cannot be undone.")
            }
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 12)
        }
    }

    // MARK: - Header
    private var header: some View {
        VStack(spacing: 10) {
            HStack {
                // 🔍 Search (Left)
                Button {
                    showSearchSheet = true
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                }

                Spacer()

                Menu {
                    Button {
                        currentMonth = monthStart(for: Date())
                    } label: {
                        Label("Back to Current Issue", systemImage: "arrow.uturn.backward")
                    }

                    if availableMonths.isEmpty {
                        Text("No past issues yet")
                            .font(.system(size: 12, weight: .regular, design: .serif))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                    } else {
                        Divider()
                        ForEach(availableMonths, id: \.self) { month in
                            Button {
                                currentMonth = monthStart(for: month)
                            } label: {
                                Label(monthLabel(month), systemImage: "calendar")
                            }
                        }
                    }
                } label: {
                    VStack(spacing: 4) {
                        Text("THE REVERIE JOURNAL")
                            .font(.system(size: 18, weight: .semibold, design: .serif))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

                        HStack(spacing: 6) {
                            Text("\(currentMonthLabel) – Vol. 10 No. 42")
                                .font(.system(size: 12, weight: .medium, design: .serif))
                                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                            
                            Image(systemName: "chevron.down")
                                .font(.system(size: 9, weight: .semibold))
                                .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                        }
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                Button { showAddSheet = true } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 14))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                }
            }
            .padding(.top, 20)
        }
    }

    // MARK: - Motto
    private var motto: some View {
        Text("\"Threads of thought, woven through time.\"")
            .font(.system(size: 13, weight: .regular, design: .serif))
            .italic()
            .multilineTextAlignment(.center)
            .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 6)
    }
    
    // MARK: - Empty State (Example Entry)
    
    private var emptyStateView: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Text("◆")
                        .font(.system(size: 11, weight: .regular, design: .serif))
                    Text("EXAMPLE ENTRY")
                        .font(.system(size: 13, weight: .semibold, design: .serif))
                        .tracking(1.2)
                    Text("◆")
                        .font(.system(size: 11, weight: .regular, design: .serif))
                }
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                
                Text("Your journal awaits your first story")
                    .font(.system(size: 12, weight: .regular, design: .serif))
                    .italic()
                    .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.top, 20)
            
            // Example Article
            VStack(alignment: .leading, spacing: 10) {
                // Article Header
                HStack {
                    Text("WEEK 42")
                        .font(.system(size: 12, weight: .semibold, design: .serif))
                        .tracking(1.1)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    
                    Text("·")
                        .font(.system(size: 12, weight: .regular, design: .serif))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                    
                    Text("Oct 14 – Oct 20")
                        .font(.system(size: 12, weight: .regular, design: .serif))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                }
                
                // Title
                Text("A Week of Small Victories")
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                
                // Author
                Text("By A Thoughtful Mind")
                    .font(.system(size: 12, weight: .regular, design: .serif))
                    .italic()
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                
                // Content
                Text("This week reminded me that progress isn't always about grand gestures. Sometimes it's found in the quiet morning routines, the conversations that linger in your mind, or the courage to try something new.\n\nI started each day with intention, savoring my coffee instead of rushing through it. I reached out to an old friend I'd been thinking about. I allowed myself to rest without guilt when my body asked for it.\n\nThese moments might seem small in the rush of daily life, but together they weave the fabric of a life well-lived. They're the threads worth remembering, the stories worth telling.")
                    .font(.system(size: 13.5, weight: .regular, design: .serif))
                    .lineSpacing(5)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                
                HStack(spacing: 4) {
                    ForEach(0..<3) { _ in
                        Text("·")
                            .font(.system(size: 11, weight: .regular, design: .serif))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                .padding(.top, 6)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .opacity(0.6)
 
            VStack(spacing: 12) {
                HStack(spacing: 4) {
                    ForEach(0..<5) { _ in
                        Text("·")
                            .font(.system(size: 11, weight: .regular, design: .serif))
                    }
                }
                .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                .frame(maxWidth: .infinity, alignment: .center)
                
                Button {
                    showAddSheet = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 13))
                        Text("Write Your First Entry")
                            .font(.system(size: 14, weight: .semibold, design: .serif))
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                }
                .buttonStyle(.plain)
                
                Text("Let your story begin")
                    .font(.system(size: 11, weight: .regular, design: .serif))
                    .italic()
                    .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Section Header
    
    private func sectionHeader(_ title: String) -> some View {
        HStack(spacing: 6) {
            Text("◆")
                .font(.system(size: 11, weight: .regular, design: .serif))
            Text(title.uppercased())
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .tracking(1.2)
            Text("◆")
                .font(.system(size: 11, weight: .regular, design: .serif))
        }
        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 6)
        .padding(.bottom, 10)
    }

    // MARK: - Article List

    private func articleList(for notes: [ReflectionNote], isFeature: Bool = false, isChallenge: Bool = false) -> some View {
        LazyVStack(alignment: .leading, spacing: 14) {
            ForEach(notes) { note in
                articleRow(note, isFeature: isFeature, isChallenge: isChallenge)
                    .background(Color.clear)
            }
        }
    }

    // MARK: - Article Row

    private func articleRow(_ note: ReflectionNote, isFeature: Bool, isChallenge: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if isChallenge, let challengeTag = note.challengeTag {
                    // Challenge tag badge
                    Text(formatChallengeTag(challengeTag).uppercased())
                        .font(.system(size: 11, weight: .bold, design: .serif))
                        .tracking(0.8)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(challengeColor(for: challengeTag))
                        )
                } else {
                    Text(note.label.uppercased())
                        .font(.system(size: 12, weight: .semibold, design: .serif))
                        .tracking(1.1)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                }

                if let end = note.endDate {
                    Text("·")
                        .font(.system(size: 12, weight: .regular, design: .serif))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                    Text("\(shortDate(note.startDate)) – \(shortDate(end))")
                        .font(.system(size: 12, weight: .regular, design: .serif))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                }

                Spacer()

                Button {
                    isEditingID = note.id
                    editedText = note.content
                    editedTitle = note.title
                    editedAuthor = note.author ?? ""
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 11))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                }
            }

            if !note.title.isEmpty {
                Text(note.title)
                    .font(.system(size: isFeature ? 16 : 14, weight: .bold, design: .serif))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
            }

            if let author = note.author,
               !author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("By \(author)")
                    .font(.system(size: 12, weight: .regular, design: .serif))
                    .italic()
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
            }

            if isEditingID == note.id {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Title")
                            .font(.system(size: 13, weight: .medium, design: .serif))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                        TextField("...", text: $editedTitle)
                            .font(.system(size: 13, weight: .semibold, design: .serif))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                            .textInputAutocapitalization(.sentences)
                    }
                    
                    // Author Editor
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Author (optional)")
                            .font(.system(size: 13, weight: .medium, design: .serif))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                        TextField("e.g., Editor", text: $editedAuthor)
                            .font(.system(size: 11, weight: .regular, design: .serif))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                            .textInputAutocapitalization(.words)
                            .disableAutocorrection(true)
                    }

                    // Content Editor with Placeholder
                    ZStack(alignment: .topLeading) {
                        if editedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text("Start writing your reflection here...")
                                .font(.system(size: 13.5, weight: .regular, design: .serif))
                                .italic()
                                .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 8)
                                .allowsHitTesting(false)
                        }
                        TextEditor(text: $editedText)
                            .font(.system(size: 14, weight: .regular, design: .serif))
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 180)
                    }

                    HStack(spacing: 16) {
                        Button("Cancel") {
                            isEditingID = nil
                            editedText = ""
                            editedTitle = ""
                            editedAuthor = ""
                        }
                        .font(.system(size: 13, weight: .medium, design: .serif))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)

                        Button("Save") {
                            note.title = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                            note.content = editedText.trimmingCharacters(in: .whitespacesAndNewlines)
                            note.author = editedAuthor.trimmingCharacters(in: .whitespacesAndNewlines)
                            note.lastEdited = Date()
                            
                            do {
                                try modelContext.save()
                                print("✅ Edit saved: \(note.label)")
                                isEditingID = nil
                                editedText = ""
                                editedTitle = ""
                                editedAuthor = ""
                            } catch {
                                print("❌ Edit save failed: \(error.localizedDescription)")
                                errorMessage = "Failed to save changes: \(error.localizedDescription)"
                                showErrorAlert = true
                            }
                        }
                        .font(.system(size: 13, weight: .semibold, design: .serif))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    }
                }
                .padding(.leading, 8)
            } else {
                Text(note.content)
                    .font(.system(size: 13.5, weight: .regular, design: .serif))
                    .lineSpacing(5)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
            }

            HStack(spacing: 4) {
                ForEach(0..<3) { _ in
                    Text("·")
                        .font(.system(size: 11, weight: .regular, design: .serif))
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
            .padding(.top, 4)
        }
        .padding(.vertical, 6)
        .id(note.id)
        .contextMenu {
            Button {
                isEditingID = note.id
                editedText = note.content
                editedTitle = note.title
                editedAuthor = note.author ?? ""
            } label: {
                Label("Edit Entry", systemImage: "pencil")
            }
            
            Divider()
            
            Button(role: .destructive) {
                noteToDelete = note
                showDeleteAlert = true
            } label: {
                Label("Delete Entry", systemImage: "trash")
            }
        }
    }

    // MARK: - Footer (brand-simple)
    
    private var footer: some View {
        VStack(spacing: 8) {
            Text("-")
                .font(.system(size: 14, weight: .regular, design: .serif))
                .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                .padding(.top, 20)

            Text("End of Current Issue")
                .font(.system(size: 12, weight: .medium, design: .serif))
                .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)

            Text("© \(String(Calendar.current.component(.year, from: Date()))) Reverie Archive — All Rights Reserved")
                .font(.system(size: 11, weight: .regular, design: .serif))
                .multilineTextAlignment(.center)
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 18)
    }

    // MARK: - Add Reflection Sheet (with placeholders)
    private var addReflectionSheet: some View {
        ZStack {
            ReverieWeaverBackground()
            VStack {
                if newType == nil {
                    VStack(spacing: 20) {
                        Text("Start a New Entry")
                            .font(.system(size: 16, weight: .semibold, design: .serif))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                            .padding(.top, 40)

                        Text("Choose your reflection style:")
                            .font(.system(size: 13, weight: .regular, design: .serif))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)

                        HStack(spacing: 40) {
                            Button("Weekly") { prepareNewReflection(type: "weekly") }
                            Button("Monthly") { prepareNewReflection(type: "monthly") }
                        }
                        .font(.system(size: 13, weight: .medium, design: .serif))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                        
                        if loadDraft() != nil {
                            VStack(spacing: 12) {
                                HStack(spacing: 4) {
                                    ForEach(0..<3) { _ in
                                        Text("·").font(.system(size: 11, weight: .regular, design: .serif))
                                    }
                                }
                                .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                                .padding(.top, 12)
                                
                                Button {
                                    restoreDraft()
                                    startAutoSaveDraft()
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "clock.arrow.circlepath")
                                            .font(.system(size: 12))
                                        Text("Continue Previous Draft")
                                            .font(.system(size: 13, weight: .medium, design: .serif))
                                    }
                                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                                }
                            }
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(newLabel.uppercased())
                            .font(.system(size: 13, weight: .semibold, design: .serif))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

                        Text(newDateRange)
                            .font(.system(size: 12, weight: .medium, design: .serif))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Title")
                                .font(.system(size: 13, weight: .medium, design: .serif))
                                .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                            TextField("A title for your thoughts?", text: $newTitle)
                                .font(.system(size: 11, weight: .semibold, design: .serif))
                                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                                .textInputAutocapitalization(.sentences)
                        }
                        .padding(.top, 6)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Author (optional)")
                                .font(.system(size: 13, weight: .medium, design: .serif))
                                .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                            TextField("e.g., Editor", text: $newAuthor)
                                .font(.system(size: 11, weight: .regular, design: .serif))
                                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                                .textInputAutocapitalization(.words)
                                .disableAutocorrection(true)
                        }

                        HStack(spacing: 4) {
                            Text("·").font(.system(size: 11, weight: .regular, design: .serif))
                            Text("·").font(.system(size: 11, weight: .regular, design: .serif))
                            Text("·").font(.system(size: 11, weight: .regular, design: .serif))
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                        .padding(.top, 2)

                        ZStack(alignment: .topLeading) {
                            if newContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text(promptFor(newType ?? "weekly"))
                                    .font(.system(size: 13.5, weight: .regular, design: .serif))
                                    .italic()
                                    .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 8)
                                    .transition(.opacity)
                                    .allowsHitTesting(false)
                            }

                            TextEditor(text: $newContent)
                                .font(.system(size: 14, weight: .regular, design: .serif))
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 220)
                        }

                        Spacer(minLength: 0)

                        Button("Publish to Journal") {
                            stopAutoSaveDraft()
                            publishNewReflection()
                        }
                        .font(.system(size: 14, weight: .semibold, design: .serif))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .buttonStyle(.plain)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .disabled(newContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .opacity(newContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
                    }
                    .padding(28)
                    .onAppear {
                        startAutoSaveDraft()
                    }
                    .onDisappear {
                        stopAutoSaveDraft()
                    }
                }
            }
        }
    }

    // MARK: - Search Sheet
    
    private var searchSheet: some View {
        NavigationStack {
            ZStack {
                ReverieWeaverBackground()
                
                VStack(spacing: 0) {
                    if searchResults.isEmpty {
                        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 50, weight: .light))
                                    .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                                    .padding(.top, 60)
                                
                                Text("Search Your Journal")
                                    .font(.system(size: 16, weight: .semibold, design: .serif))
                                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                                
                                Text("Find entries by title, content, author, or date")
                                    .font(.system(size: 13, weight: .regular, design: .serif))
                                    .multilineTextAlignment(.center)
                                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            VStack(spacing: 16) {
                                Image(systemName: "doc.text.magnifyingglass")
                                    .font(.system(size: 50, weight: .light))
                                    .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                                    .padding(.top, 60)
                                
                                Text("No Matches Found")
                                    .font(.system(size: 16, weight: .semibold, design: .serif))
                                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                                
                                Text("Try different keywords or phrases")
                                    .font(.system(size: 13, weight: .regular, design: .serif))
                                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    } else {
                        ScrollView(showsIndicators: false) {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("\(searchResults.count) \(searchResults.count == 1 ? "Entry" : "Entries") Found")
                                    .font(.system(size: 13, weight: .semibold, design: .serif))
                                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                                    .padding(.horizontal, 28)
                                    .padding(.top, 12)
                                
                                ForEach(searchResults) { note in
                                    Button {
                                        currentMonth = monthStart(for: note.startDate)
                                        showSearchSheet = false
                                        
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            scrollToID = note.id
                                        }
                                    } label: {
                                        searchResultRow(note)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.bottom, 100) 
                        }
                    }
                }
                
                // MARK: - Floating Action Button (FAB)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        themeWeekFilterFAB
                            .padding(.trailing, 20)
                            .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(colorScheme == .dark ? .dark : .light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        showSearchSheet = false
                        searchText = ""
                    }
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search entries...")
            .safeAreaInset(edge: .top, spacing: 0) {
                if showThemeWeekEntries && searchText.isEmpty {
                    themeWeekArchiveView
                }
            }
        }
    }
    
    // MARK: - Theme Week Filter FAB
    
    private var themeWeekFilterFAB: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showThemeWeekEntries.toggle()
            }
            ReverieHaptics.lightFeedback()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: showThemeWeekEntries ? "book.pages.fill" : "book.pages")
                    .font(.system(size: 15, weight: .semibold))
                
                if !showThemeWeekEntries {
                    Text("Theme Weeks")
                        .font(.system(size: 13, weight: .semibold))
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .foregroundStyle(.white)
            .padding(.horizontal, showThemeWeekEntries ? 14 : 16)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(showThemeWeekEntries ? Color.sageGreen : Color.sageGreen.opacity(0.9))
                    .shadow(
                        color: Color.black.opacity(colorScheme == .dark ? 0.4 : 0.2),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Theme Week Archive View (NEW)
    
    private var themeWeekArchiveView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("THEME WEEK REFLECTIONS")
                        .font(.system(size: 13, weight: .semibold, design: .serif))
                        .tracking(1.2)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    
                    Text("Your daily reflections from Theme Week programs")
                        .font(.system(size: 12, design: .serif))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                }
                .padding(.horizontal, 28)
                .padding(.top, 16)
                
                if themeWeekEntriesBySession.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "book.pages")
                            .font(.system(size: 40, weight: .light))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                            .padding(.top, 40)
                        
                        Text("No Theme Week Entries Yet")
                            .font(.system(size: 15, weight: .semibold, design: .serif))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                        
                        Text("Complete a Theme Week day and write a reflection to see it here")
                            .font(.system(size: 12, design: .serif))
                            .multilineTextAlignment(.center)
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    ForEach(themeWeekEntriesBySession, id: \.sessionID) { session in
                        themeWeekProgramSection(
                            sessionID: session.sessionID,
                            programTag: session.programTag,
                            entries: session.entries
                        )
                    }
                }
            }
            .padding(.bottom, 40)
        }
        .background(Color.adaptiveBorder(colorScheme: colorScheme).opacity(0.03))
    }
    
    private func themeWeekProgramSection(sessionID: String, programTag: String, entries: [ReflectionNote]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Program header with date
            HStack(spacing: 8) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 14))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(programTag)
                        .font(.system(size: 14, weight: .semibold, design: .serif))
                    
                    // Show week start date
                    if let firstEntry = entries.first {
                        Text("Started \(firstEntry.startDate, style: .date)")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // Entry count badge
                HStack(spacing: 4) {
                    Text("\(entries.count)")
                        .font(.system(size: 12, weight: .bold))
                    Text(entries.count == 1 ? "entry" : "entries")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(Color.sageGreen)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.sageGreen.opacity(0.15))
                )
            }
            .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.sageGreen.opacity(colorScheme == .dark ? 0.15 : 0.10))
            )
            
            // Day entries
            ForEach(entries.sorted(by: { ($0.themeWeekDay ?? 0) < ($1.themeWeekDay ?? 0) })) { entry in
                Button {
                    // Navigate to entry (could expand this to edit view)
                    scrollToID = entry.id
                    showSearchSheet = false
                } label: {
                    themeWeekEntryRow(entry)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 12)
    }
    
    private func themeWeekEntryRow(_ entry: ReflectionNote) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Day badge
                Text("DAY \(entry.themeWeekDay ?? 0)")
                    .font(.system(size: 10, weight: .bold, design: .serif))
                    .tracking(0.8)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                
                if let tierString = entry.themeWeekTier,
                   let tier = CompletionTier(rawValue: tierString) {
                    Text("•")
                        .font(.system(size: 10))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                    
                    Text(tier.emoji + " " + tier.displayName)
                        .font(.system(size: 11, weight: .medium))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                }
                
                Spacer()
                
                Text(entry.startDate, style: .date)
                    .font(.system(size: 10, design: .serif))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
            }
            
            if !entry.title.isEmpty {
                Text(entry.title)
                    .font(.system(size: 13, weight: .semibold, design: .serif))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    .lineLimit(1)
            }
            
            Text(entry.content)
                .font(.system(size: 12, design: .serif))
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                .lineLimit(2)
            
            Divider()
                .padding(.top, 4)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.adaptiveBorder(colorScheme: colorScheme).opacity(0.03))
        )
    }
    
    // MARK: - Search Result Row
    
    private func searchResultRow(_ note: ReflectionNote) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(note.label.uppercased())
                    .font(.system(size: 11, weight: .semibold, design: .serif))
                    .tracking(1.0)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                
                Text("·")
                    .font(.system(size: 11, weight: .regular, design: .serif))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                
                Text(note.type.capitalized)
                    .font(.system(size: 11, weight: .regular, design: .serif))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
            }
            
            if !note.title.isEmpty {
                Text(note.title)
                    .font(.system(size: 14, weight: .bold, design: .serif))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    .lineLimit(2)
            }
            
            if let author = note.author, !author.isEmpty {
                Text("By \(author)")
                    .font(.system(size: 11, weight: .regular, design: .serif))
                    .italic()
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
            }
            
            Text(note.content)
                .font(.system(size: 12.5, weight: .regular, design: .serif))
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                .lineLimit(3)
            
            Divider()
                .padding(.top, 4)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 8)
    }

    // MARK: - Duplicate Detection & Entry Limits
    
    private func existingReflection(for type: String, date: Date = Date()) -> ReflectionNote? {
        let calendar = Calendar.current
        if type == "weekly" {
            guard let weekStart = calendar.date(
                from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
            ) else { return nil }
            return reflections.first {
                $0.type == "weekly" && calendar.isDate($0.startDate, inSameDayAs: weekStart)
            }
        } else {
            guard let monthStart = calendar.date(
                from: calendar.dateComponents([.year, .month], from: date)
            ) else { return nil }
            return reflections.first {
                $0.type == "monthly" && calendar.isDate($0.startDate, inSameDayAs: monthStart)
            }
        }
    }
    
    private func canAddEntry(type: String, in month: Date) -> Bool {
        let calendar = Calendar.current
        let monthlyEntries = reflections.filter {
            $0.type == type &&
            calendar.compare($0.startDate, to: month, toGranularity: .month) == .orderedSame
        }
        
        if type == "weekly" {
            // Maximum 4 weekly entries per month
            return monthlyEntries.count < 4
        } else {
            // Maximum 1 monthly entry per month
            return monthlyEntries.count < 1
        }
    }

    private func prepareNewReflection(type: String) {
        let now = Date()
        
        guard canAddEntry(type: type, in: now) else {
            if type == "weekly" {
                errorMessage = "You've reached the maximum of 4 weekly entries for this month. Each month allows up to 4 weekly reflections."
            } else {
                errorMessage = "You already have a monthly entry for this month. Only one monthly reflection is allowed per month."
            }
            showErrorAlert = true
            return
        }
        
        if let existing = existingReflection(for: type) {
            pendingDuplicateNote = existing
            pendingReflectionType = type
            showDuplicateAlert = true
            return
        }
        
        continueWithNewReflection(type: type)
    }

    // MARK: - Prompts
    private func promptFor(_ type: String) -> String {
        let weeklyPrompts = [
            "What small victories did you have this week?",
            "What challenged your focus or patience?",
            "Which moments felt most meaningful or grounding?",
            "What are you grateful for this week?",
            "What could you do differently next week?"
        ]
        let monthlyPrompts = [
            "What did this month teach you about yourself?",
            "How have you grown since last month?",
            "Which habits or emotions defined this month's rhythm?",
            "What are you ready to leave behind as the new month begins?",
            "What are you most proud of achieving this month?"
        ]
        return type == "weekly"
            ? (weeklyPrompts.randomElement() ?? weeklyPrompts.first!)
            : (monthlyPrompts.randomElement() ?? monthlyPrompts.first!)
    }

    // MARK: - Reflection Creation Logic
    
    private func continueWithNewReflection(type: String) {
        newType = type
        let calendar = Calendar.current
        let now = Date()

        if type == "weekly" {
            let week = calendar.component(.weekOfYear, from: now)
            let start = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
            let end = calendar.date(byAdding: .day, value: 6, to: start) ?? now
            newLabel = "Week \(week)"
            newDateRange = "\(shortDate(start)) – \(shortDate(end))"
        } else {
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
            let end = calendar.date(byAdding: .month, value: 1, to: start) ?? now
            newLabel = DateFormatter.monthYearFormatter.string(from: now)
            newDateRange = "\(shortDate(start)) – \(shortDate(end))"
        }
    }

    private func publishNewReflection() {
        guard let type = newType else { return }
    
        let trimmedContent = newContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else {
            errorMessage = "Please write something before publishing."
            showErrorAlert = true
            return
        }
        
        let calendar = Calendar.current
        let now = Date()

        let start: Date
        let end: Date
        let label: String

        if type == "weekly" {
            start = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
            end = calendar.date(byAdding: .day, value: 6, to: start) ?? now
            label = "Week \(calendar.component(.weekOfYear, from: now))"
        } else {
            start = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
            end = calendar.date(byAdding: .month, value: 1, to: start) ?? now
            label = DateFormatter.monthYearFormatter.string(from: now)
        }

        let note = ReflectionNote(
            type: type,
            label: label,
            title: newTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            startDate: start,
            endDate: end,
            content: trimmedContent,
            author: newAuthor.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        modelContext.insert(note)
        
        do {
            try modelContext.save()
            print("✅ Entry saved: \(label)")
            
            currentMonth = monthStart(for: start)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // Reset state
                newType = nil
                newTitle = ""
                newContent = ""
                newAuthor = ""
             
                withAnimation(.easeInOut) {
                    showAddSheet = false
                }
             
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    scrollToID = note.id
                }
                
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            }
        } catch {
            print("❌ Save failed: \(error.localizedDescription)")
            errorMessage = "Failed to publish entry: \(error.localizedDescription)"
            showErrorAlert = true
        }
    }

    // MARK: - Helpers
    private func shortDate(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MMM d"; return f.string(from: date)
    }

    private func monthLabel(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MMMM yyyy"; return f.string(from: date)
    }

    private func monthStart(for date: Date) -> Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: date))!
    }

    // MARK: - Challenge Reflection Helpers

    /// Formats a challenge tag like "FeiStrengthW1" to "Fei Strength W1"
    private func formatChallengeTag(_ tag: String) -> String {
        // Find the challenge in MiniChallenge data
        if let challenge = MiniChallengeData.challenges.first(where: { $0.tag == tag }) {
            return challenge.title
        }
        // Fallback: Add spaces before capital letters and numbers
        var result = ""
        for char in tag {
            if char.isUppercase && !result.isEmpty {
                result += " "
            } else if char.isNumber && !result.isEmpty && !result.last!.isNumber {
                result += " "
            }
            result.append(char)
        }
        return result
    }

    /// Returns the accent color for a challenge based on its tag
    private func challengeColor(for tag: String) -> Color {
        if let challenge = MiniChallengeData.challenges.first(where: { $0.tag == tag }) {
            return Color(hex: challenge.colorHex)
        }
        return .sageGreen
    }
 
    @MainActor
    private func performRefresh() async {
        isRefreshing = true
       
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        isRefreshing = false
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }
    
    private func deleteNote(_ note: ReflectionNote) {
        modelContext.delete(note)
        
        do {
            try modelContext.save()
            print("✅ Entry deleted: \(note.label)")
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {
            print("❌ Delete failed: \(error.localizedDescription)")
            errorMessage = "Failed to delete entry: \(error.localizedDescription)"
            showErrorAlert = true
        }
    }
    
    private func startAutoSaveDraft() {
        
        draftTimer?.invalidate()
        
        draftTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            saveDraft()
        }
    }
    
    private func stopAutoSaveDraft() {
        draftTimer?.invalidate()
        draftTimer = nil
        clearDraft()
    }
    
    private func saveDraft() {
        guard let type = newType,
              !newContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        let draft = DraftData(
            type: type,
            title: newTitle,
            content: newContent,
            author: newAuthor,
            timestamp: Date()
        )
        
        if let encoded = try? JSONEncoder().encode(draft) {
            UserDefaults.standard.set(encoded, forKey: "reflection_draft")
            print("💾 Draft auto-saved")
        }
    }
    
    private func loadDraft() -> DraftData? {
        guard let data = UserDefaults.standard.data(forKey: "reflection_draft"),
              let draft = try? JSONDecoder().decode(DraftData.self, from: data) else {
            return nil
        }
        
        let daysSinceDraft = Calendar.current.dateComponents([.day], from: draft.timestamp, to: Date()).day ?? 0
        if daysSinceDraft <= 7 {
            return draft
        } else {
            clearDraft()
            return nil
        }
    }
    
    private func clearDraft() {
        UserDefaults.standard.removeObject(forKey: "reflection_draft")
    }
    
    private func restoreDraft() {
        guard let draft = loadDraft() else { return }
        
        newType = draft.type
        newTitle = draft.title
        newContent = draft.content
        newAuthor = draft.author
        
        continueWithNewReflection(type: draft.type)
    }
}

// MARK: - Formatter

extension DateFormatter {
    static let monthYearFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "MMMM yyyy"; return f
    }()
}

// MARK: - Draft Data Structure

struct DraftData: Codable {
    let type: String
    let title: String
    let content: String
    let author: String
    let timestamp: Date
}
