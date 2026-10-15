//
//  ScreenTimeService.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import Foundation
#if canImport(FamilyControls)
import FamilyControls
import DeviceActivity
import ManagedSettings
#endif

/// Service for collecting screen time data using DeviceActivity framework
/// Note: Full implementation requires Family Controls entitlement from Apple
@MainActor
@Observable
final class ScreenTimeService {
    static let shared = ScreenTimeService()
    
    // MARK: - State
    
    private(set) var authorizationStatus: ScreenTimeAuthStatus = .notDetermined
    private(set) var isMonitoring = false
    
    var isAuthorized: Bool {
        authorizationStatus == .authorized
    }
    
    var isAvailable: Bool {
        #if canImport(FamilyControls)
        return true
        #else
        return false
        #endif
    }
    
    // MARK: - Authorization
    
    /// Request Screen Time authorization using Family Controls
    func requestAuthorization() async throws {
        #if canImport(FamilyControls)
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            authorizationStatus = .authorized
            // Mark screen time as enabled in user settings
            if !UserSettings.shared.enabledSignals.contains(.screenTime) {
                UserSettings.shared.enabledSignals.insert(.screenTime)
            }
        } catch {
            authorizationStatus = .denied
            throw ScreenTimeError.notAuthorized
        }
        #else
        throw ScreenTimeError.entitlementRequired
        #endif
    }
    
    /// Check current authorization status
    func checkAuthorizationStatus() {
        #if canImport(FamilyControls)
        switch AuthorizationCenter.shared.authorizationStatus {
        case .notDetermined:
            authorizationStatus = .notDetermined
        case .denied:
            authorizationStatus = .denied
        case .approved:
            authorizationStatus = .authorized
        @unknown default:
            authorizationStatus = .notDetermined
        }
        #else
        authorizationStatus = .unavailable
        #endif
    }
    
    // MARK: - Device Activity Monitoring
    
    /// Start monitoring device activity for daily tracking
    func startDailyMonitoring() throws {
        #if canImport(FamilyControls)
        guard isAuthorized else {
            throw ScreenTimeError.notAuthorized
        }
        
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        
        let center = DeviceActivityCenter()
        try center.startMonitoring(
            .daily,
            during: schedule
        )
        
        isMonitoring = true
        #else
        throw ScreenTimeError.entitlementRequired
        #endif
    }
    
    /// Stop monitoring device activity
    func stopMonitoring() {
        #if canImport(FamilyControls)
        let center = DeviceActivityCenter()
        center.stopMonitoring([.daily])
        isMonitoring = false
        #endif
    }
    
    // MARK: - Data Collection
    
    /// Fetch screen time data for today
    /// Note: DeviceActivity doesn't provide historical data access - it reports via the extension
    func getTodayScreenTime() -> ScreenTimeDataResult? {
        // Screen time data comes from the DeviceActivityMonitor extension
        // which stores data in the shared App Group container
        return loadCachedScreenTimeData(for: Date())
    }
    
    /// Fetch screen time data for a specific date (from cache)
    func fetchScreenTimeData(for date: Date) async throws -> ScreenTimeDataResult? {
        guard isAuthorized else {
            return nil
        }
        
        return loadCachedScreenTimeData(for: date)
    }
    
    // MARK: - Data Persistence (App Group shared with extension)
    
    /// Load cached screen time data from App Group
    private func loadCachedScreenTimeData(for date: Date) -> ScreenTimeDataResult? {
        guard let defaults = UserDefaults(suiteName: "group.com.signals.app") else {
            return nil
        }
        
        let dateKey = screenTimeCacheKey(for: date)
        guard let data = defaults.data(forKey: dateKey),
              let result = try? JSONDecoder().decode(ScreenTimeDataResult.self, from: data) else {
            return nil
        }
        
        return result
    }
    
    /// Save screen time data to App Group (called from extension)
    func saveScreenTimeData(_ data: ScreenTimeDataResult, for date: Date) {
        guard let defaults = UserDefaults(suiteName: "group.com.signals.app"),
              let encoded = try? JSONEncoder().encode(data) else {
            return
        }
        
        let dateKey = screenTimeCacheKey(for: date)
        defaults.set(encoded, forKey: dateKey)
    }
    
    private func screenTimeCacheKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "screenTime_\(formatter.string(from: date))"
    }
    
    // MARK: - Private
    
    private init() {
        checkAuthorizationStatus()
    }
}

