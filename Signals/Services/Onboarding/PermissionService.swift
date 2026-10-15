//
//  PermissionService.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import Foundation
import UIKit
import HealthKit
import CoreLocation
import CoreMotion
import UserNotifications

/// Centralized service for managing all app permissions
@MainActor
final class PermissionService: NSObject {
    static let shared = PermissionService()
    
    // Services
    private let healthKit = HealthKitService.shared
    private let location = LocationService.shared
    private let motion = MotionService.shared
    private let screenTime = ScreenTimeService.shared
    
    // MARK: - Permission Status
    
    /// Get the current status of all permission groups
    func getAllPermissionStatuses() -> [PermissionGroup: PermissionStatus] {
        var statuses: [PermissionGroup: PermissionStatus] = [:]
        
        statuses[.health] = getHealthPermissionStatus()
        statuses[.location] = getLocationPermissionStatus()
        statuses[.motion] = getMotionPermissionStatus()
        statuses[.screenTime] = getScreenTimePermissionStatus()
        
        return statuses
    }
    
    func getHealthPermissionStatus() -> PermissionStatus {
        if !healthKit.isAvailable {
            return .unavailable
        }
        return healthKit.hasAuthorization ? .authorized : .notDetermined
    }
    
    func getLocationPermissionStatus() -> PermissionStatus {
        switch location.authorizationStatus {
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .unavailable
        case .denied:
            return .denied
        case .authorizedAlways:
            return .authorized
        case .authorizedWhenInUse:
            return .limited
        @unknown default:
            return .notDetermined
        }
    }
    
    func getMotionPermissionStatus() -> PermissionStatus {
        if !motion.isAvailable {
            return .unavailable
        }
        
        switch motion.authorizationStatus {
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .unavailable
        case .denied:
            return .denied
        case .authorized:
            return .authorized
        @unknown default:
            return .notDetermined
        }
    }
    
    func getScreenTimePermissionStatus() -> PermissionStatus {
        if !screenTime.isAvailable {
            return .unavailable
        }
        return screenTime.isAuthorized ? .authorized : .notDetermined
    }
    
    func getNotificationPermissionStatus() async -> PermissionStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        
        switch settings.authorizationStatus {
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .authorized:
            return .authorized
        case .provisional:
            return .limited
        case .ephemeral:
            return .limited
        @unknown default:
            return .notDetermined
        }
    }
    
    // MARK: - Request Permissions
    
    /// Request permission for a specific group
    func requestPermission(for group: PermissionGroup) async throws {
        switch group {
        case .health:
            try await requestHealthPermission()
        case .location:
            requestLocationPermission()
        case .motion:
            try await requestMotionPermission()
        case .screenTime:
            try await requestScreenTimePermission()
        case .none:
            break
        }
    }
    
    func requestHealthPermission() async throws {
        try await healthKit.requestAuthorization()
    }
    
    func requestLocationPermission() {
        location.requestAuthorization()
    }
    
    func requestMotionPermission() async throws {
        try await motion.requestAuthorization()
    }
    
    func requestScreenTimePermission() async throws {
        try await screenTime.requestAuthorization()
    }
    
    func requestNotificationPermission() async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        return try await center.requestAuthorization(options: [.alert, .badge, .sound])
    }
    
    // MARK: - Permission Flow
    
    /// Request all permissions for enabled signals in sequence
    func requestPermissionsForEnabledSignals() async -> [PermissionGroup: PermissionStatus] {
        let settings = UserSettings.shared
        var results: [PermissionGroup: PermissionStatus] = [:]
        
        // Determine which permission groups are needed
        var neededGroups = Set<PermissionGroup>()
        for signal in settings.enabledSignals {
            if signal.permissionGroup != .none {
                neededGroups.insert(signal.permissionGroup)
            }
        }
        
        // Request each needed permission
        for group in neededGroups {
            do {
                try await requestPermission(for: group)
                
                // Check status after requesting
                switch group {
                case .health:
                    results[group] = getHealthPermissionStatus()
                case .location:
                    // Location permission is async via delegate, so we just mark as requested
                    results[group] = getLocationPermissionStatus()
                case .motion:
                    results[group] = getMotionPermissionStatus()
                case .screenTime:
                    results[group] = getScreenTimePermissionStatus()
                case .none:
                    break
                }
            } catch {
                print("Failed to request \(group) permission: \(error)")
                results[group] = .denied
            }
        }
        
        // Always request notifications
        do {
            let granted = try await requestNotificationPermission()
            results[.none] = granted ? .authorized : .denied
        } catch {
            print("Failed to request notification permission: \(error)")
        }
        
        return results
    }
    
    // MARK: - Settings Deep Link
    
    /// Open the app's settings page
    func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Private
    
    private override init() {
        super.init()
    }
}

// MARK: - Permission Status

enum PermissionStatus: String {
    case notDetermined  // User hasn't made a choice yet
    case authorized     // Full access granted
    case limited        // Partial access (e.g., "When In Use" for location)
    case denied         // User explicitly denied
    case unavailable    // Not available on this device
    
    var isGranted: Bool {
        self == .authorized || self == .limited
    }
    
    var displayName: String {
        switch self {
        case .notDetermined: return "Not Set"
        case .authorized: return "Allowed"
        case .limited: return "Limited"
        case .denied: return "Denied"
        case .unavailable: return "Unavailable"
        }
    }
    
    var icon: String {
        switch self {
        case .notDetermined: return "questionmark.circle"
        case .authorized: return "checkmark.circle.fill"
        case .limited: return "checkmark.circle"
        case .denied: return "xmark.circle.fill"
        case .unavailable: return "nosign"
        }
    }
    
    var color: String {
        switch self {
        case .notDetermined: return "gray"
        case .authorized: return "green"
        case .limited: return "yellow"
        case .denied: return "red"
        case .unavailable: return "gray"
        }
    }
}

// MARK: - Permission Info

/// Information about a permission for display in onboarding
struct PermissionInfo {
    let group: PermissionGroup
    let title: String
    let description: String
    let icon: String
    
    static let health = PermissionInfo(
        group: .health,
        title: "Health Data",
        description: "So we can notice patterns in how you move and rest",
        icon: "heart.fill"
    )
    
    static let location = PermissionInfo(
        group: .location,
        title: "Location",
        description: "So we can see if leaving the house changes your day",
        icon: "location.fill"
    )
    
    static let motion = PermissionInfo(
        group: .motion,
        title: "Motion & Fitness",
        description: "So we can understand your activity patterns",
        icon: "figure.walk"
    )
    
    static let screenTime = PermissionInfo(
        group: .screenTime,
        title: "Screen Time",
        description: "So we can spot when scrolling sneaks up on you",
        icon: "iphone"
    )
    
    static let notifications = PermissionInfo(
        group: .none,
        title: "Notifications",
        description: "So we can share insights when they're ready",
        icon: "bell.fill"
    )
    
    static let all: [PermissionInfo] = [health, location, motion, screenTime, notifications]
    
    static func forGroup(_ group: PermissionGroup) -> PermissionInfo? {
        all.first { $0.group == group }
    }
}
