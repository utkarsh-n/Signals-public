//
//  WeeklyReport.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import Foundation
import SwiftData

@Model
final class WeeklyReport {
    var id: UUID
    var weekStartDate: Date
    var weekEndDate: Date
    var summary: String
    var comparisonDataRaw: Data?  // Encoded WeekComparison
    var generatedAt: Date
    var isRead: Bool
    
    @Relationship(deleteRule: .nullify)
    var insights: [Insight]?
    
    @Relationship(deleteRule: .nullify)
    var snapshots: [DailySnapshot]?
    
    init(
        id: UUID = UUID(),
        weekStartDate: Date,
        weekEndDate: Date,
        summary: String = "",
        comparisonToPrevious: WeekComparison? = nil,
        generatedAt: Date = Date(),
        isRead: Bool = false
    ) {
        self.id = id
        self.weekStartDate = weekStartDate
        self.weekEndDate = weekEndDate
        self.summary = summary
        self.comparisonDataRaw = try? JSONEncoder().encode(comparisonToPrevious)
        self.generatedAt = generatedAt
        self.isRead = isRead
    }
    
    // MARK: - Computed Accessors
    
    var comparisonToPrevious: WeekComparison? {
        get {
            guard let data = comparisonDataRaw else { return nil }
            return try? JSONDecoder().decode(WeekComparison.self, from: data)
        }
        set {
            comparisonDataRaw = try? JSONEncoder().encode(newValue)
        }
    }
    
    /// The most notable insight for the week (highest confidence)
    var topPattern: Insight? {
        insights?.max(by: { $0.confidence < $1.confidence })
    }
}

// MARK: - Convenience Methods

extension WeeklyReport {
    var formattedDateRange: String {
        let startFormatted = weekStartDate.formatted(.dateTime.month(.abbreviated).day())
        let endFormatted = weekEndDate.formatted(.dateTime.month(.abbreviated).day())
        return "\(startFormatted) - \(endFormatted)"
    }
    
    var weekNumber: Int {
        Calendar.current.component(.weekOfYear, from: weekStartDate)
    }
    
    var insightCount: Int {
        insights?.count ?? 0
    }
    
    /// Marks the report as read along with all its insights
    func markAsRead() {
        isRead = true
        insights?.forEach { $0.markAsRead() }
    }
    
    // MARK: - Aggregate Statistics
    
    var averageSteps: Int? {
        guard let snaps = snapshots else { return nil }
        let stepsArray = snaps.compactMap { $0.stepCount }
        guard !stepsArray.isEmpty else { return nil }
        return stepsArray.reduce(0, +) / stepsArray.count
    }
    
    var averageSleep: Double? {
        guard let snaps = snapshots else { return nil }
        let sleepArray = snaps.compactMap { $0.sleepHours }
        guard !sleepArray.isEmpty else { return nil }
        return sleepArray.reduce(0, +) / Double(sleepArray.count)
    }
    
    var averageScreenTime: Int? {
        guard let snaps = snapshots else { return nil }
        let screenArray = snaps.compactMap { $0.screenTimeMinutes }
        guard !screenArray.isEmpty else { return nil }
        return screenArray.reduce(0, +) / screenArray.count
    }
    
    var totalReflections: Int {
        snapshots?.reduce(0) { $0 + ($1.reflections?.count ?? 0) } ?? 0
    }
}