// MARK: - Device Activity Names

#if canImport(DeviceActivity)
extension DeviceActivityName {
    static let daily = DeviceActivityName("signals.daily")
}
#endif

// MARK: - Authorization Status

enum ScreenTimeAuthStatus: String {
    case notDetermined
    case authorized
    case denied
    case unavailable
}

// MARK: - Supporting Types

struct ScreenTimeDataResult: Codable {
    var date: Date
    var totalMinutes: Int
    var pickups: Int
    var appUsage: [AppUsageEntry]
    var firstPickupTime: Date?
    var lastPickupTime: Date?
    var hourlyUsage: [Int]  // 24 hours of usage data
    
    init(
        date: Date = Date(),
        totalMinutes: Int = 0,
        pickups: Int = 0,
        appUsage: [AppUsageEntry] = [],
        firstPickupTime: Date? = nil,
        lastPickupTime: Date? = nil,
        hourlyUsage: [Int] = Array(repeating: 0, count: 24)
    ) {
        self.date = date
        self.totalMinutes = totalMinutes
        self.pickups = pickups
        self.appUsage = appUsage
        self.firstPickupTime = firstPickupTime
        self.lastPickupTime = lastPickupTime
        self.hourlyUsage = hourlyUsage
    }
    
    var collectedSignals: [SignalType] {
        var signals: [SignalType] = []
        signals.append(.screenTime)
        return signals
    }
    
    /// App usage grouped by category
    var usageByCategory: [String: Int] {
        var result: [String: Int] = [:]
        for entry in appUsage {
            result[entry.category, default: 0] += entry.minutes
        }
        return result
    }
    
    /// Top categories by usage
    var topCategories: [(category: String, minutes: Int)] {
        usageByCategory
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { (category: $0.key, minutes: $0.value) }
    }
    
    /// Total hours as formatted string
    var formattedTotal: String {
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

// Note: AppUsageEntry and AppCategory are defined in SupportingTypes.swift

enum ScreenTimeError: Error, LocalizedError {
    case notAvailable
    case notAuthorized
    case entitlementRequired
    case queryFailed
    case monitoringFailed
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Screen Time API is not available on this device"
        case .notAuthorized:
            return "Screen Time access not authorized"
        case .entitlementRequired:
            return "Family Controls entitlement required. Apply at developer.apple.com"
        case .queryFailed:
            return "Failed to query Screen Time data"
        case .monitoringFailed:
            return "Failed to start device activity monitoring"
        }
    }
}

/*
 IMPLEMENTATION NOTES FOR FAMILY CONTROLS:
 
 1. Apply for Family Controls entitlement at:
    https://developer.apple.com/contact/request/family-controls-distribution
 
 2. Add to entitlements file (uncomment in Signals.entitlements):
    <key>com.apple.developer.family-controls</key>
    <true/>
 
 3. Create DeviceActivityMonitor extension target:
    - File > New > Target > Device Activity Monitor Extension
    - Name: SignalsDeviceActivityMonitor
    - Use the same App Group: group.com.signals.app
 
 4. In the extension, implement DeviceActivityMonitor:
    - intervalDidStart: Start tracking for the day
    - intervalDidEnd: Finalize and save data to App Group
    - eventDidReachThreshold: Optional awareness nudges
 
 5. The extension writes ScreenTimeDataResult to the App Group UserDefaults
    using saveScreenTimeData(), which the main app reads via loadCachedScreenTimeData()
 
 Note: DeviceActivity respects privacy - we only access category-level data,
 never individual app names or detailed usage.
 */
