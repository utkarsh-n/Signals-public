//
//  InsightWidgets.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//
//  Widget components for the Insights tab grid
//  Uses Swift Charts and Liquid Glass design
//

import SwiftUI
import Charts

// MARK: - Widget Size

enum WidgetSize {
    case small      // 1x1 - half width
    case medium     // 2x1 - full width
    case large      // 2x2 - full width, double height
    
    var gridSpan: Int {
        switch self {
        case .small: return 1
        case .medium, .large: return 2
        }
    }
    
    var minHeight: CGFloat {
        switch self {
        case .small: return 120
        case .medium: return 120
        case .large: return 260
        }
    }
}

// MARK: - Widget Card Container

struct WidgetCard<Content: View>: View {
    let title: String
    var icon: String? = nil
    var iconColor: Color = ColorPalette.accent
    var size: WidgetSize = .small
    var tint: Color? = nil
    var accessibilityValue: String? = nil
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Header
            HStack(spacing: Spacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundStyle(iconColor)
                        .accessibilityHidden(true)
                }
                Text(title)
                    .font(Typography.caption)
                    .foregroundStyle(ColorPalette.secondaryText)
                Spacer()
            }
            
            // Content
            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Spacing.standard)
        .frame(minHeight: size.minHeight)
        .liquidGlass(tint: tint, cornerRadius: CornerRadius.standard)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) widget")
        .accessibilityValue(accessibilityValue ?? "")
    }
}

// MARK: - Day Composition Widget (Large - Pie Chart)

struct DayCompositionWidget: View {
    let sleepHours: Double
    let workHours: Double
    let screenTimeHours: Double
    let activeHours: Double
    let homeIdleHours: Double
    
    var body: some View {
        WidgetCard(title: "Day Composition", icon: "chart.pie.fill", iconColor: ColorPalette.accent, size: .large) {
            GeometryReader { geometry in
                HStack(spacing: Spacing.lg) {
                    // Pie Chart
                    Chart(pieData, id: \.category) { item in
                        SectorMark(
                            angle: .value("Hours", item.hours),
                            innerRadius: .ratio(0.5),
                            angularInset: 1.5
                        )
                        .foregroundStyle(item.color)
                        .cornerRadius(4)
                    }
                    .frame(width: geometry.size.width * 0.4)
                    .chartLegend(.hidden)
                    
                    // Legend
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        ForEach(pieData, id: \.category) { item in
                            HStack(spacing: Spacing.sm) {
                                Circle()
                                    .fill(item.color)
                                    .frame(width: 10, height: 10)
                                
                                Text(item.category)
                                    .font(Typography.caption)
                                    .foregroundStyle(ColorPalette.secondaryText)
                                
                                Spacer()
                                
                                Text(String(format: "%.1fh", item.hours))
                                    .font(Typography.caption)
                                    .foregroundStyle(ColorPalette.primaryText)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
    
    private var pieData: [(category: String, hours: Double, color: Color)] {
        [
            ("Sleep", sleepHours, ColorPalette.sleep),
            ("Work", workHours, .purple),
            ("Screen Time", screenTimeHours, ColorPalette.screenTime),
            ("Active", activeHours, ColorPalette.exercise),
            ("Home", homeIdleHours, .gray.opacity(0.5))
        ].filter { $0.hours > 0 }
    }
}

// MARK: - Idle Score Widget (Small)

struct IdleScoreWidget: View {
    let idleHours: Double
    let weeklyTrend: [Double]  // 7 days
    
    var body: some View {
        WidgetCard(title: "Idle Time", icon: "pause.circle.fill", iconColor: .gray, size: .small) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Main metric
                HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                    Text(String(format: "%.1f", idleHours))
                        .font(Typography.largeMetric)
                    Text("hours")
                        .font(Typography.caption)
                        .foregroundStyle(ColorPalette.secondaryText)
                }
                
                // Sparkline
                if !weeklyTrend.isEmpty {
                    Chart(Array(weeklyTrend.enumerated()), id: \.offset) { index, value in
                        LineMark(
                            x: .value("Day", index),
                            y: .value("Hours", value)
                        )
                        .foregroundStyle(.gray)
                        .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                    }
                    .chartXAxis(.hidden)
                    .chartYAxis(.hidden)
                    .frame(height: 30)
                }
            }
        }
    }
}

// MARK: - Screen Time Widget (Small)

struct ScreenTimeWidget: View {
    let totalMinutes: Int
    let averageMinutes: Int
    let pickups: Int
    let hourlyData: [Int]  // 24 hours
    
    private var accessibilityText: String {
        let diff = totalMinutes - averageMinutes
        let comparison = diff >= 0 ? "\(formatTime(abs(diff))) above average" : "\(formatTime(abs(diff))) below average"
        return "\(formatTime(totalMinutes)), \(comparison), \(pickups) pickups"
    }
    
    var body: some View {
        WidgetCard(title: "Screen Time", icon: "iphone", iconColor: ColorPalette.screenTime, size: .small, tint: ColorPalette.screenTime.opacity(0.05), accessibilityValue: accessibilityText) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Main metric with comparison
                HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                    Text(formatTime(totalMinutes))
                        .font(Typography.metric)
                    
                    comparisonBadge
                }
                
                // Pickups
                Text("\(pickups) pickups")
                    .font(Typography.caption)
                    .foregroundStyle(ColorPalette.secondaryText)
                
                // Hourly bar chart
                if !hourlyData.isEmpty {
                    HourlyBarChart(data: hourlyData, color: ColorPalette.screenTime)
                        .frame(height: 24)
                }
            }
        }
    }
    
