//
//  TrendAnalyzer.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import Foundation

/// Analyzes trends over time (week-over-week, month-over-month)
@MainActor
final class TrendAnalyzer {
    static let shared = TrendAnalyzer()
    
    // Minimum significant change threshold
    private let significantChangeThreshold = 0.10  // 10%
    
    // MARK: - Week Comparison
    
    /// Compare two weeks of data
    func compareWeeks(current: [DailySnapshot], previous: [DailySnapshot]) -> WeekComparison {
        var comparison = WeekComparison(
            stepsChange: nil,
            sleepChange: nil,
            screenTimeChange: nil,
            moodChange: nil,
            reflectionCountChange: nil
        )
        
        // Steps comparison
        let currentSteps = current.compactMap { $0.stepCount }
        let previousSteps = previous.compactMap { $0.stepCount }
        if !currentSteps.isEmpty && !previousSteps.isEmpty {
            let currentAvg = Double(currentSteps.reduce(0, +)) / Double(currentSteps.count)
            let previousAvg = Double(previousSteps.reduce(0, +)) / Double(previousSteps.count)
            if previousAvg > 0 {
                comparison = WeekComparison(
                    stepsChange: (currentAvg - previousAvg) / previousAvg * 100,
                    sleepChange: comparison.sleepChange,
                    screenTimeChange: comparison.screenTimeChange,
                    moodChange: comparison.moodChange,
                    reflectionCountChange: comparison.reflectionCountChange
                )
            }
        }
        
        // Sleep comparison
        let currentSleep = current.compactMap { $0.sleepHours }
        let previousSleep = previous.compactMap { $0.sleepHours }
        if !currentSleep.isEmpty && !previousSleep.isEmpty {
            let currentAvg = currentSleep.reduce(0, +) / Double(currentSleep.count)
            let previousAvg = previousSleep.reduce(0, +) / Double(previousSleep.count)
            if previousAvg > 0 {
                comparison = WeekComparison(
                    stepsChange: comparison.stepsChange,
                    sleepChange: (currentAvg - previousAvg) / previousAvg * 100,
                    screenTimeChange: comparison.screenTimeChange,
                    moodChange: comparison.moodChange,
                    reflectionCountChange: comparison.reflectionCountChange
                )
            }
        }
        
        // Screen time comparison
        let currentScreen = current.compactMap { $0.screenTimeMinutes }
        let previousScreen = previous.compactMap { $0.screenTimeMinutes }
        if !currentScreen.isEmpty && !previousScreen.isEmpty {
            let currentAvg = Double(currentScreen.reduce(0, +)) / Double(currentScreen.count)
            let previousAvg = Double(previousScreen.reduce(0, +)) / Double(previousScreen.count)
            if previousAvg > 0 {
                comparison = WeekComparison(
                    stepsChange: comparison.stepsChange,
                    sleepChange: comparison.sleepChange,
                    screenTimeChange: (currentAvg - previousAvg) / previousAvg * 100,
                    moodChange: comparison.moodChange,
                    reflectionCountChange: comparison.reflectionCountChange
                )
            }
        }
        
        // Mood comparison
        let currentMoods = current.compactMap { $0.averageMood }
        let previousMoods = previous.compactMap { $0.averageMood }
        if !currentMoods.isEmpty && !previousMoods.isEmpty {
            let currentAvg = currentMoods.reduce(0, +) / Double(currentMoods.count)
            let previousAvg = previousMoods.reduce(0, +) / Double(previousMoods.count)
            if previousAvg > 0 {
                comparison = WeekComparison(
                    stepsChange: comparison.stepsChange,
                    sleepChange: comparison.sleepChange,
                    screenTimeChange: comparison.screenTimeChange,
                    moodChange: (currentAvg - previousAvg) / previousAvg * 100,
                    reflectionCountChange: comparison.reflectionCountChange
                )
            }
        }
        
        // Reflection count comparison
        let currentReflections = current.reduce(0) { $0 + ($1.reflections?.count ?? 0) }
        let previousReflections = previous.reduce(0) { $0 + ($1.reflections?.count ?? 0) }
        comparison = WeekComparison(
            stepsChange: comparison.stepsChange,
            sleepChange: comparison.sleepChange,
            screenTimeChange: comparison.screenTimeChange,
            moodChange: comparison.moodChange,
            reflectionCountChange: currentReflections - previousReflections
        )
        
        return comparison
    }
    
