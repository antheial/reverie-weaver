//
//  ViewEntryView.swift
//  Mood App
//
//  ✅ UPDATED ViewEntryView - Deterministic Audio File Lookup + AM/PM playback
//  - Uses year_day_slot.m4a naming instead of database audioFileName
//  - Morning shown first (sun.max.fill), then Evening (moon.stars.fill)
//  - Leap-year safe navigation using currentYear
//  - Year-scoped @Query via custom init (no in-memory filtering)
//

import SwiftUI
import SwiftData
import AVFoundation
import Combine

struct ViewEntryView: View {
    @Binding var selectedDay: Int?
    @Binding var currentScreen: ContentView.ScreenType
    let currentYear: Int

    // ✅ Year-scoped @Query
    @Query private var entries: [MoodEntry]

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @State private var lightDrift = false

    // Audio playback
    @State private var audioPlayerMorning: AVAudioPlayer?
    @State private var audioPlayerEvening: AVAudioPlayer?
    @State private var isPlayingMorning = false
    @State private var isPlayingEvening = false

    // Swipe navigation
    @GestureState private var swipeOffset: CGSize = .zero

    // ✅ Custom init for year-scoped query
    init(selectedDay: Binding<Int?>, currentScreen: Binding<ContentView.ScreenType>, currentYear: Int) {
        self._selectedDay = selectedDay
        self._currentScreen = currentScreen
        self.currentYear = currentYear
        self._entries = Query(
            filter: #Predicate<MoodEntry> { $0.year == currentYear },
            sort: [SortDescriptor(\MoodEntry.dayOfYear)]
        )
    }

    // MARK: - Computed Entry

    private var entry: MoodEntry? {
        guard let day = selectedDay else { return nil }
        return entries.first { $0.dayOfYear == day }
    }

    private var mood: Mood? {
        guard let entry = entry else { return nil }
        return Mood.allMoods.first { $0.id == entry.moodId }
    }

