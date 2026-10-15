//
//  TimelineSegment.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//
//  Represents a segment of time in the user's day timeline
//

import Foundation
import SwiftUI
import SwiftData

// MARK: - Location Types

/// Types of locations that can be detected in the timeline
enum LocationType: String, Codable, CaseIterable {
    case home = "Home"
    case work = "Work"
    case transit = "Transit"
    case gym = "Gym"
    case school = "School"
    case newPlace = "New Place"
    case unknown = "Unknown"
    
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .work: return "briefcase.fill"
        case .transit: return "car.fill"
        case .gym: return "dumbbell.fill"
        case .school: return "graduationcap.fill"
        case .newPlace: return "mappin.circle.fill"
        case .unknown: return "location.fill"
        }
    }
    
    var color: String {
        switch self {
        case .home: return "blue"
        case .work: return "purple"
        case .transit: return "green"
        case .gym: return "orange"
        case .school: return "teal"
        case .newPlace: return "pink"
        case .unknown: return "gray"
        }
    }
}

// MARK: - Segment Source

/// Identifies the source of a timeline segment
enum SegmentSource: String, Codable, Equatable {
    case automatic      // From location/sensor data
    case manual         // User-created event
    case appUsage       // Aggregated app opens from Shortcuts
}

// MARK: - Timeline Segment

/// A segment of time within a day's timeline
/// Represents a continuous period at a location with accumulated activity data
struct TimelineSegment: Identifiable, Codable, Equatable {
    let id: UUID
    let startTime: Date
    var endTime: Date?              // nil if segment is still active
    var locationType: LocationType
    var locationLabel: String       // Custom label like "Home", "Coffee Shop"
    var screenTimeMinutes: Int
    var stepCount: Int
    var reflections: [TimelineReflection]
    var appOpenCount: Int
    var isActive: Bool              // Currently happening
    
    // New properties for manual events and app usage
    var source: SegmentSource
    var manualEventID: UUID?        // Reference to ManualEvent if source is .manual
    var customIcon: String?         // For custom events
    var customColorHex: String?     // For custom events
    var appOpenDetails: [AppOpenDetail]  // Detailed app opens for this segment
    var isEditable: Bool            // Whether user can edit this segment
    
    init(
        id: UUID = UUID(),
        startTime: Date,
        endTime: Date? = nil,
        locationType: LocationType = .unknown,
        locationLabel: String = "",
        screenTimeMinutes: Int = 0,
        stepCount: Int = 0,
        reflections: [TimelineReflection] = [],
        appOpenCount: Int = 0,
        isActive: Bool = false,
        source: SegmentSource = .automatic,
        manualEventID: UUID? = nil,
        customIcon: String? = nil,
        customColorHex: String? = nil,
        appOpenDetails: [AppOpenDetail] = [],
        isEditable: Bool = true
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.locationType = locationType
        self.locationLabel = locationLabel.isEmpty ? locationType.rawValue : locationLabel
        self.screenTimeMinutes = screenTimeMinutes
        self.stepCount = stepCount
        self.reflections = reflections
        self.appOpenCount = appOpenCount
        self.isActive = isActive
        self.source = source
        self.manualEventID = manualEventID
        self.customIcon = customIcon
        self.customColorHex = customColorHex
        self.appOpenDetails = appOpenDetails
        self.isEditable = isEditable
    }
    
    // MARK: - Computed Properties
    
    /// Duration of the segment in minutes
    var durationMinutes: Int {
        let end = endTime ?? Date()
        return Int(end.timeIntervalSince(startTime) / 60)
    }
    
    /// Formatted duration string
    var formattedDuration: String {
        let hours = durationMinutes / 60
        let mins = durationMinutes % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins)m"
    }
    
    /// Formatted time range
    var timeRangeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        let start = formatter.string(from: startTime)
        if let endTime = endTime {
            let end = formatter.string(from: endTime)
            return "\(start) – \(end)"
        }
        return "\(start) – now"
    }
    
    /// Start time formatted
    var formattedStartTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: startTime)
    }
    
    /// End time formatted (or "now" if active)
    var formattedEndTime: String {
        if let endTime = endTime {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: endTime)
        }
        return "now"
    }
    
    /// Proportional height for timeline display (based on duration)
    /// Minimum 60pt, maximum 300pt, scaled by duration
    func proportionalHeight(minHeight: CGFloat = 60, maxHeight: CGFloat = 300) -> CGFloat {
        let baseDuration: CGFloat = 60 // 1 hour = base height
        let durationFactor = CGFloat(durationMinutes) / baseDuration
        let scaledHeight = minHeight + (durationFactor * 40)
        return min(max(scaledHeight, minHeight), maxHeight)
    }
    
    /// Whether this segment has any activity data
    var hasActivity: Bool {
        screenTimeMinutes > 0 || stepCount > 0 || !reflections.isEmpty || appOpenCount > 0 || !appOpenDetails.isEmpty
    }
    
    /// Display icon (custom or location-based)
    var displayIcon: String {
        customIcon ?? locationType.icon
    }
    
    /// Display color (custom or location-based)
    var displayColor: Color {
        if let hex = customColorHex {
            return Color(hex: hex) ?? locationColorValue
        }
        return locationColorValue
    }
    
    private var locationColorValue: Color {
        switch locationType {
        case .home: return .blue
        case .work: return .purple
        case .transit: return .green
        case .gym: return .orange
        case .school: return .teal
        case .newPlace: return .pink
        case .unknown: return .gray
        }
    }
    
    /// Whether this is a manual event
    var isManualEvent: Bool {
        source == .manual
    }
    
    /// Aggregated app opens grouped by category
    var aggregatedAppOpens: [AppOpenDetail] {
        // Group app opens by category and return aggregated
        var grouped: [String: AppOpenDetail] = [:]
        for detail in appOpenDetails {
            let key = detail.category
            if var existing = grouped[key] {
                existing.count += detail.count
                if detail.lastOpenTime > existing.lastOpenTime {
                    existing.lastOpenTime = detail.lastOpenTime
                }
                grouped[key] = existing
            } else {
                grouped[key] = detail
            }
        }
        return Array(grouped.values).sorted { $0.count > $1.count }
    }
}

