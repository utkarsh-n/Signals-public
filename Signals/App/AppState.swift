//
//  AppState.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import SwiftUI
import SwiftData

/// Global observable app state
@MainActor
@Observable
final class AppState {
    // MARK: - Navigation
    
    var selectedTab: Tab = .home
    var showingOnboarding: Bool = false
    var showingPaywall: Bool = false
    
    // MARK: - UI State
    
    var isLoading: Bool = false
    var toastMessage: String?
    var showToast: Bool = false
    var isAppActive: Bool = true
    
    // MARK: - Data State
    
    var todaySnapshot: DailySnapshot?
    var latestInsight: Insight?
    var unreadInsightCount: Int = 0
    
    // MARK: - Services State
    
    var isCollectingData: Bool = false
    var lastSyncDate: Date?
    var daysOfData: Double = 0
    
    // MARK: - Initialization
    
    init() {
        // Check if onboarding should be shown
        showingOnboarding = !UserSettings.shared.hasCompletedOnboarding
        
        // Set up lifecycle observers
        setupLifecycleObservers()
    }
    
    // MARK: - Lifecycle
    
    private func setupLifecycleObservers() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor [weak self] in
                self?.handleAppWillResignActive()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor [weak self] in
                self?.handleAppDidBecomeActive()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor [weak self] in
                self?.handleAppDidEnterBackground()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor [weak self] in
                self?.handleAppWillEnterForeground()
            }
        }
    }
    
    private func handleAppWillResignActive() {
        isAppActive = false
    }
    
    private func handleAppDidBecomeActive() {
        isAppActive = true
        
        // Process any pending deep links
        NavigationRouter.shared.processPendingDeepLink(with: self)
    }
    
    private func handleAppDidEnterBackground() {
        // Save any pending data
        UserSettings.shared.lastBackgroundDate = Date()
    }
    
    private func handleAppWillEnterForeground() {
        // Check if we need to refresh data (e.g., day changed)
        checkForDayChange()
    }
    
    private func checkForDayChange() {
        if let lastBackground = UserSettings.shared.lastBackgroundDate {
            let lastDay = Calendar.current.startOfDay(for: lastBackground)
            let today = Calendar.current.startOfDay(for: Date())
            
            if lastDay != today {
                // Day has changed, need to refresh
                todaySnapshot = nil
                // Data will be refreshed when view appears
            }
        }
    }
    
    // MARK: - Methods
    
    func showToast(_ message: String) {
        toastMessage = message
        showToast = true
        
        // Auto-dismiss after 3 seconds
        Task {
            try? await Task.sleep(for: .seconds(3))
            showToast = false
        }
    }
    
    func completeOnboarding() {
        UserSettings.shared.hasCompletedOnboarding = true
        showingOnboarding = false
    }
    
    func refreshTodayData(from context: ModelContext) {
        let today = Calendar.current.startOfDay(for: Date())
        
        let snapshotDescriptor = FetchDescriptor<DailySnapshot>(
            predicate: #Predicate { $0.date == today }
        )
        
        if let snapshots = try? context.fetch(snapshotDescriptor) {
            todaySnapshot = snapshots.first
        }
        
        // Fetch latest unread insight
        var insightDescriptor = FetchDescriptor<Insight>(
            predicate: #Predicate { !$0.isRead },
            sortBy: [SortDescriptor(\.generatedDate, order: .reverse)]
        )
        insightDescriptor.fetchLimit = 1
        
        if let insights = try? context.fetch(insightDescriptor) {
            latestInsight = insights.first
        }
        
        // Count unread insights
        let countDescriptor = FetchDescriptor<Insight>(
            predicate: #Predicate { !$0.isRead }
        )
        unreadInsightCount = (try? context.fetchCount(countDescriptor)) ?? 0
        
        // Calculate days of data
        calculateDaysOfData(from: context)
    }
    
    private func calculateDaysOfData(from context: ModelContext) {
        var descriptor = FetchDescriptor<DailySnapshot>(
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        descriptor.fetchLimit = 1
        
        if let snapshots = try? context.fetch(descriptor),
           let firstSnapshot = snapshots.first {
            let days = Calendar.current.dateComponents(
                [.day],
                from: firstSnapshot.date,
                to: Date()
            ).day ?? 0
            daysOfData = Double(max(days, 0))
        }
    }
}

// MARK: - Tab Enum

enum Tab: String, CaseIterable, Identifiable {
    case home
    case insights
    case timeline
    case reflect
    case settings
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .home: return "Home"
        case .insights: return "Insights"
        case .timeline: return "Timeline"
        case .reflect: return "Reflect"
        case .settings: return "Settings"
        }
    }
    
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .insights: return "lightbulb.fill"
        case .timeline: return "calendar"
        case .reflect: return "pencil.and.outline"
        case .settings: return "gearshape.fill"
        }
    }
}