    @ViewBuilder
    private var comparisonBadge: some View {
        let diff = totalMinutes - averageMinutes
        let diffText = diff >= 0 ? "+\(formatTime(abs(diff)))" : "-\(formatTime(abs(diff)))"
        
        Text(diffText)
            .font(Typography.caption)
            .foregroundStyle(diff >= 0 ? .orange : .green)
    }
    
    private func formatTime(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins)m"
    }
}

// MARK: - Steps Widget (Small)

struct StepsWidget: View {
    let steps: Int
    let average: Int
    let distance: Double?  // meters
    
    private var accessibilityText: String {
        var text = "\(steps.formatted()) steps, \(Int(Double(steps) / Double(max(average, 1)) * 100)) percent of your average"
        if let distance = distance {
            text += ", \(String(format: "%.1f", distance / 1000)) kilometers"
        }
        return text
    }
    
    var body: some View {
        WidgetCard(title: "Steps", icon: "figure.walk", iconColor: ColorPalette.steps, size: .small, tint: ColorPalette.steps.opacity(0.05), accessibilityValue: accessibilityText) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Step count
                Text(steps.formatted())
                    .font(Typography.largeMetric)
                
                // Progress ring against personal average
                HStack(spacing: Spacing.md) {
                    ProgressRing(
                        progress: min(Double(steps) / Double(max(average, 1)), 1.5),
                        color: ColorPalette.steps,
                        lineWidth: 6
                    )
                    .frame(width: 40, height: 40)
                    .accessibilityHidden(true)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(Int(Double(steps) / Double(max(average, 1)) * 100))%")
                            .font(Typography.caption)
                            .foregroundStyle(ColorPalette.steps)
                        
                        Text("of avg")
                            .font(Typography.caption2)
                            .foregroundStyle(ColorPalette.tertiaryText)
                    }
                    
                    if let distance = distance {
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(String(format: "%.1f", distance / 1000))
                                .font(Typography.caption)
                            Text("km")
                                .font(Typography.caption2)
                                .foregroundStyle(ColorPalette.tertiaryText)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Sleep Widget (Small)

struct SleepWidget: View {
    let hours: Double
    let quality: SleepQuality?
    let weeklyTrend: [Double]
    
    private var accessibilityText: String {
        var text = "\(String(format: "%.1f", hours)) hours of sleep"
        if let quality = quality {
            text += ", quality: \(quality.displayName)"
        }
        return text
    }
    
    var body: some View {
        WidgetCard(title: "Sleep", icon: "bed.double.fill", iconColor: ColorPalette.sleep, size: .small, tint: ColorPalette.sleep.opacity(0.05), accessibilityValue: accessibilityText) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Main metric
                HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                    Text(String(format: "%.1f", hours))
                        .font(Typography.largeMetric)
                    Text("hours")
                        .font(Typography.caption)
                        .foregroundStyle(ColorPalette.secondaryText)
                    
                    Spacer()
                    
                    if let quality = quality {
                        Text(quality.displayName)
                            .font(Typography.caption)
                            .foregroundStyle(ColorPalette.color(for: quality))
                    }
                }
                
                // Weekly sparkline
                if !weeklyTrend.isEmpty {
                    Chart(Array(weeklyTrend.enumerated()), id: \.offset) { index, value in
                        AreaMark(
                            x: .value("Day", index),
                            y: .value("Hours", value)
                        )
                        .foregroundStyle(ColorPalette.sleep.opacity(0.3))
                        
                        LineMark(
                            x: .value("Day", index),
                            y: .value("Hours", value)
                        )
                        .foregroundStyle(ColorPalette.sleep)
                        .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                    }
                    .chartXAxis(.hidden)
                    .chartYAxis(.hidden)
                    .frame(height: 30)
                }
            }
        }
    }
}

