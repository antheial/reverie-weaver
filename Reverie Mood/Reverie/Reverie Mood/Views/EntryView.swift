// COMPLETE REPLACEMENT FOR EntryView
// This is the unified, flowing design - everything in one smooth card!

import SwiftUI
import SwiftData
import Speech
import AVFoundation

struct EntryView: View {
    @Binding var selectedDay: Int?
    @Binding var currentScreen: ContentView.ScreenType
    let currentYear: Int
    
    // ✅ FIXED: Use @Query to get fresh data
    @Query private var allEntries: [MoodEntry]
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    
    // ✅ Filter entries for current year
    private var entries: [MoodEntry] {
        allEntries.filter { $0.year == currentYear }
    }
    
    // State
    @State private var selectedMood: Mood?
    @State private var reflection = ""
    @State private var emotionDescription = "" // ✨ NEW: Specific emotion descriptor
    @State private var showSuccess = false
    
    // Voice-to-text
    @State private var isRecording = false
    @State private var speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer(locale: Locale(identifier: Locale.preferredLanguages.first ?? "en-US"))
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    @State private var audioEngine = AVAudioEngine()
    @State private var pulse = false
    
    // Voice memo
    @State private var audioRecorder: AVAudioRecorder?
    @State private var isRecordingAudio = false
    @State private var recordingTimer: Timer?
    @State private var recordingDuration: TimeInterval = 0
    
    // ✨ AM/PM slot selection (no audioFileName needed - check file system directly)
    enum MemoSlot: String, CaseIterable {
        case morning = "Morning"
        case evening = "Evening"
        
        var icon: String {
            switch self {
            case .morning: return "sun.horizon.fill"
            case .evening: return "moon.stars.fill"
            }
        }
    }
    @State private var selectedSlot: MemoSlot = .evening  // Default to evening
    
    // UI helpers
    @State private var selectedPrompt: String = ""
    @State private var currentMoodIndex: Int = 3
    @GestureState private var dragOffset: CGFloat = 0  // ✅ Changed to @GestureState for performance
    @State private var lightDrift = false
    @State private var isInitialLoad = true  // ✅ For smooth loading animation
    
    // ✨ NEW: Swipe navigation
    @GestureState private var swipeOffset: CGSize = .zero
    @State private var isTransitioning = false
    @State private var gestureStartY: CGFloat? = nil
    
    // Derived
    private var currentDayEntry: MoodEntry? {
        guard let day = selectedDay else { return nil }
        return entries.first { $0.dayOfYear == day }
    }
    
