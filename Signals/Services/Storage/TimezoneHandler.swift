//
//  TimezoneHandler.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import Foundation
import SwiftData
import UIKit

/// Handles timezone and clock changes to maintain data integrity
@MainActor
final class TimezoneHandler {
    // MARK: - Singleton
    
    static let shared = TimezoneHandler()
    
    // MARK: - State
    
    private var lastKnownTimezone: TimeZone?
    private var lastKnownDate: Date?
    
    private init() {
        lastKnownTimezone = TimeZone.current
        lastKnownDate = Date()
        
        // Observe timezone changes
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name.NSSystemTimeZoneDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor [weak self] in
                self?.handleTimezoneChange()
            }
        }
        
        // Observe significant time changes (clock manually changed, daylight saving, etc.)
        NotificationCenter.default.addObserver(
            forName: UIApplication.significantTimeChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor [weak self] in
                self?.handleSignificantTimeChange()
            }
        }
    }
    
    // MARK: - Timezone Change Handling
    
    private func handleTimezoneChange() {
        let newTimezone = TimeZone.current
        
        guard let oldTimezone = lastKnownTimezone,
              newTimezone.identifier != oldTimezone.identifier else {
            return
        }
        
        // Record the timezone change
        let change = TimezoneChange(
            from: oldTimezone,
            to: newTimezone,
            date: Date()
        )
        
        recordTimezoneChange(change)
        
        // Update stored reference
        lastKnownTimezone = newTimezone
        UserSettings.shared.lastKnownTimezone = newTimezone.identifier
    }
    
    private func handleSignificantTimeChange() {
        // This handles cases like:
        // - User manually changed the clock
        // - Daylight saving time transition
        // - Automatic time sync after being offline
        
        let now = Date()
        
        // Check if there's an unexpected time jump
        if let lastDate = lastKnownDate {
            let expectedInterval = Date().timeIntervalSince(lastDate)
            
            // If time jumped significantly (more than expected), log it
            if abs(expectedInterval) > 3600 { // 1 hour threshold
                // This could indicate the user changed their clock
                // We don't adjust data, just note it for insights
            }
        }
        
        lastKnownDate = now
    }
    
    // MARK: - Date Normalization
    
    /// Normalize a date to midnight in the current timezone
    func normalizeToMidnight(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }
    
    /// Check if a date is "today" accounting for timezone
    func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }
    
    /// Get the appropriate date for a snapshot based on time of day
    /// If it's between midnight and 4 AM, it might still be part of "yesterday" for sleep data
    func getSnapshotDate(for timestamp: Date) -> Date {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: timestamp)
        
        // If between midnight and 4 AM, consider it part of the previous day
        // This helps with sleep tracking that spans midnight
        if hour < 4 {
            if let yesterday = calendar.date(byAdding: .day, value: -1, to: timestamp) {
                return calendar.startOfDay(for: yesterday)
            }
        }
        
        return calendar.startOfDay(for: timestamp)
    }
    
    // MARK: - Timezone Change Recording
    
    private func recordTimezoneChange(_ change: TimezoneChange) {
        // Store timezone change history for potential data adjustment
        var changes = getTimezoneChanges()
        changes.append(change)
        
        // Keep only last 10 changes
        if changes.count > 10 {
            changes = Array(changes.suffix(10))
        }
        
        saveTimezoneChanges(changes)
    }
    
    private func getTimezoneChanges() -> [TimezoneChange] {
        guard let data = UserDefaults.standard.data(forKey: "timezoneChanges"),
              let changes = try? JSONDecoder().decode([TimezoneChange].self, from: data) else {
            return []
        }
        return changes
    }
    
    private func saveTimezoneChanges(_ changes: [TimezoneChange]) {
        if let data = try? JSONEncoder().encode(changes) {
            UserDefaults.standard.set(data, forKey: "timezoneChanges")
        }
    }
    
    // MARK: - Validation
    
    /// Validate that a snapshot's date makes sense
    func validateSnapshotDate(_ snapshot: DailySnapshot) -> Bool {
        let date = snapshot.date
        let now = Date()
        
        // Date shouldn't be in the future
        guard date <= now else { return false }
        
        // Date shouldn't be unreasonably old (more than 2 years)
        guard let twoYearsAgo = Calendar.current.date(byAdding: .year, value: -2, to: now),
              date >= twoYearsAgo else { return false }
        
        return true
    }
    
    /// Get days between two dates, accounting for timezone
    func daysBetween(_ startDate: Date, and endDate: Date) -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        
        return calendar.dateComponents([.day], from: start, to: end).day ?? 0
    }
}

// MARK: - Timezone Change Model

struct TimezoneChange: Codable {
    let fromIdentifier: String
    let toIdentifier: String
    let date: Date
    
    init(from: TimeZone, to: TimeZone, date: Date) {
        self.fromIdentifier = from.identifier
        self.toIdentifier = to.identifier
        self.date = date
    }
    
    var fromTimezone: TimeZone? {
        TimeZone(identifier: fromIdentifier)
    }
    
    var toTimezone: TimeZone? {
        TimeZone(identifier: toIdentifier)
    }
    
    var offsetChange: Int {
        let from = fromTimezone?.secondsFromGMT() ?? 0
        let to = toTimezone?.secondsFromGMT() ?? 0
        return (to - from) / 3600 // Hours
    }
}

// MARK: - UserSettings Extension

extension UserSettings {
    var lastKnownTimezone: String {
        get { UserDefaults.standard.string(forKey: "lastKnownTimezone") ?? TimeZone.current.identifier }
        set { UserDefaults.standard.set(newValue, forKey: "lastKnownTimezone") }
    }
}
