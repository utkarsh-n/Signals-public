//
//  TimelineBuilder.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//
//  Service for building timeline segments from daily snapshots and location data
//

import Foundation
import SwiftUI
import SwiftData

/// Service that builds timeline segments from raw data
@MainActor
final class TimelineBuilder {
    static let shared = TimelineBuilder()
    
    private init() {}
    
    // MARK: - Timeline Building
    
    /// Builds a complete DailyTimeline from a DailySnapshot
    func buildTimeline(
        for snapshot: DailySnapshot,
        reflections: [Reflection] = [],
        manualEvents: [ManualEvent] = [],
        appOpenLogs: [AppOpenLog] = []
    ) -> DailyTimeline {
        var timeline = DailyTimeline(date: snapshot.date)
        
        // Build sleep block
        if let sleepHours = snapshot.sleepHours, sleepHours > 0 {
            // Estimate wake time (assume 7 AM if not available)
            let calendar = Calendar.current
            let wakeTime = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: snapshot.date) ?? snapshot.date
            
            timeline.sleepBlock = SleepBlock(
                wakeTime: wakeTime,
                sleepDuration: sleepHours,
                quality: snapshot.sleepQuality
            )
        }
        
        // Build segments from location clusters
        var segments: [TimelineSegment] = []
        
        if let clusters = snapshot.locationClusters, !clusters.isEmpty {
            // Create segments from location clusters
            segments = buildSegmentsFromClusters(
                clusters,
                snapshot: snapshot,
                reflections: reflections,
                appOpenLogs: appOpenLogs
            )
        } else if manualEvents.isEmpty {
            // Only create a "day" segment if no location data AND no manual events
            let segment = buildSingleDaySegment(snapshot: snapshot, reflections: reflections, appOpenLogs: appOpenLogs)
            segments = [segment]
        }
        
        // Always add "Your Day" segment for today - it shows progress throughout the day
        // This is separate from location-based segments and manual events
        if Calendar.current.isDateInToday(snapshot.date) {
            // Only add if not already present from the single day segment case
            let hasYourDay = segments.contains { $0.locationLabel == "Your Day" || $0.locationLabel == "Starting your day" }
            if !hasYourDay {
                let yourDaySegment = buildSingleDaySegment(snapshot: snapshot, reflections: reflections, appOpenLogs: appOpenLogs)
                segments.insert(yourDaySegment, at: 0)
            }
        }
        
        // Merge in manual events
        segments = mergeManualEvents(manualEvents, into: segments)
        
        // Sort by start time first
        segments.sort { $0.startTime < $1.startTime }
        
        // Mark the last non-manual segment as active if viewing today
        // Manual events keep their specified end times
        if Calendar.current.isDateInToday(snapshot.date), !segments.isEmpty {
            // Find the last non-manual segment to mark as active
            if let lastNonManualIndex = segments.lastIndex(where: { !$0.isManualEvent }) {
                segments[lastNonManualIndex].isActive = true
                segments[lastNonManualIndex].endTime = nil
            }
        }
        
