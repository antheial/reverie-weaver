//
//  ThemeWeekCompletionSheet.swift
//  Reverie Weaver
//
//  Celebration and review sheet shown when user completes all 7 days
//  Uses only SF Symbols for all icons
//

import SwiftUI
import SwiftData

struct ThemeWeekCompletionSheet: View {
    let progress: ThemeWeekProgress
    let program: ThemeWeekHabit
    let journalEntries: [ReflectionNote]
    let onRunAgain: () -> Void
    let onViewReflections: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var showWeekReviewSheet = false
    @State private var confettiCounter = 0
    
    var body: some View {
        ZStack {
            ReverieWeaverBackground()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    // MARK: - Celebration Header
                    celebrationHeader
                    
                    // MARK: - Tier Distribution
                    tierDistributionCard
                    
                    // MARK: - Journal Summary
                    journalSummaryCard
                    
                    // MARK: - Growth Reflection Prompt
                    weekReviewPromptCard
                    
                    // MARK: - Action Buttons
                    actionButtons
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 40)
            }
        }
        .presentationDetents([.large])
        .interactiveDismissDisabled(false)
        .onAppear {
            // Mark as viewed
            progress.markCompletionSheetViewed()
            try? modelContext.save()
            
            // Trigger confetti animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    confettiCounter += 1
                }
            }
            
            ReverieHaptics.successFeedback()
        }
        .sheet(isPresented: $showWeekReviewSheet) {
            weekReviewJournalSheet
        }
    }
    
    // MARK: - Celebration Header
    
    private var celebrationHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                // SF Symbol confetti effect
                if confettiCounter > 0 {
                    ForEach(0..<20) { index in
                        Image(systemName: sfSymbolConfetti[index % sfSymbolConfetti.count])
                            .font(.system(size: 24))
                            .foregroundStyle(confettiColors[index % confettiColors.count])
                            .offset(
                                x: CGFloat.random(in: -100...100),
                                y: CGFloat.random(in: -150...50)
                            )
                            .opacity(0)
                            .animation(
                                .easeOut(duration: 1.5)
                                .delay(Double(index) * 0.05),
                                value: confettiCounter
                            )
                    }
                }
                
                VStack(spacing: 12) {
                    Text("Week Complete!")
                        .font(.system(size: 34, weight: .bold, design: .serif))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    
                    if let badge = progress.weekBadge {
                        Text(badge)
                            .font(.system(size: 16, weight: .medium, design: .serif))
                            .foregroundStyle(Color.sageGreen)
                    }
                    
                    Text(progress.adaptationMessage)
                        .font(.system(size: 15, design: .serif))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 20)
        }
    }
    
    // SF Symbols for confetti
    private let sfSymbolConfetti = [
        "sparkle", "star.fill", "circle.fill", "diamond.fill",
        "sparkles", "star.circle.fill", "heart.fill", "flame.fill"
    ]
    
    private let confettiColors = [
        Color(hex: "B8D4C8"), // Sage green
        Color(hex: "9BB5CE"), // Blue
        Color(hex: "D4B896"), // Gold
        Color.sageGreen,
        Color.pink.opacity(0.7),
        Color.purple.opacity(0.7)
    ]
    
    // MARK: - Tier Distribution Card
    
    private var tierDistributionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Week at a Glance")
                .font(.system(size: 18, weight: .semibold, design: .serif))
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
            
            VStack(spacing: 12) {
                tierRow(
                    icon: "leaf.fill",
                    label: "Seed Days",
                    count: progress.seedCount,
                    color: Color(hex: "B8D4C8")
                )
                
                tierRow(
                    icon: "leaf.circle.fill",
                    label: "Sprout Days",
                    count: progress.sproutCount,
                    color: Color(hex: "9BB5CE")
                )
                
                tierRow(
                    icon: "sparkles",
                    label: "Bloom Days",
                    count: progress.bloomCount,
                    color: Color(hex: "D4B896")
                )
            }
            
            Text("You adapted to your capacity each day—that's wisdom.")
                .font(.system(size: 13, design: .serif))
                .italic()
                .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                .padding(.top, 8)
        }
        .padding(20)
        .reverieCardStyle(colorScheme: colorScheme)
    }
    
    private func tierRow(icon: String, label: String, count: Int, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)
            
            Text(label)
                .font(.system(size: 15, weight: .medium, design: .serif))
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
            
            Spacer()
            
            HStack(spacing: 4) {
                Text("\(count)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(color)
                
                Text(count == 1 ? "day" : "days")
                    .font(.system(size: 14))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(colorScheme == .dark ? 0.15 : 0.10))
        )
    }
    
    // MARK: - Journal Summary Card
    
    private var journalSummaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Reflections")
                        .font(.system(size: 18, weight: .semibold, design: .serif))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    
                    Text("\(journalEntries.count) of 7 days journaled")
                        .font(.system(size: 13))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                }
                
                Spacer()
                
                Button {
                    onViewReflections()
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Text("View All")
                            .font(.system(size: 13, weight: .medium))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 11))
                    }
                    .foregroundStyle(Color.sageGreen)
                }
            }
            
            if journalEntries.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "book.pages")
                        .font(.system(size: 30))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                    
                    Text("You completed the week without journaling—and that's okay. The practice itself is what matters most.")
                        .font(.system(size: 13, design: .serif))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(journalEntries.sorted(by: { ($0.themeWeekDay ?? 0) < ($1.themeWeekDay ?? 0) })) { entry in
                            journalEntryPreview(entry)
                        }
                    }
                }
            }
        }
        .padding(20)
        .reverieCardStyle(colorScheme: colorScheme)
    }
    
    private func journalEntryPreview(_ entry: ReflectionNote) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text("DAY \(entry.themeWeekDay ?? 0)")
                    .font(.system(size: 10, weight: .bold, design: .serif))
                    .tracking(0.8)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                
                if let tierString = entry.themeWeekTier,
                   let tier = CompletionTier(rawValue: tierString) {
                    Text("•")
                        .font(.system(size: 10))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                    
                    Image(systemName: tierSFSymbol(for: tier))
                        .font(.system(size: 11))
                        .foregroundStyle(tierColor(for: tier))
                }
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
                .lineLimit(3)
        }
        .frame(width: 200)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.adaptiveBorder(colorScheme: colorScheme).opacity(0.05))
        )
    }
    
    private func tierSFSymbol(for tier: CompletionTier) -> String {
        switch tier {
        case .seed: return "leaf.fill"
        case .sprout: return "leaf.circle.fill"
        case .bloom: return "sparkles"
        }
    }
    
    private func tierColor(for tier: CompletionTier) -> Color {
        switch tier {
        case .seed: return Color(hex: "B8D4C8")
        case .sprout: return Color(hex: "9BB5CE")
        case .bloom: return Color(hex: "D4B896")
        }
    }
    
    // MARK: - Week Review Prompt Card
    
    private var weekReviewPromptCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.sageGreen)
                
                Text("Final Reflection (Optional)")
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
            }
            
            Text("Take a moment to reflect on your whole week. What shifted? What surprised you?")
                .font(.system(size: 14, design: .serif))
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            Button {
                showWeekReviewSheet = true
            } label: {
                HStack {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 14))
                    Text("Write Week Review")
                        .font(.system(size: 15, weight: .medium, design: .serif))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.sageGreen.opacity(colorScheme == .dark ? 0.2 : 0.15))
                )
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .reverieCardStyle(colorScheme: colorScheme)
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                onRunAgain()
                dismiss()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14))
                    Text("Run This Week Again")
                        .font(.system(size: 15, weight: .semibold, design: .serif))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                .reverieCardStyle(colorScheme: colorScheme)
            }
            .buttonStyle(.plain)
            
            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.system(size: 15, weight: .medium, design: .serif))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Week Review Journal Sheet
    
    private var weekReviewJournalSheet: some View {
        NavigationStack {
            ZStack {
                ReverieWeaverBackground()
                
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "moon.stars.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Color.sageGreen)
                            
                            Text(progress.programTitle)
                                .font(.system(size: 16, weight: .semibold, design: .serif))
                                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                        }
                        
                        Text("Week Review")
                            .font(.system(size: 13))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
                    // Prompt
                    VStack(alignment: .leading, spacing: 12) {
                        Text(ConnectionClarityPrompts.weekReviewPrompt)
                            .font(.system(size: 14, design: .serif))
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.sageGreen.opacity(colorScheme == .dark ? 0.15 : 0.10))
                            )
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // Note: Actual journal entry will be created via standard flow
                    Text("This will create a week review entry in your journal.")
                        .font(.system(size: 13, design: .serif))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.bottom, 20)
                }
            }
            .navigationTitle("Week Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showWeekReviewSheet = false
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Create Entry") {
                        createWeekReviewEntry()
                        showWeekReviewSheet = false
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func createWeekReviewEntry() {
        let calendar = Calendar.current
        let now = Date()
        
        // Calculate week range
        let weekStart = progress.startDate
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? now
        
        // Create weekly reflection note linked to this Theme Week session
        let note = ReflectionNote(
            type: "weekly",
            label: "Week Review",
            title: "\(progress.programTitle) - Week Complete",
            startDate: weekStart,
            endDate: weekEnd,
            content: ConnectionClarityPrompts.weekReviewPrompt,
            author: nil,
            themeWeekTag: progress.programTag,
            themeWeekDay: nil,  // Not day-specific
            themeWeekTier: nil,  // Not tier-specific
            themeWeekSessionID: progress.sessionID
        )
        
        modelContext.insert(note)
        
        do {
            try modelContext.save()
            print("✅ Week review entry created")
            ReverieHaptics.successFeedback()
        } catch {
            print("❌ Failed to create week review: \(error.localizedDescription)")
        }
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: ThemeWeekProgress.self, ReflectionNote.self, configurations: config)
    
    let progress = ThemeWeekProgress(
        programID: "connection-clarity-w1",
        programTag: "ConnectionClarityW1",
        programTitle: "Connection Clarity Week",
        startDate: Date()
    )
    
    // Simulate completed week
    progress.completeDay(1, tier: .seed, habitID: UUID())
    progress.completeDay(2, tier: .sprout, habitID: UUID())
    progress.completeDay(3, tier: .sprout, habitID: UUID())
    progress.completeDay(4, tier: .bloom, habitID: UUID())
    progress.completeDay(5, tier: .seed, habitID: UUID())
    progress.completeDay(6, tier: .sprout, habitID: UUID())
    progress.completeDay(7, tier: .bloom, habitID: UUID())
    
    let program = ThemeWeekHabit(
        name: "Communication Patterns",
        icon: "bubble.left.and.bubble.right",
        colorHex: "9BB5CE",
        seedTier: "Notice one moment",
        sproutTier: "Track patterns",
        bloomTier: "Identify triggers",
        dayNumber: 1,
        tag: "ConnectionClarityW1"
    )
    
    return ThemeWeekCompletionSheet(
        progress: progress,
        program: program,
        journalEntries: [],
        onRunAgain: { print("Run again") },
        onViewReflections: { print("View reflections") }
    )
    .modelContainer(container)
}
