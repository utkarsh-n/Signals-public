//
//  InsightGenerator.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import Foundation
import SwiftData

/// Generates natural language insights from detected patterns, correlations, and trends
@MainActor
final class InsightGenerator {
    static let shared = InsightGenerator()
    
    private let patternEngine = PatternEngine.shared
    private let correlationEngine = CorrelationEngine.shared
    private let trendAnalyzer = TrendAnalyzer.shared
    
    // Configuration
    private let maxInsightsPerWeek = 5
    private let minimumConfidence = 0.6
    private let insightCooldownDays = 28  // Don't repeat same insight type for 4 weeks
    
    // Track recently generated insights to avoid repetition
    private var recentInsightKeys: [String: Date] = [:]
    
    // MARK: - Insight Generation
    
    /// Generate insights from the given snapshots
    func generateInsights(from snapshots: [DailySnapshot], context: ModelContext) -> [Insight] {
        var insights: [Insight] = []
        
        // Detect patterns
        let patterns = patternEngine.detectPatterns(from: snapshots)
        insights.append(contentsOf: generatePatternInsights(from: patterns))
        
        // Detect correlations
        let correlations = correlationEngine.analyzeCorrelations(from: snapshots)
        insights.append(contentsOf: generateCorrelationInsights(from: correlations))
        
        // Detect trends
        let trends = trendAnalyzer.detectTrends(from: snapshots)
        insights.append(contentsOf: generateTrendInsights(from: trends))
        
        // Check for milestones
        insights.append(contentsOf: generateMilestoneInsights(from: snapshots, context: context))
        
        // Filter, deduplicate, and limit
        let filtered = insights
            .filter { $0.confidence >= minimumConfidence }
            .filter { !isInsightOnCooldown($0) }
            .sorted { $0.confidence > $1.confidence }
            .prefix(maxInsightsPerWeek)
        
        // Mark these insights as generated
        for insight in filtered {
            markInsightGenerated(insight)
        }
        
        return Array(filtered)
    }
    
    // MARK: - Pattern Insights
    
    private func generatePatternInsights(from patterns: [DetectedPattern]) -> [Insight] {
        var insights: [Insight] = []
        
        for pattern in patterns {
            guard let template = InsightTemplates.template(for: pattern.description) else {
                continue
            }
            
            let values = buildTemplateValues(for: pattern)
            let body = template.fillingTemplate(with: values)
            let title = generateTitle(for: pattern)
            
            let insight = Insight(
                category: categoryFor(patternType: pattern.type),
                title: title,
                body: body,
                supportingData: buildSupportingData(for: pattern),
                signalsInvolved: [pattern.signal],
                confidence: pattern.confidence,
                timeSpan: .week
            )
            
            insights.append(insight)
        }
        
        return insights
    }
    
    private func buildTemplateValues(for pattern: DetectedPattern) -> [String: String] {
        var values: [String: String] = [:]
        
        if let dayName = pattern.dayName {
            values["dayName"] = dayName
        }
        
        values["metric"] = pattern.signal.displayName.lowercased()
        
        if let streakDays = pattern.streakDays {
            values["streakDays"] = "\(streakDays)"
        }
        
        if let value = pattern.value {
            values["value"] = formatValue(value, for: pattern.signal)
        }
        
        if let comparison = pattern.comparisonValue {
            values["comparison"] = formatValue(comparison, for: pattern.signal)
        }
        
        return values
    }
    
    private func generateTitle(for pattern: DetectedPattern) -> String {
        switch pattern.type {
        case .dayOfWeek:
            if let dayName = pattern.dayName {
                return "\(dayName) \(pattern.signal.displayName.lowercased())"
            }
            return "\(pattern.signal.displayName) pattern"
        case .weekendVsWeekday:
            return "Weekend vs. weekday"
        case .streak:
            return "\(pattern.streakDays ?? 0)-day streak"
        case .anomaly:
            return "Unusual \(pattern.signal.displayName.lowercased())"
        case .timeOfDay:
            return "Timing pattern"
        case .milestone:
            return "Milestone reached"
        }
    }
    
    private func categoryFor(patternType: PatternType) -> InsightCategory {
        switch patternType {
        case .dayOfWeek, .weekendVsWeekday, .timeOfDay:
            return .pattern
        case .streak:
            return .milestone
        case .anomaly:
            return .anomaly
        case .milestone:
            return .milestone
        }
    }
    
    private func buildSupportingData(for pattern: DetectedPattern) -> InsightData {
        var metrics: [String: Double] = [:]
        
        if let value = pattern.value {
            metrics["value"] = value
        }
        if let comparison = pattern.comparisonValue {
            metrics["comparison"] = comparison
        }
        if let streakDays = pattern.streakDays {
            metrics["streakDays"] = Double(streakDays)
        }
        
        var dates: [String: Date] = [:]
        if let date = pattern.date {
            dates["date"] = date
        }
        if let streakEnd = pattern.streakEndDate {
            dates["streakEndDate"] = streakEnd
        }
        
        return InsightData(metrics: metrics, dates: dates, signals: [pattern.signal])
    }
    
    // MARK: - Correlation Insights
    
