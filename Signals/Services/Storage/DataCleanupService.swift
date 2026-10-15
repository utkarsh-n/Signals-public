//
//  DataCleanupService.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import Foundation
import SwiftData

/// Service for cleaning up old data based on retention settings
@MainActor
final class DataCleanupService {
    // MARK: - Singleton
    
    static let shared = DataCleanupService()
    
    private init() {}
    
    // MARK: - Cleanup Operations
    
    /// Perform data cleanup based on user retention settings
    func performCleanup(context: ModelContext) async {
        let retentionMonths = UserSettings.shared.dataRetentionMonths
        
        // Skip if retention is set to unlimited (0 or very high)
        guard retentionMonths > 0 && retentionMonths < 120 else { return }
        
        // Calculate cutoff date
        guard let cutoffDate = Calendar.current.date(
            byAdding: .month,
            value: -retentionMonths,
            to: Date()
        ) else { return }
        
        // Clean up snapshots
        await cleanupSnapshots(before: cutoffDate, context: context)
        
        // Clean up insights
        await cleanupInsights(before: cutoffDate, context: context)
        
        // Clean up reflections
        await cleanupReflections(before: cutoffDate, context: context)
        
        // Clean up mood entries
        await cleanupMoodEntries(before: cutoffDate, context: context)
        
        // Clean up weekly reports
        await cleanupWeeklyReports(before: cutoffDate, context: context)
        
        // Update last cleanup date
        UserSettings.shared.lastDataCleanupDate = Date()
        
        // Save changes
        try? context.save()
    }
    