    // Parse emotion description and reflection
    private var parsedReflection: (emotion: String?, text: String) {
        guard let entry = entry else { return (nil, "") }
        let full = entry.reflection

        if full.hasPrefix("[emotion: ") {
            if let end = full.firstIndex(of: "]") {
                let start = full.index(full.startIndex, offsetBy: 10)
                let emotion = String(full[start..<end])

                let after = full.index(after: end)
                let text = after < full.endIndex
                    ? String(full[after...]).trimmingCharacters(in: .whitespaces)
                    : ""
                return (emotion, text)
            }
        }
        return (nil, full)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            if colorScheme == .dark {
                DarkEtherealBackground()
            } else {
                LightPaperBackground(drift: lightDrift)
            }

            VStack(spacing: 20) {
                // Header
                headerSection

                Spacer()

                // Entry Content
                VStack(spacing: 24) {
                    // Date Section
                    if let day = selectedDay {
                        VStack(spacing: 6) {
                            Text("Day \(day)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .gray)

                            Text(dateString(for: day))
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.9) : Color(hex: "2D3748"))
                        }
                    }

                    // Mood Blob
                    if let moodValue = mood {
                        MoodBlob(mood: moodValue, size: 70)
                            .shadow(color: colorScheme == .dark ? .white.opacity(0.2) : .gray.opacity(0.3),
                                    radius: 10, y: 4)
                    }

                    // Reflection Text
                    reflectionSection

                    // ✅ AM/PM Voice Memo Playback (morning first)
                    voiceMemoPlaybackSection

                    Spacer()

                    // Edit Button
                    editButton
                }
            }
        }
        .offset(x: swipeOffset.width * 0.3, y: 0)
        .gesture(dayNavigationGesture)
        .animation(.easeInOut(duration: 0.3), value: selectedDay)
        .onAppear {
            if colorScheme == .light {
                withAnimation(.easeInOut(duration: 8)) { lightDrift = true }
            }
        }
        .onDisappear {
            stopAllPlayback()
        }
        .animation(.easeInOut(duration: 0.6), value: colorScheme)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Button(action: {
                currentScreen = .year
                selectedDay = nil
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.85) : Color(hex: "2D3748"))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial.opacity(0.5))
                .cornerRadius(12)
            }

            Spacer()

            if let entry = entry {
                Button(action: { deleteEntry(entry) }) {
                    Text("Clear")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.red.opacity(0.8))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial.opacity(0.4))
                        .cornerRadius(10)
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }

    // MARK: - Reflection Section

    private var reflectionSection: some View {
        VStack(spacing: 16) {
            if let _ = entry {
                let parsed = parsedReflection

                // Emotion Description (if exists)
                if let emotion = parsed.emotion {
                    Text(emotion)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.85) : Color(hex: "2D3748"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial.opacity(0.5))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(colorScheme == .dark ? 0.1 : 0.2), lineWidth: 1)
                        )
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                }

                // Reflection Text
                if !parsed.text.isEmpty {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        colorScheme == .dark
                                            ? Color.purple.opacity(0.25)
                                            : Color.white.opacity(0.7),
                                        .clear
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 150
                                )
                            )
                            .frame(width: 300, height: 300)
                            .blur(radius: 40)
                            .opacity(0.6)

                        Text(parsed.text)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.9) : Color(hex: "2D3748"))
                            .multilineTextAlignment(.center)
                            .lineSpacing(6)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 24)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.ultraThinMaterial.opacity(colorScheme == .dark ? 0.4 : 0.6))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(colorScheme == .dark ? 0.1 : 0.25), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
    }

    // MARK: - ✅ Voice Memo Playback Section

    private var voiceMemoPlaybackSection: some View {
        VStack(spacing: 12) {
            if hasMorningMemo() || hasEveningMemo() {
                Text("Voice Memos")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .gray)

                HStack(spacing: 12) {
                    // Morning Memo (top / left)
                    if hasMorningMemo() {
                        voiceMemoButton(
                            slot: .morning,
                            icon: "sun.max.fill",
                            title: "Morning",
                            color: .orange,
                            isPlaying: isPlayingMorning,
                            onPlay: { togglePlayback(slot: .morning) },
                            onDelete: { deleteVoiceMemo(slot: .morning) }
                        )
                    }

                    // Evening Memo
                    if hasEveningMemo() {
                        voiceMemoButton(
                            slot: .evening,
                            icon: "moon.stars.fill",
                            title: "Evening",
                            color: .purple,
                            isPlaying: isPlayingEvening,
                            onPlay: { togglePlayback(slot: .evening) },
                            onDelete: { deleteVoiceMemo(slot: .evening) }
                        )
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }

    private func voiceMemoButton(
        slot: MemoSlot,
        icon: String,
        title: String,
        color: Color,
        isPlaying: Bool,
        onPlay: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)

                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.85) : Color(hex: "2D3748"))

                Spacer()
            }

            HStack(spacing: 8) {
                Button(action: onPlay) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(color)
                }

                Spacer()

                Button(action: onDelete) {
                    Image(systemName: "trash.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.red.opacity(0.7))
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial.opacity(colorScheme == .dark ? 0.4 : 0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(colorScheme == .dark ? 0.1 : 0.2), lineWidth: 1)
        )
    }

    // MARK: - Edit Button

    private var editButton: some View {
        Button(action: {
            currentScreen = .entry
        }) {
            Text("Edit")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.purple)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(.ultraThinMaterial.opacity(0.6))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.purple.opacity(0.3), lineWidth: 2)
                )
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }

    // MARK: - Day Navigation Gesture

    private var dayNavigationGesture: some Gesture {
        DragGesture()
            .updating($swipeOffset) { value, state, _ in
                let h = abs(value.translation.width)
                let v = abs(value.translation.height)

                if v > h && value.translation.height > 50 {
                    state = CGSize(width: 0, height: value.translation.height)
                } else if h > v {
                    state = CGSize(width: value.translation.width, height: 0)
                }
            }
            .onEnded { value in
                let h = abs(value.translation.width)
                let v = abs(value.translation.height)

                if v > h && value.translation.height > 100 {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentScreen = .year
                        selectedDay = nil
                    }
                } else if h > v && value.translation.width < -50 {
                    navigateToDay(offset: 1)
                } else if h > v && value.translation.width > 50 {
                    navigateToDay(offset: -1)
                }
            }
    }

    // ✅ Leap-year safe nav
    private func navigateToDay(offset: Int) {
        guard let currentDay = selectedDay else { return }
        let newDay = currentDay + offset

        let cal = Calendar.current
        let jan1 = cal.date(from: DateComponents(year: currentYear, month: 1, day: 1))!
        let daysInYear = cal.range(of: .day, in: .year, for: jan1)?.count ?? 365

        guard newDay >= 1 && newDay <= daysInYear else {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            return
        }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedDay = newDay
        }
    }

    // MARK: - ✅ Audio Helper Methods (Deterministic Lookup)

    private enum MemoSlot { case morning, evening }

    private func memoURL(year: Int, day: Int, slot: MemoSlot) -> URL {
        let filename = "moodmemo_\(year)_\(day)_\(slot == .morning ? "morning" : "evening").m4a"
        return recordingsDirectory().appendingPathComponent(filename)
    }

    private func recordingsDirectory() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = docs.appendingPathComponent("Recordings", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func hasMorningMemo() -> Bool {
        guard let day = selectedDay else { return false }
        return FileManager.default.fileExists(atPath: memoURL(year: currentYear, day: day, slot: .morning).path)
    }

    private func hasEveningMemo() -> Bool {
        guard let day = selectedDay else { return false }
        return FileManager.default.fileExists(atPath: memoURL(year: currentYear, day: day, slot: .evening).path)
    }

    // MARK: - Playback

    private func togglePlayback(slot: MemoSlot) {
        if (slot == .morning && isPlayingMorning) || (slot == .evening && isPlayingEvening) {
            stopPlayback(slot: slot)
        } else {
            startPlayback(slot: slot)
        }
    }

    private func startPlayback(slot: MemoSlot) {
        guard let day = selectedDay else { return }

        let url = memoURL(year: currentYear, day: day, slot: slot)
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("❌ Voice memo not found:", url.path)
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)

            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            player.play()

            if slot == .morning {
                audioPlayerMorning = player
                isPlayingMorning = true
            } else {
                audioPlayerEvening = player
                isPlayingEvening = true
            }

            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            print("▶️ Playing:", url.lastPathComponent)
        } catch {
            print("❌ Playback error:", error)
        }
    }

    private func stopPlayback(slot: MemoSlot) {
        if slot == .morning {
            audioPlayerMorning?.stop()
            audioPlayerMorning = nil
            isPlayingMorning = false
        } else {
            audioPlayerEvening?.stop()
            audioPlayerEvening = nil
            isPlayingEvening = false
        }
    }

    private func stopAllPlayback() {
        stopPlayback(slot: .morning)
        stopPlayback(slot: .evening)
    }

    private func deleteVoiceMemo(slot: MemoSlot) {
        guard let day = selectedDay else { return }

        let url = memoURL(year: currentYear, day: day, slot: slot)
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.removeItem(at: url)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                print("🗑 Deleted:", url.lastPathComponent)
            } catch {
                print("❌ Delete error:", error)
            }
        }
    }

    // MARK: - Delete Entry

    private func deleteEntry(_ entry: MoodEntry) {
        // Also delete AM/PM memos for this day
        if let _ = selectedDay {
            deleteVoiceMemo(slot: .morning)
            deleteVoiceMemo(slot: .evening)
        }

        modelContext.delete(entry)

        do {
            try modelContext.save()
            print("✅ Entry deleted")
        } catch {
            print("❌ Failed to delete entry:", error)
        }

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        currentScreen = .year
        selectedDay = nil
    }

    // MARK: - Helpers

    private func dateString(for day: Int) -> String {
        let calendar = Calendar.current
        guard let startOfYear = calendar.date(from: DateComponents(year: currentYear, month: 1, day: 1)),
              let date = calendar.date(byAdding: .day, value: day - 1, to: startOfYear) else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date)
    }
}
