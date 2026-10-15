//
//  PermissionMonitor.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import Foundation
import HealthKit
import CoreLocation
import CoreMotion
import UserNotifications

/// Monitors permission states and handles revocation
@MainActor
@Observable
final class PermissionMonitor {
    // MARK: - Singleton
    
    static let shared = PermissionMonitor()
    
    // MARK: - Permission States
    
    var healthKitAuthorized: Bool = false
    var locationAuthorized: Bool = false
    var motionAuthorized: Bool = false
    var notificationsAuthorized: Bool = false
    
    // MARK: - Revocation Alerts
    
    var showingPermissionAlert: Bool = false
    var permissionAlertType: PermissionType?
    var revokedPermissions: Set<PermissionType> = []
    
    // MARK: - Private
    
    private let healthStore = HKHealthStore()
    private let locationManager = CLLocationManager()
    private let motionManager = CMMotionActivityManager()
    
    private init() {
        // Initial check
        Task {
            await refreshAllPermissions()
        }
    }
    
    // MARK: - Permission Checks
    
    /// Refresh all permission states
    func refreshAllPermissions() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.checkHealthKitPermission() }
            group.addTask { await self.checkLocationPermission() }
            group.addTask { await self.checkMotionPermission() }
            group.addTask { await self.checkNotificationPermission() }
        }
        
        checkForRevocations()
    }
    
    /// Check HealthKit permission
    func checkHealthKitPermission() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            healthKitAuthorized = false
            return
        }
        
        // Check authorization for a key type
        let stepType = HKQuantityType(.stepCount)
        let status = healthStore.authorizationStatus(for: stepType)
        healthKitAuthorized = status == .sharingAuthorized
    }
    
    /// Check location permission
    func checkLocationPermission() async {
        let status = locationManager.authorizationStatus
        locationAuthorized = status == .authorizedAlways || status == .authorizedWhenInUse
    }
    
    /// Check motion permission
    func checkMotionPermission() async {
        let status = CMMotionActivityManager.authorizationStatus()
        motionAuthorized = status == .authorized
    }
    
    /// Check notification permission
    func checkNotificationPermission() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationsAuthorized = settings.authorizationStatus == .authorized
    }
    
    // MARK: - Revocation Handling
    
    /// Check for permission revocations against enabled signals
    private func checkForRevocations() {
        let settings = UserSettings.shared
        var revoked: Set<PermissionType> = []
        
        // Check health-related signals
        let healthSignals: Set<SignalType> = [.steps, .sleep, .exercise, .heartRate, .hrv]
        if !healthSignals.isDisjoint(with: settings.enabledSignals) && !healthKitAuthorized {
            revoked.insert(.health)
        }
        
        // Check location signals
        let locationSignals: Set<SignalType> = [.location, .distance, .places]
        if !locationSignals.isDisjoint(with: settings.enabledSignals) && !locationAuthorized {
            revoked.insert(.location)
        }
        
        // Check motion signals
        if settings.enabledSignals.contains(.motion) && !motionAuthorized {
            revoked.insert(.motion)
        }
        
        // Update state
        if !revoked.isEmpty && revoked != revokedPermissions {
            revokedPermissions = revoked
            showingPermissionAlert = true
            permissionAlertType = revoked.first
        }
    }
    
    /// Handle when user acknowledges revocation
    func acknowledgeRevocation() {
        showingPermissionAlert = false
        permissionAlertType = nil
    }
    
    /// Open system settings for the app
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    /// Disable signals that no longer have permission
    func disableRevokedSignals() {
        let settings = UserSettings.shared
        
        if revokedPermissions.contains(.health) {
            settings.enabledSignals.subtract([.steps, .sleep, .exercise, .heartRate, .hrv])
        }
        
        if revokedPermissions.contains(.location) {
            settings.enabledSignals.subtract([.location, .distance, .places])
        }
        
        if revokedPermissions.contains(.motion) {
            settings.enabledSignals.remove(.motion)
        }
        
        revokedPermissions.removeAll()
        acknowledgeRevocation()
    }
}

// MARK: - Permission Type

enum PermissionType: String, CaseIterable {
    case health
    case location
    case motion
    case notifications
    case screenTime
    
    var displayName: String {
        switch self {
        case .health: return "Health"
        case .location: return "Location"
        case .motion: return "Motion"
        case .notifications: return "Notifications"
        case .screenTime: return "Screen Time"
        }
    }
    
    var icon: String {
        switch self {
        case .health: return "heart.fill"
        case .location: return "location.fill"
        case .motion: return "figure.walk"
        case .notifications: return "bell.fill"
        case .screenTime: return "hourglass"
        }
    }
    
    var revocationMessage: String {
        switch self {
        case .health:
            return "Health access has been revoked. Some signals like steps, sleep, and heart rate won't be tracked until you re-enable access in Settings."
        case .location:
            return "Location access has been revoked. Location-based insights won't be available until you re-enable access in Settings."
        case .motion:
            return "Motion access has been revoked. Activity tracking won't work until you re-enable access in Settings."
        case .notifications:
            return "Notification access has been revoked. You won't receive insight notifications until you re-enable them in Settings."
        case .screenTime:
            return "Screen Time access has been revoked. Screen time tracking won't work until you re-enable it."
        }
    }
}

// MARK: - Permission Alert View

import SwiftUI

struct PermissionRevokedAlert: View {
    let permissionType: PermissionType
    let onOpenSettings: () -> Void
    let onDisableSignals: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Icon
            Image(systemName: permissionType.icon)
                .font(.system(size: 40))
                .foregroundStyle(.orange)
            
            // Title
            Text("\(permissionType.displayName) Access Revoked")
                .font(Typography.title)
                .foregroundStyle(ColorPalette.primaryText)
            
            // Message
            Text(permissionType.revocationMessage)
                .font(Typography.body)
                .foregroundStyle(ColorPalette.secondaryText)
                .multilineTextAlignment(.center)
            
            // Actions
            VStack(spacing: 12) {
                Button(action: onOpenSettings) {
                    Text("Open Settings")
                        .font(Typography.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(ColorPalette.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Button(action: onDisableSignals) {
                    Text("Disable Related Signals")
                        .font(Typography.body)
                        .foregroundStyle(ColorPalette.secondaryText)
                }
                
                Button(action: onDismiss) {
                    Text("Remind Me Later")
                        .font(Typography.caption)
                        .foregroundStyle(ColorPalette.tertiaryText)
                }
            }
        }
        .padding(24)
        .background(ColorPalette.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(32)
    }
}