    // MARK: - Trend Detection
    
    /// Detect trends over a period of time
    func detectTrends(from snapshots: [DailySnapshot]) -> [DetectedTrend] {
        guard snapshots.count >= 14 else { return [] }
        
        var trends: [DetectedTrend] = []
        
        // Sort by date
        let sorted = snapshots.sorted { $0.date < $1.date }
        
        // Detect step trends
        if let stepTrend = detectMetricTrend(
            snapshots: sorted,
            getValue: { $0.stepCount.map { Double($0) } },
            signal: .steps
        ) {
            trends.append(stepTrend)
        }
        
        // Detect sleep trends
        if let sleepTrend = detectMetricTrend(
            snapshots: sorted,
            getValue: { $0.sleepHours },
            signal: .sleep
        ) {
            trends.append(sleepTrend)
        }
        
        // Detect screen time trends
        if let screenTrend = detectMetricTrend(
            snapshots: sorted,
            getValue: { $0.screenTimeMinutes.map { Double($0) } },
            signal: .screenTime
        ) {
            trends.append(screenTrend)
        }
        
        // Detect exercise trends
        if let exerciseTrend = detectMetricTrend(
            snapshots: sorted,
            getValue: { $0.exerciseMinutes.map { Double($0) } },
            signal: .exercise
        ) {
            trends.append(exerciseTrend)
        }
        
        return trends.filter { abs($0.percentageChange) >= significantChangeThreshold * 100 }
    }
    
    private func detectMetricTrend(
        snapshots: [DailySnapshot],
        getValue: (DailySnapshot) -> Double?,
        signal: SignalType
    ) -> DetectedTrend? {
        // Split into first half and second half
        let midpoint = snapshots.count / 2
        let firstHalf = Array(snapshots.prefix(midpoint))
        let secondHalf = Array(snapshots.suffix(snapshots.count - midpoint))
        
        let firstValues = firstHalf.compactMap(getValue)
        let secondValues = secondHalf.compactMap(getValue)
        
        guard firstValues.count >= 3, secondValues.count >= 3 else {
            return nil
        }
        
        let firstAvg = firstValues.reduce(0, +) / Double(firstValues.count)
        let secondAvg = secondValues.reduce(0, +) / Double(secondValues.count)
        
        guard firstAvg > 0 else { return nil }
        
        let percentChange = (secondAvg - firstAvg) / firstAvg * 100
        
        // Calculate trend direction using simple linear regression
        let direction = calculateTrendDirection(
            snapshots: snapshots,
            getValue: getValue
        )
        
        return DetectedTrend(
            signal: signal,
            direction: direction,
            percentageChange: percentChange,
            startValue: firstAvg,
            endValue: secondAvg,
            periodDays: snapshots.count,
            confidence: min(0.9, 0.5 + abs(percentChange) / 100)
        )
    }
    
    private func calculateTrendDirection(
        snapshots: [DailySnapshot],
        getValue: (DailySnapshot) -> Double?
    ) -> TrendDirection {
        // Use linear regression slope to determine direction
        var points: [(x: Double, y: Double)] = []
        
        for (index, snapshot) in snapshots.enumerated() {
            if let value = getValue(snapshot) {
                points.append((x: Double(index), y: value))
            }
        }
        
        guard points.count >= 5 else { return .stable }
        
        let slope = linearRegressionSlope(points)
        
        // Normalize slope by average value to get percentage change per day
        let avgY = points.map { $0.y }.reduce(0, +) / Double(points.count)
        guard avgY > 0 else { return .stable }
        
        let normalizedSlope = slope / avgY
        
        if normalizedSlope > 0.01 {  // > 1% per day increase
            return .increasing
        } else if normalizedSlope < -0.01 {  // > 1% per day decrease
            return .decreasing
        } else {
            return .stable
        }
    }
    
