//
//  FocusCategoryPicker.swift
//  Reverie Weaver
//
//

import SwiftUI

struct FocusCategoryPicker: View {
    @Bindable var timerManager: PomodoroTimerManager
    let onStart: () -> Void
    let onCancel: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var appeared = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 1. Main Background
            ReverieWeaverBackground()
                .ignoresSafeArea()
            
            // 2. Scrolling Content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    
                    Color.clear.frame(height: 60)
                    
                    // Smart Note Input
                    noteInputSection
                    
                    // Category List
                    categoryListSection
                    
                    Color.clear.frame(height: 100)
                }
                .padding(.horizontal, 24)
            }
            
            // 3. Fixed Header
            VStack {
                headerView
                Spacer()
            }
            .allowsHitTesting(false)
            
            // 4. Fixed Bottom Buttons
            bottomButtons
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.primary.opacity(0.2))
                .frame(width: 36, height: 4)
                .padding(.top, 10)
            
            Text("Quick Focus")
                .font(.system(size: 16, weight: .semibold))
                .fontDesign(.serif)
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity)
        .background(Color.clear)
    }
    
    // MARK: - Smart Note Input
    
    private var noteInputSection: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 16))
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                .padding(.top, 2)
            
            ZStack(alignment: .topLeading) {
                if timerManager.sessionNote.isEmpty {
                    Text(timerManager.selectedCategory.description)
                        .font(.system(size: 16, weight: .regular))
                        .fontDesign(.serif)
                        .foregroundStyle(Color.secondary.opacity(0.6))
                        .allowsHitTesting(false)
                }
                
                TextField("", text: $timerManager.sessionNote, axis: .vertical)
                    .font(.system(size: 15, weight: .medium))
                    .fontDesign(.serif)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    .tint(Color.sageGreen)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.primary.opacity(0.05), lineWidth: 0.5)
                )
        )
    }
    
    // MARK: - Category List
    
    private var categoryListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SELECT CATEGORY")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.0)
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                .padding(.leading, 4)
            
            VStack(spacing: 8) {
                ForEach(FocusCategory.allCases.filter { $0 != .uncategorized }, id: \.self) { category in
                    Button {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            timerManager.selectedCategory = category
                        }
                    } label: {
                        CategoryRow(category: category, isSelected: timerManager.selectedCategory == category)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Bottom Buttons
    
    private var bottomButtons: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [.clear, Color.black.opacity(0.05)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 20)
            .opacity(0.3)
            
            HStack(spacing: 12) {
                // Cancel
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    onCancel()
                } label: {
                    Text("Cancel")
                        .font(.system(size: 14, weight: .medium))
                        .fontDesign(.serif)
                        .foregroundStyle(Color.primary.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Capsule().strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
                                )
                        )
                }
                .buttonStyle(.plain)
                
                Button {
                    let impact = UINotificationFeedbackGenerator()
                    impact.notificationOccurred(.success)
                    
                    // Call startQuickFocusSession() directly
                    // This ensures portrait mode = 1 session only
                    timerManager.startQuickFocusSession()
                    
                    // Also call the parent's onStart for sheet dismissal
                    onStart()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 12))
                        Text("Start Session")
                            .font(.system(size: 14, weight: .semibold))
                            .fontDesign(.serif)
                    }
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(Color.sageGreen)
                            .shadow(color: Color.sageGreen.opacity(0.3), radius: 8, y: 4)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
            .background(Color.clear)
        }
    }
}

// MARK: - Category Row

struct CategoryRow: View {
    let category: FocusCategory
    let isSelected: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                Circle()
                    .fill(isSelected
                          ? AnyShapeStyle(category.color.opacity(0.15))
                          : AnyShapeStyle(Color.clear))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .strokeBorder(isSelected ? category.color : Color.secondary.opacity(0.1), lineWidth: 1)
                    )
                
                Image(systemName: category.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(isSelected ? category.color : Color.secondary.opacity(0.7))
            }
            
            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(category.rawValue)
                    .font(.system(size: 15, weight: .medium))
                    .fontDesign(.serif)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                
                Text(category.description)
                    .font(.system(size: 12))
                    .fontDesign(.serif)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Checkmark
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(category.color)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isSelected ? AnyShapeStyle(Color.white.opacity(0.1)) : AnyShapeStyle(Color.clear))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(isSelected ? category.color.opacity(0.3) : Color.clear, lineWidth: 0.5)
        )
        .contentShape(Rectangle())
    }
}