        timeline.segments = segments
        return timeline
    }
    
    /// Builds a complete DailyTimeline with all data sources
    func buildTimeline(for snapshot: DailySnapshot, reflections: [Reflection] = []) -> DailyTimeline {
        // Legacy method - call the full version with empty arrays for new data sources
        return buildTimeline(for: snapshot, reflections: reflections, manualEvents: [], appOpenLogs: [])
    }
    
    /// Builds a timeline for today with real-time updates
    func buildTodayTimeline(context: ModelContext) -> DailyTimeline? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Fetch today's snapshot
        let descriptor = FetchDescriptor<DailySnapshot>(
            predicate: #Predicate { snapshot in
                snapshot.date >= today
            }
        )
        
        guard let snapshots = try? context.fetch(descriptor),
              let todaySnapshot = snapshots.first else {
            // No snapshot yet - return empty timeline for today
            return DailyTimeline(date: today, segments: [
                TimelineSegment(
                    startTime: Date(),
                    locationType: .unknown,
                    locationLabel: "Starting your day",
                    isActive: true
                )
            ])
        }
        
        // Fetch today's reflections
        let reflectionDescriptor = FetchDescriptor<Reflection>(
            predicate: #Predicate { reflection in
                reflection.createdAt >= today
            },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        let reflections = (try? context.fetch(reflectionDescriptor)) ?? []
        
        return buildTimeline(for: todaySnapshot, reflections: reflections)
    }
    
    // MARK: - Private Helpers
    
    private func buildSegmentsFromClusters(
        _ clusters: [LocationCluster],
        snapshot: DailySnapshot,
        reflections: [Reflection],
        appOpenLogs: [AppOpenLog]
    ) -> [TimelineSegment] {
        let calendar = Calendar.current
        var segments: [TimelineSegment] = []
        
        // Distribute time proportionally based on cluster time spent
        let totalTime = clusters.reduce(0) { $0 + $1.timeSpentMinutes }
        guard totalTime > 0 else { return [] }
        
        var currentTime = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: snapshot.date) ?? snapshot.date
        
        for cluster in clusters {
            let locationType = mapClusterToLocationType(cluster.label)
            let duration = cluster.timeSpentMinutes
            let endTime = calendar.date(byAdding: .minute, value: duration, to: currentTime) ?? currentTime
            
            // Find reflections within this time window
            let segmentReflections = reflections.filter { reflection in
                reflection.createdAt >= currentTime && reflection.createdAt < endTime
            }.map { TimelineReflection(from: $0) }
            
            // Find app opens within this time window and aggregate
            let segmentAppOpens = aggregateAppOpens(appOpenLogs.filter { log in
                log.timestamp >= currentTime && log.timestamp < endTime
            })
            
            // Distribute stats proportionally
            let timeFraction = Double(duration) / Double(totalTime)
            let segmentScreenTime = Int(Double(snapshot.screenTimeMinutes ?? 0) * timeFraction)
            let segmentSteps = Int(Double(snapshot.stepCount ?? 0) * timeFraction)
            let segmentAppOpenCount = segmentAppOpens.reduce(0) { $0 + $1.count }
            
            let segment = TimelineSegment(
                startTime: currentTime,
                endTime: endTime,
                locationType: locationType,
                locationLabel: cluster.label,
                screenTimeMinutes: segmentScreenTime,
                stepCount: segmentSteps,
                reflections: segmentReflections,
                appOpenCount: segmentAppOpenCount,
                isActive: false,
                appOpenDetails: segmentAppOpens
            )
            
            segments.append(segment)
            currentTime = endTime
        }
        
        return mergeShortSegments(segments)
    }
    
    private func buildSingleDaySegment(snapshot: DailySnapshot, reflections: [Reflection], appOpenLogs: [AppOpenLog] = []) -> TimelineSegment {
        let calendar = Calendar.current
        let startTime = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: snapshot.date) ?? snapshot.date
        let endTime = calendar.isDateInToday(snapshot.date) ? nil : calendar.date(bySettingHour: 22, minute: 0, second: 0, of: snapshot.date)
        
        let timelineReflections = reflections.map { TimelineReflection(from: $0) }
        let aggregatedAppOpens = aggregateAppOpens(appOpenLogs)
        
        return TimelineSegment(
            startTime: startTime,
            endTime: endTime,
            locationType: .home,
            locationLabel: "Your Day",
            screenTimeMinutes: snapshot.screenTimeMinutes ?? 0,
            stepCount: snapshot.stepCount ?? 0,
            reflections: timelineReflections,
            appOpenCount: aggregatedAppOpens.reduce(0) { $0 + $1.count },
            isActive: calendar.isDateInToday(snapshot.date),
            appOpenDetails: aggregatedAppOpens
        )
    }
    
    // MARK: - App Open Aggregation
    
    /// Aggregates app open logs by category within hourly windows
    private func aggregateAppOpens(_ logs: [AppOpenLog]) -> [AppOpenDetail] {
        guard !logs.isEmpty else { return [] }
        
        // Group by category
        var grouped: [String: (count: Int, first: Date, last: Date)] = [:]
        
        for log in logs {
            let category = log.category.rawValue
            if var existing = grouped[category] {
                existing.count += 1
                existing.first = min(existing.first, log.timestamp)
                existing.last = max(existing.last, log.timestamp)
                grouped[category] = existing
            } else {
                grouped[category] = (count: 1, first: log.timestamp, last: log.timestamp)
            }
        }
        
        return grouped.map { category, data in
            AppOpenDetail(
                category: category,
                count: data.count,
                firstOpenTime: data.first,
                lastOpenTime: data.last
            )
        }.sorted { $0.count > $1.count }
    }
    
    // MARK: - Manual Events Merging
    
    /// Merges manual events into the segment list, splitting or replacing automatic segments as needed
    private func mergeManualEvents(_ manualEvents: [ManualEvent], into segments: [TimelineSegment]) -> [TimelineSegment] {
        guard !manualEvents.isEmpty else { return segments }
        
        var result = segments
        
        for event in manualEvents.sorted(by: { $0.startTime < $1.startTime }) {
            // Create segment from manual event
            let manualSegment = createSegmentFromManualEvent(event)
            
            // Find overlapping segments and adjust
            result = insertManualSegment(manualSegment, into: result)
        }
        
        return result
    }
    
    private func createSegmentFromManualEvent(_ event: ManualEvent) -> TimelineSegment {
        let category = event.category
        
        // Determine location type from category
        let locationType: LocationType
        switch category {
        case .work: locationType = .work
        case .school: locationType = .school
        case .exercise: locationType = .gym
        case .driving: locationType = .transit
        default: locationType = .unknown
        }
        
        var customIcon: String? = nil
        var customColorHex: String? = nil
        
        if case .custom(let custom) = category {
            customIcon = custom.icon
            customColorHex = custom.colorHex
        } else {
            customIcon = category.icon
            customColorHex = category.color.hexString
        }
        
        return TimelineSegment(
            startTime: event.startTime,
            endTime: event.endTime,
            locationType: locationType,
            locationLabel: category.displayName,
            screenTimeMinutes: 0,
            stepCount: 0,
            reflections: [],
            appOpenCount: 0,
            isActive: false,
            source: .manual,
            manualEventID: event.id,
            customIcon: customIcon,
            customColorHex: customColorHex,
            appOpenDetails: [],
            isEditable: true
        )
    }
    
    private func insertManualSegment(_ manualSegment: TimelineSegment, into segments: [TimelineSegment]) -> [TimelineSegment] {
        var result: [TimelineSegment] = []
        
        for segment in segments {
            // Never split "Your Day" or "Starting your day" segments - they're summary segments
            let isYourDaySegment = segment.locationLabel == "Your Day" || segment.locationLabel == "Starting your day"
            if isYourDaySegment {
                result.append(segment)
                continue
            }
            
            // Check if this segment overlaps with the manual segment
            let segmentEnd = segment.endTime ?? Date()
            let manualEnd = manualSegment.endTime ?? Date()
            
            let overlaps = segment.startTime < manualEnd && manualSegment.startTime < segmentEnd
            
            if overlaps && segment.source != .manual {
                // Split or adjust the automatic segment
                
                // Part before manual event
                if segment.startTime < manualSegment.startTime {
                    var beforeSegment = segment
                    beforeSegment.endTime = manualSegment.startTime
                    if beforeSegment.durationMinutes >= 5 {
                        result.append(beforeSegment)
                    }
                }
                
                // Part after manual event
                if segmentEnd > manualEnd {
                    let afterSegment = TimelineSegment(
                        startTime: manualEnd,
                        endTime: segment.endTime,
                        locationType: segment.locationType,
                        locationLabel: segment.locationLabel,
                        screenTimeMinutes: 0,
                        stepCount: 0,
                        reflections: [],
                        appOpenCount: 0,
                        isActive: segment.isActive
                    )
                    if afterSegment.durationMinutes >= 5 {
                        result.append(afterSegment)
                    }
                }
            } else {
                result.append(segment)
            }
        }
        
        // Add the manual segment
        result.append(manualSegment)
        
        return result.sorted { $0.startTime < $1.startTime }
    }
    
    /// Merges very short segments (<5 min) into adjacent segments
    private func mergeShortSegments(_ segments: [TimelineSegment]) -> [TimelineSegment] {
        guard segments.count > 1 else { return segments }
        
        var merged: [TimelineSegment] = []
        
        for segment in segments {
            if segment.durationMinutes < 5, let last = merged.last {
                // Merge into previous segment
                var updated = last
                updated.endTime = segment.endTime
                updated.screenTimeMinutes += segment.screenTimeMinutes
                updated.stepCount += segment.stepCount
                updated.reflections += segment.reflections
                updated.appOpenCount += segment.appOpenCount
                merged[merged.count - 1] = updated
            } else {
                merged.append(segment)
            }
        }
        
        return merged
    }
    
    private func mapClusterToLocationType(_ label: String) -> LocationType {
        let lowercased = label.lowercased()
        
        if lowercased.contains("home") {
            return .home
        } else if lowercased.contains("work") || lowercased.contains("office") {
            return .work
        } else if lowercased.contains("gym") || lowercased.contains("fitness") {
            return .gym
        } else if lowercased.contains("school") || lowercased.contains("university") {
            return .school
        } else if lowercased.contains("transit") || lowercased.contains("commute") {
            return .transit
        } else if lowercased.contains("new") {
            return .newPlace
        }
        
        return .unknown
    }
}

