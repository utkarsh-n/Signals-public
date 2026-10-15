//
//  WeeklyReportGenerator.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import Foundation
import SwiftData

/// Generates comprehensive weekly reports
@MainActor
final class WeeklyReportGenerator {
    static let shared = WeeklyReportGenerator()
    
    private let insightGenerator = InsightGenerator.shared
    private let trendAnalyzer = TrendAnalyzer.shared
    
    // MARK: - Report Generation
    
    /// Generate a weekly report for the given week
    func generateReport(
        weekStartDate: Date,
        allSnapshots: [DailySnapshot],
        context: ModelContext
    ) -> WeeklyReport {
        // Get snapshots for this week
        let weekSnapshots = trendAnalyzer.snapshotsForWeek(
            containing: weekStartDate,
            from: allSnapshots
        )
        
        // Get previous week's snapshots for comparison
        let previousWeekStart = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: weekStartDate)!
        let previousWeekSnapshots = trendAnalyzer.snapshotsForWeek(
            containing: previousWeekStart,
            from: allSnapshots
        )
        
        // Calculate week comparison
        let comparison = trendAnalyzer.compareWeeks(
            current: weekSnapshots,
            previous: previousWeekSnapshots
        )
        
        // Generate insights for this week
        let insights = insightGenerator.generateInsights(from: weekSnapshots, context: context)
        
        // Generate summary
        let summary = generateSummary(
            snapshots: weekSnapshots,
            comparison: comparison,
            insights: insights
        )
        
        // Calculate week end date
        let weekEndDate = Calendar.current.date(byAdding: .day, value: 6, to: weekStartDate)!
        
        // Create the report
        let report = WeeklyReport(
            weekStartDate: weekStartDate,
            weekEndDate: weekEndDate,
            summary: summary,
            comparisonToPrevious: comparison
        )
        
        // Link insights to report
        report.insights = insights
        report.snapshots = weekSnapshots
        
        // Insert into context
        context.insert(report)
        for insight in insights {
            context.insert(insight)
        }
        
        return report
    }
    
    /// Generate a report for the most recently completed week
    func generateReportForLastWeek(
        allSnapshots: [DailySnapshot],
        context: ModelContext
    ) -> WeeklyReport {
        // Find the start of last week
        let today = Date()
        let calendar = Calendar.current
        
        // Get the start of this week
        let thisWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        
        // Go back one week
        let lastWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: thisWeekStart)!
        
        return generateReport(
            weekStartDate: lastWeekStart,
            allSnapshots: allSnapshots,
            context: context
        )
    }
    
    // MARK: - Summary Generation
    
    private func generateSummary(
        snapshots: [DailySnapshot],
        comparison: WeekComparison,
        insights: [Insight]
    ) -> String {
        var summaryParts: [String] = []
        
        // Calculate averages
        let steps = snapshots.compactMap { $0.stepCount }
        let sleep = snapshots.compactMap { $0.sleepHours }
        let reflectionCount = snapshots.reduce(0) { $0 + ($1.reflections?.count ?? 0) }
        
        // Build base summary
        if !steps.isEmpty {
            let avgSteps = steps.reduce(0, +) / steps.count
            summaryParts.append("You averaged \(avgSteps.formatted()) steps")
        }
        
        if !sleep.isEmpty {
            let avgSleep = sleep.reduce(0, +) / Double(sleep.count)
            summaryParts.append(String(format: "%.1f hours of sleep", avgSleep))
        }
        
        if reflectionCount > 0 {
            summaryParts.append("\(reflectionCount) reflection\(reflectionCount == 1 ? "" : "s")")
        }
        
        var summary = ""
        if !summaryParts.isEmpty {
            summary = "This week: " + summaryParts.joined(separator: ", ") + "."
        }
        
        // Add comparison highlights
        if let stepsChange = comparison.stepsChange, abs(stepsChange) >= 10 {
            let direction = stepsChange > 0 ? "up" : "down"
            summary += " Steps are \(direction) \(String(format: "%.0f", abs(stepsChange)))% from last week."
        }
        
        if let sleepChange = comparison.sleepChange, abs(sleepChange) >= 10 {
            let direction = sleepChange > 0 ? "more" : "less"
            summary += " You slept \(direction) than last week."
        }
        
        // Add top insight preview if available
        if let topInsight = insights.first {
            summary += " \(topInsight.body)"
        }
        
        return summary.trimmingCharacters(in: .whitespaces)
    }
    
    // MARK: - Report Queries
    
    /// Fetch the most recent weekly report
    func fetchLatestReport(context: ModelContext) -> WeeklyReport? {
        var descriptor = FetchDescriptor<WeeklyReport>(
            sortBy: [SortDescriptor(\.weekStartDate, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        
        return try? context.fetch(descriptor).first
    }
    
    /// Fetch all reports for a given year
    func fetchReports(forYear year: Int, context: ModelContext) -> [WeeklyReport] {
        let calendar = Calendar.current
        
        guard let yearStart = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
              let yearEnd = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1)) else {
            return []
        }
        
        let descriptor = FetchDescriptor<WeeklyReport>(
            predicate: #Predicate { report in
                report.weekStartDate >= yearStart && report.weekStartDate < yearEnd
            },
            sortBy: [SortDescriptor(\.weekStartDate, order: .reverse)]
        )
        
        return (try? context.fetch(descriptor)) ?? []
    }
    
    /// Check if a report exists for a given week
    func reportExists(for weekStart: Date, context: ModelContext) -> Bool {
        let weekEnd = Calendar.current.date(byAdding: .day, value: 1, to: weekStart)!
        
        let descriptor = FetchDescriptor<WeeklyReport>(
            predicate: #Predicate { report in
                report.weekStartDate >= weekStart && report.weekStartDate < weekEnd
            }
        )
        
        let count = (try? context.fetchCount(descriptor)) ?? 0
        return count > 0
    }
    
    // MARK: - Statistics
    
    /// Calculate statistics across all weekly reports
    func calculateOverallStatistics(from reports: [WeeklyReport]) -> OverallStatistics {
        guard !reports.isEmpty else {
            return OverallStatistics()
        }
        
        var totalInsights = 0
        var totalSteps: [Int] = []
        var totalSleep: [Double] = []
        var totalReflections = 0
        
        for report in reports {
            totalInsights += report.insightCount
            
            if let avgSteps = report.averageSteps {
                totalSteps.append(avgSteps)
            }
            if let avgSleep = report.averageSleep {
                totalSleep.append(avgSleep)
            }
            totalReflections += report.totalReflections
        }
        
        return OverallStatistics(
            totalWeeks: reports.count,
            totalInsights: totalInsights,
            averageSteps: totalSteps.isEmpty ? nil : totalSteps.reduce(0, +) / totalSteps.count,
            averageSleep: totalSleep.isEmpty ? nil : totalSleep.reduce(0, +) / Double(totalSleep.count),
            totalReflections: totalReflections
        )
    }
    
    private init() {}
}

// MARK: - Supporting Types

struct OverallStatistics {
    var totalWeeks: Int = 0
    var totalInsights: Int = 0
    var averageSteps: Int?
    var averageSleep: Double?
    var totalReflections: Int = 0
}
