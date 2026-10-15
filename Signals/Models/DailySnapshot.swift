//
//  DailySnapshot.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import Foundation
import SwiftData

@Model
final class DailySnapshot {
    var id: UUID
    var date: Date  // Calendar day (midnight-normalized)
    
    // MARK: - Health Signals
    var stepCount: Int?
    var sleepHours: Double?
    var sleepQuality: SleepQuality?
    var exerciseMinutes: Int?
    var restingHeartRate: Double?
    var hrvAverage: Double?
    
    // MARK: - Activity Signals
    var screenTimeMinutes: Int?
    var appPickups: Int?
    var topAppsData: Data?  // Encoded [AppUsageEntry]
    
    // MARK: - Location Signals
    var locationClustersData: Data?  // Encoded [LocationCluster]
    var distanceTraveled: Double?  // Meters
    var placesVisited: Int?
    var leftHome: Bool?
    
    // MARK: - Motion Signals
    var activeMinutes: Int?
    var activityType: PrimaryActivity?
    
    // MARK: - User-Generated
    @Relationship(deleteRule: .cascade)
    var reflections: [Reflection]?
    
    @Relationship(deleteRule: .cascade)
    var moodEntries: [MoodEntry]?
    
    // MARK: - Computed Properties Storage
    var dayOfWeek: Int  // 1-7 (Sunday = 1)
    var isWeekend: Bool
    var weatherCondition: WeatherCondition?
    
    // MARK: - Metadata
    var signalsCollectedRaw: [String]  // Stored as raw values
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        date: Date = Date()
    ) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        
        let calendar = Calendar.current
        self.dayOfWeek = calendar.component(.weekday, from: date)
        self.isWeekend = calendar.isDateInWeekend(date)
        
        self.signalsCollectedRaw = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // MARK: - Computed Accessors
    
    var topApps: [AppUsageEntry]? {
        get {
            guard let data = topAppsData else { return nil }
            return try? JSONDecoder().decode([AppUsageEntry].self, from: data)
        }
        set {
            topAppsData = try? JSONEncoder().encode(newValue)
        }
    }
    
    var locationClusters: [LocationCluster]? {
        get {
            guard let data = locationClustersData else { return nil }
            return try? JSONDecoder().decode([LocationCluster].self, from: data)
        }
        set {
            locationClustersData = try? JSONEncoder().encode(newValue)
        }
    }
    
    var signalsCollected: [SignalType] {
        get {
            signalsCollectedRaw.compactMap { SignalType(rawValue: $0) }
        }
        set {
            signalsCollectedRaw = newValue.map { $0.rawValue }
        }
    }
}

// MARK: - Convenience Methods

extension DailySnapshot {
    /// Returns a summary string for the day
    var summaryText: String {
        var parts: [String] = []
        
        if let steps = stepCount {
            parts.append("\(steps.formatted()) steps")
        }
        if let sleep = sleepHours {
            parts.append("\(String(format: "%.1f", sleep)) hrs sleep")
        }
        if let screenTime = screenTimeMinutes {
            let hours = screenTime / 60
            let mins = screenTime % 60
            if hours > 0 {
                parts.append("\(hours)h \(mins)m screen time")
            } else {
                parts.append("\(mins)m screen time")
            }
        }
        if let reflectionCount = reflections?.count, reflectionCount > 0 {
            parts.append("\(reflectionCount) reflection\(reflectionCount == 1 ? "" : "s")")
        }
        
        return parts.isEmpty ? "No data yet" : parts.joined(separator: " · ")
    }
    
    /// Returns the average mood for the day if any mood entries exist
    var averageMood: Double? {
        guard let entries = moodEntries, !entries.isEmpty else { return nil }
        let sum = entries.reduce(0) { $0 + $1.mood.rawValue }
        return Double(sum) / Double(entries.count)
    }
    
    /// Checks if this snapshot has any meaningful data
    var hasData: Bool {
        stepCount != nil ||
        sleepHours != nil ||
        screenTimeMinutes != nil ||
        !(reflections?.isEmpty ?? true) ||
        !(moodEntries?.isEmpty ?? true)
    }
    
    /// Formatted date string
    var formattedDate: String {
        date.formatted(date: .abbreviated, time: .omitted)
    }
    
    var dayName: String {
        date.formatted(.dateTime.weekday(.wide))
    }
}
