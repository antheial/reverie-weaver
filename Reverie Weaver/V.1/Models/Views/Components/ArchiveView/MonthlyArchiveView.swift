//
//  MonthlyArchiveView.swift
//  Reverie Weaver
//
//  Oct 2025
//  Structure:
//  - Month Navigator
//  - Monthly Summary + Insights Carousel
//  - Challenge Milestones
//  - Completion Trend Chart
//  - Focus Distribution (Pie Chart)
//

import SwiftUI
import SwiftData
import os.log

struct MonthlyArchiveView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Queries
    @Query(sort: \Habit.order) private var habits: [Habit]
    @Query private var completions: [HabitCompletion]
    @Query private var allPomodoros: [PomodoroSession]
    @Query private var profiles: [UserProfile]
    @Query private var reflections: [DailyReflection]
    @Query private var allThemeWeekProgress: [ThemeWeekProgress]
    @Query(sort: \MiniChallengeProgress.startDate, order: .reverse)
    private var allMiniChallengeProgress: [MiniChallengeProgress]
    
    // MARK: - Shared Calculator
    private var statsCalculator: HabitStatsCalculator {
        HabitStatsCalculator(
            completions: completions,
            habits: habits,
            reflections: reflections,
            profiles: profiles
        )
    }

    // MARK: - State
    @State private var currentDate = Date()
    @State private var showMonthPicker = false
    
    @State private var isNavigatorPressed = false
    
    // Constellation feature
    @State private var selectedStar: ConstellationStar?

    // MARK: - Body
    var body: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // 1. Month Navigator
                    monthNavigator

                    // 2. Monthly Summary + Insights
                    VStack(spacing: 16) {
                        monthlySummaryCard
                        insightsCarousel
                    }
                    
                    // 3. Achievement Constellation
                    if !constellationStars.isEmpty {
                        achievementConstellationCard
                    }

                    // 4. Challenge Milestone Row
                    if hasChallengeMilestones {
                        challengeMilestoneRow
                    }

                    // 5. Completion Trend
                    completionTrendCard

                    // 6. Focus Distribution (Pie Chart)
                    focusDistributionCard
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 120)
            }
        }
        .sheet(isPresented: $showMonthPicker) {
            WeekCalendarSheet(currentDate: $currentDate)
                .presentationDetents([.medium])
                .presentationCornerRadius(24)
        }
        .sheet(item: $selectedStar) { star in
            switch star.type {
            case .miniChallenge:
                MiniChallengeQuickSummarySheet(
                    challengeID: star.id,
                    challengeName: star.name,
                    completedDate: star.completedDate
                )
            case .themeWeek:
                ThemeWeekQuickSummarySheet(
                    progressID: star.id,
                    programTitle: star.name,
                    completedDate: star.completedDate
                )
            case .project50:
                Project50MilestoneSheet(
                    oldLevel: extractOldLevel(from: star.id),
                    newLevel: extractNewLevel(from: star.id),
                    achievedDate: star.completedDate
                )
            case .restWeek:
                RestWeekWisdomSheet(
                    weekDate: star.completedDate,
                    restDayCount: extractRestCount(from: star.id)
                )
            }
        }
    }

    // MARK: - Month Navigator
    
    private var monthNavigator: some View {
           VStack(spacing: 4) {
               Text(monthYearString)
                   .font(.system(size: 16, weight: .semibold))
                   .fontDesign(.serif)
                   .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                   .padding(.vertical, 6)
                   .frame(maxWidth: .infinity)
                   .contentShape(Rectangle())
                   .scaleEffect(isNavigatorPressed ? 0.98 : 1.0)
                   .gesture(
                       DragGesture(minimumDistance: 10)
                           .onChanged { _ in
                               if !isNavigatorPressed {
                                   isNavigatorPressed = true
                               }
                           }
                           .onEnded { value in
                               isNavigatorPressed = false
                               
                               let swipeDistance = value.translation.width
                               #if DEBUG
                               print("📅 Month swipe detected: \(swipeDistance) points")
                               #endif
                               
                               if swipeDistance > 50 {
                                   withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                       navigateToPreviousMonth()
                                   }
                                   UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                   AppLog.info("Navigated to previous month", category: "monthly")
                               }
                               else if swipeDistance < -50 {
                                   withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                       navigateToNextMonth()
                                   }
                                   UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                   AppLog.info("Navigated to next month", category: "monthly")
                               }
                               else {
                                   #if DEBUG
                                   print("⚠️ Swipe too short - ignored")
                                   #endif
                               }
                           }
                   )
                   .simultaneousGesture(longPressGesture)
           }
       }
    
    // MARK: - Monthly Summary Card
    
    private var monthlySummaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Text("Monthly Summary")
                    .font(.system(size: 13, weight: .regular))
                    .fontDesign(.serif)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                Spacer()
            }

            HStack(spacing: 20) {
                statColumn(value: "\(threadsWoven)", label: "Threads Woven", color: .sageGreen)
                statColumn(value: "\(completionPercentage)%", label: "Avg Completion", color: .dustyBlue)
                statColumn(value: "\(favoriteCount)", label: "Favorites", color: .terracottaRose)
                statColumn(value: "\(focusHours)", label: "Focus Hours", color: .paleMauve)
            }

            if let growth = monthGrowthDifference {
                HStack(spacing: 4) {
                    Image(systemName: growth.isImprovement ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(growth.isImprovement ? Color.sageGreen : Color.terracottaRose)
                    Text("\(abs(growth.difference))% vs last month")
                        .font(.system(size: 12, weight: .medium))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                }
            }
        }
        .padding(20)
        .reverieCardStyle(colorScheme: colorScheme)
    }

    // MARK: - Insights Carousel
    
    private var insightsCarousel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.paleMauve)
                Text("Insights")
                    .font(.system(size: 13, weight: .medium))
                    .fontDesign(.serif)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    insightCard(title: "Best Day", message: bestDayMessage, color: .dustyBlue, icon: "star.fill")
                    insightCard(title: "Weekend Tip", message: weekendMessage, color: .terracottaRose, icon: "chart.bar.fill")
                    insightCard(title: "Growth", message: trendInsightNote, color: .sageGreen, icon: "arrow.up.right")
                }
                .padding(.horizontal, 4)
            }
        }
    }

    // MARK: - Challenge Milestone Row
    
    private var challengeMilestoneRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "flag.checkered")
                .font(.system(size: 13))
                .foregroundStyle(Color.sageGreen)
            Text(challengeMilestoneText)
                .font(.system(size: 13, weight: .medium))
                .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
            Spacer()
        }
        .padding(16)
        .reverieCardStyle(colorScheme: colorScheme)
    }

    // MARK: - Completion Trend Card
    
    private var completionTrendCard: some View {
        let trendData = weeklyCumulativeRates.isEmpty ? weeklyCompletionRates : weeklyCumulativeRates

        return VStack(alignment: .leading, spacing: 10) {
            // Title row (unchanged)
            HStack(spacing: 8) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.dustyBlue)
                Text("Completion Trend")
                    .font(.system(size: 14, weight: .regular))
                    .fontDesign(.serif)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
            }

            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    TrendYAxis()
                    CompletionTrendView(weeks: trendData)
                        .frame(height: 90)
                        .padding(.trailing, 4)
                }

                TrendXAxisLabels(pointCount: trendData.count)
            }

            Text(trendInsightNote)
                .font(.system(size: 12))
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
        }
        .padding(20)
        .reverieCardStyle(colorScheme: colorScheme)
    }
    

    // MARK: - Focus Distribution (Pie Chart)
    
    private var focusDistributionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.paleMauve)
                Text("Focus Distribution")
                    .font(.system(size: 14, weight: .regular))
                    .fontDesign(.serif)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
            }

            if focusBreakdown.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "hourglass.circle")
                        .font(.system(size: 28))
                        .foregroundStyle(.primary)
                    Text("No focus sessions this month")
                        .font(.system(size: 13, weight: .medium))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    Text("Pomodoro sessions you log will appear here.")
                        .font(.system(size: 12))
                        .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 24)
            } else {
                FocusPieChartView(
                    data: focusBreakdown,
                    colorScheme: colorScheme,
                    colorProvider: categoryColor(for:)
                )
                .frame(width: 160, height: 160)
                .frame(maxWidth: .infinity, alignment: .center)

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(focusBreakdown.keys.sorted(by: {
                        focusBreakdown[$0] ?? 0 > focusBreakdown[$1] ?? 0
                    })), id: \.self) { category in
                        HStack(spacing: 6) {
                            Image(systemName: categoryIcon(for: category))
                                .font(.system(size: 12))
                                .foregroundStyle(categoryColor(for: category))
                            Text("\(category) · \(focusHoursString(for: category))")
                                .font(.system(size: 11))
                                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                        }
                    }
                }
            }
        }
        .padding(20)
        .reverieCardStyle(colorScheme: colorScheme)
    }
    

    // MARK: - Insight Card Component
    
    private func insightCard(title: String, message: String, color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(color)
            }

            Text(message)
                .font(.system(size: 12))
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                .lineLimit(3)
        }
        .padding(14)
        .frame(width: 220)
        .reverieCardStyle(colorScheme: colorScheme)
    }

    // MARK: - Subview Helpers
    private func statColumn(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 11))
                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private struct CompletionTrendView: View {
        let weeks: [Double]
        var body: some View {
            GeometryReader { geo in
                let step = geo.size.width / CGFloat(max(weeks.count - 1, 1))
                Path { path in
                    for (index, rate) in weeks.enumerated() {
                        let x = CGFloat(index) * step
                        let y = geo.size.height * (1 - CGFloat(rate))
                        index == 0 ? path.move(to: CGPoint(x: x, y: y)) : path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                .stroke(
                    LinearGradient(colors: [.sageGreen, .dustyBlue], startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                )
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: weeks)
            }
        }
    }

    // MARK: - Focus Pie Chart
    
    private struct FocusPieChartView: View {
        let data: [String: Double]
        let colorScheme: ColorScheme
        let colorProvider: (String) -> Color

        var body: some View {
            GeometryReader { geo in
                let total = max(data.values.reduce(0, +), 0.01)
                let sortedKeys = Array(data.keys.sorted())
                let side = min(geo.size.width, geo.size.height)
                let radius = side / 2.0
                let gapDeg: Double = 1.2

                ZStack {
                    ForEach(Array(sortedKeys.enumerated()), id: \.offset) { index, key in
                        let value = data[key] ?? 0
                        let startAngle = startAngle(for: index, in: sortedKeys, total: total)
                        let endAngle = startAngle + Angle(degrees: (value / total) * 360)
                        let midAngle = Angle(degrees: (startAngle.degrees + endAngle.degrees) / 2)

                        PieSliceShape(
                            startAngle: startAngle + .degrees(gapDeg/2),
                            endAngle:   endAngle   - .degrees(gapDeg/2)
                        )
                        .fill(colorProvider(key).opacity(colorScheme == .dark ? 0.9 : 0.8))
                        .frame(width: side, height: side)
                        .clipped()

                        let percentage = (value / total) * 100
                        if percentage > 5 {
                            let labelRadius = radius * 0.6
                            let x = geo.size.width / 2 + labelRadius * CGFloat(cos(midAngle.radians))
                            let y = geo.size.height / 2 + labelRadius * CGFloat(sin(midAngle.radians))

                            Text("\(Int(percentage))%")
                                .font(.system(size: 11, weight: .medium))
                                .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                                .position(x: x, y: y)
                                .allowsHitTesting(false)
                        }
                    }
                    Circle()
                        .stroke(Color.adaptiveBorder(colorScheme: colorScheme).opacity(0.5), lineWidth: 0.6)
                        .frame(width: side, height: side)
                }
                .frame(width: side, height: side)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
                .clipped()
                .drawingGroup()
            }
            .aspectRatio(1, contentMode: .fit)
        }

        // MARK: - Angle Helper
        
        private func startAngle(for index: Int, in keys: [String], total: Double) -> Angle {
            guard index > 0 else { return Angle(degrees: -90) }
            let previousValues = keys.prefix(index).compactMap { data[$0] }
            let ratio = previousValues.reduce(0, +) / total
            return Angle(degrees: -90 + (ratio * 360))
        }
    }

    // MARK: - Pie Slice Shape
    
    private struct PieSliceShape: Shape {
        var startAngle: Angle
        var endAngle: Angle

        func path(in rect: CGRect) -> Path {
            var path = Path()
            let side = min(rect.width, rect.height)
            let center = CGPoint(x: rect.midX, y: rect.midY)

            path.move(to: center)
            path.addArc(
                center: center,
                radius: side / 2.0,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: false
            )
            path.closeSubpath()
            return path
        }
    }


    // MARK: - Computed Values
    
    private var monthStart: Date {
        let comps = Calendar.current.dateComponents([.year, .month], from: currentDate)
        return Calendar.current.date(from: comps) ?? Calendar.current.startOfDay(for: currentDate)
    }

    private var monthEnd: Date {
        let next = Calendar.current.date(byAdding: .month, value: 1, to: monthStart) ?? monthStart
        let lastDay = Calendar.current.date(byAdding: .day, value: -1, to: next) ?? monthStart
        return lastDay
    }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentDate)
    }

    private var threadsWoven: Int {
        statsCalculator.uniqueCompletions(inMonthStarting: monthStart)
    }

    // Calculate total possible completions based on active habits per day (now with rest day exclusion)
    private var totalHabitsCount: Int {
        statsCalculator.totalPossible(inMonthStarting: monthStart)
    }

    private var daysInMonth: Int {
        Calendar.current.range(of: .day, in: .month, for: currentDate)?.count ?? 30
    }

    private var completionPercentage: Int {
        let rate = statsCalculator.monthlyRate(forMonthStarting: monthStart)
        return Int((rate * 100).rounded())
    }

    private var favoriteCount: Int {
        completions.filter { $0.reflection?.isFavorite == true && $0.completedAt >= monthStart && $0.completedAt <= monthEnd }.count
    }

    private var focusHours: Int {
        let sessions = allPomodoros.filter {
            $0.sessionType == "work" && $0.completedAt >= monthStart && $0.completedAt <= monthEnd
        }
        let totalMinutes = sessions.reduce(0) { $0 + $1.duration }
        return totalMinutes / 60
    }

    // MARK: - Weekly completion
    
    private var weeklyCompletionRates: [Double] {
        guard habits.count > 0 else { return [] }
        let cal = Calendar.current

        let weekRange: Range<Int> = cal.range(of: .weekOfMonth, in: .month, for: currentDate) ?? (1..<6)

        return weekRange.compactMap { week -> Double? in
            let monthStartWeekStart = cal.date(from: cal.dateComponents([.year, .month], from: currentDate))!
            let weekStart = cal.date(byAdding: .weekOfMonth, value: week - 1, to: monthStartWeekStart)!
            let start = max(weekStart, monthStart)
            let weekEnd = cal.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
            let end = min(weekEnd, monthEnd)

            // Get rest days for this period
            let restDaysThisWeek = statsCalculator.restDays(forWeekStarting: start)
            
            // Calculate total possible based on active habits each day (excluding rest days)
            var totalPossible = 0
            var currentDay = start
            while currentDay <= end {
                let normalizedDay = cal.startOfDay(for: currentDay)
                
                // Skip rest days
                if !restDaysThisWeek.contains(normalizedDay) {
                    totalPossible += statsCalculator.activeHabitCount(on: currentDay)
                }
                
                currentDay = cal.date(byAdding: .day, value: 1, to: currentDay) ?? currentDay
                if currentDay > end { break }
            }
            
            guard totalPossible > 0 else { return 0 }

            // Count unique scheduled completions only (excluding rest days)
            var uniqueCount = 0
            currentDay = start
            while currentDay <= end {
                let normalizedDay = cal.startOfDay(for: currentDay)
                
                if !restDaysThisWeek.contains(normalizedDay) {
                    let dayCompletions = completions.filter {
                        cal.isDate($0.completedAt, inSameDayAs: currentDay)
                    }
                    
                    let scheduled = statsCalculator.scheduledCompletions(from: dayCompletions)
                    let uniqueHabits = Set(scheduled.map { $0.habitId })
                    let activeCount = statsCalculator.activeHabitCount(on: currentDay)
                    
                    uniqueCount += min(uniqueHabits.count, activeCount)
                }
                
                currentDay = cal.date(byAdding: .day, value: 1, to: currentDay) ?? currentDay
                if currentDay > end { break }
            }
            
            return min(1.0, Double(uniqueCount) / Double(totalPossible))
        }
    }
    
    // MARK: - Monthly cumulative (exactly 4 buckets: W1–W4)
    
    private var weeklyCumulativeRates: [Double] {
        guard habits.count > 0 else { return [] }
        let cal = Calendar.current

        // Month bounds
        let startOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: currentDate))!
        let totalDays = cal.range(of: .day, in: .month, for: currentDate)!.count
        let endOfMonth = cal.date(byAdding: .day, value: totalDays - 1, to: startOfMonth)!

        // Get rest days for the entire month
        let restDaysThisMonth = statsCalculator.restDays(forMonthStarting: startOfMonth)

        // Split month into 4 equal(ish) day ranges
        let cut2 = 1 + totalDays / 4
        let cut3 = 1 + (totalDays * 2) / 4
        let cut4 = 1 + (totalDays * 3) / 4

        let buckets: [(startDay: Int, endDay: Int)] = [
            (1,            max(cut2 - 1, 1)),
            (cut2,         max(cut3 - 1, cut2)),
            (cut3,         max(cut4 - 1, cut3)),
            (cut4,         totalDays)
        ]

        var cumDone = 0
        var cumPossible = 0
        var points: [Double] = []

        for b in buckets {
            // Build start/end dates for this bucket
            var comps = cal.dateComponents([.year, .month], from: currentDate)
            comps.day = b.startDay
            let bucketStart = cal.date(from: comps) ?? startOfMonth

            comps.day = b.endDay
            let bucketEnd = min(cal.date(from: comps) ?? endOfMonth, endOfMonth)
            
            // Safe date addition with fallback
            guard let nextDay = cal.date(byAdding: .day, value: 1, to: bucketEnd) else {
                AppLog.error("Failed to calculate next day for bucket end", category: "monthly")
                points.append(points.last ?? 0)
                continue
            }

            var bucketPossible = 0
            var bucketDone = 0
            var currentDay = bucketStart
            
            while currentDay < nextDay {
                let normalizedDay = cal.startOfDay(for: currentDay)
                
                // Skip rest days
                if !restDaysThisMonth.contains(normalizedDay) {
                    let activeCount = statsCalculator.activeHabitCount(on: currentDay)
                    bucketPossible += activeCount
                    
                    // Count completions for this day
                    let dayCompletions = completions.filter {
                        cal.isDate($0.completedAt, inSameDayAs: currentDay)
                    }
                    
                    let scheduled = statsCalculator.scheduledCompletions(from: dayCompletions)
                    let uniqueHabits = Set(scheduled.map { $0.habitId })
                    bucketDone += min(uniqueHabits.count, activeCount)
                }
                
                guard let next = cal.date(byAdding: .day, value: 1, to: currentDay) else {
                    break
                }
                currentDay = next
                if currentDay >= nextDay { break }
            }
            
            guard bucketPossible > 0 else { points.append(points.last ?? 0); continue }

            cumDone += bucketDone
            cumPossible += bucketPossible

            let rate = Double(cumDone) / Double(max(cumPossible, 1))
            points.append(min(max(rate, 0), 1))
        }

        return points
    }


    private var trendInsightNote: String {
        if weeklyCompletionRates.last ?? 0 > weeklyCompletionRates.first ?? 0 {
            return "Your consistency strengthened as the month progressed."
        } else if weeklyCompletionRates.last ?? 0 < weeklyCompletionRates.first ?? 0 {
            return "Momentum dipped mid-month — a gentle reminder to rest and refocus."
        } else {
            return "Steady rhythm maintained across the month — well done."
        }
    }

    private var monthGrowthDifference: (isImprovement: Bool, difference: Int)? {
        guard let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentDate) else { return nil }
        let cal = Calendar.current
        let start = cal.date(from: cal.dateComponents([.year, .month], from: lastMonth)) ?? lastMonth
        let daysInLastMonth = cal.range(of: .day, in: .month, for: lastMonth)?.count ?? 30
        let end = cal.date(byAdding: .day, value: daysInLastMonth - 1, to: start) ?? start
        
        // Get rest days for last month
        let restDaysLastMonth = statsCalculator.restDays(forMonthStarting: start)
        
        // Calculate total possible for last month based on active habits per day (excluding rest days)
        var totalLast = 0
        var currentDay = start
        while currentDay <= end {
            let normalizedDay = cal.startOfDay(for: currentDay)
            
            if !restDaysLastMonth.contains(normalizedDay) {
                totalLast += statsCalculator.activeHabitCount(on: currentDay)
            }
            
            currentDay = cal.date(byAdding: .day, value: 1, to: currentDay) ?? currentDay
            if currentDay > end { break }
        }
        
        guard totalLast > 0 else { return nil }
        
        // Count unique scheduled completions for last month (excluding rest days)
        var uniqueCount = 0
        currentDay = start
        while currentDay <= end {
            let normalizedDay = cal.startOfDay(for: currentDay)
            
            if !restDaysLastMonth.contains(normalizedDay) {
                let dayCompletions = completions.filter {
                    cal.isDate($0.completedAt, inSameDayAs: currentDay)
                }
                
                let scheduled = statsCalculator.scheduledCompletions(from: dayCompletions)
                let uniqueHabits = Set(scheduled.map { $0.habitId })
                let activeCount = statsCalculator.activeHabitCount(on: currentDay)
                
                uniqueCount += min(uniqueHabits.count, activeCount)
            }
            
            currentDay = cal.date(byAdding: .day, value: 1, to: currentDay) ?? currentDay
            if currentDay > end { break }
        }
        
        let lastPercent = min(100, Int(Double(uniqueCount) / Double(totalLast) * 100))
        let diff = completionPercentage - lastPercent
        guard abs(diff) >= 3 else { return nil }
        return (isImprovement: diff > 0, difference: abs(diff))
    }
    
    // MARK: - Minimal axes overlay for the trend line (0–100% + W1…W5)
    
    private struct TrendAxesOverlay: View {
        @Environment(\.colorScheme) private var colorScheme
        let pointCount: Int

        var body: some View {
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let leftInset: CGFloat = 28
                let bottomInset: CGFloat = 18
                let topInset: CGFloat = 4
                let rightInset: CGFloat = 4
                let stroke = Color.adaptiveBorder(colorScheme: colorScheme).opacity(0.35)

                ZStack(alignment: .topLeading) {
                    Path { p in
                        p.move(to: CGPoint(x: leftInset, y: topInset))
                        p.addLine(to: CGPoint(x: leftInset, y: h - bottomInset))
                    }
                    .stroke(stroke, lineWidth: 0.5)

                    Path { p in
                        p.move(to: CGPoint(x: leftInset, y: h - bottomInset))
                        p.addLine(to: CGPoint(x: w - rightInset, y: h - bottomInset))
                    }
                    .stroke(stroke, lineWidth: 0.5)

                    ForEach([0, 50, 100], id: \.self) { v in
                        let usableH = h - topInset - bottomInset
                        let y = (1 - CGFloat(v)/100) * usableH + topInset

                        Path { p in
                            p.move(to: CGPoint(x: leftInset, y: y))
                            p.addLine(to: CGPoint(x: w - rightInset, y: y))
                        }
                        .stroke(stroke.opacity(v == 50 ? 0.35 : 0.2),
                                style: StrokeStyle(lineWidth: 0.4,
                                                   dash: v == 50 ? [2, 2] : [1, 3]))

                        Text("\(v)%")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.dynamicSecondaryLabel)
                            .position(x: 14, y: y)
                    }

                    let n = max(pointCount, 1)
                    ForEach(0..<n, id: \.self) { i in
                        let usableW = w - leftInset - rightInset
                        let x = leftInset + usableW * CGFloat(i) / CGFloat(max(n - 1, 1))
                        Text("W\(i + 1)")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.dynamicSecondaryLabel)
                            .position(x: x, y: h - 8)
                    }
                }
            }
            .allowsHitTesting(false)
        }
    }

    // MARK: - Slim Y axis (outside the chart)
    
    private struct TrendYAxis: View {
        @Environment(\.colorScheme) private var colorScheme
        var body: some View {
            VStack(spacing: 0) {
                Text("100%").font(.system(size: 11)).foregroundStyle(Color.dynamicSecondaryLabel)
                Spacer()
                Text("50%").font(.system(size: 11)).foregroundStyle(Color.dynamicSecondaryLabel)
                Spacer()
                Text("0%").font(.system(size: 11)).foregroundStyle(Color.dynamicSecondaryLabel)
            }
            .frame(width: 34)
        }
    }

    // MARK: - W1…Wn labels (outside, under the chart)
    
    private struct TrendXAxisLabels: View {
        let pointCount: Int
        var body: some View {
            HStack(spacing: 0) {
                Spacer(minLength: 34)
                if pointCount > 0 {
                    ForEach(0..<pointCount, id: \.self) { i in
                        Text("W\(i + 1)")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.dynamicSecondaryLabel)
                        if i < pointCount - 1 { Spacer() }
                    }
                }
            }
        }
    }


    private var bestDayMessage: String {
        "Your highest completion day this month was Sunday — a sign of restored energy."
    }

    private var weekendMessage: String {
        "Weekend habits dropped slightly — keep weekends lighter for sustainable balance."
    }

    // MARK: - Challenge Data (safe defaults)
    private var hasChallengeMilestones: Bool {
        completedMiniChallengesCount > 0 || completedThemeWeeksCount > 0 || leveledUpProject50
    }

    private var completedMiniChallengesCount: Int {
        let descriptor = FetchDescriptor<MiniChallengeProgress>()
        let allProgress = (try? modelContext.fetch(descriptor)) ?? []
        return allProgress.filter {
            ($0.isCompleted) &&
            (($0.completedDate ?? Date()) >= monthStart) &&
            (($0.completedDate ?? Date()) <= monthEnd)
        }.count
    }
    
    private var completedThemeWeeksCount: Int {
        return allThemeWeekProgress.filter { progress in
            progress.isCompleted &&
            progress.daysCompleted >= 7 &&
            (progress.completedDate ?? Date()) >= monthStart &&
            (progress.completedDate ?? Date()) <= monthEnd
        }.count
    }

    private var leveledUpProject50: Bool {
        let manager = Project50ProgressManager.shared
        if let levelStart = manager.journey.levelStartDates[manager.journey.currentLevel] {
            return levelStart >= monthStart && levelStart <= monthEnd
        }
        return false
    }

    // MARK: - Completed mini-challenge names (this month)
    private var challengeNameByID: [String:String] = [
        "focus_sprint":"Focus Sprint",
        "radiant_skin":"Radiant Skin Reset",
        // ...
    ]

    // MARK: - Mini challenge display name (stored on progress)
    private func miniChallengeDisplayName(_ p: MiniChallengeProgress) -> String? {
        let t = p.challengeTitle
        return t.isEmpty ? nil : t
    }

    // MARK: - Completed mini-challenge names for this month
    private var completedMiniChallengeNames: [String] {
        let descriptor = FetchDescriptor<MiniChallengeProgress>()
        let all = (try? modelContext.fetch(descriptor)) ?? []

        let monthOnes = all.filter { p in
            p.isCompleted &&
            (p.completedDate ?? .distantPast) >= monthStart &&
            (p.completedDate ?? .distantPast) < Calendar.current.date(byAdding: .day, value: 1, to: monthEnd)!
        }

        
        var seen = Set<String>()
        var result: [String] = []
        for p in monthOnes {
            if let n = miniChallengeDisplayName(p), seen.insert(n).inserted {
                result.append(n)
            }
        }
        return result
    }
    
    // MARK: - Completed Theme Week names for this month
    private var completedThemeWeekNames: [String] {
        let monthOnes = allThemeWeekProgress.filter { p in
            p.isCompleted &&
            p.daysCompleted >= 7 &&
            (p.completedDate ?? .distantPast) >= monthStart &&
            (p.completedDate ?? .distantPast) < Calendar.current.date(byAdding: .day, value: 1, to: monthEnd)!
        }
        
        var seen = Set<String>()
        var result: [String] = []
        for p in monthOnes {
            let name = p.programTitle
            if !name.isEmpty && seen.insert(name).inserted {
                result.append(name)
            }
        }
        return result
    }

    private var challengeMilestoneText: String {
        var parts: [String] = []

        // Mini Challenges
        let miniNames = completedMiniChallengeNames
        if !miniNames.isEmpty {
            let list: String
            if miniNames.count <= 2 {
                list = miniNames.joined(separator: ", ")
            } else {
                list = miniNames.prefix(2).joined(separator: ", ") + " +\(miniNames.count - 2) more"
            }
            parts.append("\(miniNames.count) Mini Challenge\(miniNames.count > 1 ? "s" : "") completed: \(list)")
        } else if completedMiniChallengesCount > 0 {
            parts.append("\(completedMiniChallengesCount) Mini Challenge\(completedMiniChallengesCount > 1 ? "s" : "") completed")
        }
        
        // Theme Weeks
        let themeNames = completedThemeWeekNames
        if !themeNames.isEmpty {
            let list: String
            if themeNames.count <= 2 {
                list = themeNames.joined(separator: ", ")
            } else {
                list = themeNames.prefix(2).joined(separator: ", ") + " +\(themeNames.count - 2) more"
            }
            parts.append("\(themeNames.count) Theme Week\(themeNames.count > 1 ? "s" : "") completed: \(list)")
        } else if completedThemeWeeksCount > 0 {
            parts.append("\(completedThemeWeeksCount) Theme Week\(completedThemeWeeksCount > 1 ? "s" : "") completed")
        }

        // Project 50
        if leveledUpProject50 {
            parts.append("Advanced to Project 50 Level \(Project50ProgressManager.shared.journey.currentLevel)")
        }
        
        return parts.joined(separator: " · ")
    }


    // MARK: - Focus Breakdown Helpers (CRASH-SAFE)
    private var focusBreakdown: [String: Double] {
        var totals: [String: Double] = [:]
        let sessions = allPomodoros.filter {
            $0.sessionType == "work" && $0.completedAt >= monthStart && $0.completedAt <= monthEnd
        }

        for session in sessions {
            let cat = session.category ?? "Uncategorized"
            totals[cat, default: 0] += Double(session.duration)
        }
        return totals
    }

    // MARK: - Icon/Color mapping for dashboard categories
    private func categoryIcon(for category: String) -> String {
        switch category.lowercased() {
        case "work & projects", "work", "projects":           return "briefcase.fill"
        case "learning & growth", "learning", "growth":       return "book.fill"
        case "health & wellness", "wellness", "health":       return "heart.fill"
        case "creative practice", "creativity", "creative":   return "paintbrush.fill"
        default:                                              return "circle.fill"
        }
    }

    private func categoryColor(for category: String) -> Color {
        switch category.lowercased() {
        case "work & projects", "work", "projects":           return .dustyBlue
        case "learning & growth", "learning", "growth":       return .terracottaRose
        case "health & wellness", "wellness", "health":       return .sageGreen
        case "creative practice", "creativity", "creative":   return .paleMauve
        default:                                              return .dynamicSecondaryLabel
        }
    }

    private func focusHoursString(for category: String) -> String {
        guard let minutes = focusBreakdown[category], minutes > 0 else { return "0h" }
        let hours = minutes / 60
        return hours < 1 ? "\(Int(minutes))m" : "\(Int(hours))h"
    }

    // MARK: - Gestures
       private var dragGesture: some Gesture {
           DragGesture(minimumDistance: 10)
               .onEnded { value in
                   let swipeDistance = value.translation.width
                   
                   #if DEBUG
                   print("📅 Month swipe detected: \(swipeDistance) points")
                   #endif
                   
                   // Swipe right (previous month)
                   if swipeDistance > 50 {
                       withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                           navigateToPreviousMonth()
                       }
                       // Haptic feedback for successful navigation
                       UIImpactFeedbackGenerator(style: .light).impactOccurred()
                       AppLog.info("Navigated to previous month", category: "monthly")
                   }
                   // Swipe left (next month)
                   else if swipeDistance < -50 {
                       withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                           navigateToNextMonth()
                       }
                       UIImpactFeedbackGenerator(style: .light).impactOccurred()
                       AppLog.info("Navigated to next month", category: "monthly")
                   }
                   else {
                       #if DEBUG
                       print("⚠️ Swipe too short - ignored (need >50 points)")
                       #endif
                   }
               }
       }

       private var longPressGesture: some Gesture {
           LongPressGesture(minimumDuration: 0.5)
               .onEnded { _ in
                   UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                   showMonthPicker = true
                   AppLog.info("Month picker opened via long press", category: "monthly")
               }
       }

    // MARK: - Navigation Functions
    
       private func navigateToPreviousMonth() {
           let oldMonth = monthYearString
           
           if let newDate = Calendar.current.date(byAdding: .month, value: -1, to: currentDate) {
               currentDate = newDate
               AppLog.info("Month changed: \(oldMonth) → \(monthYearString)", category: "monthly")
           } else {
               AppLog.error("Failed to calculate previous month", category: "monthly")
               currentDate = Calendar.current.date(byAdding: .month, value: -1, to: currentDate) ?? currentDate
           }
       }

       private func navigateToNextMonth() {
           let oldMonth = monthYearString
           
           if let newDate = Calendar.current.date(byAdding: .month, value: 1, to: currentDate) {
               currentDate = newDate
               AppLog.info("Month changed: \(oldMonth) → \(monthYearString)", category: "monthly")
           } else {
               AppLog.error("Failed to calculate next month", category: "monthly")
               currentDate = Calendar.current.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate
           }
       }
    
    // MARK: - Achievement Constellation
    
    private var achievementConstellationCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.paleMauve)
                Text("Achievement Constellation")
                    .font(.system(size: 14, weight: .medium))
                    .fontDesign(.serif)
                    .timeAdaptiveText(colorScheme: colorScheme, style: .primary)
                Spacer()
            }
            
            GeometryReader { geometry in
                ZStack {
                    constellationBackground
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                 
                    constellationLines(in: geometry.size)
                        .stroke(
                            Color.white.opacity(timeAdaptiveOpacity(0.3, 0.4)),
                            style: StrokeStyle(lineWidth: 1.5, dash: [5, 3])
                        )
                    
                    ForEach(Array(constellationStars.enumerated()), id: \.element.id) { index, star in
                        starView(star)
                            .position(starPosition(index: index, total: constellationStars.count, in: geometry.size))
                            .transition(.scale.combined(with: .opacity))
                            .animation(
                                .spring(response: 0.6, dampingFraction: 0.7)
                                .delay(Double(index) * 0.1),
                                value: constellationStars.count
                            )
                    }
                }
            }
            .frame(height: 180)
            
            Rectangle()
                .fill(Color.dynamicSecondaryLabel.opacity(0.2))
                .frame(height: 1)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 40)
           
            VStack(spacing: 6) {
                Text(constellationPoetry)
                    .font(.system(size: 13, design: .serif))
                    .italic()
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    .multilineTextAlignment(.center)
                
                Text("✨ \(constellationStars.count) challenge\(constellationStars.count == 1 ? "" : "s") completed")
                    .font(.system(size: 12, weight: .medium))
                    .timeAdaptiveText(colorScheme: colorScheme, style: .secondary)
                    .opacity(0.7)
            }
        }
        .padding(20)
        .reverieCardStyle(colorScheme: colorScheme)
    }
    
    private var constellationBackground: some View {
        let hour = Calendar.current.component(.hour, from: Date())
        let period = TimeOfDay(hour: hour)
        
        return ZStack {
            if colorScheme == .dark {
                LinearGradient(
                    colors: [
                        Color(hex: "1A1612").opacity(0.95),
                        Color(hex: "2C2520").opacity(0.90),
                        Color(hex: "3D3530").opacity(0.85)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                Group {
                    switch period {
                    case .deepNight, .evening:
                        LinearGradient(
                            colors: [
                                Color(hex: "1A1612").opacity(0.88),
                                Color(hex: "2C2520").opacity(0.82),
                                Color(hex: "3D3530").opacity(0.75)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        
                    case .dawn:
                        // Dawn: Twilight transition
                        LinearGradient(
                            colors: [
                                Color(hex: "2B4162").opacity(0.85),
                                Color(hex: "73628A").opacity(0.78),
                                Color(hex: "E8B4B8").opacity(0.70)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        
                    case .dusk:
                        // Dusk: Purple twilight magic
                        LinearGradient(
                            colors: [
                                Color(hex: "8B7BA8").opacity(0.82),
                                Color(hex: "5E6FA3").opacity(0.78),
                                Color(hex: "2C3E50").opacity(0.75)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        
                    case .goldenHour:
                        // Golden hour: Warm evening sky
                        LinearGradient(
                            colors: [
                                Color(hex: "D4A5A5").opacity(0.78),
                                Color(hex: "9B8B9F").opacity(0.75),
                                Color(hex: "5E6FA3").opacity(0.72)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        
                    default:
                        // Daytime: Soft daytime sky (subtle, not distracting)
                        LinearGradient(
                            colors: [
                                Color(hex: "E3F2FD").opacity(0.65),
                                Color(hex: "E1F5FE").opacity(0.60),
                                Color(hex: "B3E5FC").opacity(0.55)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                }
            }
            
            // Subtle stars texture overlay (matches your paper texture philosophy)
            // Only visible in night/evening periods for authenticity
            if shouldShowStarsTexture(for: period) {
                StarsTextureView()
                    .opacity(colorScheme == .dark ? 0.25 : 0.20)
                    .blendMode(.screen)
            }
        }
    }
    
    // Helper to determine when to show stars texture
    private func shouldShowStarsTexture(for period: TimeOfDay) -> Bool {
        if colorScheme == .dark { return true }
        
        switch period {
        case .deepNight, .evening, .dusk:
            return true
        case .dawn, .goldenHour:
            return true
        default:
            return false
        }
    }
    
    private func starView(_ star: ConstellationStar) -> some View {
        ZStack {
            Image(systemName: star.icon)
                .font(.system(size: star.type.starSize, weight: .semibold))
                .foregroundStyle(star.color)
                .shadow(color: star.color.opacity(0.6), radius: star.type.glowRadius)

            // Show subtitle (e.g., percentage) for partial completions
            if let subtitle = star.subtitle {
                Text(subtitle)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(star.color)
                    .offset(y: star.type.starSize / 2 + 6)
            }
        }
        .onTapGesture {
            selectedStar = star
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
    
    private func constellationLines(in size: CGSize) -> Path {
        Path { path in
            guard constellationStars.count > 1 else { return }
            
            for i in 0..<constellationStars.count - 1 {
                let startCenter = starPosition(index: i, total: constellationStars.count, in: size)
                let endCenter = starPosition(index: i + 1, total: constellationStars.count, in: size)
                
                let startStar = constellationStars[i]
                let endStar = constellationStars[i + 1]
                let startRadius = (startStar.type.starSize / 2) + startStar.type.glowRadius
                let endRadius = (endStar.type.starSize / 2) + endStar.type.glowRadius
                
                let adjustedPoints = calculateEdgePoints(
                    from: startCenter,
                    to: endCenter,
                    startRadius: startRadius,
                    endRadius: endRadius
                )
                
                path.move(to: adjustedPoints.start)
                path.addLine(to: adjustedPoints.end)
            }
        }
    }

    private func calculateEdgePoints(
        from startCenter: CGPoint,
        to endCenter: CGPoint,
        startRadius: CGFloat,
        endRadius: CGFloat
    ) -> (start: CGPoint, end: CGPoint) {
        let dx = endCenter.x - startCenter.x
        let dy = endCenter.y - startCenter.y
        let distance = sqrt(dx * dx + dy * dy)
        
        guard distance > 0 else {
            return (start: startCenter, end: endCenter)
        }
        
        let unitX = dx / distance
        let unitY = dy / distance
        
        let adjustedStart = CGPoint(
            x: startCenter.x + unitX * startRadius,
            y: startCenter.y + unitY * startRadius
        )
        
        let adjustedEnd = CGPoint(
            x: endCenter.x - unitX * endRadius,
            y: endCenter.y - unitY * endRadius
        )
        
        return (start: adjustedStart, end: adjustedEnd)
    }

    private func starPosition(index: Int, total: Int, in size: CGSize) -> CGPoint {
        let centerX = size.width / 2
        let centerY = size.height / 2
        let radius: CGFloat = 60
        
        switch total {
        case 1:
            return CGPoint(x: centerX, y: centerY)
            
        case 2:
            return index == 0 ?
                CGPoint(x: centerX - radius, y: centerY - 10) :
                CGPoint(x: centerX + radius, y: centerY + 10)
            
        case 3:
            // Triangle
            let positions: [CGPoint] = [
                CGPoint(x: centerX, y: centerY - radius),
                CGPoint(x: centerX - radius, y: centerY + radius),
                CGPoint(x: centerX + radius, y: centerY + radius)
            ]
            return positions[index]
            
        case 4:
            // Diamond
            let positions: [CGPoint] = [
                CGPoint(x: centerX, y: centerY - radius),
                CGPoint(x: centerX - radius, y: centerY),
                CGPoint(x: centerX + radius, y: centerY),
                CGPoint(x: centerX, y: centerY + radius)
            ]
            return positions[index]
            
        case 5:
            // Pentagon
            let angle = (2 * .pi / 5) * Double(index) - .pi / 2
            return CGPoint(
                x: centerX + radius * CGFloat(cos(angle)),
                y: centerY + radius * CGFloat(sin(angle))
            )
            
        default:
            // Circle layout for 6+
            let angle = (2 * .pi / Double(total)) * Double(index) - .pi / 2
            return CGPoint(
                x: centerX + radius * CGFloat(cos(angle)),
                y: centerY + radius * CGFloat(sin(angle))
            )
        }
    }

    
    // MARK: - Constellation Data
    
    private var constellationStars: [ConstellationStar] {
        var stars: [ConstellationStar] = []

        // MARK: - Mini Challenges (Full Completion: 7/7)
        let miniCompleted = allMiniChallengeProgress.filter {
            $0.isCompleted &&
            ($0.completedDate ?? .distantPast) >= monthStart &&
            ($0.completedDate ?? .distantPast) < Calendar.current.date(byAdding: .day, value: 1, to: monthEnd)!
        }

        for mini in miniCompleted {
            stars.append(ConstellationStar(
                id: mini.challengeID,
                type: .miniChallenge,
                name: mini.challengeTitle,
                completedDate: mini.completedDate ?? Date(),
                icon: "flag.checkered.2.crossed",
                color: .sageGreen,
                subtitle: nil  // Full completion, no percentage needed
            ))
        }

        // MARK: - Mini Challenges (Partial Success: ≥85.7% archived)
        let miniArchived = allMiniChallengeProgress.filter {
            $0.isArchived &&
            !$0.isCompleted &&  // Not full 7/7, but archived as partial success
            ($0.archivedDate ?? .distantPast) >= monthStart &&
            ($0.archivedDate ?? .distantPast) < Calendar.current.date(byAdding: .day, value: 1, to: monthEnd)!
        }

        for mini in miniArchived {
            let percentage = Int(mini.successRate * 100)
            stars.append(ConstellationStar(
                id: "\(mini.challengeID)-archived",
                type: .miniChallenge,
                name: mini.challengeTitle,
                completedDate: mini.archivedDate ?? Date(),
                icon: "flag.checkered.2.crossed",
                color: .sageGreen.opacity(0.7),  // Slightly dimmer for partial
                subtitle: "\(percentage)%"  // Show success rate
            ))
        }
        
        // MARK: - Theme Weeks (Full Completion: 7/7)
        let themeCompleted = allThemeWeekProgress.filter {
            $0.isCompleted &&
            $0.daysCompleted >= 7 &&
            ($0.completedDate ?? .distantPast) >= monthStart &&
            ($0.completedDate ?? .distantPast) < Calendar.current.date(byAdding: .day, value: 1, to: monthEnd)!
        }

        for theme in themeCompleted {
            stars.append(ConstellationStar(
                id: theme.id.uuidString,
                type: .themeWeek,
                name: theme.programTitle,
                completedDate: theme.completedDate ?? Date(),
                icon: "star.fill",
                color: .paleMauve,
                subtitle: nil  // Full completion, no percentage needed
            ))
        }

        // MARK: - Theme Weeks (Partial Success: ≥85.7% archived)
        let themeArchived = allThemeWeekProgress.filter {
            $0.isArchived &&
            !$0.isCompleted &&  // Not full 7/7, but archived as partial success
            ($0.archivedDate ?? .distantPast) >= monthStart &&
            ($0.archivedDate ?? .distantPast) < Calendar.current.date(byAdding: .day, value: 1, to: monthEnd)!
        }

        for theme in themeArchived {
            let percentage = Int(theme.successRate * 100)
            stars.append(ConstellationStar(
                id: "\(theme.id.uuidString)-archived",
                type: .themeWeek,
                name: theme.programTitle,
                completedDate: theme.archivedDate ?? Date(),
                icon: "star.fill",
                color: .paleMauve.opacity(0.7),  // Slightly dimmer for partial
                subtitle: "\(percentage)%"  // Show success rate
            ))
        }
        
        let journey = Project50ProgressManager.shared.journey
        let calendar = Calendar.current
        let monthEndExclusive = calendar.date(byAdding: .day, value: 1, to: monthEnd) ?? monthEnd

        for level in [1, 2, 3] {
            if let levelDate = journey.levelCompletionDates[level],
               levelDate >= monthStart,
               levelDate < monthEndExclusive {
                
                // Safe level name lookup with bounds checking
                let levelNames = ["", "Foundation", "Focus", "Depth"]
                let levelName = level < levelNames.count ? levelNames[level] : "Level \(level)"
                
                stars.append(ConstellationStar(
                    id: "p50-level-\(level)",
                    type: .project50,
                    name: "Level \(level): \(levelName)",
                    completedDate: levelDate,
                    icon: "arrow.up.circle.fill",
                    color: .dustyBlue
                ))
                
                #if DEBUG
                print("📊 P50 Level \(level) completed on \(levelDate.formatted(.dateTime.month().day()))")
                #endif
            }
        }
        
        // MARK: - Rest Day Wisdom Stars (NEW)
        // Award stars for weeks with intentional rest (1-2 rest days = wisdom, not avoidance)
        let intentionalRestDays = reflections.filter {
            $0.isRestDay &&
            $0.date >= monthStart &&
            $0.date < monthEndExclusive
        }
        
        // Group rest days by week to avoid cluttering
        let weeklyRestCounts = Dictionary(grouping: intentionalRestDays) { reflection in
            calendar.component(.weekOfYear, from: reflection.date)
        }
        
        // Award ONE star per week that had 1-2 rest days (intentional rest, not burnout)
        for (week, restDays) in weeklyRestCounts where restDays.count >= 1 && restDays.count <= 2 {
            // Use the first rest day of that week as the achievement date
            if let firstRest = restDays.sorted(by: { $0.date < $1.date }).first {
                stars.append(ConstellationStar(
                    id: "rest-week-\(week)-\(restDays.count)",
                    type: .restWeek,
                    name: "Intentional Rest",
                    completedDate: firstRest.date,
                    icon: "moon.zzz.fill",
                    color: .softLavender
                ))
                
                #if DEBUG
                print("🌙 Rest Week star added: Week \(week) with \(restDays.count) rest day(s)")
                #endif
            }
        }
        
        return stars.sorted { $0.completedDate < $1.completedDate }
    }
    
    private var constellationPoetry: String {
        let count = constellationStars.count
        let restStars = constellationStars.filter { $0.type == .restWeek }
        
        // Prioritize rest wisdom if present (with other achievements)
        if !restStars.isEmpty && count > 1 {
            return "You honored rest — that's wisdom shining"
        }
        
        // Solo rest star gets special message
        if count == 1 && !restStars.isEmpty {
            return "Rest is a practice, not a failure"
        }
        
        let themeWeeks = constellationStars.filter { $0.type == .themeWeek }
        if !themeWeeks.isEmpty {
            let seedRatio = calculateThemeWeekSeedRatio()
            if seedRatio > 0.6 {
                return "You honored the quiet glow of rest"
            } else if seedRatio > 0.4 {
                return "Balance illuminates your path"
            }
        }
        
        switch count {
        case 0: return "The sky awaits your first star"
        case 1: return "A single star marks the beginning"
        case 2: return "Your constellation begins to form"
        case 3: return "\(count) stars woven this month"
        case 4...5: return "A brilliant constellation emerged"
        case 6...7: return "The night sky glows with your dedication"
        default: return "You've painted the heavens"
        }
    }
    
    private func calculateThemeWeekSeedRatio() -> Double {
        let themeWeeks = allThemeWeekProgress.filter {
            $0.isCompleted &&
            ($0.completedDate ?? .distantPast) >= monthStart &&
            ($0.completedDate ?? .distantPast) < Calendar.current.date(byAdding: .day, value: 1, to: monthEnd)!
        }
        
        guard !themeWeeks.isEmpty else { return 0 }
        
        var seedCount = 0
        var totalDays = 0
        
        for theme in themeWeeks {
            for record in theme.completionRecords {
                totalDays += 1
                if record.tier == .seed {
                    seedCount += 1
                }
            }
        }
        
        return totalDays > 0 ? Double(seedCount) / Double(totalDays) : 0
    }
    
    private func extractOldLevel(from id: String) -> Int {
        let components = id.components(separatedBy: "-")
        guard components.count == 3, let level = Int(components[1]) else { return 1 }
        return level
    }
    
    private func extractNewLevel(from id: String) -> Int {
        let components = id.components(separatedBy: "-")
        guard components.count == 3, let level = Int(components[2]) else { return 2 }
        return level
    }
    
    private func extractRestCount(from id: String) -> Int {
        // ID format: "rest-week-{weekNum}-{count}"
        let components = id.components(separatedBy: "-")
        guard components.count == 4, let count = Int(components[3]) else { return 1 }
        return count
    }
    
    private func timeAdaptiveOpacity(_ light: Double, _ dark: Double) -> Double {
        colorScheme == .dark ? dark : light
    }
}

// MARK: - Stars Texture Component

private struct StarsTextureView: View {
    var body: some View {
        Canvas { context, size in
            var generator = SeededRandomNumberGenerator(seed: 42)

            let starCount = 80

            for _ in 0..<starCount {
                let x = CGFloat.random(in: 0...size.width, using: &generator)
                let y = CGFloat.random(in: 0...size.height, using: &generator)
                let starSize = CGFloat.random(in: 0.5...1.8, using: &generator)
                let opacity = Double.random(in: 0.3...0.8, using: &generator)

                let rect = CGRect(x: x - starSize / 2, y: y - starSize / 2, width: starSize, height: starSize)
                let path = Path(ellipseIn: rect)
                context.fill(path, with: .color(Color.white.opacity(opacity)))
            }

            let twinkleCount = 12
            for _ in 0..<twinkleCount {
                let x = CGFloat.random(in: 0...size.width, using: &generator)
                let y = CGFloat.random(in: 0...size.height, using: &generator)
                let starSize = CGFloat.random(in: 1.2...2.5, using: &generator)
                let opacity = Double.random(in: 0.5...0.9, using: &generator)

                let rect = CGRect(x: x - starSize / 2, y: y - starSize / 2, width: starSize, height: starSize)
                let path = Path(ellipseIn: rect)

                let glowRect = rect.insetBy(dx: -0.5, dy: -0.5)
                let glowPath = Path(ellipseIn: glowRect)
                context.fill(glowPath, with: .color(Color.white.opacity(opacity * 0.35)))

                context.fill(path, with: .color(Color.white.opacity(opacity)))
            }
        }
    }
}