    private func linearRegressionSlope(_ points: [(x: Double, y: Double)]) -> Double {
        let n = Double(points.count)
        let sumX = points.map { $0.x }.reduce(0, +)
        let sumY = points.map { $0.y }.reduce(0, +)
        let sumXY = points.map { $0.x * $0.y }.reduce(0, +)
        let sumX2 = points.map { $0.x * $0.x }.reduce(0, +)
        
        let denominator = n * sumX2 - sumX * sumX
        guard denominator != 0 else { return 0 }
        
        return (n * sumXY - sumX * sumY) / denominator
    }
    
    // MARK: - Month Comparison
    
    /// Compare current month to previous month
    func compareMonths(current: [DailySnapshot], previous: [DailySnapshot]) -> MonthComparison {
        let weekComparison = compareWeeks(current: current, previous: previous)
        
        // Additional month-specific metrics
        let currentActiveDays = current.filter { $0.hasData }.count
        let previousActiveDays = previous.filter { $0.hasData }.count
        
        let currentReflectionDays = current.filter { !($0.reflections?.isEmpty ?? true) }.count
        let previousReflectionDays = previous.filter { !($0.reflections?.isEmpty ?? true) }.count
        
        return MonthComparison(
            weekComparison: weekComparison,
            activeDaysChange: currentActiveDays - previousActiveDays,
            reflectionDaysChange: currentReflectionDays - previousReflectionDays,
            currentActiveDays: currentActiveDays,
            previousActiveDays: previousActiveDays
        )
    }
    
    // MARK: - Helpers
    
    /// Get snapshots for a specific week
    func snapshotsForWeek(containing date: Date, from allSnapshots: [DailySnapshot]) -> [DailySnapshot] {
        let calendar = Calendar.current
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)),
              let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else {
            return []
        }
        
        return allSnapshots.filter { snapshot in
            snapshot.date >= weekStart && snapshot.date < weekEnd
        }
    }
    
    /// Get snapshots for a specific month
    func snapshotsForMonth(containing date: Date, from allSnapshots: [DailySnapshot]) -> [DailySnapshot] {
        let calendar = Calendar.current
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: date)),
              let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else {
            return []
        }
        
        return allSnapshots.filter { snapshot in
            snapshot.date >= monthStart && snapshot.date < monthEnd
        }
    }
    
    private init() {}
}

// MARK: - Supporting Types

struct DetectedTrend {
    let signal: SignalType
    let direction: TrendDirection
    let percentageChange: Double
    let startValue: Double
    let endValue: Double
    let periodDays: Int
    let confidence: Double
    
    var isSignificant: Bool {
        abs(percentageChange) >= 10
    }
    
    var changeDescription: String {
        let absChange = abs(percentageChange)
        if absChange < 5 {
            return "stayed about the same"
        } else if absChange < 15 {
            return direction == .increasing ? "increased slightly" : "decreased slightly"
        } else if absChange < 30 {
            return direction == .increasing ? "increased" : "decreased"
        } else {
            return direction == .increasing ? "increased significantly" : "decreased significantly"
        }
    }
}

enum TrendDirection: String {
    case increasing
    case decreasing
    case stable
    
    var displayName: String {
        rawValue
    }
    
    var icon: String {
        switch self {
        case .increasing: return "arrow.up.right"
        case .decreasing: return "arrow.down.right"
        case .stable: return "arrow.right"
        }
    }
}

struct MonthComparison {
    let weekComparison: WeekComparison
    let activeDaysChange: Int
    let reflectionDaysChange: Int
    let currentActiveDays: Int
    let previousActiveDays: Int
}
