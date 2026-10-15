//
//  NewDeviceHandler.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import Foundation
import SwiftData

/// Handles new device/fresh install scenarios
@MainActor
final class NewDeviceHandler {
    // MARK: - Singleton
    
    static let shared = NewDeviceHandler()
    
    private init() {}
    
    // MARK: - Device State Detection
    
    /// Check if this is a fresh install with no data
    func isFreshInstall(context: ModelContext) -> Bool {
        // Check if there are any snapshots
        let snapshotCount = (try? context.fetchCount(FetchDescriptor<DailySnapshot>())) ?? 0
        
        // Check if onboarding has been completed
        let hasCompletedOnboarding = UserSettings.shared.hasCompletedOnboarding
        
        return snapshotCount == 0 && !hasCompletedOnboarding
    }
    
    /// Check if this is a new device with iCloud data potentially available
    func isNewDeviceWithPotentialData(context: ModelContext) -> Bool {
        // Has completed onboarding but no local data
        let snapshotCount = (try? context.fetchCount(FetchDescriptor<DailySnapshot>())) ?? 0
        let hasCompletedOnboarding = UserSettings.shared.hasCompletedOnboarding
        
        return snapshotCount == 0 && hasCompletedOnboarding
    }
    
    /// Check if app is in "early days" mode (< 7 days of data)
    func isInEarlyDays(context: ModelContext) -> Bool {
        guard let firstLaunch = UserSettings.shared.firstLaunchDate else {
            return true
        }
        
        let daysSinceFirstLaunch = Calendar.current.dateComponents(
            [.day],
            from: firstLaunch,
            to: Date()
        ).day ?? 0
        
        return daysSinceFirstLaunch < 7
    }
    
    /// Get the current app phase for a user
    func getAppPhase(context: ModelContext) -> AppPhase {
        if isFreshInstall(context: context) {
            return .freshInstall
        }
        
        if isNewDeviceWithPotentialData(context: context) {
            return .newDevice
        }
        
        let snapshotCount = (try? context.fetchCount(FetchDescriptor<DailySnapshot>())) ?? 0
        
        if snapshotCount == 0 {
            return .noData
        }
        
        if snapshotCount < 7 {
            return .collecting(days: snapshotCount)
        }
        
        if snapshotCount < 14 {
            return .earlyInsights
        }
        
        return .active
    }
    
    // MARK: - Fresh Install Setup
    
    /// Perform initial setup for a fresh install
    func setupFreshInstall() {
        // Record first launch date if not set
        if UserSettings.shared.firstLaunchDate == nil {
            UserSettings.shared.firstLaunchDate = Date()
        }
        
        // Initialize default enabled signals
        if UserSettings.shared.enabledSignals.isEmpty {
            // Don't pre-select any signals - let user choose in onboarding
        }
        
        // Set default notification preferences
        UserSettings.shared.notificationsEnabled = true
        UserSettings.shared.weeklyReportNotificationsEnabled = true
        UserSettings.shared.insightNotificationsEnabled = true
    }
    
    // MARK: - Messaging
    
    /// Get appropriate empty state message based on app phase
    func getEmptyStateConfig(for screen: AppScreen, phase: AppPhase) -> EmptyStateConfig {
        switch (screen, phase) {
        case (.home, .freshInstall):
            return EmptyStateConfig(
                icon: "waveform.circle",
                title: "Welcome to Signals",
                message: "Complete the setup to start tracking your patterns.",
                actionTitle: "Get Started",
                actionType: .startOnboarding
            )
            
        case (.home, .noData), (.home, .newDevice):
            return EmptyStateConfig(
                icon: "antenna.radiowaves.left.and.right",
                title: "Signals is listening",
                message: "We're collecting your first day of data. Check back tomorrow to see your activity.",
                actionTitle: nil,
                actionType: nil
            )
            
        case (.home, .collecting(let days)):
            let remaining = 7 - days
            return EmptyStateConfig(
                icon: "chart.line.uptrend.xyaxis",
                title: "Building your baseline",
                message: "We need \(remaining) more day\(remaining == 1 ? "" : "s") of data before we can generate your first insights.",
                actionTitle: nil,
                actionType: nil
            )
            
        case (.insights, .collecting(let days)):
            let remaining = 7 - days
            return EmptyStateConfig(
                icon: "sparkles",
                title: "Insights coming soon",
                message: "\(remaining) more day\(remaining == 1 ? "" : "s") until your first weekly insights arrive.",
                actionTitle: nil,
                actionType: nil
            )
            
        case (.insights, _):
            return EmptyStateConfig(
                icon: "sparkles",
                title: "Your insights will appear here",
                message: "Signals analyzes your patterns and generates personalized insights every week.",
                actionTitle: nil,
                actionType: nil
            )
            
        case (.timeline, .noData), (.timeline, .newDevice):
            return EmptyStateConfig(
                icon: "calendar",
                title: "Your timeline is empty",
                message: "As you use the app, your daily snapshots will appear here.",
                actionTitle: nil,
                actionType: nil
            )
            
        case (.timeline, _):
            return EmptyStateConfig(
                icon: "calendar",
                title: "Your timeline will appear here",
                message: "Track your days and watch your personal history unfold.",
                actionTitle: nil,
                actionType: nil
            )
            
        case (.reflect, _):
            return EmptyStateConfig(
                icon: "text.quote",
                title: "No reflections yet",
                message: "Start writing reflections to capture your thoughts and see patterns emerge.",
                actionTitle: "Write a Reflection",
                actionType: .startReflection
            )
            
        default:
            return EmptyStateConfig(
                icon: "questionmark.circle",
                title: "No data available",
                message: "Check back later.",
                actionTitle: nil,
                actionType: nil
            )
        }
    }
}

// MARK: - Supporting Types

/// Current phase of app usage
enum AppPhase: Equatable {
    case freshInstall
    case newDevice
    case noData
    case collecting(days: Int)
    case earlyInsights
    case active
    
    var description: String {
        switch self {
        case .freshInstall: return "Fresh install"
        case .newDevice: return "New device"
        case .noData: return "No data yet"
        case .collecting(let days): return "Collecting data (Day \(days))"
        case .earlyInsights: return "Early insights"
        case .active: return "Active"
        }
    }
}

/// App screens for empty state configuration
enum AppScreen {
    case home
    case insights
    case timeline
    case reflect
    case settings
}

/// Configuration for empty states
struct EmptyStateConfig {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let actionType: EmptyStateAction?
}

/// Actions that can be taken from empty states
enum EmptyStateAction {
    case startOnboarding
    case startReflection
    case openSettings
    case none
}

// MARK: - View Extension

import SwiftUI

extension View {
    /// Shows appropriate empty state based on app phase
    @ViewBuilder
    func emptyState(
        when isEmpty: Bool,
        screen: AppScreen,
        phase: AppPhase,
        action: ((EmptyStateAction) -> Void)? = nil
    ) -> some View {
        if isEmpty {
            let config = NewDeviceHandler.shared.getEmptyStateConfig(for: screen, phase: phase)
            
            EmptyStateView(
                icon: config.icon,
                title: config.title,
                message: config.message,
                actionTitle: config.actionTitle,
                action: config.actionType.map { actionType in
                    { action?(actionType) }
                }
            )
        } else {
            self
        }
    }
}