// MARK: - Timeline ViewModel

@MainActor
@Observable
final class TimelineViewModel {
    private(set) var timeline: DailyTimeline?
    private(set) var isLoading = false
    private(set) var error: Error?
    
    var selectedDate: Date = Date() {
        didSet {
            if !Calendar.current.isDate(selectedDate, inSameDayAs: oldValue) {
                loadTimeline()
            }
        }
    }
    
    private var modelContext: ModelContext?
    
    func setup(context: ModelContext) {
        self.modelContext = context
        loadTimeline()
    }
    
    func loadTimeline() {
        guard let context = modelContext else { return }
        
        isLoading = true
        error = nil
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        
        // Fetch snapshot for selected date
        let descriptor = FetchDescriptor<DailySnapshot>(
            predicate: #Predicate { snapshot in
                snapshot.date >= startOfDay && snapshot.date < endOfDay
            }
        )
        
        do {
            let snapshots = try context.fetch(descriptor)
            
            // Fetch reflections for the day
            let reflectionDescriptor = FetchDescriptor<Reflection>(
                predicate: #Predicate { reflection in
                    reflection.createdAt >= startOfDay && reflection.createdAt < endOfDay
                },
                sortBy: [SortDescriptor(\.createdAt)]
            )
            let reflections = try context.fetch(reflectionDescriptor)
            
