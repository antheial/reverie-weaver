//
// WeekCalendarSheet.swift
// Reverie Weaver
//
// Simple calendar sheet for selecting a week
// Appears on long-press of week navigator
//keep in mind this is being used in loom, choosing week
//

import SwiftUI

struct WeekCalendarSheet: View {
    @Binding var currentDate: Date
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var displayedMonth: Date = Date()

    var body: some View {
        NavigationStack {
            ZStack {
                ReverieWeaverBackground()

                VStack(spacing: 20) {
                    // Month navigation
                    HStack {
                        Button {
                            changeMonth(by: -1)
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16))
                                .foregroundStyle(Color.dynamicLabel)
                                .frame(width: 40, height: 40)
                        }

                        Spacer()

                        Text(monthYearString)
                            .font(.system(size: 18, weight: .semibold))
                            .fontDesign(.serif)
                            .foregroundStyle(Color.dynamicLabel)

                        Spacer()

                        Button {
                            changeMonth(by: 1)
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16))
                                .foregroundStyle(Color.dynamicLabel)
                                .frame(width: 40, height: 40)
                        }
                    }
                    .padding(.horizontal, 24)

                    // Simple calendar grid
                    VStack(spacing: 12) {
                        // Week day headers
                        HStack(spacing: 0) {
                            ForEach(weekDayHeaders, id: \.self) { day in
                                Text(day)
                                    .font(.system(size: 11, weight: .medium))
                                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                                    .frame(maxWidth: .infinity)
                            }
                        }

                        // Days grid
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
                            ForEach(Array(daysInMonth.enumerated()), id: \.offset) { index, date in
                                if let date = date {
                                    Button {
                                        selectWeek(containing: date)
                                    } label: {
                                        Text("\(Calendar.current.component(.day, from: date))")
                                            .font(.system(size: 14, weight: isCurrentWeek(date) ? .semibold : .regular))
                                            .foregroundStyle(
                                                Calendar.current.isDateInToday(date) ? Color.sageGreen :
                                                isCurrentWeek(date) ? Color.dustyBlue :
                                                Color.dynamicLabel
                                            )
                                            .frame(width: 40, height: 40)
                                            .background(
                                                Circle()
                                                    .fill(
                                                        Calendar.current.isDateInToday(date) ? Color.sageGreen.opacity(0.15) :
                                                        isCurrentWeek(date) ? Color.dustyBlue.opacity(0.15) :
                                                        Color.clear
                                                    )
                                            )
                                    }
                                } else {
                                    Color.clear.frame(width: 40, height: 40)
                                }
                            }
                        }

                    }
                    .padding(.horizontal, 24)

                    Spacer()
                }
                .padding(.top, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.sageGreen)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }

    private var weekDayHeaders: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        return formatter.shortWeekdaySymbols
    }

    private var daysInMonth: [Date?] {
        let calendar = Calendar.current

        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)),
              let monthRange = calendar.range(of: .day, in: .month, for: monthStart) else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let firstWeekdayOffset = firstWeekday - calendar.firstWeekday
        let adjustedOffset = firstWeekdayOffset >= 0 ? firstWeekdayOffset : firstWeekdayOffset + 7

        var days: [Date?] = Array(repeating: nil, count: adjustedOffset)

        for day in monthRange {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                days.append(date)
            }
        }

        return days
    }

    private func changeMonth(by months: Int) {
        if let newMonth = Calendar.current.date(byAdding: .month, value: months, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }

    private func selectWeek(containing date: Date) {
        currentDate = date
        ReverieHaptics.lightFeedback()
        dismiss()
    }

    private func isCurrentWeek(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let currentWeek = calendar.component(.weekOfYear, from: currentDate)
        let currentYear = calendar.component(.yearForWeekOfYear, from: currentDate)
        let dateWeek = calendar.component(.weekOfYear, from: date)
        let dateYear = calendar.component(.yearForWeekOfYear, from: date)
        return currentWeek == dateWeek && currentYear == dateYear
    }
}
