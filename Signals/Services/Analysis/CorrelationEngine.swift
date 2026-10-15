//
//  CorrelationEngine.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import Foundation

/// Analyzes correlations between different signals
@MainActor
final class CorrelationEngine {
    static let shared = CorrelationEngine()
    
    // Minimum requirements for correlation analysis
    private let minimumDataPoints = 14
    private let significanceThreshold = 0.4  // |r| > 0.4 to report
    private let pValueThreshold = 0.05
    
    // MARK: - Correlation Analysis
    
    /// Analyze all correlations between signals
    func analyzeCorrelations(from snapshots: [DailySnapshot]) -> [DetectedCorrelation] {
        guard snapshots.count >= minimumDataPoints else {
            return []
        }
        
        var correlations: [DetectedCorrelation] = []
        
        // Sleep → Next Day correlations
        correlations.append(contentsOf: analyzeSleepCorrelations(from: snapshots))
        
        // Screen Time correlations
        correlations.append(contentsOf: analyzeScreenTimeCorrelations(from: snapshots))
        
        // Steps/Activity correlations
        correlations.append(contentsOf: analyzeActivityCorrelations(from: snapshots))
        
        // Weather correlations
        correlations.append(contentsOf: analyzeWeatherCorrelations(from: snapshots))
        
        // Filter by significance and sort by correlation strength
        return correlations
            .filter { abs($0.correlationCoefficient) >= significanceThreshold }
            .sorted { abs($0.correlationCoefficient) > abs($1.correlationCoefficient) }
    }
    
    // MARK: - Sleep Correlations
    
    private func analyzeSleepCorrelations(from snapshots: [DailySnapshot]) -> [DetectedCorrelation] {
        var correlations: [DetectedCorrelation] = []
        
        // Sort by date to pair consecutive days
        let sorted = snapshots.sorted { $0.date < $1.date }
        
        // Build pairs of (previous night's sleep, next day's data)
        var sleepToNextDaySteps: [(Double, Double)] = []
        var sleepToNextDayMood: [(Double, Double)] = []
        var sleepToNextDayScreenTime: [(Double, Double)] = []
        
        for i in 0..<(sorted.count - 1) {
            let today = sorted[i]
            let tomorrow = sorted[i + 1]
            
            // Check if days are consecutive
            guard let daysBetween = Calendar.current.dateComponents([.day], from: today.date, to: tomorrow.date).day,
                  daysBetween == 1 else {
                continue
            }
            
            if let sleep = today.sleepHours {
                if let steps = tomorrow.stepCount {
                    sleepToNextDaySteps.append((sleep, Double(steps)))
                }
                if let mood = tomorrow.averageMood {
                    sleepToNextDayMood.append((sleep, mood))
                }
                if let screenTime = tomorrow.screenTimeMinutes {
                    sleepToNextDayScreenTime.append((sleep, Double(screenTime)))
                }
            }
        }
        
        // Calculate correlations
        if let r = pearsonCorrelation(sleepToNextDaySteps) {
            correlations.append(DetectedCorrelation(
                signal1: .sleep,
                signal2: .steps,
                relationship: .sleepToNextDayActivity,
                correlationCoefficient: r,
                dataPoints: sleepToNextDaySteps.count,
                isPositive: r > 0
            ))
        }
        
        if let r = pearsonCorrelation(sleepToNextDayMood) {
            correlations.append(DetectedCorrelation(
                signal1: .sleep,
                signal2: .mood,
                relationship: .sleepToNextDayMood,
                correlationCoefficient: r,
                dataPoints: sleepToNextDayMood.count,
                isPositive: r > 0
            ))
        }
        
        if let r = pearsonCorrelation(sleepToNextDayScreenTime) {
            // Note: negative correlation would mean better sleep = less screen time
            correlations.append(DetectedCorrelation(
                signal1: .sleep,
                signal2: .screenTime,
                relationship: .sleepToNextDayScreenTime,
                correlationCoefficient: r,
                dataPoints: sleepToNextDayScreenTime.count,
                isPositive: r > 0
            ))
        }
        
        return correlations
    }
    
    // MARK: - Screen Time Correlations
    
