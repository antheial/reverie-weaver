//
// ReflectionSheet.swift
// ReverieWeaver
//
// Reflection journal after completing a habit with photo support
// Updated with SF Symbols and consistent styling

import SwiftUI
import SwiftData
import PhotosUI

struct ReflectionSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allCompletions: [HabitCompletion] // For photo count
    @StateObject private var localization = LocalizationManager.shared
    
    let habit: Habit
    let completion: HabitCompletion
    let onDismiss: () -> Void
    
    @State private var mood = "Neutral"
    @State private var notes = ""
    @State private var isFavorite = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var showPhotoLimitWarning = false
    
    // UPDATED: SF Symbol moods matching the app's aesthetic
    private let moods = [
        ("Energized", "bolt.fill", "Feeling motivated and ready"),
        ("Calm", "leaf.fill", "Peaceful and centered"),
        ("Neutral", "circle.fill", "Steady and balanced"),
        ("Tired", "moon.fill", "Need rest and recovery"),
        ("Stressed", "cloud.fill", "Feeling overwhelmed")
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header prompt
                    Text("How are you different after completing this?")
                        .font(.system(size: 13, weight: .regular))
                        .fontDesign(.serif)
                        .italic()
                        .foregroundStyle(Color.dynamicSecondaryLabel)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Mood selector with SF Symbols
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: "face.smiling")
                                .font(.system(size: 12))
                                .foregroundStyle(Color(hex: habit.colorHex))
                            Text("How did it feel?")
                                .font(.system(size: 12, weight: .regular))
                                .fontDesign(.serif)
                                .foregroundStyle(Color.dynamicLabel)
                        }
                        
                        VStack(spacing: 8) {
                            ForEach(moods, id: \.0) { moodOption in
                                Button {
                                    mood = moodOption.0
                                } label: {
                                    HStack(spacing: 12) {
                                        // SF Symbol icon instead of emoji
                                        Image(systemName: moodOption.1)
                                            .font(.system(size: 16))
                                            .foregroundStyle(Color(hex: habit.colorHex))
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(moodOption.0)
                                                .font(.system(size: 12, weight: .medium))
                                                .fontDesign(.serif)
                                                .foregroundStyle(Color.dynamicLabel)
                                            
                                            Text(moodOption.2)
                                                .font(.system(size: 10, weight: .regular))
                                                .fontDesign(.serif)
                                                .foregroundStyle(Color.dynamicSecondaryLabel)
                                        }
                                        
                                        Spacer()
                                        
                                        if mood == moodOption.0 {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 16))
                                                .foregroundStyle(Color(hex: habit.colorHex))
                                        }
                                    }
                                    .padding(14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(mood == moodOption.0 ? Color(hex: habit.colorHex).opacity(0.1) : Color.white.opacity(0.3))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(
                                                mood == moodOption.0 ? Color(hex: habit.colorHex) : Color.clear,
                                                lineWidth: 1.5
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "text.alignleft")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.dynamicSecondaryLabel)
                            Text("Your Thoughts")
                                .font(.system(size: 12, weight: .regular))
                                .fontDesign(.serif)
                                .foregroundStyle(Color.dynamicLabel)
                        }
                        
                        TextField("Write what comes to mind...", text: $notes, axis: .vertical)
                            .multilingualTextField()
                            .textFieldStyle(.plain)
                            .font(.system(size: 12, weight: .regular))
                            .fontDesign(.serif)
                            .foregroundStyle(Color.dynamicLabel)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.45))
                                    .shadow(color: Color.shadowColor, radius: 6, y: 2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color.white.opacity(0.4), lineWidth: 1)
                            )
                            .lineLimit(4...8)
                    }
                    
                    // Photo picker
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.dynamicSecondaryLabel)
                            
                            Text("Add a Photo (optional)")
                                .font(.system(size: 12, weight: .regular))
                                .fontDesign(.serif)
                                .foregroundStyle(Color.dynamicLabel)
                            
                            Spacer()
                            
                            Text("\(getMonthPhotoCount())/20")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(getMonthPhotoCount() >= 20 ? Color.red : Color.dynamicSecondaryLabel)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(getMonthPhotoCount() >= 20 ? Color.red.opacity(0.1) : Color.white.opacity(0.3))
                                .clipShape(Capsule())
                            
                            if photoData != nil {
                                Button {
                                    photoData = nil
                                    selectedPhoto = nil
                                } label: {
                                    Text("Remove")
                                        .font(.system(size: 11, weight: .medium))
                                        .fontDesign(.serif)
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                        
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            if let photoData = photoData, let uiImage = UIImage(data: photoData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 160)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(Color(hex: habit.colorHex).opacity(0.3), lineWidth: 2)
                                    )
                            } else {
                                VStack(spacing: 12) {
                                    Image(systemName: "photo.on.rectangle.angled")
                                        .font(.system(size: 32))
                                        .foregroundStyle(Color.dynamicSecondaryLabel)
                                    Text("Tap to add photo")
                                        .font(.system(size: 12, weight: .regular))
                                        .fontDesign(.serif)
                                        .foregroundStyle(Color.dynamicSecondaryLabel)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 120)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.3))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                                        .foregroundStyle(Color.dynamicSecondaryLabel.opacity(0.3))
                                )
                            }
                        }
                        .onChange(of: selectedPhoto) { _, newValue in
                            Task {
                                if !checkPhotoLimit() {
                                    selectedPhoto = nil
                                    return
                                }
                                
                                if let data = try? await newValue?.loadTransferable(type: Data.self) {
                                    if let uiImage = UIImage(data: data) {
                                        let resizedImage = resizeImageIfNeeded(uiImage)
                                        if let compressedData = resizedImage.jpegData(compressionQuality: 0.6) {
                                            if compressedData.count > 500_000 {
                                                photoData = resizedImage.jpegData(compressionQuality: 0.4)
                                            } else {
                                                photoData = compressedData
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // Favorite toggle
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle(isOn: $isFavorite) {
                            HStack(spacing: 8) {
                                Image(systemName: isFavorite ? "heart.fill" : "heart")
                                    .foregroundStyle(isFavorite ? Color.paleMauve : Color.dynamicSecondaryLabel)
                                    .font(.system(size: 14))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Mark as favorite")
                                        .font(.system(size: 12, weight: .medium))
                                        .fontDesign(.serif)
                                        .foregroundStyle(Color.dynamicLabel)
                                    
                                    Text("View all favorites in Archive")
                                        .font(.system(size: 10, weight: .regular))
                                        .fontDesign(.serif)
                                        .foregroundStyle(Color.dynamicSecondaryLabel)
                                }
                            }
                        }
                        .tint(Color.paleMauve)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isFavorite ? Color.paleMauve.opacity(0.1) : Color.white.opacity(0.3))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(
                                    isFavorite ? Color.paleMauve : Color.clear,
                                    lineWidth: 1.5
                                )
                        )
                    }
                }
                .padding(24)
                .dismissKeyboardOnBackgroundTap()
            }
            .background(ReverieWeaverBackground())
            .navigationTitle("Reflect on \(habit.name)")
            .navigationBarTitleDisplayMode(.inline)
            .keyboardDismissToolbar()
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Reflect on \(habit.name)")
                        .font(.system(size: 13, weight: .semibold))
                        .fontDesign(.serif)
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") {
                        onDismiss()
                    }
                    .font(.system(size: 12, weight: .regular))
                    .fontDesign(.serif)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveReflection()
                    }
                    .font(.system(size: 12, weight: .medium))
                    .fontDesign(.serif)
                }
            }
        }
        .presentationDetents([.fraction(0.8)])
        .presentationDragIndicator(.visible)
        .alert("Photo Limit Reached", isPresented: $showPhotoLimitWarning) {
            Button("OK") { }
        } message: {
            Text("You've added 20 photos this month. To manage storage, consider adding fewer photos or clearing old reflections in Settings.")
        }
        .onAppear {
            // Load existing reflection if any
            if let existingReflection = completion.reflection {
                mood = existingReflection.mood
                notes = existingReflection.notes
                isFavorite = existingReflection.isFavorite
                photoData = existingReflection.photoData
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func saveReflection() {
        if let existingReflection = completion.reflection {
            // UPDATE existing reflection
            existingReflection.mood = mood
            existingReflection.notes = notes
            existingReflection.isFavorite = isFavorite
            existingReflection.photoData = photoData
            print("✅ Updated existing reflection - Favorite: \(isFavorite)")
        } else {
            // CREATE new reflection
            let reflection = Reflection(
                mood: mood,
                notes: notes,
                isFavorite: isFavorite,
                photoData: photoData,
                habitId: habit.id,
                habitName: habit.name,
                habitColorHex: habit.colorHex
            )
            
            // Insert into context
            modelContext.insert(reflection)
            
            // Link to the passed completion
            completion.reflection = reflection
            print("✅ Created and linked reflection to completion for \(habit.name)")
            print("✅ Favorite status: \(isFavorite)")
            print("✅ Has photo: \(photoData != nil)")
        }
        
        // Force save the context
        do {
            try modelContext.save()
            print("✅ Reflection saved successfully")
        } catch {
            print("❌ Error saving reflection: \(error)")
        }
        
        dismiss()
        onDismiss()
    }
    
    private func resizeImageIfNeeded(_ image: UIImage) -> UIImage {
        let maxWidth: CGFloat = 1200
        guard image.size.width > maxWidth else { return image }
        
        let scale = maxWidth / image.size.width
        let newHeight = image.size.height * scale
        let newSize = CGSize(width: maxWidth, height: newHeight)
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    private func getMonthPhotoCount() -> Int {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
        
        let thisMonthPhotos = allCompletions.filter { completion in
            guard let reflection = completion.reflection,
                  reflection.photoData != nil else { return false }
            return reflection.createdAt >= startOfMonth && reflection.createdAt <= endOfMonth
        }
        
        return thisMonthPhotos.count
    }
    
    private func checkPhotoLimit() -> Bool {
        let monthCount = getMonthPhotoCount()
        
        if monthCount >= 20 {
            showPhotoLimitWarning = true
            return false
        }
        
        return true
    }
}
