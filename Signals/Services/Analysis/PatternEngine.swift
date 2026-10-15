//
//  PatternEngine.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import Foundation
import SwiftData

/// Detects behavioral patterns in user data
@MainActor
final class PatternEngine {
    static let shared = PatternEngine()
    
    // Minimum data requirements
    private let minimumDaysForDayOfWeekPattern = 14
    private let minimumDaysForStreakDetection = 3
    private let minimumDaysForBaseline = 7
    
    // MARK: - Pattern Detection
    
    /// Analyze snapshots and detect all patterns
    func detectPatterns(from snapshots: [DailySnapshot]) -> [DetectedPattern] {
        guard snapshots.count >= minimumDaysForBaseline else {
            return []
        }
        
        var patterns: [DetectedPattern] = []
        
        // Day of week patterns
        patterns.append(contentsOf: detectDayOfWeekPatterns(from: snapshots))
        
        // Streak patterns
        patterns.append(contentsOf: detectStreaks(from: snapshots))
        
        // Baseline deviations
        patterns.append(contentsOf: detectDeviations(from: snapshots))
        
        // Time-based patterns
        patterns.append(contentsOf: detectTimePatterns(from: snapshots))
        
        return patterns.sorted { $0.confidence > $1.confidence }
    }
    
    // MARK: - Day of Week Patterns
    
    /// Detect patterns that occur on specific days of the week
    func detectDayOfWeekPatterns(from snapshots: [DailySnapshot]) -> [DetectedPattern] {
        guard snapshots.count >= minimumDaysForDayOfWeekPattern else {
            return []
        }
        
        var patterns: [DetectedPattern] = []
        
        // Group snapshots by day of week
        var byDayOfWeek: [Int: [DailySnapshot]] = [:]
        for snapshot in snapshots {
            byDayOfWeek[snapshot.dayOfWeek, default: []].append(snapshot)
        }
        
        // Analyze steps by day of week
        if let stepPattern = analyzeMetricByDayOfWeek(
            snapshots: snapshots,
            byDayOfWeek: byDayOfWeek,
            metricName: "steps",
            getValue: { $0.stepCount.map { Double($0) } }
        ) {
            patterns.append(stepPattern)
        }
        
        // Analyze sleep by day of week
        if let sleepPattern = analyzeMetricByDayOfWeek(
            snapshots: snapshots,
            byDayOfWeek: byDayOfWeek,
            metricName: "sleep",
            getValue: { $0.sleepHours }
        ) {
            patterns.append(sleepPattern)
        }
        
        // Analyze screen time by day of week
        if let screenPattern = analyzeMetricByDayOfWeek(
            snapshots: snapshots,
            byDayOfWeek: byDayOfWeek,
            metricName: "screenTime",
            getValue: { $0.screenTimeMinutes.map { Double($0) } }
        ) {
            patterns.append(screenPattern)
        }
        
        // Weekend vs weekday patterns
        if let weekendPattern = detectWeekendPattern(from: snapshots) {
            patterns.append(weekendPattern)
        }
        
        return patterns
    }
    