    private func analyzeScreenTimeCorrelations(from snapshots: [DailySnapshot]) -> [DetectedCorrelation] {
        var correlations: [DetectedCorrelation] = []
        
        let sorted = snapshots.sorted { $0.date < $1.date }
        
        // Screen time today → sleep quality tonight
        var screenTimeToSleep: [(Double, Double)] = []
        
        for i in 0..<(sorted.count - 1) {
            let today = sorted[i]
            let tomorrow = sorted[i + 1]
            
            guard let daysBetween = Calendar.current.dateComponents([.day], from: today.date, to: tomorrow.date).day,
                  daysBetween == 1 else {
                continue
            }
            
            if let screenTime = today.screenTimeMinutes,
               let sleep = tomorrow.sleepHours {
                screenTimeToSleep.append((Double(screenTime), sleep))
            }
        }
        
        if let r = pearsonCorrelation(screenTimeToSleep) {
            correlations.append(DetectedCorrelation(
                signal1: .screenTime,
                signal2: .sleep,
                relationship: .screenTimeToSleep,
                correlationCoefficient: r,
                dataPoints: screenTimeToSleep.count,
                isPositive: r > 0
            ))
        }
        
        // Same day: screen time vs mood
        var screenTimeToMood: [(Double, Double)] = []
        for snapshot in snapshots {
            if let screenTime = snapshot.screenTimeMinutes,
               let mood = snapshot.averageMood {
                screenTimeToMood.append((Double(screenTime), mood))
            }
        }
        
        if let r = pearsonCorrelation(screenTimeToMood) {
            correlations.append(DetectedCorrelation(
                signal1: .screenTime,
                signal2: .mood,
                relationship: .screenTimeToMood,
                correlationCoefficient: r,
                dataPoints: screenTimeToMood.count,
                isPositive: r > 0
            ))
        }
        
        return correlations
    }
    
    // MARK: - Activity Correlations
    
    private func analyzeActivityCorrelations(from snapshots: [DailySnapshot]) -> [DetectedCorrelation] {
        var correlations: [DetectedCorrelation] = []
        
        // Steps vs mood (same day)
        var stepsToMood: [(Double, Double)] = []
        for snapshot in snapshots {
            if let steps = snapshot.stepCount,
               let mood = snapshot.averageMood {
                stepsToMood.append((Double(steps), mood))
            }
        }
        
        if let r = pearsonCorrelation(stepsToMood) {
            correlations.append(DetectedCorrelation(
                signal1: .steps,
                signal2: .mood,
                relationship: .stepsToMood,
                correlationCoefficient: r,
                dataPoints: stepsToMood.count,
                isPositive: r > 0
            ))
        }
        
        // Steps vs reflection sentiment
        var stepsToReflectionSentiment: [(Double, Double)] = []
        for snapshot in snapshots {
            guard let steps = snapshot.stepCount,
                  let reflections = snapshot.reflections,
                  !reflections.isEmpty else { continue }
            
            let sentimentScore = reflections.compactMap { $0.sentiment }.map { sentimentToScore($0) }
            guard !sentimentScore.isEmpty else { continue }
            
            let avgSentiment = sentimentScore.reduce(0, +) / Double(sentimentScore.count)
            stepsToReflectionSentiment.append((Double(steps), avgSentiment))
        }
        
        if let r = pearsonCorrelation(stepsToReflectionSentiment) {
            correlations.append(DetectedCorrelation(
                signal1: .steps,
                signal2: .reflection,
                relationship: .stepsToReflectionSentiment,
                correlationCoefficient: r,
                dataPoints: stepsToReflectionSentiment.count,
                isPositive: r > 0
            ))
        }
        
        // Exercise vs sleep quality
        let sorted = snapshots.sorted { $0.date < $1.date }
        var exerciseToSleep: [(Double, Double)] = []
        
        for i in 0..<(sorted.count - 1) {
            let today = sorted[i]
            let tomorrow = sorted[i + 1]
            
            guard let daysBetween = Calendar.current.dateComponents([.day], from: today.date, to: tomorrow.date).day,
                  daysBetween == 1 else { continue }
            
            if let exercise = today.exerciseMinutes,
               let sleep = tomorrow.sleepHours {
                exerciseToSleep.append((Double(exercise), sleep))
            }
        }
        
        if let r = pearsonCorrelation(exerciseToSleep) {
            correlations.append(DetectedCorrelation(
                signal1: .exercise,
                signal2: .sleep,
                relationship: .exerciseToSleep,
                correlationCoefficient: r,
                dataPoints: exerciseToSleep.count,
                isPositive: r > 0
            ))
        }
        
        return correlations
    }
    
    // MARK: - Weather Correlations
    
