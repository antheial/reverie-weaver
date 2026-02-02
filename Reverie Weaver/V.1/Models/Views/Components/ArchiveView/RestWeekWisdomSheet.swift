//
//  RestWeekWisdomSheet.swift
//  Reverie Weaver
//
//  Sheet shown when tapping rest day constellation star
//  Celebrates intentional rest as wisdom
//

import SwiftUI

struct RestWeekWisdomSheet: View {
    let weekDate: Date
    let restDayCount: Int
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    private var weekString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: weekDate)
        let offset = weekday - 1
        guard let weekStart = calendar.date(byAdding: .day, value: -offset, to: weekDate),
              let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else {
            return formatter.string(from: weekDate)
        }
        
        return "\(formatter.string(from: weekStart)) - \(formatter.string(from: weekEnd))"
    }
    
    private var wisdomMessage: String {
        switch restDayCount {
        case 1:
            return "You took one intentional rest day this week. That's not weakness — that's wisdom. Rest is how we sustain the rhythm, not break it."
        case 2:
            return "Two rest days this week. You're learning to listen to your body's signals before burnout forces the choice. This is mastery of self-awareness."
        default:
            return "You honored your need for rest. Progress isn't measured only in action — sometimes it's measured in knowing when to pause."
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Spacer()
                
                // Moon icon
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.softLavender.opacity(0.3),
                                    Color.softLavender.opacity(0.1),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 80
                            )
                        )
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundStyle(Color.softLavender)
                }
                
                // Title
                VStack(spacing: 8) {
                    Text("Intentional Rest")
                        .font(.system(size: 24, weight: .bold))
                        .fontDesign(.serif)
                        .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                    
                    Text(weekString)
                        .font(.system(size: 15, weight: .regular))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                }
                
                // Wisdom message
                Text(wisdomMessage)
                    .font(.system(size: 13, weight: .regular))
                    .fontDesign(.serif)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
                
                // Stats
                VStack(spacing: 12) {
                    HStack(spacing: 24) {
                        statItem(value: "\(restDayCount)", label: restDayCount == 1 ? "Rest Day" : "Rest Days")
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 24)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.softLavender.opacity(colorScheme == .dark ? 0.15 : 0.12))
                    )
                }
                
                Spacer()
                
                // Quote
                VStack(spacing: 8) {
                    Text("\"Rest is not idleness.\"")
                        .font(.system(size: 13, design: .serif))
                        .italic()
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    
                    Text("— John Lubbock")
                        .font(.system(size: 12))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .subtle)
                }
                .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ReverieWeaverBackground())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .semibold, design: .serif))
                .foregroundStyle(Color.softLavender)
            Text(label)
                .font(.system(size: 11, weight: .regular))
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
        }
    }
}

#Preview {
    RestWeekWisdomSheet(weekDate: Date(), restDayCount: 2)
}
