//
//  UserSettings.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import Foundation
import SwiftUI

/// User preferences and settings stored in UserDefaults via AppStorage
final class UserSettings {
    static let shared = UserSettings()
    
    // MARK: - Onboarding
    
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false
    @AppStorage("onboardingStep") var onboardingStep = 0
    
    // MARK: - Enabled Signals
    
    @AppStorage("enabledSignals") private var enabledSignalsRaw: String = ""
    
    var enabledSignals: Set<SignalType> {
        get {
            let rawValues = enabledSignalsRaw.split(separator: ",").map(String.init)
            return Set(rawValues.compactMap { SignalType(rawValue: $0) })
        }
        set {
            enabledSignalsRaw = newValue.map { $0.rawValue }.joined(separator: ",")
        }
    }
    
    func isSignalEnabled(_ signal: SignalType) -> Bool {
        enabledSignals.contains(signal)
    }
    
    func toggleSignal(_ signal: SignalType) {
        if enabledSignals.contains(signal) {
            enabledSignals.remove(signal)
        } else {
            enabledSignals.insert(signal)
        }
    }
    
    // MARK: - Subscription
    
    @AppStorage("subscriptionStatus") var subscriptionStatusRaw: String = SubscriptionStatus.none.rawValue
    @AppStorage("trialStartDate") private var trialStartDateInterval: Double = 0
    @AppStorage("subscriptionExpirationDate") private var subscriptionExpirationInterval: Double = 0
    
    var subscriptionStatus: SubscriptionStatus {
        get { SubscriptionStatus(rawValue: subscriptionStatusRaw) ?? .none }
        set { subscriptionStatusRaw = newValue.rawValue }
    }
    
    var trialStartDate: Date? {
        get { trialStartDateInterval > 0 ? Date(timeIntervalSince1970: trialStartDateInterval) : nil }
        set { trialStartDateInterval = newValue?.timeIntervalSince1970 ?? 0 }
    }
    
    var subscriptionExpirationDate: Date? {
        get { subscriptionExpirationInterval > 0 ? Date(timeIntervalSince1970: subscriptionExpirationInterval) : nil }
        set { subscriptionExpirationInterval = newValue?.timeIntervalSince1970 ?? 0 }
    }
    
    var isSubscribed: Bool {
        subscriptionStatus == .subscribed
    }
    