    // ✨ Check for existing recordings (file system check only)
    private var hasMorningMemo: Bool {
        guard let day = selectedDay else { return false }
        let url = memoURL(year: currentYear, day: day, slot: .morning)
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    private var hasEveningMemo: Bool {
        guard let day = selectedDay else { return false }
        let url = memoURL(year: currentYear, day: day, slot: .evening)
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    // ✨ Check if current selected slot has a recording
    private var hasCurrentSlotMemo: Bool {
        guard let day = selectedDay else { return false }
        let url = memoURL(year: currentYear, day: day, slot: selectedSlot)
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    // ✅ CODE CLEANUP: Computed color properties
    private var primaryText: Color {
        colorScheme == .dark ? Color(hex: "E2E8F0") : Color(hex: "2D3748")
    }
    
    private var secondaryText: Color {
        colorScheme == .dark ? .white.opacity(0.6) : .gray
    }
    
    private var tertiaryText: Color {
        colorScheme == .dark ? .white.opacity(0.8) : Color(hex: "2D3748").opacity(0.75)
    }
    
    private var cardMaterial: Material {
        colorScheme == .dark ? .ultraThinMaterial : .thick
    }
    
    private var cardOverlay: Color {
        colorScheme == .dark ? Color.black.opacity(0.25) : Color(hex: "F9EBD6").opacity(0.4)
    }
    
    private var editorBackground: Color {
        colorScheme == .dark ? Color.black.opacity(0.18) : Color(hex: "FFF7EC").opacity(0.4)
    }
    
    private var promptColor: Color {
        colorScheme == .dark ? .white.opacity(0.55) : Color(hex: "2D3748").opacity(0.6)
    }
    
    var body: some View {
        ZStack {
            // Background
            if colorScheme == .dark {
                DarkEtherealBackground()
            } else {
                LightPaperBackground(drift: lightDrift)
            }
            
            // Mist overlay when recording
            if isRecording || isRecordingAudio {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(0.5)
                    .blur(radius: 8)
                    .ignoresSafeArea()
            }
            
            VStack(spacing: 0) {
                header
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Date section
                        if let day = selectedDay {
                            VStack(spacing: 6) {
                                Text("Day \(day)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(secondaryText)
                                Text(dateString(for: day))
                                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                                    .foregroundColor(primaryText)
                                    .shadow(color: .black.opacity(colorScheme == .dark ? 0.35 : 0.05), radius: 6, y: 3)
                            }
                            .padding(.top, 20)
                            .padding(.bottom, 24)
                        }
                        
                        // ✨ UNIFIED CARD
                        unifiedCard
                            .padding(.horizontal, 18)
                    }
                }
            }
            
            if showSuccess { successAnimation }
        }
        .offset(x: swipeOffset.width * 0.3, y: 0) // ✨ Slight parallax while swiping
        .gesture(dayNavigationGesture) // ✨ Swipe between days
        .animation(.easeInOut(duration: 0.3), value: selectedDay)
        .onAppear {
            if colorScheme == .light {
                withAnimation(.easeInOut(duration: 8)) { lightDrift = true }
            }
            loadExistingEntry()
            updateSpeechRecognizerToSystemLanguage()
        }
        .animation(.easeInOut(duration: 0.6), value: colorScheme)
        .onChange(of: selectedMood?.id) { _, _ in
            if let mood = selectedMood {
                selectedPrompt = mood.prompts.randomElement() ?? "What's on your mind?"
            }
        }
    }
    
    // MARK: - Unified Card (The Magic!)
    
    private var unifiedCard: some View {
        VStack(spacing: 0) {
            // Mood Selection Section
            VStack(spacing: 16) {
                Text("How did you feel?")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? Color(hex: "CBD5E1") : Color(hex: "4A5568"))
                    .padding(.top, 20)
                
                moodCarousel
                
                // ✨ NEW: Emotion Description Field (appears after mood selection)
                if selectedMood != nil {
                    emotionDescriptionField
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        .padding(.top, 8)
                }
                
                Spacer().frame(height: 12)
            }
            
            // ✨ MAGICAL DIVIDER appears after selection
            if selectedMood != nil {
                magicalDivider
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
            
            // ✨ Note section blooms in smoothly
            if let mood = selectedMood {
                noteSection(mood: mood)
                    .scaleEffect(selectedMood != nil ? 1.0 : 0.85)
                    .rotationEffect(.degrees(selectedMood != nil ? 0 : -3))
                    .offset(y: selectedMood != nil ? 0 : 20)
                    .opacity(selectedMood != nil ? 1.0 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: selectedMood?.id)
            }
        }
        .frame(maxWidth: 640)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(cardMaterial)
                .overlay(cardOverlay)
                .shadow(color: colorScheme == .dark ? .black.opacity(0.2) : .brown.opacity(0.1), radius: 12, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(Color.white.opacity(colorScheme == .dark ? 0.06 : 0.2), lineWidth: 1)
        )
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: selectedMood?.id)
    }
    
    // ✨ MAGICAL DIVIDER with sparkles
    private var magicalDivider: some View {
        ZStack {
            // Glowing gradient line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            .clear,
                            .purple.opacity(0.3),
                            .pink.opacity(0.3),
                            .purple.opacity(0.3),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .blur(radius: 1)
            
            // Drifting sparkles along the line
            HStack(spacing: 50) {
                ForEach(0..<5) { i in
                    Circle()
                        .fill(Color.white.opacity(0.7))
                        .frame(width: 3, height: 3)
                        .blur(radius: 1)
                        .offset(y: sin(Double(i) * 0.8) * 3)
                        .animation(
                            .easeInOut(duration: 2 + Double(i) * 0.3)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.2),
                            value: selectedMood != nil
                        )
                }
            }
        }
        .frame(height: 24)
        .padding(.vertical, 16)
    }
    
