//
//  ThemeWeekJournalSheet.swift
//  Reverie Weaver
//
//  Journal integration for Theme Week daily reflections
//  Only accessible through Theme Week detail view
//

import SwiftUI
import SwiftData

// MARK: - Journal Context

struct JournalContext: Identifiable {
    let id = UUID()
    let programTag: String
    let programTitle: String
    let dayNumber: Int
    let dayTheme: String
    let prompt: String
    let tier: CompletionTier?
    let colorHex: String
    let sessionID: String
}

// MARK: - Theme Week Journal Sheet

struct ThemeWeekJournalSheet: View {
    let context: JournalContext
    let existingEntry: ReflectionNote?
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var title: String
    @State private var content: String
    @State private var author: String
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    // Auto-save draft
    @State private var draftTimer: Timer? = nil
    @State private var hasAppeared = false  // Track first appearance
    
    init(context: JournalContext, existingEntry: ReflectionNote? = nil) {
        self.context = context
        self.existingEntry = existingEntry
        
        _title = State(initialValue: existingEntry?.title ?? "")
        _content = State(initialValue: existingEntry?.content ?? "")
        _author = State(initialValue: existingEntry?.author ?? "")
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Explicit background color to prevent blank screen
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()

                ReverieWeaverBackground()
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        contextBadge

                        // Always show prompt card (use fallback if empty)
                        promptCard

                        Divider()
                            .background(Color.adaptiveBorder(colorScheme: colorScheme).opacity(0.3))
                            .padding(.vertical, 4)

                        titleField
                        contentEditor

                        Spacer(minLength: 40)
                    }
                    .padding(24)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle(existingEntry == nil ? "New Reflection" : "Edit Reflection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        stopAutoSave()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        saveJournalEntry()
                    } label: {
                        if isSaving {
                            ProgressView()
                                .tint(Color(hex: context.colorHex))
                        } else {
                            Text("Save")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                #if DEBUG
                print("📝 [JournalSheet] onAppear - context: \(context.programTag), day: \(context.dayNumber), prompt: \(context.prompt.prefix(50))...")
                #endif
                // Force immediate render to prevent blank screen
                DispatchQueue.main.async {
                    hasAppeared = true
                }
                startAutoSave()
            }
            .onDisappear {
                stopAutoSave()
            }
        }
    }
    
    // MARK: - Context Badge
    
    private var contextBadge: some View {
        HStack(spacing: 10) {
            // Day icon
            ZStack {
                Circle()
                    .fill(Color(hex: context.colorHex).opacity(0.15))
                    .frame(width: 36, height: 36)
                Text("\(context.dayNumber)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(hex: context.colorHex))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(context.programTitle)
                    .font(.system(size: 11, weight: .medium))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                
                HStack(spacing: 6) {
                    Text("Day \(context.dayNumber): \(context.dayTheme)")
                        .font(.system(size: 14, weight: .semibold))
                        .fontDesign(.serif)
                    
                    if let tier = context.tier {
                        Text("•")
                            .font(.system(size: 11))
                        Text(tier.emoji + " " + tier.displayName)
                            .font(.system(size: 12, weight: .medium))
                    }
                }
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
            }
            
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: context.colorHex).opacity(colorScheme == .dark ? 0.08 : 0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color(hex: context.colorHex).opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Prompt Card

    private var displayPrompt: String {
        if context.prompt.isEmpty {
            return "How did today's practice feel for you? What did you notice?"
        }
        return context.prompt
    }

    private var promptCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 13))
                Text("Reflection Prompt")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(Color(hex: context.colorHex))

            Text(displayPrompt)
                .font(.system(size: 14, design: .serif))
                .italic()
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                .lineSpacing(4)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.adaptiveBorder(colorScheme: colorScheme).opacity(0.05))
        )
    }
    
    // MARK: - Title Field
    
    private var titleField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Title (optional)")
                .font(.system(size: 13, weight: .medium))
                .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
            
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.adaptiveBorder(colorScheme: colorScheme).opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Color.adaptiveBorder(colorScheme: colorScheme).opacity(0.2), lineWidth: 1)
                    )
                
                TextField("A title for this reflection...", text: $title)
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    .textInputAutocapitalization(.sentences)
                    .padding(12)
            }
            .frame(height: 44)
        }
    }
    
    // MARK: - Content Editor
    
    private var contentEditor: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Your Reflection")
                .font(.system(size: 13, weight: .medium))
                .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
            
            ZStack(alignment: .topLeading) {
                // Explicit background for TextEditor
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.adaptiveBorder(colorScheme: colorScheme).opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Color.adaptiveBorder(colorScheme: colorScheme).opacity(0.2), lineWidth: 1)
                    )
                
                if content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Start writing your thoughts here...\n\nWhat did you notice today? How did it feel? What surprised you?")
                        .font(.system(size: 14, design: .serif))
                        .italic()
                        .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                        .opacity(0.5)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }
                
                TextEditor(text: $content)
                    .font(.system(size: 14, design: .serif))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)  // Explicit clear background
                    .frame(minHeight: 240)
                    .padding(8)
                    .onChange(of: content) { _, _ in
                        // Trigger auto-save on content change
                    }
            }
        }
    }
    
    // MARK: - Save Logic
    
    private func saveJournalEntry() {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedContent.isEmpty else {
            errorMessage = "Please write something before saving."
            showError = true
            return
        }
        
        isSaving = true
        
        if let existing = existingEntry {
            existing.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            existing.content = trimmedContent
            existing.author = author.trimmingCharacters(in: .whitespacesAndNewlines)
            existing.lastEdited = Date()
            
            #if DEBUG
            print("📝 [Journal] Updating existing entry for Day \(context.dayNumber)")
            #endif
        } else {
            // CREATE new entry
            let note = ReflectionNote(
                type: "daily",
                label: "Day \(context.dayNumber): \(context.dayTheme)",
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                startDate: Date(),
                endDate: nil,
                content: trimmedContent,
                author: author.trimmingCharacters(in: .whitespacesAndNewlines),
                themeWeekTag: context.programTag,
                themeWeekDay: context.dayNumber,
                themeWeekTier: context.tier?.rawValue,
                themeWeekSessionID: context.sessionID
            )
            
            modelContext.insert(note)
            
            #if DEBUG
            print("📝 [Journal] Created new entry for Day \(context.dayNumber)")
            #endif
        }
        
        do {
            try modelContext.save()
            ReverieHaptics.successFeedback()
            
            stopAutoSave()
            clearDraft()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                dismiss()
            }
        } catch {
            isSaving = false
            errorMessage = "Failed to save entry: \(error.localizedDescription)"
            showError = true
            print("❌ [Journal] Save failed: \(error)")
        }
    }

    // MARK: - Auto-Save Draft

    private func startAutoSave() {
        draftTimer?.invalidate()
        
        draftTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            saveDraft()
        }
    }

    private func stopAutoSave() {
        draftTimer?.invalidate()
        draftTimer = nil
    }

    private func saveDraft() {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        let draftKey = "journal_draft_\(context.programTag)_day\(context.dayNumber)"
        
        let draft: [String: String] = [
            "title": title,
            "content": content,
            "author": author,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        if let encoded = try? JSONEncoder().encode(draft) {
            UserDefaults.standard.set(encoded, forKey: draftKey)
            #if DEBUG
            print("💾 [Journal] Draft auto-saved for Day \(context.dayNumber)")
            #endif
        }
    }

    private func clearDraft() {
        let draftKey = "journal_draft_\(context.programTag)_day\(context.dayNumber)"
        UserDefaults.standard.removeObject(forKey: draftKey)
    }
}

// MARK: - Preview

#Preview {
    ThemeWeekJournalSheet(
        context: JournalContext(
            programTag: "ConnectionClarityW1",
            programTitle: "Connection Clarity Week",
            dayNumber: 3,
            dayTheme: "\"I\" Statements",
            prompt: "You completed your intended goal. What did you notice while practicing one 'I feel...' statement?",
            tier: .sprout,
            colorHex: "9DB4C8",
            sessionID: "ConnectionClarityW1_2024-12-20"
        ),
        existingEntry: nil
    )
    .modelContainer(for: ReflectionNote.self, inMemory: true)
}