    var isInTrial: Bool {
        guard subscriptionStatus == .trial,
              let startDate = trialStartDate else { return false }
        let trialEndDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate) ?? startDate
        return Date() < trialEndDate
    }
    
    var trialDaysRemaining: Int? {
        guard isInTrial, let startDate = trialStartDate else { return nil }
        let trialEndDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate) ?? startDate
        return Calendar.current.dateComponents([.day], from: Date(), to: trialEndDate).day
    }
    
    var trialEndDate: Date? {
        guard let startDate = trialStartDate else { return nil }
        return Calendar.current.date(byAdding: .day, value: 7, to: startDate)
    }
    
    var hasFullAccess: Bool {
        isSubscribed || isInTrial
    }
    
    // MARK: - Notifications
    
    @AppStorage("notificationsEnabled") var notificationsEnabled = true
    @AppStorage("insightNotificationsEnabled") var insightNotificationsEnabled = true
    @AppStorage("weeklyReportNotificationsEnabled") var weeklyReportNotificationsEnabled = true
    @AppStorage("reflectionRemindersEnabled") var reflectionRemindersEnabled = false
    @AppStorage("reflectionReminderHour") var reflectionReminderHour = 21  // 9 PM
    @AppStorage("reflectionReminderMinute") var reflectionReminderMinute = 0
    @AppStorage("insightDeliveryHour") var insightDeliveryHour = 9  // 9 AM
    @AppStorage("weeklyReportDayRaw") var weeklyReportDayRaw = 2  // Monday
    
    var insightDeliveryTime: Date {
        get {
            Calendar.current.date(from: DateComponents(hour: insightDeliveryHour, minute: 0)) ?? Date()
        }
        set {
            insightDeliveryHour = Calendar.current.component(.hour, from: newValue)
        }
    }
    
    var reflectionReminderTime: Date {
        get {
            Calendar.current.date(from: DateComponents(hour: reflectionReminderHour, minute: reflectionReminderMinute)) ?? Date()
        }
        set {
            reflectionReminderHour = Calendar.current.component(.hour, from: newValue)
            reflectionReminderMinute = Calendar.current.component(.minute, from: newValue)
        }
    }
    
    var weeklyReportDay: Weekday {
        get { Weekday(rawValue: weeklyReportDayRaw) ?? .monday }
        set { weeklyReportDayRaw = newValue.rawValue }
    }
    
    // MARK: - Appearance
    
    @AppStorage("appearanceMode") var appearanceModeRaw: String = AppearanceMode.system.rawValue
    @AppStorage("accentColorName") var accentColorName: String = "blue"
    
    var appearanceMode: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceModeRaw) ?? .system }
        set { appearanceModeRaw = newValue.rawValue }
    }
    
    var colorScheme: ColorScheme? {
        switch appearanceMode {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
    
    // Alias for settings view compatibility
    var theme: AppTheme {
        get {
            switch appearanceMode {
            case .system: return .system
            case .light: return .light
            case .dark: return .dark
            }
        }
        set {
            switch newValue {
            case .system: appearanceMode = .system
            case .light: appearanceMode = .light
            case .dark: appearanceMode = .dark
            }
        }
    }
    
    // MARK: - Privacy
    
    @AppStorage("dataRetentionMonths") var dataRetentionMonths = 12
    @AppStorage("lastDataCleanupDate") private var lastDataCleanupInterval: Double = 0
    
    var lastDataCleanupDate: Date? {
        get { lastDataCleanupInterval > 0 ? Date(timeIntervalSince1970: lastDataCleanupInterval) : nil }
        set { lastDataCleanupInterval = newValue?.timeIntervalSince1970 ?? 0 }
    }
    
    @AppStorage("lastSyncDate") private var lastSyncDateInterval: Double = 0
    
    var lastSyncDate: Date? {
        get { lastSyncDateInterval > 0 ? Date(timeIntervalSince1970: lastSyncDateInterval) : nil }
        set { lastSyncDateInterval = newValue?.timeIntervalSince1970 ?? 0 }
    }
    
    @AppStorage("lastBackgroundDate") private var lastBackgroundDateInterval: Double = 0
    
    var lastBackgroundDate: Date? {
        get { lastBackgroundDateInterval > 0 ? Date(timeIntervalSince1970: lastBackgroundDateInterval) : nil }
        set { lastBackgroundDateInterval = newValue?.timeIntervalSince1970 ?? 0 }
    }
    
    // MARK: - App State
    
    @AppStorage("firstLaunchDate") private var firstLaunchDateInterval: Double = 0
    @AppStorage("lastOpenedDate") private var lastOpenedDateInterval: Double = 0
    
    var firstLaunchDate: Date? {
        get { firstLaunchDateInterval > 0 ? Date(timeIntervalSince1970: firstLaunchDateInterval) : nil }
        set { firstLaunchDateInterval = newValue?.timeIntervalSince1970 ?? 0 }
    }
    
    var lastOpenedDate: Date? {
        get { lastOpenedDateInterval > 0 ? Date(timeIntervalSince1970: lastOpenedDateInterval) : nil }
        set { lastOpenedDateInterval = newValue?.timeIntervalSince1970 ?? 0 }
    }
    
    var daysSinceFirstLaunch: Int? {
        guard let firstLaunch = firstLaunchDate else { return nil }
        return Calendar.current.dateComponents([.day], from: firstLaunch, to: Date()).day
    }
    
    // MARK: - Initialization
    
    private init() {
        if firstLaunchDate == nil {
            firstLaunchDate = Date()
        }
    }
    
    func recordAppOpen() {
        lastOpenedDate = Date()
    }
}

// MARK: - Supporting Enums

enum SubscriptionStatus: String {
    case none
    case trial
    case subscribed
    case expired
    case gracePeriod
}

enum AppearanceMode: String, CaseIterable {
    case system
    case light
    case dark
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

enum ReflectionFrequency: String, CaseIterable {
    case daily
    case sometimes
    case never
    
    var displayName: String {
        switch self {
        case .daily: return "Yes, remind me daily"
        case .sometimes: return "Sometimes"
        case .never: return "Not for now"
        }
    }
}