    /// Check if cleanup is needed
    func shouldPerformCleanup() -> Bool {
        guard let lastCleanup = UserSettings.shared.lastDataCleanupDate else {
            return true
        }
        
        // Cleanup once per week at most
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())
        return lastCleanup < (weekAgo ?? Date())
    }
    
    // MARK: - Private Cleanup Methods
    
    private func cleanupSnapshots(before cutoffDate: Date, context: ModelContext) async {
        let descriptor = FetchDescriptor<DailySnapshot>(
            predicate: #Predicate { $0.date < cutoffDate }
        )
        
        if let oldSnapshots = try? context.fetch(descriptor) {
            for snapshot in oldSnapshots {
                context.delete(snapshot)
            }
        }
    }
    
    private func cleanupInsights(before cutoffDate: Date, context: ModelContext) async {
        // Keep saved insights regardless of age
        let descriptor = FetchDescriptor<Insight>(
            predicate: #Predicate { $0.generatedDate < cutoffDate && !$0.isSaved }
        )
        
        if let oldInsights = try? context.fetch(descriptor) {
            for insight in oldInsights {
                context.delete(insight)
            }
        }
    }
    
    private func cleanupReflections(before cutoffDate: Date, context: ModelContext) async {
        let descriptor = FetchDescriptor<Reflection>(
            predicate: #Predicate { $0.createdAt < cutoffDate }
        )
        
        if let oldReflections = try? context.fetch(descriptor) {
            for reflection in oldReflections {
                context.delete(reflection)
            }
        }
    }
    
    private func cleanupMoodEntries(before cutoffDate: Date, context: ModelContext) async {
        let descriptor = FetchDescriptor<MoodEntry>(
            predicate: #Predicate { $0.timestamp < cutoffDate }
        )
        
        if let oldEntries = try? context.fetch(descriptor) {
            for entry in oldEntries {
                context.delete(entry)
            }
        }
    }
    
    private func cleanupWeeklyReports(before cutoffDate: Date, context: ModelContext) async {
        let descriptor = FetchDescriptor<WeeklyReport>(
            predicate: #Predicate { $0.generatedAt < cutoffDate }
        )
        
        if let oldReports = try? context.fetch(descriptor) {
            for report in oldReports {
                context.delete(report)
            }
        }
    }
    
    // MARK: - Manual Cleanup
    
    /// Delete all data for a specific date range
    func deleteDataInRange(from startDate: Date, to endDate: Date, context: ModelContext) async {
        // Delete snapshots in range
        let snapshotDescriptor = FetchDescriptor<DailySnapshot>(
            predicate: #Predicate { $0.date >= startDate && $0.date <= endDate }
        )
        
        if let snapshots = try? context.fetch(snapshotDescriptor) {
            for snapshot in snapshots {
                context.delete(snapshot)
            }
        }
        
        // Delete insights in range
        let insightDescriptor = FetchDescriptor<Insight>(
            predicate: #Predicate { $0.generatedDate >= startDate && $0.generatedDate <= endDate }
        )
        
        if let insights = try? context.fetch(insightDescriptor) {
            for insight in insights {
                context.delete(insight)
            }
        }
        
        // Delete reflections in range
        let reflectionDescriptor = FetchDescriptor<Reflection>(
            predicate: #Predicate { $0.createdAt >= startDate && $0.createdAt <= endDate }
        )
        
        if let reflections = try? context.fetch(reflectionDescriptor) {
            for reflection in reflections {
                context.delete(reflection)
            }
        }
        
        // Delete mood entries in range
        let moodDescriptor = FetchDescriptor<MoodEntry>(
            predicate: #Predicate { $0.timestamp >= startDate && $0.timestamp <= endDate }
        )
        
        if let entries = try? context.fetch(moodDescriptor) {
            for entry in entries {
                context.delete(entry)
            }
        }
        
        try? context.save()
    }
    
    /// Delete all user data
    func deleteAllData(context: ModelContext) async {
        // Delete all snapshots
        let snapshotDescriptor = FetchDescriptor<DailySnapshot>()
        if let snapshots = try? context.fetch(snapshotDescriptor) {
            for snapshot in snapshots {
                context.delete(snapshot)
            }
        }
        
        // Delete all insights
        let insightDescriptor = FetchDescriptor<Insight>()
        if let insights = try? context.fetch(insightDescriptor) {
            for insight in insights {
                context.delete(insight)
            }
        }
        
        // Delete all reflections
        let reflectionDescriptor = FetchDescriptor<Reflection>()
        if let reflections = try? context.fetch(reflectionDescriptor) {
            for reflection in reflections {
                context.delete(reflection)
            }
        }
        
        // Delete all mood entries
        let moodDescriptor = FetchDescriptor<MoodEntry>()
        if let entries = try? context.fetch(moodDescriptor) {
            for entry in entries {
                context.delete(entry)
            }
        }
        
        // Delete all weekly reports
        let reportDescriptor = FetchDescriptor<WeeklyReport>()
        if let reports = try? context.fetch(reportDescriptor) {
            for report in reports {
                context.delete(report)
            }
        }
        
        try? context.save()
    }
    
    // MARK: - Data Statistics
    
    /// Get data statistics for display
    func getDataStatistics(context: ModelContext) -> DataStatistics {
        let snapshotCount = (try? context.fetchCount(FetchDescriptor<DailySnapshot>())) ?? 0
        let insightCount = (try? context.fetchCount(FetchDescriptor<Insight>())) ?? 0
        let reflectionCount = (try? context.fetchCount(FetchDescriptor<Reflection>())) ?? 0
        let moodCount = (try? context.fetchCount(FetchDescriptor<MoodEntry>())) ?? 0
        
        // Get date range
        var oldestDescriptor = FetchDescriptor<DailySnapshot>(
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        oldestDescriptor.fetchLimit = 1
        let oldestDate = (try? context.fetch(oldestDescriptor))?.first?.date
        
        var newestDescriptor = FetchDescriptor<DailySnapshot>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        newestDescriptor.fetchLimit = 1
        let newestDate = (try? context.fetch(newestDescriptor))?.first?.date
        
        return DataStatistics(
            snapshotCount: snapshotCount,
            insightCount: insightCount,
            reflectionCount: reflectionCount,
            moodEntryCount: moodCount,
            oldestDataDate: oldestDate,
            newestDataDate: newestDate
        )
    }
}

// MARK: - Data Statistics

struct DataStatistics {
    let snapshotCount: Int
    let insightCount: Int
    let reflectionCount: Int
    let moodEntryCount: Int
    let oldestDataDate: Date?
    let newestDataDate: Date?
    
    var totalRecords: Int {
        snapshotCount + insightCount + reflectionCount + moodEntryCount
    }
    
    var dateRangeDescription: String {
        guard let oldest = oldestDataDate, let newest = newestDataDate else {
            return "No data"
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        return "\(formatter.string(from: oldest)) - \(formatter.string(from: newest))"
    }
}