// MARK: - Trend Card Widget (Medium)

struct TrendCardWidget: View {
    let trendText: String
    let trendType: TrendType
    let sparklineData: [Double]
    
    enum TrendType {
        case up, down, neutral
        
        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .neutral: return "arrow.right"
            }
        }
        
        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .orange
            case .neutral: return .gray
            }
        }
    }
    
    var body: some View {
        WidgetCard(title: "Trend", icon: "chart.line.uptrend.xyaxis", iconColor: trendType.color, size: .medium) {
            HStack(spacing: Spacing.lg) {
                // Trend text
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: trendType.icon)
                            .foregroundStyle(trendType.color)
                        Text(trendText)
                            .font(Typography.body)
                            .foregroundStyle(ColorPalette.primaryText)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Sparkline
                if !sparklineData.isEmpty {
                    Chart(Array(sparklineData.enumerated()), id: \.offset) { index, value in
                        LineMark(
                            x: .value("Day", index),
                            y: .value("Value", value)
                        )
                        .foregroundStyle(trendType.color)
                        .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                    }
                    .chartXAxis(.hidden)
                    .chartYAxis(.hidden)
                    .frame(width: 80, height: 40)
                }
            }
        }
    }
}

// MARK: - Weekly Insight Widget (Medium)

struct WeeklyInsightWidget: View {
    let insight: Insight?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            Haptics.insightRevealed()
            onTap()
        }) {
            WidgetCard(title: "Weekly Insight", icon: "sparkles", iconColor: ColorPalette.accent, size: .medium, tint: ColorPalette.accent.opacity(0.05)) {
                if let insight = insight {
                    HStack(spacing: Spacing.md) {
                        Image(systemName: insight.category.icon)
                            .font(.title2)
                            .foregroundStyle(ColorPalette.color(for: insight.category))
                        
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text(insight.title)
                                .font(Typography.headline)
                                .foregroundStyle(ColorPalette.primaryText)
                                .lineLimit(1)
                            
                            Text(insight.body)
                                .font(Typography.caption)
                                .foregroundStyle(ColorPalette.secondaryText)
                                .lineLimit(2)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(ColorPalette.tertiaryText)
                    }
                } else {
                    HStack {
                        Image(systemName: "sparkles")
                            .font(.title2)
                            .foregroundStyle(ColorPalette.tertiaryText)
                        
                        Text("Your first weekly insight arrives Sunday")
                            .font(Typography.body)
                            .foregroundStyle(ColorPalette.secondaryText)
                        
                        Spacer()
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Location Breakdown Widget (Small)

struct LocationBreakdownWidget: View {
    let homeHours: Double
    let workHours: Double
    let transitHours: Double
    let otherHours: Double
    let placesCount: Int
    
    var body: some View {
        WidgetCard(title: "Places", icon: "location.fill", iconColor: ColorPalette.location, size: .small, tint: ColorPalette.location.opacity(0.05)) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Stacked bar
                GeometryReader { geometry in
                    HStack(spacing: 2) {
                        ForEach(barData, id: \.label) { item in
                            Rectangle()
                                .fill(item.color)
                                .frame(width: max(geometry.size.width * CGFloat(item.hours / totalHours), 4))
                        }
                    }
                    .clipShape(Capsule())
                }
                .frame(height: 12)
                
                // Legend
                HStack(spacing: Spacing.md) {
                    ForEach(barData.prefix(3), id: \.label) { item in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(item.color)
                                .frame(width: 6, height: 6)
                            Text(item.label)
                                .font(Typography.caption2)
                                .foregroundStyle(ColorPalette.tertiaryText)
                        }
                    }
                }
                
                // Places count
                HStack {
                    Text("\(placesCount)")
                        .font(Typography.metric)
                    Text("places visited")
                        .font(Typography.caption)
                        .foregroundStyle(ColorPalette.secondaryText)
                }
            }
        }
    }
    
    private var barData: [(label: String, hours: Double, color: Color)] {
        [
            ("Home", homeHours, .blue),
            ("Work", workHours, .purple),
            ("Transit", transitHours, .green),
            ("Other", otherHours, .gray)
        ].filter { $0.hours > 0 }
    }
    
    private var totalHours: Double {
        homeHours + workHours + transitHours + otherHours
    }
}

// MARK: - Supporting Views

struct HourlyBarChart: View {
    let data: [Int]
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 1) {
                ForEach(0..<min(data.count, 24), id: \.self) { index in
                    let value = data[index]
                    let maxValue = data.max() ?? 1
                    let height = maxValue > 0 ? CGFloat(value) / CGFloat(maxValue) : 0
                    
                    Rectangle()
                        .fill(index == Calendar.current.component(.hour, from: Date()) ? color : color.opacity(0.5))
                        .frame(height: max(geometry.size.height * height, 2))
                        .frame(maxHeight: .infinity, alignment: .bottom)
                }
            }
        }
    }
}

