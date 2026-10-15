//
//  DataOrchestrator.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import Foundation
import SwiftData
import CoreLocation

/// Coordinates all data collection services and assembles DailySnapshots
@MainActor
final class DataOrchestrator {
    static let shared = DataOrchestrator()
    
    // Services
    private let healthKit = HealthKitService.shared
    private let location = LocationService.shared
    private let motion = MotionService.shared
    private let screenTime = ScreenTimeService.shared
    private let weather = WeatherService.shared
    
    // State
    private(set) var isCollecting = false
    private(set) var lastCollectionDate: Date?
    private var currentLocation: CLLocation?
    
    // MARK: - Data Collection
    
    /// Collect all data for a specific date and create/update a DailySnapshot
    func collectData(for date: Date, context: ModelContext) async -> DailySnapshot {
        isCollecting = true
        defer { isCollecting = false }
        
        // Get or create snapshot for this date
        let snapshot = await getOrCreateSnapshot(for: date, context: context)
        
        // Track which signals were collected (based on enabled settings)
        let collectedSignals = Array(UserSettings.shared.enabledSignals)
        
        // Collect from each enabled service in parallel
        await withTaskGroup(of: Void.self) { group in
            let settings = UserSettings.shared
            
            // Health data
            if settings.enabledSignals.contains(.steps) ||
               settings.enabledSignals.contains(.sleep) ||
               settings.enabledSignals.contains(.exercise) ||
               settings.enabledSignals.contains(.heartRate) ||
               settings.enabledSignals.contains(.hrv) {
                group.addTask {
                    await self.collectHealthData(for: date, into: snapshot)
                }
            }
            
            // Motion data
            if settings.enabledSignals.contains(.motion) ||
               settings.enabledSignals.contains(.steps) {
                group.addTask {
                    await self.collectMotionData(for: date, into: snapshot)
                }
            }
            
            // Location data
            if settings.enabledSignals.contains(.location) ||
               settings.enabledSignals.contains(.distance) ||
               settings.enabledSignals.contains(.places) {
                group.addTask {
                    await self.collectLocationData(for: date, into: snapshot)
                }
            }
            
            // Screen time data
            if settings.enabledSignals.contains(.screenTime) ||
               settings.enabledSignals.contains(.appPickups) {
                group.addTask {
                    await self.collectScreenTimeData(for: date, into: snapshot)
                }
            }
            
            // Weather data
            if settings.enabledSignals.contains(.weather) {
                group.addTask {
                    await self.collectWeatherData(for: date, into: snapshot)
                }
            }
        }
        
        // Update metadata
        snapshot.signalsCollected = collectedSignals
        snapshot.updatedAt = Date()
        
        // Save
        do {
            try context.save()
        } catch {
            print("Failed to save snapshot: \(error)")
        }
        
        lastCollectionDate = Date()
        return snapshot
    }
    
