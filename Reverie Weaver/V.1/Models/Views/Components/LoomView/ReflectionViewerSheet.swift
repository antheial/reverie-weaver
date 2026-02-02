//
// ReflectionViewerSheet.swift
// ReverieWeaver
//
// Read-only viewer for saved reflections
// UPDATED: Multi-photo gallery support with horizontal scroll

import SwiftUI
import SwiftData

struct ReflectionViewerSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let reflection: Reflection
    let habit: Habit
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Habit info header
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color(hex: habit.colorHex))
                            .frame(width: 16, height: 16)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(habit.name)
                                .font(.system(size: 14, weight: .medium))
                                .fontDesign(.serif)
                                .foregroundStyle(Color.dynamicLabel)
                            
                            Text(reflection.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.system(size: 13, weight: .regular))
                                .fontDesign(.serif)
                                .foregroundStyle(Color.dynamicSecondaryLabel)
                        }
                        
                        Spacer()
                        
                        if reflection.isFavorite {
                            Image(systemName: "heart.fill")
                                .foregroundStyle(Color.paleMauve)
                                .font(.system(size: 16))
                        }
                    }
                    .padding(16)
                    .background(Color.dynamicSecondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Mood section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "face.smiling")
                                .font(.system(size: 13))
                                .foregroundStyle(Color(hex: habit.colorHex))
                            Text("Mood")
                                .font(.system(size: 13, weight: .regular))
                                .fontDesign(.serif)
                                .foregroundStyle(Color.dynamicLabel)
                        }
                        
                        Text(reflection.mood)
                            .font(.system(size: 14, weight: .medium))
                            .fontDesign(.serif)
                            .foregroundStyle(Color.dynamicLabel)
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.dynamicSecondaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // Notes section
                    if !reflection.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "text.alignleft")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.dynamicSecondaryLabel)
                                Text("Thoughts")
                                    .font(.system(size: 13, weight: .regular))
                                    .fontDesign(.serif)
                                    .foregroundStyle(Color.dynamicLabel)
                            }
                            
                            Text(reflection.notes)
                                .font(.system(size: 13, weight: .regular))
                                .fontDesign(.serif)
                                .foregroundStyle(Color.dynamicLabel)
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.dynamicSecondaryBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    
                    // UPDATED: Multi-photo gallery
                    if !reflection.photosData.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "photo.fill")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.dynamicSecondaryLabel)
                                Text("Photos (\(reflection.photosData.count))")
                                    .font(.system(size: 13, weight: .regular))
                                    .fontDesign(.serif)
                                    .foregroundStyle(Color.dynamicLabel)
                            }
                            
                            // Photo gallery - different layouts based on count
                            if reflection.photosData.count == 1 {
                                // Single photo - full width
                                SinglePhotoView(photoData: reflection.photosData[0])
                            } else {
                                // Multiple photos - horizontal scroll
                                MultiPhotoGallery(photosData: reflection.photosData)
                            }
                        }
                    }
                }
                .padding(24)
            }
            .background(Color.dynamicBackground)
            .navigationTitle("Reflection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Reflection")
                        .font(.system(size: 13, weight: .semibold))
                        .fontDesign(.serif)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 13, weight: .regular))
                    .fontDesign(.serif)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Supporting Views

/// Single photo display - full width
struct SinglePhotoView: View {
    let photoData: Data
    
    var body: some View {
        if let uiImage = UIImage(data: photoData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                )
        }
    }
}

/// Multi-photo horizontal scroll gallery
struct MultiPhotoGallery: View {
    let photosData: [Data]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(photosData.enumerated()), id: \.offset) { index, photoData in
                    if let uiImage = UIImage(data: photoData) {
                        VStack(alignment: .leading, spacing: 6) {
                            // Photo index indicator
                            Text("\(index + 1) of \(photosData.count)")
                                .font(.system(size: 11, weight: .medium))
                                .fontDesign(.serif)
                                .foregroundStyle(Color.dynamicSecondaryLabel)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.dynamicSecondaryBackground)
                                .clipShape(Capsule())
                            
                            // Photo
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 280, height: 280)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
        }
        .frame(height: 320)
    }
}

// MARK: - Preview Helper
// This struct remains for backward compatibility during migration
// It will be removed once all existing reflections are migrated
extension ReflectionViewerSheet {
    /// Legacy single photo support (for migration period)
    var hasLegacySinglePhoto: Bool {
        // Check if old photoData property exists (you'll need to handle this in Reflection model)
        false
    }
}