    // MARK: - Mood Carousel (✅ IMPROVED: Better Performance + Gesture Handling + Rubber-band)
    
    private var moodCarousel: some View {
        ZStack {
            ForEach(Array(Mood.allMoods.enumerated()), id: \.element.id) { index, mood in
                let position = CGFloat(index - currentMoodIndex)
                let offset = position * 100 + dragOffset  // ✅ Using dragOffset (GestureState)
                let absOffset = abs(offset)
                let isCentered = absOffset < 30
                let scale: CGFloat = isCentered ? 1.0 : max(0.65, 1.0 - absOffset / 200)
                let opacity: Double = isCentered ? 1.0 : max(0.35, 1.0 - Double(absOffset) / 180)
                let blur: CGFloat = isCentered ? 0 : min(12, absOffset / 15)
                
                VStack(spacing: 8) {
                    MoodBlob(mood: mood, size: isCentered ? 58 : 36)
                        .scaleEffect(scale)
                        .blur(radius: blur)
                        .opacity(opacity)
                        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: currentMoodIndex)
                    
                    Text(mood.name)
                        .font(.system(size: isCentered ? 14 : 11, weight: isCentered ? .semibold : .medium))
                        .foregroundColor(primaryText)
                        .opacity(opacity)
                }
                .offset(x: offset)
                .zIndex(Double(Mood.allMoods.count) - absOffset)
                .onTapGesture {
                    if isCentered {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            selectedMood = mood
                        }
                    }
                }
            }
        }
        .frame(height: 120)
        .padding(.horizontal, 20)
        .gesture(improvedDragGesture)  // ✅ Using improved gesture
    }
    
    // ✅ NEW: Improved drag gesture with rubber-band effect and better conflict handling
    private var improvedDragGesture: some Gesture {
        DragGesture()
            .updating($dragOffset) { value, state, _ in
                let translation = value.translation.width
                let horizontalMovement = abs(translation)
                let verticalMovement = abs(value.translation.height)
                
                // ✅ Only respond to horizontal drags (prevents ScrollView conflict)
                guard horizontalMovement > verticalMovement else { return }
                
                // ✅ Rubber-band effect at edges
                if currentMoodIndex == 0 && translation > 0 {
                    // At start, pulling right - add resistance
                    state = translation * 0.3
                } else if currentMoodIndex == (Mood.allMoods.count - 1) && translation < 0 {
                    // At end, pulling left - add resistance
                    state = translation * 0.3
                } else {
                    // Normal scrolling
                    state = translation
                }
            }
            .onEnded { value in
                let translation = value.translation.width
                let horizontalMovement = abs(translation)
                let verticalMovement = abs(value.translation.height)
                
                // Only process horizontal drags
                guard horizontalMovement > verticalMovement else { return }
                
                // ✅ Rubber-band snap back at edges
                if (currentMoodIndex == 0 && translation > 0) ||
                   (currentMoodIndex == (Mood.allMoods.count - 1) && translation < 0) {
                    // User tried to scroll past boundary - just haptic feedback
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    return
                }
                
                let threshold: CGFloat = 30
                let velocity = value.predictedEndTranslation.width - translation
                var newIndex = currentMoodIndex
                
                // Calculate new index based on swipe
                if abs(velocity) > 100 {
                    if velocity < 0 || translation < -threshold {
                        newIndex = min(currentMoodIndex + 1, Mood.allMoods.count - 1)
                    } else if velocity > 0 || translation > threshold {
                        newIndex = max(currentMoodIndex - 1, 0)
                    }
                }
                
                if newIndex != currentMoodIndex {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
                
                withAnimation(.interpolatingSpring(stiffness: 150, damping: 18)) {
                    currentMoodIndex = newIndex
                }
            }
    }
    
    // ✨ Emotion Description Field (Compact + Tap to Dismiss)
    private var emotionDescriptionField: some View {
        VStack(spacing: 4) {
            TextField("Describe it... (optional)", text: $emotionDescription)
                .font(.system(size: 12))
                .foregroundColor(primaryText)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(editorBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.15), lineWidth: 1)
                )
                .multilingualTextField()
                .keyboardDismissToolbar()
                .onChange(of: emotionDescription) { _, newValue in
                    if newValue.count > 30 {
                        emotionDescription = String(newValue.prefix(30))
                    }
                }

            HStack {
                Text("e.g. “anxious about work”, “tired but content”")
                    .font(.system(size: 10))
                    .foregroundColor(secondaryText.opacity(0.7))
                    .italic()
                Spacer()
                Text("\(emotionDescription.count)/30")
                    .font(.system(size: 10))
                    .foregroundColor(secondaryText.opacity(0.6))
            }
            .padding(.horizontal, 8)
        }
        .padding(.horizontal, 8)
        .padding(.top, 18)  // 👈 move down
        // 👇 Add tap-to-dismiss on the entire area
        .dismissKeyboardOnTap()
    }
    
    // ✨ NEW: Day Navigation Gesture (Swipe between days)
    private var dayNavigationGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                // Record where the gesture started
                if gestureStartY == nil {
                    gestureStartY = value.startLocation.y
                }
            }
            .updating($swipeOffset) { value, state, _ in
                // Only activate if the gesture started in the bottom half
                let screenHeight = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?
                    .screen.bounds.height ?? 0
                guard let startY = gestureStartY,
                      startY > screenHeight / 2 else { return }

                let horizontal = abs(value.translation.width)
                let vertical = abs(value.translation.height)

                if vertical > horizontal && value.translation.height > 50 {
                    state = CGSize(width: 0, height: value.translation.height)
                } else if horizontal > vertical {
                    state = CGSize(width: value.translation.width, height: 0)
                }
            }

            .onEnded { value in
                defer { gestureStartY = nil }
                let screenHeight = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?
                    .screen.bounds.height ?? 0
                guard let startY = gestureStartY,
                      startY > screenHeight / 2 else { return }

                let horizontal = abs(value.translation.width)
                let vertical = abs(value.translation.height)

                // ↓ Swipe down = Go back to year view
                if vertical > horizontal && value.translation.height > 100 {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentScreen = .year
                        selectedDay = nil
                    }
                }
                // ← Swipe left = Next day
                else if horizontal > vertical && value.translation.width < -50 {
                    navigateToDay(offset: 1)
                }
                // → Swipe right = Previous day
                else if horizontal > vertical && value.translation.width > 50 {
                    navigateToDay(offset: -1)
                }
            }
    }
    
    // MARK: - Note Section (Blooms In)
    
    private func noteSection(mood: Mood) -> some View {
        VStack(spacing: 16) {
            // ✨ IMPROVED: Better change button
            HStack {
                HStack(spacing: 8) {
                    MoodBlob(mood: mood, size: 24)
                    Text(mood.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(primaryText)
                }
                
                Spacer()
                
                // ✅ PROMINENT CHANGE BUTTON
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        selectedMood = nil
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 12))
                        Text("Change")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.purple.opacity(0.8), Color.indigo.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .shadow(color: .purple.opacity(0.3), radius: 6, y: 2)
                }
            }
            .padding(.horizontal, 22)
            
            // ✨ AM/PM Voice Memo Slot Picker (Simple & Clean)
            HStack(spacing: 12) {
                ForEach(MemoSlot.allCases, id: \.self) { slot in
                    Button(action: { selectedSlot = slot }) {
                        HStack(spacing: 6) {
                            Image(systemName: slot.icon)
                                .font(.system(size: 13))
                            Text(slot.rawValue)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(selectedSlot == slot ? .white : secondaryText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(selectedSlot == slot ?
                                    Color.blue.opacity(0.8) :
                                    editorBackground)
                        )
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
                
                // Show existing recordings indicators
                HStack(spacing: 8) {
                    if hasMorningMemo {
                        Image(systemName: "sun.horizon.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.orange.opacity(0.7))
                    }
                    if hasEveningMemo {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.purple.opacity(0.7))
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 8)
            
            // Note input header
            HStack(spacing: 10) {
                Text("Quick Note?")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(primaryText)
                Text("(optional)")
                    .font(.system(size: 11))
                    .foregroundColor(secondaryText)
                Spacer()
                voiceToTextButton
                voiceMemoButton
            }
            .padding(.horizontal, 22)
            
            // Text editor
            textEditorSection
                .padding(.horizontal, 22)
            
            characterCount
                .padding(.horizontal, 22)
            
            if hasCurrentSlotMemo {
                audioAttachmentView
                    .padding(.horizontal, 22)
            }
            
            // Save actions
            VStack(spacing: 10) {
                if !reflection.trimmingCharacters(in: .whitespaces).isEmpty {
                    Button(action: saveEntry) {
                        Text("Save with note")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(colors: [Color.purple, Color.indigo],
                                               startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .shadow(color: .purple.opacity(0.35), radius: 14, y: 6)
                    }
                }
                
                Button(action: saveEntry) {
                    Text(reflection.trimmingCharacters(in: .whitespaces).isEmpty ? "Done" : "Skip note")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.8) : .gray)
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Reusable Components (keeping your originals)
    
    private var header: some View {
        HStack {
            Button {
                currentScreen = .year
                selectedDay = nil
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(colorScheme == .dark ? Color(hex: "E2E8F0") : Color(hex: "2D3748"))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule())
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private var textEditorSection: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 18)
                .fill(cardMaterial)
                .overlay(editorBackground)
                .frame(height: 110)
                .contentShape(Rectangle())
                            .onTapGesture {
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                               to: nil, from: nil, for: nil)
                            }
            
            if reflection.isEmpty && !selectedPrompt.isEmpty {
                Text(selectedPrompt)
                    .foregroundColor(promptColor)
                    .font(.system(size: 12))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 16)
                    .allowsHitTesting(false) // ✅ Make placeholder non-interactive
            }
            
            if isRecording { recordingIndicator }
            if isRecordingAudio { audioRecordingIndicator }
            
            TextEditor(text: $reflection)
                .frame(height: 110)
                .padding(10)
                .background(Color.clear)
                .scrollContentBackground(.hidden)
                .cornerRadius(16)
                .onChange(of: reflection) { _, newValue in
                    if newValue.count > 200 { reflection = String(newValue.prefix(200)) }
                }
                .foregroundStyle(primaryText)
        }
    }
    
    private var characterCount: some View {
        HStack {
            Spacer()
            Text("\(reflection.count)/200")
                .font(.system(size: 11))
                .foregroundColor(secondaryText)
        }
    }
    
    private var recordingIndicator: some View {
        HStack(spacing: 8) {
            Circle().fill(Color.blue).frame(width: 8, height: 8)
            Text("Listening...")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.blue)
        }
        .padding(12)
    }
    
    private var audioRecordingIndicator: some View {
        HStack(spacing: 8) {
            Circle().fill(Color.red).frame(width: 8, height: 8)
            Image(systemName: selectedSlot.icon)
                .font(.system(size: 10))
                .foregroundColor(selectedSlot == .morning ? .orange : .purple)
            Text("\(selectedSlot.rawValue) • \(formatTime(recordingDuration))")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.red)
        }
        .padding(12)
    }
    
    private var voiceToTextButton: some View {
        Button(action: { isRecording ? stopRecording() : startRecording() }) {
            ZStack {
                if isRecording {
                    Circle()
                        .strokeBorder(
                            LinearGradient(colors: [.blue.opacity(0.8), .purple.opacity(0.8)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 2
                        )
                        .background(Circle().fill(Color.blue.opacity(0.18)))
                        .frame(width: 36, height: 36)
                        .scaleEffect(pulse ? 1.12 : 1.0)
                        .animation(isRecording ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true) : .default, value: pulse)
                        .onAppear { pulse = true }
                        .onDisappear { pulse = false }
                }
                Image(systemName: isRecording ? "waveform" : "mic.fill")
                    .font(.system(size: 16))
                    .foregroundColor(isRecording ? .blue : (colorScheme == .dark ? .white.opacity(0.8) : Color(hex: "2D3748").opacity(0.8)))
            }
        }
        .disabled(isRecordingAudio)
    }
    
    private var voiceMemoButton: some View {
        Button(action: { isRecordingAudio ? stopAudioRecording() : startAudioRecording() }) {
            ZStack {
                if isRecordingAudio {
                    Circle()
                        .strokeBorder(Color.red.opacity(0.9), lineWidth: 2)
                        .background(Circle().fill(Color.red.opacity(0.18)))
                        .frame(width: 36, height: 36)
                        .scaleEffect(1.1)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isRecordingAudio)
                }
                Image(systemName: isRecordingAudio ? "stop.circle.fill" : "recordingtape")
                    .font(.system(size: 16))
                    .foregroundColor(isRecordingAudio ? .red : (colorScheme == .dark ? .white.opacity(0.8) : Color(hex: "2D3748").opacity(0.8)))
            }
        }
        .disabled(isRecording)
    }
    
    private var audioAttachmentView: some View {
        HStack(spacing: 8) {
            Image(systemName: "waveform.circle.fill").foregroundColor(.pink)
            
            // ✨ Show which slot this recording is for
            HStack(spacing: 4) {
                Image(systemName: selectedSlot.icon)
                    .font(.system(size: 10))
                    .foregroundColor(selectedSlot == .morning ? .orange : .purple)
                Text("\(selectedSlot.rawValue) memo attached")
                    .font(.system(size: 12))
                    .foregroundColor(tertiaryText)
            }
            
            Spacer()
            Button(action: deleteAudioRecording) {
                Image(systemName: "trash")
                    .font(.system(size: 12))
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background((colorScheme == .dark ? Color.pink.opacity(0.12) : Color.pink.opacity(0.1)))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    private var successAnimation: some View {
        ZStack {
            ForEach(0..<3) { i in
                Circle()
                    .fill(
                        LinearGradient(colors: [Color.pink.opacity(0.6), Color.purple.opacity(0.4)],
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing)
                    )
                    .frame(width: 120 + CGFloat(i) * 20, height: 120 + CGFloat(i) * 20)
                    .blur(radius: 20)
                    .opacity(0.4 - Double(i) * 0.1)
            }
            Circle()
                .fill(LinearGradient(colors: [Color.pink, Color.purple],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 90, height: 90)
                .shadow(color: Color.pink.opacity(0.5), radius: 20, y: 10)
            Image(systemName: "checkmark")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.white)
        }
        .scaleEffect(showSuccess ? 1.0 : 0.3)
        .opacity(showSuccess ? 1.0 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.6), value: showSuccess)
    }
    
    // MARK: - Helpers (keeping all your original functions)
    
    private func dateString(for day: Int) -> String {
        let calendar = Calendar.current
        guard let startOfYear = calendar.date(from: DateComponents(year: currentYear, month: 1, day: 1)),
              let date = calendar.date(byAdding: .day, value: day - 1, to: startOfYear) else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let seconds = Int(time)
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
    
    // ✨ NEW: Navigate to adjacent day
    private func navigateToDay(offset: Int) {
        guard let currentDay = selectedDay else { return }
        let newDay = currentDay + offset
        
        // Check bounds (1-365 or 1-366 for leap years)
        let calendar = Calendar.current
        let daysInYear = calendar.range(of: .day, in: .year, for: Date())?.count ?? 365
        
        guard newDay >= 1 && newDay <= daysInYear else {
            // At boundary - just haptic feedback
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            return
        }
        
        // Save current entry if there's unsaved content
        if selectedMood != nil && (!reflection.isEmpty || !emotionDescription.isEmpty || hasCurrentSlotMemo) {
            // Auto-save before navigating
            saveEntryQuietly()
        }
        
        // Navigate to new day
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedDay = newDay
            loadExistingEntry()
        }
    }
    
    private func saveEntry() {
        guard let day = selectedDay, let mood = selectedMood else { return }
        
        if isRecording { stopRecording() }
        if isRecordingAudio { stopAudioRecording() }
        
        // ✨ Combine emotion description with reflection
        var combinedReflection = reflection.trimmingCharacters(in: .whitespaces)
        if !emotionDescription.isEmpty {
            combinedReflection = "[emotion: \(emotionDescription)]" + (combinedReflection.isEmpty ? "" : " \(combinedReflection)")
        }
        
        // ✅ Non-destructive save: Update existing or create new
        if let existing = currentDayEntry {
            existing.moodId = mood.id
            existing.moodName = mood.name
            existing.moodColor = mood.color.toHex()
            existing.reflection = combinedReflection
            existing.date = Date()
        } else {
            let entry = MoodEntry(
                dayOfYear: day,
                moodId: mood.id,
                moodName: mood.name,
                moodColor: mood.color.toHex(),
                reflection: combinedReflection,
                date: Date(),
                year: currentYear
            )
            modelContext.insert(entry)
        }
        
        // ✅ CRITICAL FIX: Save the context to persist changes immediately
        do {
            try modelContext.save()
            print("✅ Entry saved successfully!")
        } catch {
            print("❌ Failed to save entry: \(error)")
        }
        
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        
        showSuccess = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            showSuccess = false
            currentScreen = .year
            selectedDay = nil
        }
    }
    
    // ✨ NEW: Save entry without navigation (for auto-save when swiping)
    private func saveEntryQuietly() {
        guard let day = selectedDay, let mood = selectedMood else { return }
        
        if isRecording { stopRecording() }
        if isRecordingAudio { stopAudioRecording() }
        
        // ✨ Combine emotion description with reflection
        var combinedReflection = reflection.trimmingCharacters(in: .whitespaces)
        if !emotionDescription.isEmpty {
            combinedReflection = "[emotion: \(emotionDescription)]" + (combinedReflection.isEmpty ? "" : " \(combinedReflection)")
        }
        
        // ✅ Non-destructive save: Update existing or create new
        if let existing = currentDayEntry {
            existing.moodId = mood.id
            existing.moodName = mood.name
            existing.moodColor = mood.color.toHex()
            existing.reflection = combinedReflection
            existing.date = Date()
        } else {
            let entry = MoodEntry(
                dayOfYear: day,
                moodId: mood.id,
                moodName: mood.name,
                moodColor: mood.color.toHex(),
                reflection: combinedReflection,
                date: Date(),
                year: currentYear
            )
            modelContext.insert(entry)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("❌ Failed to auto-save entry: \(error)")
        }
    }
    
    private func recordingsContainerURL() -> URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.yourname.moodapp")?
            .appendingPathComponent("Recordings", isDirectory: true)
    }
    
    // ✨ Generate deterministic URL for AM/PM memos
    private func memoURL(year: Int, day: Int, slot: MemoSlot) -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let folder = docs.appendingPathComponent("Recordings", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        
        let slotName = slot == .morning ? "morning" : "evening"
        let filename = String(format: "moodmemo_%d_%03d_%@.m4a", year, day, slotName)
        return folder.appendingPathComponent(filename)
    }
    
    private func startAudioRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try audioSession.overrideOutputAudioPort(.speaker)
            try audioSession.setActive(true)
            
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            // ✨ Use deterministic filename based on selected slot
            guard let day = selectedDay else {
                print("❌ No day selected")
                return
            }
            
            let fileURL = memoURL(year: currentYear, day: day, slot: selectedSlot)
            
            // If file exists, we're overwriting
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try? FileManager.default.removeItem(at: fileURL)
            }
            
            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()
            
            isRecordingAudio = true
            recordingDuration = 0
            
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                self.recordingDuration += 0.1
                if self.recordingDuration >= 60 {
                    self.stopAudioRecording()
                }
            }
            
            print("🎙 Recording started at:", fileURL.path)
        } catch {
            print("❌ Audio recording error:", error)
            isRecordingAudio = false
        }
    }
    
    private func stopAudioRecording() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        if let recorder = audioRecorder {
            if recorder.isRecording {
                recorder.stop()
            }
            audioRecorder = nil
        }
        
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("⚠️ Failed to deactivate audio session:", error)
        }
        
        isRecordingAudio = false
        print("🛑 Recording stopped after \(formatTime(recordingDuration))s")
    }
    
    private func deleteAudioRecording() {
        guard let day = selectedDay else { return }
        let fileURL = memoURL(year: currentYear, day: day, slot: selectedSlot)
        
        if audioRecorder?.url == fileURL {
            stopAudioRecording()
        }
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                try FileManager.default.removeItem(at: fileURL)
                print("🗑 Deleted recording:", fileURL.lastPathComponent)
            } catch {
                print("⚠️ Failed to delete file:", error)
            }
        }
    }
    
    private func updateSpeechRecognizerToSystemLanguage() {
        let localeId = Locale.preferredLanguages.first ?? "en-US"
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: localeId))
    }
    
    private func startRecording() {
        recognitionTask?.cancel(); recognitionTask = nil
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session error: \(error)")
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputNode.outputFormat(forBus: 0)) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            DispatchQueue.main.async {
                if let result = result {
                    self.reflection = String(result.bestTranscription.formattedString.prefix(200))
                }
                if error != nil || (result?.isFinal ?? false) {
                    self.stopRecording()
                }
            }
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
            isRecording = true
        } catch {
            print("Audio engine start error: \(error)")
            isRecording = false
        }
    }
    
    private func stopRecording() {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
    }
    
    private func loadExistingEntry() {
        // Reset state
        emotionDescription = ""
        reflection = ""
        selectedMood = nil
        
        if let entry = currentDayEntry {
            if let mood = Mood.allMoods.first(where: { $0.id == entry.moodId }) {
                selectedMood = mood
                if let idx = Mood.allMoods.firstIndex(where: { $0.id == mood.id }) {
                    currentMoodIndex = idx
                }
            }
            
            // ✨ Parse emotion description from reflection
            let fullReflection = entry.reflection
            if fullReflection.hasPrefix("[emotion: ") {
                if let endIndex = fullReflection.firstIndex(of: "]") {
                    let startIndex = fullReflection.index(fullReflection.startIndex, offsetBy: 10) // "[emotion: ".count
                    emotionDescription = String(fullReflection[startIndex..<endIndex])
                    
                    // Get the rest after the bracket
                    let afterBracket = fullReflection.index(after: endIndex)
                    if afterBracket < fullReflection.endIndex {
                        reflection = String(fullReflection[afterBracket...]).trimmingCharacters(in: .whitespaces)
                    }
                } else {
                    reflection = fullReflection
                }
            } else {
                reflection = fullReflection
            }
            
            // Note: We don't load audioFileName anymore - we check file system directly
            // using hasCurrentSlotMemo computed property
        }
        if let mood = selectedMood {
            selectedPrompt = mood.prompts.randomElement() ?? "What's on your mind?"
        }
    }
}
