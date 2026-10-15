//
//  BackgroundTaskHandler.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import Foundation
import SwiftData

/// Handles background data collection and analysis tasks
@MainActor
final class BackgroundTaskHandler {
    // MARK: - Singleton
    
    static let shared = BackgroundTaskHandler()
    
    // MARK: - Services
    
    private let healthKitService = HealthKitService.shared
    private let locationService = LocationService.shared
    private let motionService = MotionService.shared
    private let weatherService = WeatherService.shared
    
    private init() {}
    
    // MARK: - Daily Collection
    
    /// Performs daily data collection for the previous day
    func performDailyCollection() async {
        let calendar = Calendar.current
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) else { return }
        let yesterdayStart = calendar.startOfDay(for: yesterday)
        
        do {
            // Get or create the model context
            let container = PersistenceController.shared.container
            let context = ModelContext(container)
            
            // Check if snapshot already exists for yesterday
            let existingDescriptor = FetchDescriptor<DailySnapshot>(
                predicate: #Predicate { $0.date == yesterdayStart }
            )
            
            let existingSnapshots = try context.fetch(existingDescriptor)
            let snapshot: DailySnapshot
            
            if let existing = existingSnapshots.first {
                snapshot = existing
            } else {
                snapshot = DailySnapshot(date: yesterdayStart)
                context.insert(snapshot)
            }
            
            // Collect health data
            await collectHealthData(for: snapshot, date: yesterday)
            
            // Collect motion data
            await collectMotionData(for: snapshot, date: yesterday)
            
            // Collect weather data
            await collectWeatherData(for: snapshot)
            
            // Update metadata
            snapshot.updatedAt = Date()
            
            // Save the snapshot
            try context.save()
            
            // Update last sync date
            UserSettings.shared.lastSyncDate = Date()
            
        } catch {
            print("Daily collection failed: \(error)")
        }
    }
    
    // MARK: - Weekly Analysis
    
    /// Performs weekly pattern analysis and insight generation
    func performWeeklyAnalysis() async {
        do {
            let container = PersistenceController.shared.container
            let context = ModelContext(container)
            
            // Get last 4 weeks of snapshots
            let fourWeeksAgo = Calendar.current.date(byAdding: .day, value: -28, to: Date()) ?? Date()
            let snapshotDescriptor = FetchDescriptor<DailySnapshot>(
                predicate: #Predicate { $0.date >= fourWeeksAgo },
                sortBy: [SortDescriptor(\.date, order: .forward)]
            )
            
            let snapshots = try context.fetch(snapshotDescriptor)
            
            guard snapshots.count >= 7 else {
                // Not enough data for analysis
                return
            }
            
            // Generate insights using the unified generator
            _ = InsightGenerator.shared.generateInsights(
                from: snapshots,
                context: context
            )
            
            // Generate weekly report
            let calendar = Calendar.current
            let today = Date()
            let thisWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
            let lastWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: thisWeekStart)!
            
            let weeklyReport = WeeklyReportGenerator.shared.generateReport(
                weekStartDate: lastWeekStart,
                allSnapshots: snapshots,
                context: context
            )
            
            // Save everything
            try context.save()
            
            // Schedule notification for Monday morning
            await NotificationService.shared.scheduleWeeklyReportNotification(
                report: weeklyReport
            )
            
        } catch {
            print("Weekly analysis failed: \(error)")
        }
    }
    
    // MARK: - Save Partial Progress
    
    /// Saves any partial progress if task is expiring
    func savePartialProgress() async {
        // This would save any in-progress analysis state
        // For now, we just ensure any pending writes are committed
        do {
            let container = PersistenceController.shared.container
            let context = ModelContext(container)
            try context.save()
        } catch {
            print("Failed to save partial progress: \(error)")
        }
    }
    
    // MARK: - Foreground Sync
    
    /// Manual sync triggered from foreground (pull-to-refresh)
    func performForegroundSync() async {
        // Sync today's data
        let today = Calendar.current.startOfDay(for: Date())
        
        do {
            let container = PersistenceController.shared.container
            let context = ModelContext(container)
            
            // Get or create today's snapshot
            let descriptor = FetchDescriptor<DailySnapshot>(
                predicate: #Predicate { $0.date == today }
            )
            
            let snapshots = try context.fetch(descriptor)
            let snapshot: DailySnapshot
            
            if let existing = snapshots.first {
                snapshot = existing
            } else {
                snapshot = DailySnapshot(date: today)
                context.insert(snapshot)
            }
            
            // Collect current data
            await collectHealthData(for: snapshot, date: Date())
            await collectMotionData(for: snapshot, date: Date())
            
            snapshot.updatedAt = Date()
            try context.save()
            
            UserSettings.shared.lastSyncDate = Date()
            
        } catch {
            print("Foreground sync failed: \(error)")
        }
    }
    
    // MARK: - Private Collection Methods
    
    private func collectHealthData(for snapshot: DailySnapshot, date: Date) async {
        guard UserSettings.shared.isSignalEnabled(.steps) ||
              UserSettings.shared.isSignalEnabled(.sleep) ||
              UserSettings.shared.isSignalEnabled(.exercise) ||
              UserSettings.shared.isSignalEnabled(.heartRate) else {
            return
        }
        
        let healthData = await healthKitService.fetchAllHealthData(for: date)
        
        if UserSettings.shared.isSignalEnabled(.steps) {
            snapshot.stepCount = healthData.stepCount
        }
        
        if UserSettings.shared.isSignalEnabled(.sleep) {
            snapshot.sleepHours = healthData.sleepHours
            snapshot.sleepQuality = healthData.sleepQuality
        }
        
        if UserSettings.shared.isSignalEnabled(.exercise) {
            snapshot.exerciseMinutes = healthData.exerciseMinutes
        }
        
        if UserSettings.shared.isSignalEnabled(.heartRate) {
            snapshot.restingHeartRate = healthData.restingHeartRate
        }
        
        if UserSettings.shared.isSignalEnabled(.hrv) {
            snapshot.hrvAverage = healthData.hrvAverage
        }
        
        // Update collected signals
        var signals = snapshot.signalsCollected
        if healthData.stepCount != nil && !signals.contains(.steps) { signals.append(.steps) }
        if healthData.sleepHours != nil && !signals.contains(.sleep) { signals.append(.sleep) }
        if healthData.exerciseMinutes != nil && !signals.contains(.exercise) { signals.append(.exercise) }
        if healthData.restingHeartRate != nil && !signals.contains(.heartRate) { signals.append(.heartRate) }
        if healthData.hrvAverage != nil && !signals.contains(.hrv) { signals.append(.hrv) }
        snapshot.signalsCollected = signals
    }
    
    private func collectMotionData(for snapshot: DailySnapshot, date: Date) async {
        guard UserSettings.shared.isSignalEnabled(.motion) else { return }
        
        let motionData = await motionService.fetchAllMotionData(for: date)
        
        snapshot.activityType = motionData.primaryActivity
        
        var signals = snapshot.signalsCollected
        if !signals.contains(.motion) { signals.append(.motion) }
        snapshot.signalsCollected = signals
    }
    
    private func collectWeatherData(for snapshot: DailySnapshot) async {
        guard UserSettings.shared.isSignalEnabled(.weather) else { return }
        
        // Get user's last known location for weather
        if let location = locationService.lastKnownLocation {
            do {
                if let weather = try await weatherService.fetchWeather(for: location, date: snapshot.date) {
                    snapshot.weatherCondition = weather.condition
                    
                    var signals = snapshot.signalsCollected
                    if !signals.contains(.weather) { signals.append(.weather) }
                    snapshot.signalsCollected = signals
                }
            } catch {
                print("Failed to fetch weather: \(error)")
            }
        }
    }
}
