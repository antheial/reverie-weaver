//
// ReflectionSheet.swift
// ReverieWeaver
//
// Reflection journal after completing a habit with MULTI-photo support
// Updated with photo quota management and journal-style photo previews
// Shows saved photos as cards with "Add another photo" button

import SwiftUI
import SwiftData
import PhotosUI

struct ReflectionSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @StateObject private var localization = LocalizationManager.shared
    @StateObject private var quotaManager = PhotoQuotaManager.shared
    
    let habit: Habit
    let completion: HabitCompletion
    let onDismiss: () -> Void
    
    @State private var mood = "Neutral"
    @State private var notes = ""
    @State private var isFavorite = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photosData: [Data] = []
    @State private var showPhotoLimitWarning = false
    
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
                    Text("How are you different after completing this?")
                        .font(.system(size: 13, weight: .regular))
                        .fontDesign(.serif)
                        .italic()
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Mood selector with SF Symbols
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: "face.smiling")
                                .font(.system(size: 13))
                                .foregroundStyle(Color(hex: habit.colorHex))
                            Text("How did it feel?")
                                .font(.system(size: 13, weight: .regular))
                                .fontDesign(.serif)
                                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                        }
                        
                        VStack(spacing: 8) {
                            ForEach(moods, id: \.0) { moodOption in
                                Button {
                                    mood = moodOption.0
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: moodOption.1)
                                            .font(.system(size: 16))
                                            .foregroundStyle(Color(hex: habit.colorHex))
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(moodOption.0)
                                                .font(.system(size: 13, weight: .medium))
                                                .fontDesign(.serif)
                                                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                                            
                                            Text(moodOption.2)
                                                .font(.system(size: 11, weight: .regular))
                                                .fontDesign(.serif)
                                                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
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
                                            .fill(mood == moodOption.0 ? Color(hex: habit.colorHex).opacity(0.1) : Color.white.opacity(0.2))
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
                                .font(.system(size: 13))
                                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                            Text("Your Thoughts")
                                .font(.system(size: 13, weight: .regular))
                                .fontDesign(.serif)
                                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                        }
                        
                        TextField("Write what comes to mind...", text: $notes, axis: .vertical)
                            .multilingualTextField()
                            .textFieldStyle(.plain)
                            .font(.system(size: 13, weight: .regular))
                            .fontDesign(.serif)
                            .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.20))
                                    .shadow(color: Color.shadowColor, radius: 6, y: 2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color.white.opacity(0.20), lineWidth: 1)
                            )
                            .lineLimit(4...8)
                    }
                    
                    // Multi-photo section with journal-style previews
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 13))
                                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                            
                            Text("Photos (optional)")
                                .font(.system(size: 13, weight: .regular))
                                .fontDesign(.serif)
                                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                            
                            Spacer()
                            
                            // Photo quota badge (only shows at 80% capacity)
                            PhotoQuotaBadge()
                        }
                        
                        // Journal-style preview cards
                        if !photosData.isEmpty {
                            VStack(spacing: 12) {
                                ForEach(Array(photosData.enumerated()), id: \.offset) { index, photoData in
                                    if let uiImage = UIImage(data: photoData) {
                                        PhotoPreviewCard(
                                            image: uiImage,
                                            index: index + 1,
                                            total: photosData.count,
                                            habitColor: Color(hex: habit.colorHex),
                                            onRemove: {
                                                removePhoto(at: index)
                                            }
                                        )
                                    }
                                }
                            }
                        }
                        
                        // ADD PHOTO BUTTON
                        PhotosPickerButton(
                            hasExistingPhotos: !photosData.isEmpty,
                            isAtLimit: quotaManager.isAtLimit,
                            habitColor: Color(hex: habit.colorHex),
                            selectedPhoto: $selectedPhoto
                        )
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
                                        .font(.system(size: 13, weight: .medium))
                                        .fontDesign(.serif)
                                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                                    
                                    Text("View all favorites in Archive")
                                        .font(.system(size: 11, weight: .regular))
                                        .fontDesign(.serif)
                                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                                }
                            }
                        }
                        .tint(Color.paleMauve)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isFavorite ? Color.paleMauve.opacity(0.1) : Color.white.opacity(0.2))
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
                    .font(.system(size: 13, weight: .regular))
                    .fontDesign(.serif)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveReflection()
                    }
                    .font(.system(size: 13, weight: .medium))
                    .fontDesign(.serif)
                }
            }
        }
        .presentationDetents([.fraction(0.8)])
        .presentationDragIndicator(.visible)
        .photoLimitAlert(isPresented: $showPhotoLimitWarning)
        .onChange(of: selectedPhoto) { _, newItem in
            Task {
                await loadPhoto(from: newItem)
            }
        }
        .onAppear {
            // Load existing reflection if any
            if let existingReflection = completion.reflection {
                mood = existingReflection.mood
                notes = existingReflection.notes
                isFavorite = existingReflection.isFavorite
                photosData = existingReflection.photosData
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
            existingReflection.photosData = photosData
            print("✅ Updated existing reflection - Favorite: \(isFavorite), Photos: \(photosData.count)")
        } else {
            // CREATE new reflection
            let reflection = Reflection(
                mood: mood,
                notes: notes,
                isFavorite: isFavorite,
                photosData: photosData,
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
            print("✅ Photos count: \(photosData.count)")
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
    
    /// Load photo from PhotosPicker
    private func loadPhoto(from item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        // Check quota before loading
        guard quotaManager.canAddPhoto() else {
            showPhotoLimitWarning = true
            selectedPhoto = nil
            return
        }
        
        // Load the image data
        if let data = try? await item.loadTransferable(type: Data.self),
           let uiImage = UIImage(data: data) {
            
            // Resize and compress for performance
            let resized = resizeImageIfNeeded(uiImage)
            
            if let compressedData = resized.jpegData(compressionQuality: 0.8) {
                await MainActor.run {
                    photosData.append(compressedData)
                    quotaManager.recordPhotoAdded()
                    selectedPhoto = nil
                    print("📸 Photo added - Total: \(photosData.count)")
                }
            }
        }
    }
    
    /// Remove photo from array
    private func removePhoto(at index: Int) {
        guard index < photosData.count else { return }
        photosData.remove(at: index)
        quotaManager.recordPhotoRemoved()
        print("🗑️ Photo removed - Remaining: \(photosData.count)")
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
}

// MARK: - Supporting Views

/// Journal-style photo preview card with remove button
struct PhotoPreviewCard: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let image: UIImage
    let index: Int
    let total: Int
    let habitColor: Color
    let onRemove: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "photo.fill")
                    .font(.system(size: 12))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                
                Text("Photo \(index)")
                    .font(.system(size: 12, weight: .medium))
                    .fontDesign(.serif)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                
                Spacer()
                
                Button(action: onRemove) {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                        Text("Remove")
                            .font(.system(size: 12, weight: .medium))
                            .fontDesign(.serif)
                    }
                    .foregroundStyle(.red)
                }
            }
            
            // Photo preview
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                )
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.2))
        )
    }
}

/// Photo picker button with conditional styling
struct PhotosPickerButton: View {
    let hasExistingPhotos: Bool
    let isAtLimit: Bool
    let habitColor: Color
    @Binding var selectedPhoto: PhotosPickerItem?
    
    var body: some View {
        PhotosPicker(selection: $selectedPhoto, matching: .images) {
            HStack(spacing: 8) {
                Image(systemName: hasExistingPhotos ? "plus.circle" : "camera")
                    .font(.system(size: 14))
                    .foregroundStyle(isAtLimit ? Color.dynamicSecondaryLabel : habitColor)
                
                Text(hasExistingPhotos ? "Add another photo" : "Add a photo")
                    .font(.system(size: 13, weight: .medium))
                    .fontDesign(.serif)
                    .foregroundStyle(isAtLimit ? Color.dynamicSecondaryLabel : Color.dynamicLabel)
            }
            .frame(maxWidth: .infinity)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                isAtLimit ? Color.clear : Color.white.opacity(0.2),
                                style: StrokeStyle(lineWidth: 1.5, dash: [4, 4])
                            )
                    )
            )
        }
        .disabled(isAtLimit)
        .opacity(isAtLimit ? 0.5 : 1.0)
    }
}
