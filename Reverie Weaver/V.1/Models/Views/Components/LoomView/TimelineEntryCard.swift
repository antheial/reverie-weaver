//  MARK: - Timeline Entry Card Component
//
// TimelineEntryCard.swift
// ReverieWeaver
//
import SwiftUI
import SwiftData

struct  TimelineEntryCard: View {
    @Environment(\.colorScheme) private var colorScheme
     let  completion: HabitCompletion
     let  habit: Habit
     let  onTap: () -> Void
    
     var  body:  some  View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with habit info
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color(hex: habit.colorHex))
                        .frame(width: 10, height: 10)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(habit.name)
                            .font(.system(size: 13, weight: .medium))
                            .fontDesign(.serif)
                            .foregroundStyle(Color.dynamicLabel)
                        
                        Text(completion.completedAt.formatted(date: .omitted, time: .shortened))
                            .font(.system(size: 11, weight: .regular))
                            .fontDesign(.serif)
                            .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    }
                    
                    Spacer()
                    
                     if   let  reflection = completion.reflection {
                        // Show indicators if there's a reflection
                        HStack(spacing: 8) {
                             if  reflection.photoData !=  nil  {
                                Image(systemName: "photo.fill")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color.dustyBlue)
                            }
                            
                             if  reflection.isFavorite {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color.paleMauve)
                            }
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11))
                                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        }
                    }  else  {
                        HStack(spacing: 6) {
                            Text("Add reflection")
                                .font(.system(size: 11, weight: .regular))
                                .fontDesign(.serif)
                                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11))
                                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        }
                    }
                }
                
                // Reflection preview if exists
                 if   let  reflection = completion.reflection {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        // Mood
                        HStack(spacing: 6) {
                            Image(systemName: "face.smiling")
                                .font(.system(size: 11))
                                .foregroundStyle(Color(hex: habit.colorHex))
                            Text(reflection.mood)
                                .font(.system(size: 11, weight: .medium))
                                .fontDesign(.serif)
                                .foregroundStyle(Color.dynamicLabel)
                        }
                        
                        // Notes preview
                         if  !reflection.notes.isEmpty {
                            Text(reflection.notes)
                                .font(.system(size: 11, weight: .regular))
                                .fontDesign(.serif)
                                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                                .lineLimit(2)
                        }
                        
                        // Photo preview
                         if   let  photoData = reflection.photoData,  let  uiImage = UIImage(data: photoData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.habitCardBackground)
                    .shadow(color: Color.shadowColor, radius: 4, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.habitCardBorder, lineWidth: 1)
            )
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
    }
}
