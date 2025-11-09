//
//  ReflectionNote.swift
//  Reverie Weaver
//
//  THE REVERIE JOURNAL – Newspaper-Style Edition
//  FIXED: Proper error handling + timing + validation
//

import SwiftUI
import SwiftData

// MARK: - Data Model
@Model
final class ReflectionNote {
    var id: UUID
    var type: String           // "weekly" or "monthly"
    var label: String          // e.g. "Week 42" or "October 2025"
    var title: String          // user-entered title
    var startDate: Date
    var endDate: Date?
    var content: String
    var author: String?        // ✅ NEW (optional byline)
    var lastEdited: Date

    init(type: String,
         label: String,
         title: String = "",
         startDate: Date,
         endDate: Date? = nil,
         content: String = "",
         author: String? = nil) {
        self.id = UUID()
        self.type = type
        self.label = label
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.content = content
        self.author = author
        self.lastEdited = Date()
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

    @State private var currentMonth: Date =
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date())) ?? Date()
    @State private var scrollToID: UUID? = nil

    // New entry state
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
    
    // ✅ NEW: Error handling
    @State private var showErrorAlert = false
    @State private var errorMessage = ""

    @Namespace private var scrollSpace

    // MARK: - Computed Data
    private var filteredNotes: [ReflectionNote] {
        reflections.filter {
            Calendar.current.compare($0.startDate, to: currentMonth, toGranularity: .month) == .orderedSame
        }
    }

    private var weeklyNotes: [ReflectionNote]  { filteredNotes.filter { $0.type == "weekly" } }
    private var monthlyNotes: [ReflectionNote] { filteredNotes.filter { $0.type == "monthly" } }

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

                        if !weeklyNotes.isEmpty {
                            sectionHeader("Weekly Edition")
                            articleList(for: weeklyNotes)
                        }

                        if !monthlyNotes.isEmpty {
                            sectionHeader("Monthly Edition")
                            articleList(for: monthlyNotes, isFeature: true)
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
            }
        }
        .sheet(isPresented: $showAddSheet) { addReflectionSheet }
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
        // ✅ NEW: Error alert
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 12)
        }
    }

    // MARK: - Header
    private var header: some View {
        VStack(spacing: 10) {
            HStack {
                // 📰 Archives (Left)
                Menu {
                    Button {
                        currentMonth = monthStart(for: Date())
                    } label: {
                        Label("Back to Current Issue", systemImage: "arrow.uturn.backward")
                    }

                    if availableMonths.isEmpty {
                        Text("No past issues yet")
                            .font(.system(size: 11, weight: .regular, design: .serif))
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
                    Image(systemName: "newspaper.fill")
                        .font(.system(size: 14))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                }

                Spacer()

                // Center Title
                VStack(spacing: 4) {
                    Text("THE REVERIE JOURNAL")
                        .font(.system(size: 18, weight: .semibold, design: .serif))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

                    Text("\(currentMonthLabel) – Vol. 10 No. 42")
                        .font(.system(size: 11, weight: .medium, design: .serif))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                }

                Spacer()

                // ✏️ Add (Right)
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
            .font(.system(size: 12, weight: .regular, design: .serif))
            .italic()
            .multilineTextAlignment(.center)
            .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 6)
    }

    // MARK: - Section Header
    private func sectionHeader(_ title: String) -> some View {
        HStack(spacing: 6) {
            Text("◆")
                .font(.system(size: 10, weight: .regular, design: .serif))
            Text(title.uppercased())
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .tracking(1.2)
            Text("◆")
                .font(.system(size: 10, weight: .regular, design: .serif))
        }
        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 6)
        .padding(.bottom, 10)
    }

    // MARK: - Article List
    private func articleList(for notes: [ReflectionNote], isFeature: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(notes) { note in
                articleRow(note, isFeature: isFeature)
            }
        }
    }

    // MARK: - Article Row
    private func articleRow(_ note: ReflectionNote, isFeature: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Article Header
            HStack {
                Text(note.label.uppercased())
                    .font(.system(size: 11, weight: .semibold, design: .serif))
                    .tracking(1.1)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)

                if let end = note.endDate {
                    Text("·")
                        .font(.system(size: 11, weight: .regular, design: .serif))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                    Text("\(shortDate(note.startDate)) – \(shortDate(end))")
                        .font(.system(size: 11, weight: .regular, design: .serif))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                }

                Spacer()

                // Edit Icon
                Button {
                    isEditingID = note.id
                    editedText = note.content
                    editedTitle = note.title
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 10))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                }
            }

            // Title
            if !note.title.isEmpty {
                Text(note.title)
                    .font(.system(size: isFeature ? 16 : 14, weight: .bold, design: .serif))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
            }

            // ✅ Author (only when present)
            if let author = note.author,
               !author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("By \(author)")
                    .font(.system(size: 11, weight: .regular, design: .serif))
                    .italic()
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
            }

            // Content or Editor
            if isEditingID == note.id {
                VStack(alignment: .leading, spacing: 12) {
                    // Title Editor
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Title")
                            .font(.system(size: 12, weight: .medium, design: .serif))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                        TextField("...", text: $editedTitle)
                            .font(.system(size: 12, weight: .semibold, design: .serif))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                            .textInputAutocapitalization(.sentences)
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
                        }
                        .font(.system(size: 13, weight: .medium, design: .serif))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)

                        Button("Save") {
                            // ✅ FIXED: Proper error handling for edits
                            note.title = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                            note.content = editedText.trimmingCharacters(in: .whitespacesAndNewlines)
                            note.lastEdited = Date()
                            
                            do {
                                try modelContext.save()
                                print("✅ Edit saved: \(note.label)")
                                isEditingID = nil
                                editedText = ""
                                editedTitle = ""
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

            // Divider
            HStack(spacing: 4) {
                ForEach(0..<3) { _ in
                    Text("·")
                        .font(.system(size: 10, weight: .regular, design: .serif))
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
            .padding(.top, 4)
        }
        .padding(.vertical, 6)
        .id(note.id)
    }

    // MARK: - Footer (brand-simple)
    private var footer: some View {
        VStack(spacing: 8) {
            Text("-")
                .font(.system(size: 14, weight: .regular, design: .serif))
                .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                .padding(.top, 20)

            Text("End of Current Issue")
                .font(.system(size: 11, weight: .medium, design: .serif))
                .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)

            Text("© \(String(Calendar.current.component(.year, from: Date()))) Reverie Archive — All Rights Reserved")
                .font(.system(size: 10, weight: .regular, design: .serif))
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
                    // Step 1 – Choose Type
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
                    }
                } else {
                    // Step 2 – Writing Interface
                    VStack(alignment: .leading, spacing: 16) {
                        Text(newLabel.uppercased())
                            .font(.system(size: 13, weight: .semibold, design: .serif))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .primary)

                        Text(newDateRange)
                            .font(.system(size: 11, weight: .medium, design: .serif))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)

                        // Title Field
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Title")
                                .font(.system(size: 12, weight: .medium, design: .serif))
                                .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                            TextField("A title for your thoughts?", text: $newTitle)
                                .font(.system(size: 10, weight: .semibold, design: .serif))
                                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                                .textInputAutocapitalization(.sentences)
                        }
                        .padding(.top, 6)

                        // Author Field (optional)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Author (optional)")
                                .font(.system(size: 12, weight: .medium, design: .serif))
                                .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                            TextField("e.g., Editor", text: $newAuthor)
                                .font(.system(size: 10, weight: .regular, design: .serif))
                                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                                .textInputAutocapitalization(.words)
                                .disableAutocorrection(true)
                        }

                        // Subtle Divider
                        HStack(spacing: 4) {
                            Text("·").font(.system(size: 10, weight: .regular, design: .serif))
                            Text("·").font(.system(size: 10, weight: .regular, design: .serif))
                            Text("·").font(.system(size: 10, weight: .regular, design: .serif))
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                        .padding(.top, 2)

                        // TextEditor with clear placeholder
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

                        // Publish Button
                        Button("Publish to Journal") {
                            publishNewReflection()
                        }
                        .font(.system(size: 14, weight: .semibold, design: .serif))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .buttonStyle(.plain)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        // ✅ NEW: Disable if content is empty
                        .disabled(newContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .opacity(newContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
                    }
                    .padding(28)
                }
            }
        }
    }

    // MARK: - Duplicate Detection
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

    private func prepareNewReflection(type: String) {
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

    // ✅ FIXED: Proper save timing + error handling + validation
    private func publishNewReflection() {
        guard let type = newType else { return }
        
        // ✅ NEW: Validate content is not empty
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
        
        // ✅ FIXED: Proper save with error handling
        do {
            try modelContext.save()
            print("✅ Entry saved: \(label)")
            
            // Set the month FIRST
            currentMonth = monthStart(for: start)
            
            // ✅ FIXED: Wait for @Query to refresh, THEN close sheet
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // Reset state
                newType = nil
                newTitle = ""
                newContent = ""
                newAuthor = ""
                
                // Close sheet
                withAnimation(.easeInOut) {
                    showAddSheet = false
                }
                
                // THEN scroll to the new entry
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
}

// MARK: - Formatter
extension DateFormatter {
    static let monthYearFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "MMMM yyyy"; return f
    }()
}