    private func generateCorrelationInsights(from correlations: [DetectedCorrelation]) -> [Insight] {
        var insights: [Insight] = []
        
        for correlation in correlations {
            guard let template = InsightTemplates.template(for: correlation.relationship) else {
                continue
            }
            
            let title = generateTitle(for: correlation)
            
            let insight = Insight(
                category: .correlation,
                title: title,
                body: template,
                supportingData: InsightData(
                    metrics: [
                        "correlation": correlation.correlationCoefficient,
                        "dataPoints": Double(correlation.dataPoints)
                    ],
                    signals: [correlation.signal1, correlation.signal2]
                ),
                signalsInvolved: [correlation.signal1, correlation.signal2],
                confidence: correlation.confidence,
                timeSpan: .month
            )
            
            insights.append(insight)
        }
        
        return insights
    }
    
    private func generateTitle(for correlation: DetectedCorrelation) -> String {
        return "\(correlation.signal1.displayName) & \(correlation.signal2.displayName.lowercased())"
    }
    
    // MARK: - Trend Insights
    
    private func generateTrendInsights(from trends: [DetectedTrend]) -> [Insight] {
        var insights: [Insight] = []
        
        for trend in trends where trend.isSignificant {
            let key = "\(trend.signal.rawValue)_\(trend.direction.rawValue)"
            guard let template = InsightTemplates.trendTemplate(for: key) else {
                continue
            }
            
            let values: [String: String] = [
                "percentage": String(format: "%.0f", abs(trend.percentageChange)),
                "period": "\(trend.periodDays) days"
            ]
            
            let body = template.fillingTemplate(with: values)
            let title = "\(trend.signal.displayName) \(trend.direction.displayName)"
            
            let insight = Insight(
                category: .trend,
                title: title,
                body: body,
                supportingData: InsightData(
                    metrics: [
                        "percentageChange": trend.percentageChange,
                        "startValue": trend.startValue,
                        "endValue": trend.endValue
                    ],
                    signals: [trend.signal]
                ),
                signalsInvolved: [trend.signal],
                confidence: trend.confidence,
                timeSpan: .week
            )
            
            insights.append(insight)
        }
        
        return insights
    }
    
    // MARK: - Milestone Insights
    
    private func generateMilestoneInsights(from snapshots: [DailySnapshot], context: ModelContext) -> [Insight] {
        var insights: [Insight] = []
        
        // Check for first week complete
        if snapshots.count == 7 {
            if let template = InsightTemplates.milestoneTemplate(for: "first_week_complete") {
                insights.append(Insight(
                    category: .milestone,
                    title: "First week complete!",
                    body: template,
                    signalsInvolved: [],
                    confidence: 1.0,
                    timeSpan: .week
                ))
            }
        }
        
        // Check for first month
        if snapshots.count == 30 {
            if let template = InsightTemplates.milestoneTemplate(for: "first_month_complete") {
                insights.append(Insight(
                    category: .milestone,
                    title: "One month milestone",
                    body: template,
                    signalsInvolved: [],
                    confidence: 1.0,
                    timeSpan: .month
                ))
            }
        }
        
        // Check for step records
        if let maxSteps = snapshots.compactMap({ $0.stepCount }).max(),
           maxSteps > 15000,
           let template = InsightTemplates.milestoneTemplate(for: "steps_record") {
            let body = template.fillingTemplate(with: ["value": "\(maxSteps.formatted())"])
            insights.append(Insight(
                category: .milestone,
                title: "Step record!",
                body: body,
                supportingData: InsightData(metrics: ["steps": Double(maxSteps)]),
                signalsInvolved: [.steps],
                confidence: 1.0,
                timeSpan: .allTime
            ))
        }
        
        // Check for reflection count milestones
        let totalReflections = snapshots.reduce(0) { $0 + ($1.reflections?.count ?? 0) }
        let reflectionMilestones = [10, 25, 50, 100, 250, 500]
        
        for milestone in reflectionMilestones {
            if totalReflections >= milestone && totalReflections < milestone + 5 {
                if let template = InsightTemplates.milestoneTemplate(for: "reflection_count") {
                    let body = template.fillingTemplate(with: ["value": "\(milestone)"])
                    insights.append(Insight(
                        category: .milestone,
                        title: "\(milestone) reflections",
                        body: body,
                        signalsInvolved: [.reflection],
                        confidence: 1.0,
                        timeSpan: .allTime
                    ))
                }
                break
            }
        }
        
        return insights
    }
    
    // MARK: - Cooldown Management
    
    private func isInsightOnCooldown(_ insight: Insight) -> Bool {
        let key = "\(insight.category.rawValue)_\(insight.title)"
        
        guard let lastGenerated = recentInsightKeys[key] else {
            return false
        }
        
        let daysSince = Calendar.current.dateComponents([.day], from: lastGenerated, to: Date()).day ?? 0
        return daysSince < insightCooldownDays
    }
    
    private func markInsightGenerated(_ insight: Insight) {
        let key = "\(insight.category.rawValue)_\(insight.title)"
        recentInsightKeys[key] = Date()
    }
    
    /// Clear cooldown tracking (useful for testing)
    func clearCooldowns() {
        recentInsightKeys.removeAll()
    }
    
    // MARK: - Helpers
    
    private func formatValue(_ value: Double, for signal: SignalType) -> String {
        switch signal {
        case .steps:
            return Int(value).formatted()
        case .sleep:
            return String(format: "%.1f", value)
        case .screenTime:
            let hours = Int(value) / 60
            let minutes = Int(value) % 60
            return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
        case .exercise:
            return "\(Int(value)) minutes"
        default:
            return String(format: "%.1f", value)
        }
    }
    
    private init() {}
}