    private func analyzeWeatherCorrelations(from snapshots: [DailySnapshot]) -> [DetectedCorrelation] {
        var correlations: [DetectedCorrelation] = []
        
        // Weather vs steps
        var weatherToSteps: [(Double, Double)] = []
        for snapshot in snapshots {
            guard let weather = snapshot.weatherCondition,
                  let steps = snapshot.stepCount else { continue }
            
            let weatherScore = weatherToActivityScore(weather)
            weatherToSteps.append((weatherScore, Double(steps)))
        }
        
        if let r = pearsonCorrelation(weatherToSteps) {
            correlations.append(DetectedCorrelation(
                signal1: .weather,
                signal2: .steps,
                relationship: .weatherToActivity,
                correlationCoefficient: r,
                dataPoints: weatherToSteps.count,
                isPositive: r > 0
            ))
        }
        
        // Weather vs mood
        var weatherToMood: [(Double, Double)] = []
        for snapshot in snapshots {
            guard let weather = snapshot.weatherCondition,
                  let mood = snapshot.averageMood else { continue }
            
            let weatherScore = weatherToMoodScore(weather)
            weatherToMood.append((weatherScore, mood))
        }
        
        if let r = pearsonCorrelation(weatherToMood) {
            correlations.append(DetectedCorrelation(
                signal1: .weather,
                signal2: .mood,
                relationship: .weatherToMood,
                correlationCoefficient: r,
                dataPoints: weatherToMood.count,
                isPositive: r > 0
            ))
        }
        
        return correlations
    }
    
    // MARK: - Statistical Helpers
    
    /// Calculate Pearson correlation coefficient
    private func pearsonCorrelation(_ pairs: [(Double, Double)]) -> Double? {
        guard pairs.count >= minimumDataPoints else { return nil }
        
        let n = Double(pairs.count)
        let xs = pairs.map { $0.0 }
        let ys = pairs.map { $0.1 }
        
        let sumX = xs.reduce(0, +)
        let sumY = ys.reduce(0, +)
        let sumXY = zip(xs, ys).map { $0 * $1 }.reduce(0, +)
        let sumX2 = xs.map { $0 * $0 }.reduce(0, +)
        let sumY2 = ys.map { $0 * $0 }.reduce(0, +)
        
        let numerator = n * sumXY - sumX * sumY
        let denominator = sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY))
        
        guard denominator != 0 else { return nil }
        
        return numerator / denominator
    }
    
    private func sentimentToScore(_ sentiment: Sentiment) -> Double {
        switch sentiment {
        case .positive: return 1.0
        case .neutral: return 0.5
        case .negative: return 0.0
        }
    }
    
    private func weatherToActivityScore(_ weather: WeatherCondition) -> Double {
        switch weather {
        case .clear: return 1.0
        case .cloudy: return 0.7
        case .rainy: return 0.3
        case .snowy: return 0.2
        case .stormy: return 0.1
        }
    }
    
    private func weatherToMoodScore(_ weather: WeatherCondition) -> Double {
        switch weather {
        case .clear: return 1.0
        case .cloudy: return 0.6
        case .rainy: return 0.4
        case .snowy: return 0.5
        case .stormy: return 0.3
        }
    }
    
    private init() {}
}

// MARK: - Supporting Types

struct DetectedCorrelation {
    let signal1: SignalType
    let signal2: SignalType
    let relationship: CorrelationRelationship
    let correlationCoefficient: Double
    let dataPoints: Int
    let isPositive: Bool
    
    var strength: CorrelationStrength {
        let r = abs(correlationCoefficient)
        if r >= 0.7 { return .strong }
        if r >= 0.5 { return .moderate }
        return .weak
    }
    
    var confidence: Double {
        // Higher with more data points and stronger correlation
        let rConfidence = min(1.0, abs(correlationCoefficient))
        let dataConfidence = min(1.0, Double(dataPoints) / 30.0)
        return (rConfidence + dataConfidence) / 2.0
    }
}

enum CorrelationRelationship: String {
    case sleepToNextDayActivity
    case sleepToNextDayMood
    case sleepToNextDayScreenTime
    case screenTimeToSleep
    case screenTimeToMood
    case stepsToMood
    case stepsToReflectionSentiment
    case exerciseToSleep
    case weatherToActivity
    case weatherToMood
    case locationVarietyToMood
}

enum CorrelationStrength {
    case weak      // |r| < 0.5
    case moderate  // 0.5 <= |r| < 0.7
    case strong    // |r| >= 0.7
    
    var displayName: String {
        switch self {
        case .weak: return "slight"
        case .moderate: return "moderate"
        case .strong: return "strong"
        }
    }
}