    private func analyzeMetricByDayOfWeek(
        snapshots: [DailySnapshot],
        byDayOfWeek: [Int: [DailySnapshot]],
        metricName: String,
        getValue: (DailySnapshot) -> Double?
    ) -> DetectedPattern? {
        var averageByDay: [Int: Double] = [:]
        var countByDay: [Int: Int] = [:]
        
        for (day, daySnapshots) in byDayOfWeek {
            let values = daySnapshots.compactMap(getValue)
            guard !values.isEmpty else { continue }
            averageByDay[day] = values.reduce(0, +) / Double(values.count)
            countByDay[day] = values.count
        }
        
        guard averageByDay.count >= 5 else { return nil }
        
        // Find the day with highest and lowest average
        guard let maxDay = averageByDay.max(by: { $0.value < $1.value }),
              let minDay = averageByDay.min(by: { $0.value < $1.value }) else {
            return nil
        }
        
        // Calculate overall average
        let allValues = snapshots.compactMap(getValue)
        let overallAverage = allValues.reduce(0, +) / Double(allValues.count)
        
        // Check if the difference is significant (> 20%)
        let maxDiff = (maxDay.value - overallAverage) / overallAverage
        let minDiff = (overallAverage - minDay.value) / overallAverage
        
        guard maxDiff > 0.2 || minDiff > 0.2 else { return nil }
        
        // Determine which pattern is more significant
        if maxDiff > minDiff {
            let confidence = min(0.9, 0.5 + maxDiff)
            return DetectedPattern(
                type: .dayOfWeek,
                signal: signalForMetric(metricName),
                description: "highest_on_day",
                dayOfWeek: maxDay.key,
                value: maxDay.value,
                comparisonValue: overallAverage,
                confidence: confidence
            )
        } else {
            let confidence = min(0.9, 0.5 + minDiff)
            return DetectedPattern(
                type: .dayOfWeek,
                signal: signalForMetric(metricName),
                description: "lowest_on_day",
                dayOfWeek: minDay.key,
                value: minDay.value,
                comparisonValue: overallAverage,
                confidence: confidence
            )
        }
    }
    
    private func detectWeekendPattern(from snapshots: [DailySnapshot]) -> DetectedPattern? {
        let weekdaySnapshots = snapshots.filter { !$0.isWeekend }
        let weekendSnapshots = snapshots.filter { $0.isWeekend }
        
        guard weekdaySnapshots.count >= 5, weekendSnapshots.count >= 2 else {
            return nil
        }
        
        // Compare steps
        let weekdaySteps = weekdaySnapshots.compactMap { $0.stepCount }
        let weekendSteps = weekendSnapshots.compactMap { $0.stepCount }
        
        guard !weekdaySteps.isEmpty, !weekendSteps.isEmpty else { return nil }
        
        let avgWeekday = Double(weekdaySteps.reduce(0, +)) / Double(weekdaySteps.count)
        let avgWeekend = Double(weekendSteps.reduce(0, +)) / Double(weekendSteps.count)
        
        let difference = abs(avgWeekday - avgWeekend) / max(avgWeekday, avgWeekend)
        
        guard difference > 0.15 else { return nil }
        
        let isMoreActiveWeekday = avgWeekday > avgWeekend
        
        return DetectedPattern(
            type: .weekendVsWeekday,
            signal: .steps,
            description: isMoreActiveWeekday ? "more_active_weekdays" : "more_active_weekends",
            value: isMoreActiveWeekday ? avgWeekday : avgWeekend,
            comparisonValue: isMoreActiveWeekday ? avgWeekend : avgWeekday,
            confidence: min(0.85, 0.5 + difference)
        )
    }
    
    // MARK: - Streak Detection
    
    /// Detect streaks of consistent behavior
    func detectStreaks(from snapshots: [DailySnapshot]) -> [DetectedPattern] {
        var patterns: [DetectedPattern] = []
        
        // Sort snapshots by date
        let sorted = snapshots.sorted { $0.date < $1.date }
        
        // Detect high step streaks (> 8000 steps)
        if let stepStreak = detectStreak(
            snapshots: sorted,
            condition: { ($0.stepCount ?? 0) >= 8000 },
            signal: .steps,
            description: "high_steps_streak"
        ) {
            patterns.append(stepStreak)
        }
        
        // Detect good sleep streaks (> 7 hours)
        if let sleepStreak = detectStreak(
            snapshots: sorted,
            condition: { ($0.sleepHours ?? 0) >= 7.0 },
            signal: .sleep,
            description: "good_sleep_streak"
        ) {
            patterns.append(sleepStreak)
        }
        
        // Detect reflection streaks
        if let reflectionStreak = detectStreak(
            snapshots: sorted,
            condition: { !($0.reflections?.isEmpty ?? true) },
            signal: .reflection,
            description: "reflection_streak"
        ) {
            patterns.append(reflectionStreak)
        }
        
        // Detect low screen time streaks (< 2 hours)
        if let screenStreak = detectStreak(
            snapshots: sorted,
            condition: { ($0.screenTimeMinutes ?? Int.max) < 120 },
            signal: .screenTime,
            description: "low_screen_time_streak"
        ) {
            patterns.append(screenStreak)
        }
        
        return patterns
    }
    
