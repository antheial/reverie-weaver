//
//  MonthlyArchiveView.swift
//  Reverie Weaver
//
//  FINAL HYBRID VERSION — Oct 2025 (CRASH-SAFE)
//  Combines original vertical layout with modern insights carousel
//  Structure:
//  - Month Navigator
//  - Monthly Summary + Insights Carousel
//  - Challenge Milestones
//  - Completion Trend Chart
//  - Focus Distribution (Pie Chart)
//

import SwiftUI
import SwiftData

struct MonthlyArchiveView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Queries
    @Query(sort: \Habit.order) private var habits: [Habit]
    @Query private var completions: [HabitCompletion]
    @Query private var allPomodoros: [PomodoroSession]
    @Query private var profiles: [UserProfile]

    // MARK: - State
    @State private var currentDate = Date()
    @State private var showMonthPicker = false

    // MARK: - Body
    var body: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // 1️⃣ Month Navigator
                    monthNavigator

                    // 2️⃣ Monthly Summary + Insights
                    VStack(spacing: 16) {
                        monthlySummaryCard
                        insightsCarousel
                    }

                    // 3️⃣ Challenge Milestone Row
                    if hasChallengeMilestones {
                        challengeMilestoneRow
                    }

                    // 4️⃣ Completion Trend
                    completionTrendCard

                    // 5️⃣ Focus Distribution (Pie Chart)
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
    }

    // MARK: - Month Navigator
    private var monthNavigator: some View {
        VStack(spacing: 4) {
            Text(monthYearString)
                .font(.system(size: 16, weight: .semibold))
                .fontDesign(.serif)
                .foregroundStyle(Color.dynamicLabel)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .gesture(dragGesture)
                .simultaneousGesture(longPressGesture)
        }
    }

    // MARK: - Monthly Summary Card
    private var monthlySummaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.paleMauve)
                Text("Monthly Summary")
                    .font(.system(size: 14, weight: .regular))
                    .fontDesign(.serif)
                    .foregroundStyle(Color.dynamicLabel)
                Spacer()
            }

            HStack(spacing: 16) {
                statColumn(value: "\(threadsWoven)", label: "Threads Woven", color: .sageGreen)
                statColumn(value: "\(completionPercentage)%", label: "Avg Completion", color: .dustyBlue)
                statColumn(value: "\(favoriteCount)", label: "Favorites", color: .terracottaRose)
                statColumn(value: "\(focusHours)", label: "Focus Hours", color: .paleMauve)
            }

            if let growth = monthGrowthDifference {
                HStack(spacing: 4) {
                    Image(systemName: growth.isImprovement ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(growth.isImprovement ? Color.sageGreen : Color.terracottaRose)
                    Text("\(abs(growth.difference))% vs last month")
                        .font(.system(size: 11, weight: .medium))
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
                    .foregroundStyle(Color.dynamicLabel)
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
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.dynamicLabel)
            Spacer()
        }
        .padding(16)
        .reverieCardStyle(colorScheme: colorScheme)
    }

    // MARK: - Completion Trend Card
    private var completionTrendCard: some View {
        // ⬅️ Make the data available to the whole view
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
                    .foregroundStyle(Color.dynamicLabel)
            }

            // Chart row: Y-axis outside + chart
            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    TrendYAxis() // fixed gutter on the left
                    CompletionTrendView(weeks: trendData)
                        .frame(height: 90)
                        .padding(.trailing, 4) // tiny breathing room
                }
                // X labels outside, below the chart
                TrendXAxisLabels(pointCount: trendData.count)
            }

            Text(trendInsightNote)
                .font(.system(size: 11))
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
                    .foregroundStyle(Color.dynamicLabel)
            }

            if focusBreakdown.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "hourglass.circle")
                        .font(.system(size: 28))
                        .foregroundStyle(.primary)
                    Text("No focus sessions this month")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.dynamicLabel)
                    Text("Pomodoro sessions you log will appear here.")
                        .font(.system(size: 11))
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
                .frame(width: 160, height: 160) // instead of height: 140
                .frame(maxWidth: .infinity, alignment: .center)

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(focusBreakdown.keys.sorted(by: {
                        focusBreakdown[$0] ?? 0 > focusBreakdown[$1] ?? 0
                    })), id: \.self) { category in
                        HStack(spacing: 6) {
                            Image(systemName: categoryIcon(for: category))
                                .font(.system(size: 11))
                                .foregroundStyle(categoryColor(for: category))
                            Text("\(category) · \(focusHoursString(for: category))")
                                .font(.system(size: 10))
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
                    .font(.system(size: 12))
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(color)
            }

            Text(message)
                .font(.system(size: 11))
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
                .font(.system(size: 10))
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

    // MARK: - Focus Pie Chart (Improved, Structure Preserved)
    private struct FocusPieChartView: View {
        let data: [String: Double]
        let colorScheme: ColorScheme
        let colorProvider: (String) -> Color

        var body: some View {
            GeometryReader { geo in
                let total = max(data.values.reduce(0, +), 0.01)
                let sortedKeys = Array(data.keys.sorted())
                // ✅ Use the smaller side for radius to prevent overflow
                let side = min(geo.size.width, geo.size.height)
                let radius = side / 2.0
                let gapDeg: Double = 1.2   // ← add this line

                ZStack {
                    ForEach(Array(sortedKeys.enumerated()), id: \.offset) { index, key in
                        let value = data[key] ?? 0
                        let startAngle = startAngle(for: index, in: sortedKeys, total: total)
                        let endAngle = startAngle + Angle(degrees: (value / total) * 360)
                        let midAngle = Angle(degrees: (startAngle.degrees + endAngle.degrees) / 2)

                        // ✅ Clip slices inside the view
                        PieSliceShape(
                            startAngle: startAngle + .degrees(gapDeg/2),
                            endAngle:   endAngle   - .degrees(gapDeg/2)
                        )
                        .fill(colorProvider(key).opacity(colorScheme == .dark ? 0.9 : 0.8))
                        .frame(width: side, height: side)
                        .clipped()

                        // ✅ Only show labels for slices > 5%
                        let percentage = (value / total) * 100
                        if percentage > 5 {
                            let labelRadius = radius * 0.6
                            let x = geo.size.width / 2 + labelRadius * CGFloat(cos(midAngle.radians))
                            let y = geo.size.height / 2 + labelRadius * CGFloat(sin(midAngle.radians))

                            Text("\(Int(percentage))%")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(Color.dynamicLabel)
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
                .drawingGroup() // smoother rendering
            }
            .aspectRatio(1, contentMode: .fit) // ✅ ensures square pie
        }

        // MARK: - Angle Helper (kept for structure)
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


    // MARK: - Computed Values (Crash-Safe)
    private var monthStart: Date {
        let comps = Calendar.current.dateComponents([.year, .month], from: currentDate)
        return Calendar.current.date(from: comps) ?? Calendar.current.startOfDay(for: currentDate)
    }

    private var monthEnd: Date {
        // last day of current month at 23:59:59-ish
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
        completions.filter { $0.completedAt >= monthStart && $0.completedAt <= monthEnd }.count
    }

    private var totalHabitsCount: Int {
        habits.count * daysInMonth
    }

    private var daysInMonth: Int {
        Calendar.current.range(of: .day, in: .month, for: currentDate)?.count ?? 30
    }

    private var completionPercentage: Int {
        guard totalHabitsCount > 0 else { return 0 }
        return Int((Double(threadsWoven) / Double(totalHabitsCount)) * 100)
    }

    private var favoriteCount: Int {
        completions.filter { $0.reflection?.isFavorite == true && $0.completedAt >= monthStart && $0.completedAt <= monthEnd }.count
    }

    /// ✅ FIXED: Type-safe, no KVC
    private var focusHours: Int {
        let sessions = allPomodoros.filter {
            $0.sessionType == "work" && $0.completedAt >= monthStart && $0.completedAt <= monthEnd
        }
        let totalMinutes = sessions.reduce(0) { $0 + $1.duration }
        return totalMinutes / 60
    }

    // MARK: - Weekly completion (month-aware, partial-week safe)
    private var weeklyCompletionRates: [Double] {
        guard habits.count > 0 else { return [] }
        let cal = Calendar.current

        // Weeks intersecting this month (use open range fallback to match Range<Int>)
        let weekRange: Range<Int> = cal.range(of: .weekOfMonth, in: .month, for: currentDate) ?? (1..<6)

        return weekRange.compactMap { week -> Double? in
            // weekStart = first day of this calendar week counted from the start of the month
            let monthStartWeekStart = cal.date(from: cal.dateComponents([.year, .month], from: currentDate))!
            let weekStart = cal.date(byAdding: .weekOfMonth, value: week - 1, to: monthStartWeekStart)!
            // Clamp to month window (handles partial weeks at the edges)
            let start = max(weekStart, monthStart)
            let weekEnd = cal.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
            let end = min(weekEnd, monthEnd)

            let days = (cal.dateComponents([.day], from: start, to: end).day ?? 0) + 1
            guard days > 0 else { return 0 }

            let count = completions.filter { $0.completedAt >= start && $0.completedAt <= end }.count
            return Double(count) / Double(habits.count * days)
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

        // Split month into 4 equal(ish) day ranges
        // (1)–cut2-1, (cut2)–cut3-1, (cut3)–cut4-1, (cut4)–end
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
            let nextDay = cal.date(byAdding: .day, value: 1, to: bucketEnd)!

            // Count days and completions within this bucket
            let days = max(0, (cal.dateComponents([.day], from: bucketStart, to: nextDay).day ?? 0))
            guard days > 0 else { points.append(points.last ?? 0); continue }

            let done = completions.filter { $0.completedAt >= bucketStart && $0.completedAt < nextDay }.count
            cumDone += done
            cumPossible += habits.count * days

            let rate = Double(cumDone) / Double(max(cumPossible, 1))
            points.append(min(max(rate, 0), 1))
        }

        // Always 4 points: W1…W4
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
        let start = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: lastMonth)) ?? lastMonth
        let end = Calendar.current.date(byAdding: .month, value: 1, to: start) ?? start
        let lastMonthCompletions = completions.filter { $0.completedAt >= start && $0.completedAt <= end }
        let totalLast = habits.count * (Calendar.current.range(of: .day, in: .month, for: lastMonth)?.count ?? 30)
        guard totalLast > 0 else { return nil }
        let lastPercent = Int(Double(lastMonthCompletions.count) / Double(totalLast) * 100)
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
                    // Y axis
                    Path { p in
                        p.move(to: CGPoint(x: leftInset, y: topInset))
                        p.addLine(to: CGPoint(x: leftInset, y: h - bottomInset))
                    }
                    .stroke(stroke, lineWidth: 0.5)

                    // X axis
                    Path { p in
                        p.move(to: CGPoint(x: leftInset, y: h - bottomInset))
                        p.addLine(to: CGPoint(x: w - rightInset, y: h - bottomInset))
                    }
                    .stroke(stroke, lineWidth: 0.5)

                    // Y gridlines & labels (0%, 50%, 100%)
                    ForEach([0, 50, 100], id: \.self) { v in
                        let usableH = h - topInset - bottomInset
                        let y = (1 - CGFloat(v)/100) * usableH + topInset

                        // grid
                        Path { p in
                            p.move(to: CGPoint(x: leftInset, y: y))
                            p.addLine(to: CGPoint(x: w - rightInset, y: y))
                        }
                        .stroke(stroke.opacity(v == 50 ? 0.35 : 0.2),
                                style: StrokeStyle(lineWidth: 0.4,
                                                   dash: v == 50 ? [2, 2] : [1, 3]))

                        // label
                        Text("\(v)%")
                            .font(.system(size: 9))
                            .foregroundStyle(Color.dynamicSecondaryLabel)
                            .position(x: 14, y: y)
                    }

                    // X labels W1…Wn
                    let n = max(pointCount, 1)
                    ForEach(0..<n, id: \.self) { i in
                        let usableW = w - leftInset - rightInset
                        let x = leftInset + usableW * CGFloat(i) / CGFloat(max(n - 1, 1))
                        Text("W\(i + 1)")
                            .font(.system(size: 9))
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
                Text("100%").font(.system(size: 9)).foregroundStyle(Color.dynamicSecondaryLabel)
                Spacer()
                Text("50%").font(.system(size: 9)).foregroundStyle(Color.dynamicSecondaryLabel)
                Spacer()
                Text("0%").font(.system(size: 9)).foregroundStyle(Color.dynamicSecondaryLabel)
            }
            .frame(width: 34) // fixed gutter outside the chart
        }
    }

    // MARK: - W1…Wn labels (outside, under the chart)
    private struct TrendXAxisLabels: View {
        let pointCount: Int
        var body: some View {
            HStack(spacing: 0) {
                Spacer(minLength: 34)  // same gutter as Y axis
                if pointCount > 0 {
                    ForEach(0..<pointCount, id: \.self) { i in
                        Text("W\(i + 1)")
                            .font(.system(size: 9))
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
        completedMiniChallengesCount > 0 || leveledUpProject50
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

    // MARK: - Completed mini-challenge names (this month)
    // MARK: - Mini challenge display name (stored on progress)
    private func miniChallengeDisplayName(_ p: MiniChallengeProgress) -> String? {
        // In your DetailView we save `challengeTitle` on creation.
        // If your model makes it non-optional, just return p.challengeTitle.
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

    private var challengeMilestoneText: String {
        var parts: [String] = []

        let names = completedMiniChallengeNames
        if !names.isEmpty {
            let list: String
            if names.count <= 2 {
                list = names.joined(separator: ", ")
            } else {
                list = names.prefix(2).joined(separator: ", ") + " +\(names.count - 2) more"
            }
            parts.append("\(names.count) Mini Challenge\(names.count > 1 ? "s" : "") completed: \(list)")
        } else if completedMiniChallengesCount > 0 {
            parts.append("\(completedMiniChallengesCount) Mini Challenge\(completedMiniChallengesCount > 1 ? "s" : "") completed")
        }

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
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    if value.translation.width > 50 {
                        navigateToPreviousMonth()
                    } else if value.translation.width < -50 {
                        navigateToNextMonth()
                    }
                }
            }
    }

    private var longPressGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.5)
            .onEnded { _ in
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                showMonthPicker = true
            }
    }

    private func navigateToPreviousMonth() {
        currentDate = Calendar.current.date(byAdding: .month, value: -1, to: currentDate) ?? currentDate
    }

    private func navigateToNextMonth() {
        currentDate = Calendar.current.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate
    }
}

