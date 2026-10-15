//
//  SignalsDeviceActivityMonitor.swift
//  SignalsDeviceActivityMonitor
//
//  Device Activity Monitor Extension for Signals app
//  Monitors daily device activity and saves aggregated data to App Group
//

import DeviceActivity
import Foundation
import ManagedSettings

/// Extension point for monitoring device activity
/// This runs in a separate process from the main app
class SignalsDeviceActivityMonitor: DeviceActivityMonitor {
    
    // MARK: - App Group Storage
    
    private let appGroupID = "group.com.signals.app"
    
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }
    
    // MARK: - Interval Callbacks
    
    /// Called when the daily monitoring interval starts (midnight)
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        
        guard activity == .daily else { return }
        
        // Initialize today's data container
        let today = Date()
        let initialData = ScreenTimeExtensionData(
            date: today,
            totalMinutes: 0,
            pickups: 0,
            appUsage: [],
            firstPickupTime: today, // First activity of the day
            lastPickupTime: today,
            hourlyUsage: Array(repeating: 0, count: 24)
        )
        
        saveData(initialData, for: today)
    }
    
    /// Called when the daily monitoring interval ends (end of day)
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        
        guard activity == .daily else { return }
        
        // Finalize today's data - the data has been accumulated throughout the day
        // via eventDidReachThreshold callbacks
        
        // Mark the interval as complete
        if var data = loadData(for: Date()) {
            data.lastPickupTime = Date()
            saveData(data, for: Date())
        }
    }
    
    /// Called when a usage threshold is reached for a specific event
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        
        // Handle awareness nudge events if configured
        // This can be used to trigger notifications for screen time limits
    }
    
    /// Warning before interval starts
    override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)
        // Prepare for new day tracking
    }
    
    /// Warning before interval ends
    override func intervalWillEndWarning(for activity: DeviceActivityName) {
        super.intervalWillEndWarning(for: activity)
        // Finalize any pending data before day ends
    }
    
    // MARK: - Data Persistence
    
    private func saveData(_ data: ScreenTimeExtensionData, for date: Date) {
        guard let defaults = sharedDefaults,
              let encoded = try? JSONEncoder().encode(data) else {
            return
        }
        
        let key = cacheKey(for: date)
        defaults.set(encoded, forKey: key)
    }
    
    private func loadData(for date: Date) -> ScreenTimeExtensionData? {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: cacheKey(for: date)),
              let decoded = try? JSONDecoder().decode(ScreenTimeExtensionData.self, from: data) else {
            return nil
        }
        return decoded
    }
    
    private func cacheKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "screenTime_\(formatter.string(from: date))"
    }
}

// MARK: - Device Activity Names

extension DeviceActivityName {
    static let daily = DeviceActivityName("signals.daily")
}

// MARK: - Data Model for Extension

/// Screen time data structure shared between extension and main app
/// Must match the ScreenTimeDataResult in the main app
struct ScreenTimeExtensionData: Codable {
    var date: Date
    var totalMinutes: Int
    var pickups: Int
    var appUsage: [AppUsageExtensionEntry]
    var firstPickupTime: Date?
    var lastPickupTime: Date?
    var hourlyUsage: [Int]
}

struct AppUsageExtensionEntry: Codable {
    let category: String
    let minutes: Int
}

/*
 SETUP INSTRUCTIONS:
 
 To create this extension in Xcode:
 
 1. File > New > Target
 2. Select "Device Activity Monitor Extension"
 3. Name it "SignalsDeviceActivityMonitor"
 4. Set the same Team and Bundle ID prefix as main app
 5. Add to the same App Group: group.com.signals.app
 
 Required Capabilities (in extension's entitlements):
 - Family Controls
 - App Groups (group.com.signals.app)
 
 Info.plist keys for extension:
 - NSExtension > NSExtensionPointIdentifier: com.apple.deviceactivity.monitor
 - NSExtension > NSExtensionPrincipalClass: $(PRODUCT_MODULE_NAME).SignalsDeviceActivityMonitor
 
 Note: The Family Controls entitlement requires approval from Apple.
 Apply at: https://developer.apple.com/contact/request/family-controls-distribution
 */