    private func detectStreak(
        snapshots: [DailySnapshot],
        condition: (DailySnapshot) -> Bool,
        signal: SignalType,
        description: String
    ) -> DetectedPattern? {
        var currentStreak = 0
        var maxStreak = 0
        var streakEndDate: Date?
        
        for snapshot in snapshots {
            if condition(snapshot) {
                currentStreak += 1
                if currentStreak > maxStreak {
                    maxStreak = currentStreak
                    streakEndDate = snapshot.date
                }
            } else {
                currentStreak = 0
            }
        }
        
        // Also check if current streak is ongoing
        let isOngoing = currentStreak == maxStreak && currentStreak >= minimumDaysForStreakDetection
        
        guard maxStreak >= minimumDaysForStreakDetection else { return nil }
        
        let confidence = min(0.9, 0.5 + Double(maxStreak) * 0.05)
        
        return DetectedPattern(
            type: .streak,
            signal: signal,
            description: description,
            streakDays: maxStreak,
            streakEndDate: streakEndDate,
            isOngoing: isOngoing,
            confidence: confidence
        )
    }
    
    // MARK: - Baseline & Deviations
    
    /// Calculate personal baselines for all metrics
    func calculateBaselines(from snapshots: [DailySnapshot]) -> PersonalBaseline {
        let steps = snapshots.compactMap { $0.stepCount }
        let sleep = snapshots.compactMap { $0.sleepHours }
        let screenTime = snapshots.compactMap { $0.screenTimeMinutes }
        let exercise = snapshots.compactMap { $0.exerciseMinutes }
        
        return PersonalBaseline(
            averageSteps: steps.isEmpty ? nil : steps.reduce(0, +) / steps.count,
            stepsStdDev: standardDeviation(steps.map { Double($0) }),
            averageSleep: sleep.isEmpty ? nil : sleep.reduce(0, +) / Double(sleep.count),
            sleepStdDev: standardDeviation(sleep),
            averageScreenTime: screenTime.isEmpty ? nil : screenTime.reduce(0, +) / screenTime.count,
            screenTimeStdDev: standardDeviation(screenTime.map { Double($0) }),
            averageExercise: exercise.isEmpty ? nil : exercise.reduce(0, +) / exercise.count,
            calculatedFrom: snapshots.count
        )
    }
    
    /// Detect significant deviations from baseline
    func detectDeviations(from snapshots: [DailySnapshot]) -> [DetectedPattern] {
        guard snapshots.count >= minimumDaysForBaseline else { return [] }
        
        let baseline = calculateBaselines(from: snapshots)
        var patterns: [DetectedPattern] = []
        
        // Check the most recent snapshot for deviations
        guard let latest = snapshots.max(by: { $0.date < $1.date }) else {
            return []
        }
        
        // Check step deviation
        if let steps = latest.stepCount,
           let avgSteps = baseline.averageSteps,
           let stdDev = baseline.stepsStdDev,
           stdDev > 0 {
            let zScore = (Double(steps) - Double(avgSteps)) / stdDev
            if abs(zScore) > 1.5 {
                patterns.append(DetectedPattern(
                    type: .anomaly,
                    signal: .steps,
                    description: zScore > 0 ? "unusually_high_steps" : "unusually_low_steps",
                    value: Double(steps),
                    comparisonValue: Double(avgSteps),
                    date: latest.date,
                    confidence: min(0.9, 0.5 + abs(zScore) * 0.15)
                ))
            }
        }
        
        // Check sleep deviation
        if let sleep = latest.sleepHours,
           let avgSleep = baseline.averageSleep,
           let stdDev = baseline.sleepStdDev,
           stdDev > 0 {
            let zScore = (sleep - avgSleep) / stdDev
            if abs(zScore) > 1.5 {
                patterns.append(DetectedPattern(
                    type: .anomaly,
                    signal: .sleep,
                    description: zScore > 0 ? "unusually_high_sleep" : "unusually_low_sleep",
                    value: sleep,
                    comparisonValue: avgSleep,
                    date: latest.date,
                    confidence: min(0.9, 0.5 + abs(zScore) * 0.15)
                ))
            }
        }
        
        return patterns
    }
    