// MARK: - App Open Detail

/// Details about app opens within a timeline segment
struct AppOpenDetail: Identifiable, Codable, Equatable {
    var id: UUID
    var category: String        // AppCategory raw value
    var count: Int
    var firstOpenTime: Date
    var lastOpenTime: Date
    
    init(id: UUID = UUID(), category: String, count: Int = 1, firstOpenTime: Date, lastOpenTime: Date? = nil) {
        self.id = id
        self.category = category
        self.count = count
        self.firstOpenTime = firstOpenTime
        self.lastOpenTime = lastOpenTime ?? firstOpenTime
    }
    
    var displayText: String {
        if count == 1 {
            return "Opened \(category)"
        }
        return "Opened \(category) \(count)×"
    }
    
    var categoryIcon: String {
        AppCategory(rawValue: category)?.icon ?? "app.fill"
    }
    
    var categoryColor: Color {
        guard let appCategory = AppCategory(rawValue: category) else { return .gray }
        switch appCategory.color {
        case "blue": return .blue
        case "purple": return .purple
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        case "pink": return .pink
        case "gray": return .gray
        case "yellow": return .yellow
        case "indigo": return .indigo
        case "teal": return .teal
        case "cyan": return .cyan
        case "mint": return .mint
        default: return .gray
        }
    }
}

// MARK: - Timeline Reflection (lightweight for timeline display)

/// A lightweight reflection reference for timeline display
struct TimelineReflection: Identifiable, Codable, Equatable {
    let id: UUID
    let timestamp: Date
    let preview: String  // First ~50 chars of the reflection
    let sentiment: Sentiment?
    
    init(from reflection: Reflection) {
        self.id = reflection.id
        self.timestamp = reflection.createdAt
        self.preview = String(reflection.text.prefix(50)) + (reflection.text.count > 50 ? "..." : "")
        self.sentiment = reflection.sentiment
    }
    
    init(id: UUID = UUID(), timestamp: Date = Date(), preview: String, sentiment: Sentiment? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.preview = preview
        self.sentiment = sentiment
    }
}

// MARK: - Sleep Block

/// Special segment representing sleep at the start of the day
struct SleepBlock: Codable, Equatable {
    let wakeTime: Date
    let sleepDuration: Double  // Hours
    let quality: SleepQuality?
    
    var formattedDuration: String {
        let hours = Int(sleepDuration)
        let mins = Int((sleepDuration - Double(hours)) * 60)
        if mins > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(hours)h"
    }
    
    var formattedWakeTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: wakeTime)
    }
}

// MARK: - Daily Timeline

/// Complete timeline for a single day
struct DailyTimeline: Identifiable, Equatable {
    let id: UUID
    let date: Date
    var sleepBlock: SleepBlock?
    var segments: [TimelineSegment]
    
    init(id: UUID = UUID(), date: Date, sleepBlock: SleepBlock? = nil, segments: [TimelineSegment] = []) {
        self.id = id
        self.date = date
        self.sleepBlock = sleepBlock
        self.segments = segments
    }
    
    /// Whether this is today's timeline
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    /// The currently active segment (if any)
    var currentSegment: TimelineSegment? {
        segments.first { $0.isActive }
    }
    
    /// Total screen time across all segments
    var totalScreenTime: Int {
        segments.reduce(0) { $0 + $1.screenTimeMinutes }
    }
    
    /// Total steps across all segments
    var totalSteps: Int {
        segments.reduce(0) { $0 + $1.stepCount }
    }
    
    /// All reflections from all segments
    var allReflections: [TimelineReflection] {
        segments.flatMap { $0.reflections }
    }
    
    /// Formatted date header
    var dateHeader: String {
        if isToday {
            return "Today"
        }
        if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        }
        return date.formatted(.dateTime.weekday(.wide).month().day())
    }
}
