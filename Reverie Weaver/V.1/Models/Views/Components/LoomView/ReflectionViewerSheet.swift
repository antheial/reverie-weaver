//   MARK: - Reflection Viewer Sheet  
// ReflectionViewerSheet.swift
// ReverieWeaver

import SwiftUI
import SwiftData

struct ReflectionViewerSheet: View {
    @Environment(\.dismiss)   private     var   dismiss
    
      let reflection: Reflection
      let habit: Habit
    
      var body: some   View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Habit info
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
                                .font(.system(size: 12, weight: .regular))
                                .fontDesign(.serif)
                                .foregroundStyle(Color.dynamicSecondaryLabel)
                        }
                        
                        Spacer()
                        
                          if   reflection.isFavorite {
                            Image(systemName: "heart.fill")
                                .foregroundStyle(Color.paleMauve)
                                .font(.system(size: 16))
                        }
                    }
                    .padding(16)
                    .background(Color.dynamicSecondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Mood
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "face.smiling")
                                .font(.system(size: 12))
                                .foregroundStyle(Color(hex: habit.colorHex))
                            Text("Mood")
                                .font(.system(size: 12, weight: .regular))
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
                    
                    // Notes
                      if   !reflection.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "text.alignleft")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.dynamicSecondaryLabel)
                                Text("Thoughts")
                                    .font(.system(size: 12, weight: .regular))
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
                    
                    // Photo
                      if let photoData = reflection.photoData,   let   uiImage = UIImage(data: photoData) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "photo.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.dynamicSecondaryLabel)
                                Text("Photo")
                                    .font(.system(size: 12, weight: .regular))
                                    .fontDesign(.serif)
                                    .foregroundStyle(Color.dynamicLabel)
                            }
                            
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 12))
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
                    .font(.system(size: 12, weight: .regular))
                    .fontDesign(.serif)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