    // MARK: - Time Patterns
    
    /// Detect patterns related to time of day
    func detectTimePatterns(from snapshots: [DailySnapshot]) -> [DetectedPattern] {
        var patterns: [DetectedPattern] = []
        
        // Analyze reflection writing times
        var morningReflections = 0
        var eveningReflections = 0
        var totalReflections = 0
        
        for snapshot in snapshots {
            guard let reflections = snapshot.reflections else { continue }
            for reflection in reflections {
                totalReflections += 1
                let hour = Calendar.current.component(.hour, from: reflection.createdAt)
                if hour < 12 {
                    morningReflections += 1
                } else if hour >= 18 {
                    eveningReflections += 1
                }
            }
        }
        
        if totalReflections >= 10 {
            let morningRatio = Double(morningReflections) / Double(totalReflections)
            let eveningRatio = Double(eveningReflections) / Double(totalReflections)
            
            if morningRatio > 0.6 {
                patterns.append(DetectedPattern(
                    type: .timeOfDay,
                    signal: .reflection,
                    description: "morning_reflection_preference",
                    value: morningRatio,
                    confidence: min(0.85, morningRatio)
                ))
            } else if eveningRatio > 0.6 {
                patterns.append(DetectedPattern(
                    type: .timeOfDay,
                    signal: .reflection,
                    description: "evening_reflection_preference",
                    value: eveningRatio,
                    confidence: min(0.85, eveningRatio)
                ))
            }
        }
        
        return patterns
    }
    
    // MARK: - Helpers
    
    private func signalForMetric(_ metric: String) -> SignalType {
        switch metric {
        case "steps": return .steps
        case "sleep": return .sleep
        case "screenTime": return .screenTime
        case "exercise": return .exercise
        default: return .steps
        }
    }
    
    private func standardDeviation(_ values: [Double]) -> Double? {
        guard values.count > 1 else { return nil }
        let mean = values.reduce(0, +) / Double(values.count)
        let squaredDiffs = values.map { pow($0 - mean, 2) }
        let variance = squaredDiffs.reduce(0, +) / Double(values.count - 1)
        return sqrt(variance)
    }
    
    private init() {}
}

// MARK: - Supporting Types

struct DetectedPattern {
    let type: PatternType
    let signal: SignalType
    let description: String
    var dayOfWeek: Int?
    var value: Double?
    var comparisonValue: Double?
    var date: Date?
    var streakDays: Int?
    var streakEndDate: Date?
    var isOngoing: Bool?
    var confidence: Double
    
    init(
        type: PatternType,
        signal: SignalType,
        description: String,
        dayOfWeek: Int? = nil,
        value: Double? = nil,
        comparisonValue: Double? = nil,
        date: Date? = nil,
        streakDays: Int? = nil,
        streakEndDate: Date? = nil,
        isOngoing: Bool? = nil,
        confidence: Double
    ) {
        self.type = type
        self.signal = signal
        self.description = description
        self.dayOfWeek = dayOfWeek
        self.value = value
        self.comparisonValue = comparisonValue
        self.date = date
        self.streakDays = streakDays
        self.streakEndDate = streakEndDate
        self.isOngoing = isOngoing
        self.confidence = confidence
    }
    
    var dayName: String? {
        guard let day = dayOfWeek else { return nil }
        let formatter = DateFormatter()
        return formatter.weekdaySymbols[day - 1]
    }
}

enum PatternType {
    case dayOfWeek
    case weekendVsWeekday
    case streak
    case anomaly
    case timeOfDay
    case milestone
}

struct PersonalBaseline {
    var averageSteps: Int?
    var stepsStdDev: Double?
    var averageSleep: Double?
    var sleepStdDev: Double?
    var averageScreenTime: Int?
    var screenTimeStdDev: Double?
    var averageExercise: Int?
    var calculatedFrom: Int  // Number of days used
}