    /// Collect data for yesterday (typically called in background)
    func collectYesterdayData(context: ModelContext) async -> DailySnapshot? {
        guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) else {
            return nil
        }
        return await collectData(for: yesterday, context: context)
    }
    
    /// Quick refresh of today's data
    func refreshToday(context: ModelContext) async -> DailySnapshot {
        return await collectData(for: Date(), context: context)
    }
    
    // MARK: - Individual Collection Methods
    
    private func collectHealthData(for date: Date, into snapshot: DailySnapshot) async {
        let result = await healthKit.fetchAllHealthData(for: date)
        
        if let steps = result.stepCount {
            snapshot.stepCount = steps
        }
        if let sleep = result.sleepHours {
            snapshot.sleepHours = sleep
        }
        if let quality = result.sleepQuality {
            snapshot.sleepQuality = quality
        }
        if let exercise = result.exerciseMinutes {
            snapshot.exerciseMinutes = exercise
        }
        if let hr = result.restingHeartRate {
            snapshot.restingHeartRate = hr
        }
        if let hrv = result.hrvAverage {
            snapshot.hrvAverage = hrv
        }
    }
    
    private func collectMotionData(for date: Date, into snapshot: DailySnapshot) async {
        let result = await motion.fetchAllMotionData(for: date)
        
        if let pedometer = result.pedometerData {
            // Only use pedometer steps if HealthKit didn't provide them
            if snapshot.stepCount == nil {
                snapshot.stepCount = pedometer.steps
            }
        }
        
        if let activity = result.primaryActivity {
            snapshot.activityType = activity
        }
        
        if let activeMinutes = result.activeMinutes {
            snapshot.activeMinutes = activeMinutes
        }
    }
    
    private func collectLocationData(for date: Date, into snapshot: DailySnapshot) async {
        let result = location.getLocationData(for: date)
        
        snapshot.locationClusters = result.clusters
        snapshot.distanceTraveled = result.distanceTraveled
        snapshot.placesVisited = result.placesVisited
        snapshot.leftHome = result.leftHome
    }
    
    private func collectScreenTimeData(for date: Date, into snapshot: DailySnapshot) async {
        do {
            if let result = try await screenTime.fetchScreenTimeData(for: date) {
                snapshot.screenTimeMinutes = result.totalMinutes
                snapshot.appPickups = result.pickups
                snapshot.topApps = result.appUsage
            }
        } catch {
            print("Screen time collection failed: \(error)")
        }
    }
    
    private func collectWeatherData(for date: Date, into snapshot: DailySnapshot) async {
        // Use the last known location for weather
        guard let loc = currentLocation else {
            return
        }
        
        do {
            if let result = try await weather.fetchWeatherForGeneralLocation(
                latitude: loc.coordinate.latitude,
                longitude: loc.coordinate.longitude,
                date: date
            ) {
                snapshot.weatherCondition = result.condition
            }
        } catch {
            print("Weather collection failed: \(error)")
        }
    }
    
    // MARK: - Snapshot Management
    
    private func getOrCreateSnapshot(for date: Date, context: ModelContext) async -> DailySnapshot {
        let startOfDay = Calendar.current.startOfDay(for: date)
        
        let descriptor = FetchDescriptor<DailySnapshot>(
            predicate: #Predicate { $0.date == startOfDay }
        )
        
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        
        let newSnapshot = DailySnapshot(date: startOfDay)
        context.insert(newSnapshot)
        return newSnapshot
    }
    
    // MARK: - Service Management
    
    /// Start all background monitoring services
    func startMonitoring() {
        if UserSettings.shared.enabledSignals.contains(where: { $0.permissionGroup == .location }) {
            location.startMonitoring()
            
            // Track location updates for weather (placeholder for future implementation)
            location.onLocationUpdate = { _ in
                // Future: Update current location when it changes
            }
        }
    }
    
    /// Stop all background monitoring services
    func stopMonitoring() {
        location.stopMonitoring()
    }
    
    /// Update the current location (for weather lookups)
    func updateCurrentLocation(_ location: CLLocation) {
        self.currentLocation = location
    }
    
    // MARK: - Status
    
    /// Get collection status for all signals
    func getCollectionStatus() -> [SignalType: CollectionStatus] {
        var status: [SignalType: CollectionStatus] = [:]
        
        let settings = UserSettings.shared
        
        for signal in SignalType.allCases {
            if !settings.enabledSignals.contains(signal) {
                status[signal] = .disabled
                continue
            }
            
            switch signal.permissionGroup {
            case .health:
                status[signal] = healthKit.hasAuthorization ? .active : .permissionRequired
            case .location:
                status[signal] = location.hasAuthorization ? .active : .permissionRequired
            case .motion:
                status[signal] = motion.hasAuthorization ? .active : .permissionRequired
            case .screenTime:
                status[signal] = screenTime.isAuthorized ? .active : .permissionRequired
            case .none:
                status[signal] = .active
            }
        }
        
        return status
    }
    
    // MARK: - Private
    
    private init() {}
}

// MARK: - Supporting Types

enum CollectionStatus {
    case active          // Signal is being collected
    case disabled        // User disabled this signal
    case permissionRequired  // Need to request permission
    case unavailable     // Not available on this device
    
    var displayName: String {
        switch self {
        case .active: return "Active"
        case .disabled: return "Disabled"
        case .permissionRequired: return "Permission Required"
        case .unavailable: return "Unavailable"
        }
    }
    
    var icon: String {
        switch self {
        case .active: return "checkmark.circle.fill"
        case .disabled: return "minus.circle"
        case .permissionRequired: return "exclamationmark.circle"
        case .unavailable: return "xmark.circle"
        }
    }
}