struct ProgressRing: View {
    let progress: Double
    let color: Color
    var lineWidth: CGFloat = 8
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: min(progress, 1))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

// MARK: - Preview

#Preview("Insight Widgets") {
    ScrollView {
        VStack(spacing: Spacing.standard) {
            DayCompositionWidget(
                sleepHours: 7.5,
                workHours: 8,
                screenTimeHours: 4,
                activeHours: 1.5,
                homeIdleHours: 3
            )
            
            HStack(spacing: Spacing.standard) {
                StepsWidget(steps: 8432, average: 7500, distance: 6200)
                SleepWidget(hours: 7.5, quality: .good, weeklyTrend: [7, 6.5, 8, 7, 6, 7.5, 8])
            }
            
            HStack(spacing: Spacing.standard) {
                ScreenTimeWidget(
                    totalMinutes: 245,
                    averageMinutes: 200,
                    pickups: 52,
                    hourlyData: Array(0..<24).map { _ in Int.random(in: 0...30) }
                )
                IdleScoreWidget(idleHours: 3.5, weeklyTrend: [2, 3, 4, 3, 2.5, 3, 3.5])
            }
            
            TrendCardWidget(
                trendText: "Your screen time is down 15% this week",
                trendType: .down,
                sparklineData: [300, 280, 260, 250, 245, 230, 220]
            )
            
            WeeklyInsightWidget(insight: nil, onTap: {})
            
            LocationBreakdownWidget(
                homeHours: 12,
                workHours: 8,
                transitHours: 1.5,
                otherHours: 2.5,
                placesCount: 4
            )
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