            // Fetch manual events for the day
            let manualEventDescriptor = FetchDescriptor<ManualEvent>(
                predicate: #Predicate { event in
                    event.startTime >= startOfDay && event.startTime < endOfDay
                },
                sortBy: [SortDescriptor(\.startTime)]
            )
            let manualEvents = try context.fetch(manualEventDescriptor)
            
            // Fetch app open logs for the day
            let appOpenDescriptor = FetchDescriptor<AppOpenLog>(
                predicate: #Predicate { log in
                    log.timestamp >= startOfDay && log.timestamp < endOfDay
                },
                sortBy: [SortDescriptor(\.timestamp)]
            )
            let appOpenLogs = try context.fetch(appOpenDescriptor)
            
            if let snapshot = snapshots.first {
                timeline = TimelineBuilder.shared.buildTimeline(
                    for: snapshot,
                    reflections: reflections,
                    manualEvents: manualEvents,
                    appOpenLogs: appOpenLogs
                )
            } else {
                // No snapshot but might have manual events - create minimal timeline
                if !manualEvents.isEmpty {
                    var emptyTimeline = DailyTimeline(date: selectedDate)
                    emptyTimeline.segments = manualEvents.map { event in
                        createSegmentFromEvent(event)
                    }
                    timeline = emptyTimeline
                } else {
                    timeline = DailyTimeline(date: selectedDate)
                }
            }
        } catch {
            self.error = error
            timeline = DailyTimeline(date: selectedDate)
        }
        
        isLoading = false
    }
    
    private func createSegmentFromEvent(_ event: ManualEvent) -> TimelineSegment {
        let category = event.category
        
        var customIcon: String? = nil
        var customColorHex: String? = nil
        
        if case .custom(let custom) = category {
            customIcon = custom.icon
            customColorHex = custom.colorHex
        } else {
            customIcon = category.icon
            customColorHex = category.color.hexString
        }
        
        return TimelineSegment(
            startTime: event.startTime,
            endTime: event.endTime,
            locationType: .unknown,
            locationLabel: category.displayName,
            source: .manual,
            manualEventID: event.id,
            customIcon: customIcon,
            customColorHex: customColorHex,
            isEditable: true
        )
    }
    
    func navigateToDay(_ date: Date) {
        selectedDate = date
    }
    
    func goToPreviousDay() {
        if let previousDay = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) {
            selectedDate = previousDay
        }
    }
    
    func goToNextDay() {
        if let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate),
           nextDay <= Date() {
            selectedDate = nextDay
        }
    }
    
    func goToToday() {
        selectedDate = Date()
    }
    
    var canGoForward: Bool {
        !Calendar.current.isDateInToday(selectedDate)
    }
    
    var isViewingToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }
}
