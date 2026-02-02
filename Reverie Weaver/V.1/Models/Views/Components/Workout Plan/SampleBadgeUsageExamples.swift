//  SampleBadgeUsageExamples.swift
//  ReverieWeaver
//
//  Examples of how to use the Sample Program badge
//

import SwiftUI

// MARK: - Usage Examples

/*
 
 Example 1: Simple usage with a program card
 
 VStack(alignment: .leading, spacing: 8) {
     if template.isSampleContent {
         SampleProgramBadge()
     }
     
     Text(template.title)
         .font(.headline)
     
     Text(template.notes)
         .font(.caption)
         .foregroundStyle(.secondary)
 }
 
 
 Example 2: Using the view modifier
 
 YourProgramCard(template: template)
     .sampleBadge(isSample: template.isSampleContent)
 
 
 Example 3: Inline with title
 
 HStack {
     Text("Fei Strength Arc")
         .font(.title)
     
     if currentProgram.isSample {
         SampleProgramBadge()
     }
 }
 
 
 Example 4: In a list row
 
 ForEach(templates) { template in
     HStack {
         VStack(alignment: .leading) {
             if template.isSampleContent {
                 SampleProgramBadge()
             }
             
             Text(template.title)
                 .font(.headline)
             
             Text("\(template.durationMinutes) min")
                 .font(.caption)
                 .foregroundStyle(.secondary)
         }
         
         Spacer()
         
         Image(systemName: "chevron.right")
             .foregroundStyle(.tertiary)
     }
     .padding()
 }
 
 
 Example 5: Overlay on card
 
 ProgramCard(template: template)
     .overlay(alignment: .topLeading) {
         if template.isSampleContent {
             SampleProgramBadge()
                 .padding(12)
         }
     }
 
 */

// MARK: - Preview Examples

struct SampleBadgeExamplesPreview: View {
    let sampleTemplate = CoachClassTemplate(
        coach: .fei,
        code: "test",
        title: "Sample Workout",
        focusBodyPart: "Full Body",
        durationMinutes: 40,
        modality: .strength,
        notes: "This is a sample class",
        isSampleContent: true
    )
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Example 1: Simple badge
                GroupBox("Simple Badge") {
                    VStack(alignment: .leading, spacing: 8) {
                        SampleProgramBadge()
                        
                        Text(sampleTemplate.title)
                            .font(.headline)
                        
                        Text(sampleTemplate.notes)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                }
                
                // Example 2: Card with modifier
                GroupBox("Using View Modifier") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(sampleTemplate.title)
                            .font(.headline)
                        
                        HStack {
                            Label("\(sampleTemplate.durationMinutes) min", systemImage: "clock")
                            Spacer()
                            Label(sampleTemplate.focusBodyPart, systemImage: "figure.strengthtraining.traditional")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .sampleBadge(isSample: sampleTemplate.isSampleContent)
                }
                
                // Example 3: Inline with title
                GroupBox("Inline with Title") {
                    HStack(spacing: 12) {
                        Image(systemName: "dumbbell.fill")
                            .font(.title)
                            .foregroundStyle(.blue)
                        
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Fei Strength Arc")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                
                                SampleProgramBadge()
                            }
                            
                            Text("4-Week Program")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                }
                
                // Example 4: List style
                GroupBox("List Style") {
                    VStack(spacing: 0) {
                        ForEach(0..<3) { index in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    SampleProgramBadge()
                                    
                                    Text(sampleTemplate.title)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    Text("\(sampleTemplate.durationMinutes) min")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.tertiary)
                                    .font(.caption)
                            }
                            .padding()
                            
                            if index != 2 {
                                Divider()
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
}

#Preview {
    SampleBadgeExamplesPreview()
}
