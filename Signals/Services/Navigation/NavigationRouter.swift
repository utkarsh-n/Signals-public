//
//  NavigationRouter.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import SwiftUI

/// Handles deep linking and navigation routing throughout the app
@MainActor
@Observable
final class NavigationRouter {
    // MARK: - Singleton
    
    static let shared = NavigationRouter()
    
    // MARK: - Navigation State
    
    var pendingDeepLink: DeepLink?
    var homeNavigationPath = NavigationPath()
    var insightsNavigationPath = NavigationPath()
    var timelineNavigationPath = NavigationPath()
    var reflectNavigationPath = NavigationPath()
    var settingsNavigationPath = NavigationPath()
    
    // MARK: - Sheet State
    
    var showingInsightDetail: Insight?
    var showingDayDetail: Date?
    var showingReflectionEditor = false
    var showingWeeklyReport: WeeklyReport?
    
    private init() {}
    
    // MARK: - Deep Link Handling
    
    /// Process a deep link URL
    func handleDeepLink(_ url: URL) -> Bool {
        guard let deepLink = DeepLink(url: url) else {
            return false
        }
        
        pendingDeepLink = deepLink
        return true
    }
    
    /// Process a pending deep link with the app state
    func processPendingDeepLink(with appState: AppState) {
        guard let deepLink = pendingDeepLink else { return }
        pendingDeepLink = nil
        
        switch deepLink {
        case .home:
            appState.selectedTab = .home
            resetNavigationPath(for: .home)
            
        case .insights:
            appState.selectedTab = .insights
            resetNavigationPath(for: .insights)
            
        case .insight:
            appState.selectedTab = .insights
            // The insight detail will be shown when the view loads
            
        case .weeklyReport:
            appState.selectedTab = .insights
            // Weekly report will be shown when the view loads
            
        case .timeline:
            appState.selectedTab = .timeline
            resetNavigationPath(for: .timeline)
            
        case .day(let date):
            appState.selectedTab = .timeline
            showingDayDetail = date
            
        case .reflect:
            appState.selectedTab = .reflect
            resetNavigationPath(for: .reflect)
            
        case .newReflection:
            appState.selectedTab = .reflect
            showingReflectionEditor = true
            
        case .settings:
            appState.selectedTab = .settings
            resetNavigationPath(for: .settings)
            
        case .subscription:
            appState.showingPaywall = true
        }
    }
    
    /// Reset navigation path for a tab
    func resetNavigationPath(for tab: Tab) {
        switch tab {
        case .home:
            homeNavigationPath = NavigationPath()
        case .insights:
            insightsNavigationPath = NavigationPath()
        case .timeline:
            timelineNavigationPath = NavigationPath()
        case .reflect:
            reflectNavigationPath = NavigationPath()
        case .settings:
            settingsNavigationPath = NavigationPath()
        }
    }
    
    /// Reset all navigation paths
    func resetAllPaths() {
        homeNavigationPath = NavigationPath()
        insightsNavigationPath = NavigationPath()
        timelineNavigationPath = NavigationPath()
        reflectNavigationPath = NavigationPath()
        settingsNavigationPath = NavigationPath()
    }
}

// MARK: - Deep Link Types

/// Supported deep link destinations
enum DeepLink: Equatable {
    case home
    case insights
    case insight(id: UUID)
    case weeklyReport(id: UUID)
    case timeline
    case day(date: Date)
    case reflect
    case newReflection
    case settings
    case subscription
    
    /// Initialize from a URL
    init?(url: URL) {
        guard url.scheme == "signals" else { return nil }
        
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        
        switch url.host {
        case "home":
            self = .home
            
        case "insights":
            if let idString = pathComponents.first, let id = UUID(uuidString: idString) {
                self = .insight(id: id)
            } else {
                self = .insights
            }
            
        case "weekly-report":
            if let idString = pathComponents.first, let id = UUID(uuidString: idString) {
                self = .weeklyReport(id: id)
            } else {
                return nil
            }
            
        case "timeline":
            if let dateString = pathComponents.first,
               let date = ISO8601DateFormatter().date(from: dateString) {
                self = .day(date: date)
            } else {
                self = .timeline
            }
            
        case "reflect":
            if pathComponents.first == "new" {
                self = .newReflection
            } else {
                self = .reflect
            }
            
        case "settings":
            self = .settings
            
        case "subscription":
            self = .subscription
            
        default:
            return nil
        }
    }
    
    /// Generate URL for this deep link
    var url: URL {
        var components = URLComponents()
        components.scheme = "signals"
        
        switch self {
        case .home:
            components.host = "home"
            
        case .insights:
            components.host = "insights"
            
        case .insight(let id):
            components.host = "insights"
            components.path = "/\(id.uuidString)"
            
        case .weeklyReport(let id):
            components.host = "weekly-report"
            components.path = "/\(id.uuidString)"
            
        case .timeline:
            components.host = "timeline"
            
        case .day(let date):
            components.host = "timeline"
            components.path = "/\(ISO8601DateFormatter().string(from: date))"
            
        case .reflect:
            components.host = "reflect"
            
        case .newReflection:
            components.host = "reflect"
            components.path = "/new"
            
        case .settings:
            components.host = "settings"
            
        case .subscription:
            components.host = "subscription"
        }
        
        return components.url!
    }
}

// MARK: - Notification Deep Links

extension NavigationRouter {
    /// Handle notification tap with userInfo
    func handleNotification(userInfo: [AnyHashable: Any]) {
        guard let typeString = userInfo["type"] as? String else { return }
        
        switch typeString {
        case "weekly_report":
            if let idString = userInfo["reportId"] as? String,
               let id = UUID(uuidString: idString) {
                pendingDeepLink = .weeklyReport(id: id)
            } else {
                pendingDeepLink = .insights
            }
            
        case "insight":
            if let idString = userInfo["insightId"] as? String,
               let id = UUID(uuidString: idString) {
                pendingDeepLink = .insight(id: id)
            } else {
                pendingDeepLink = .insights
            }
            
        case "reflection_reminder":
            pendingDeepLink = .newReflection
            
        case "trial_ending", "trial_ended":
            pendingDeepLink = .subscription
            
        case "milestone":
            pendingDeepLink = .insights
            
        default:
            pendingDeepLink = .home
        }
    }
}
