//
//  AppOpenLog.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import Foundation
import SwiftData

/// Logs individual app opens captured via Shortcuts automation.
/// This enables "one sec" style app usage tracking without requiring
/// Screen Time API access.
@Model
final class AppOpenLog {
    var id: UUID
    var timestamp: Date
    var categoryRaw: String
    
    // Optional context
    var notes: String?
    var wasIntentional: Bool?  // User can mark if they meant to open the app
    
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        category: AppCategory,
        notes: String? = nil,
        wasIntentional: Bool? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.categoryRaw = category.rawValue
        self.notes = notes
        self.wasIntentional = wasIntentional
    }
    
    var category: AppCategory {
        get { AppCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }
}

// Note: AppCategory is defined in SupportingTypes.swift

// MARK: - Convenience Extensions

extension AppOpenLog {
    /// Returns the hour of day (0-23) when this app was opened
    var hourOfDay: Int {
        Calendar.current.component(.hour, from: timestamp)
    }
    
    /// Returns whether this was opened during typical "work hours" (9 AM - 5 PM weekdays)
    var duringWorkHours: Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: timestamp)
        let isWeekday = !calendar.isDateInWeekend(timestamp)
        return isWeekday && hour >= 9 && hour < 17
    }
}
