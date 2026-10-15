//
//  PaywallManager.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import Foundation
import StoreKit

/// Manages subscription state, trial tracking, and access entitlements
@MainActor
@Observable
final class PaywallManager {
    // MARK: - Singleton
    
    static let shared = PaywallManager()
    
    // MARK: - State
    
    private(set) var subscriptionState: SubscriptionState = .unknown
    private(set) var trialStartDate: Date?
    private(set) var subscriptionExpirationDate: Date?
    private(set) var isInGracePeriod: Bool = false
    
    // MARK: - Computed Properties
    
    /// Whether user has full access to all features
    var hasFullAccess: Bool {
        switch subscriptionState {
        case .subscribed, .inTrial:
            return true
        case .gracePeriod:
            return true
        case .expired, .none, .unknown:
            return false
        }
    }
    
    /// Whether user is currently in trial
    var isInTrial: Bool {
        subscriptionState == .inTrial
    }
    
    /// Whether user is subscribed (paid)
    var isSubscribed: Bool {
        subscriptionState == .subscribed
    }
    
    /// Days remaining in trial (nil if not in trial)
    var trialDaysRemaining: Int? {
        guard isInTrial, let startDate = trialStartDate else { return nil }
        
        let trialEndDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate) ?? startDate
        let days = Calendar.current.dateComponents([.day], from: Date(), to: trialEndDate).day ?? 0
        return max(0, days)
    }
    
    /// Trial end date (nil if not in trial)
    var trialEndDate: Date? {
        guard let startDate = trialStartDate else { return nil }
        return Calendar.current.date(byAdding: .day, value: 7, to: startDate)
    }
    
    // MARK: - Initialization
    
    private init() {
        // Load cached state from UserSettings
        loadCachedState()
        
        // Refresh from StoreKit
        Task {
            await refreshSubscriptionStatus()
        }
    }
    
    // MARK: - State Management
    
    /// Update entitlement status from StoreKit
    func updateEntitlementStatus(purchasedIDs: Set<String>) {
        if purchasedIDs.isEmpty {
            // Check if user was in trial
            if let trialStart = UserSettings.shared.trialStartDate {
                let trialEnd = Calendar.current.date(byAdding: .day, value: 7, to: trialStart) ?? trialStart
                
                if Date() < trialEnd {
                    subscriptionState = .inTrial
                    trialStartDate = trialStart
                } else {
                    subscriptionState = .expired
                }
            } else {
                subscriptionState = .none
            }
        } else {
            subscriptionState = .subscribed
            trialStartDate = nil
            
            // Cancel trial notifications since user subscribed
            Task {
                NotificationService.shared.cancelTrialNotifications()
            }
        }
        
        // Sync with UserSettings
        syncToUserSettings()
    }
    
    /// Refresh subscription status from StoreKit
    func refreshSubscriptionStatus() async {
        await StoreKitService.shared.updatePurchasedProducts()
        
        // Get expiration date
        subscriptionExpirationDate = await StoreKitService.shared.getExpirationDate()
        
        // Check for grace period
        if let renewalInfo = await StoreKitService.shared.getRenewalInfo() {
            isInGracePeriod = renewalInfo.gracePeriodExpirationDate != nil
            
            if isInGracePeriod {
                subscriptionState = .gracePeriod
            }
        }
    }
    
    /// Start a free trial
    func startTrial() {
        guard subscriptionState == .none || subscriptionState == .unknown else { return }
        
        let now = Date()
        trialStartDate = now
        subscriptionState = .inTrial
        
        // Save to UserSettings
        UserSettings.shared.trialStartDate = now
        UserSettings.shared.subscriptionStatus = .trial
        
        // Schedule trial notifications
        Task {
            await NotificationService.shared.scheduleTrialNotifications(trialStartDate: now)
        }
        
        Haptics.trialStarted()
    }
    
    /// Check if trial has expired
    func checkTrialExpiration() {
        guard subscriptionState == .inTrial,
              let endDate = trialEndDate else { return }
        
        if Date() >= endDate {
            subscriptionState = .expired
            UserSettings.shared.subscriptionStatus = .expired
        }
    }
    
    // MARK: - Feature Gating
    
    /// Check if a feature is accessible
    func canAccess(_ feature: PremiumFeature) -> Bool {
        if hasFullAccess {
            return true
        }
        
        // Some features are always available to free users
        switch feature {
        case .viewRecentInsights:
            return true // Free users can see 3 most recent
        case .writeReflections:
            return true // Free users can write reflections
        case .viewRecentTimeline:
            return true // Free users can see 2 weeks
        case .todayView:
            return true // Always available
        default:
            return false
        }
    }
    
    /// Get the limit for a feature (for partial access)
    func featureLimit(for feature: PremiumFeature) -> Int? {
        guard !hasFullAccess else { return nil }
        
        switch feature {
        case .viewRecentInsights:
            return 3 // Free users see only 3 insights
        case .viewRecentTimeline:
            return 14 // Free users see 14 days
        case .viewReflectionHistory:
            return 10 // Free users see 10 reflections
        default:
            return nil
        }
    }
    
    // MARK: - Private Methods
    
    private func loadCachedState() {
        let status = UserSettings.shared.subscriptionStatus
        
        switch status {
        case .subscribed:
            subscriptionState = .subscribed
        case .trial:
            subscriptionState = .inTrial
            trialStartDate = UserSettings.shared.trialStartDate
            checkTrialExpiration()
        case .expired:
            subscriptionState = .expired
        case .gracePeriod:
            subscriptionState = .gracePeriod
        case .none:
            subscriptionState = .none
        }
    }
    
    private func syncToUserSettings() {
        switch subscriptionState {
        case .subscribed:
            UserSettings.shared.subscriptionStatus = .subscribed
        case .inTrial:
            UserSettings.shared.subscriptionStatus = .trial
        case .expired:
            UserSettings.shared.subscriptionStatus = .expired
        case .gracePeriod:
            UserSettings.shared.subscriptionStatus = .gracePeriod
        case .none, .unknown:
            UserSettings.shared.subscriptionStatus = .none
        }
    }
}

// MARK: - Subscription State

enum SubscriptionState: Equatable {
    case unknown
    case none
    case inTrial
    case subscribed
    case gracePeriod
    case expired
}

// MARK: - Premium Features

enum PremiumFeature {
    // Insights
    case viewRecentInsights      // Free: 3 most recent
    case viewFullInsightHistory  // Premium only
    case viewWeeklyReports       // Premium only
    
    // Timeline
    case viewRecentTimeline      // Free: 2 weeks
    case viewFullTimeline        // Premium only
    case viewHeatmap             // Premium only
    
    // Reflect
    case writeReflections        // Always free
    case viewReflectionHistory   // Free: limited
    case viewReflectionPrompts   // Premium only
    
    // Settings
    case exportData              // Premium only
    
    // Home
    case todayView               // Always free
}
