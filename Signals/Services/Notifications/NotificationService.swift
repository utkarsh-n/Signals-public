//
//  NotificationService.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import Foundation
import UserNotifications

/// Manages local notification scheduling and delivery
@MainActor
final class NotificationService {
    // MARK: - Singleton
    
    static let shared = NotificationService()
    
    private let center = UNUserNotificationCenter.current()
    
    private init() {}
    
    // MARK: - Permission Request
    
    /// Request notification permission
    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            return granted
        } catch {
            print("Notification permission request failed: \(error)")
            return false
        }
    }
    
    /// Check current permission status
    func checkPermissionStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }
    
    // MARK: - Weekly Report Notification
    
    /// Schedule notification for weekly report
    func scheduleWeeklyReportNotification(report: WeeklyReport) async {
        guard UserSettings.shared.weeklyReportNotificationsEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Your weekly insights are ready"
        
        // Use top insight as preview if available
        if let topInsight = report.topPattern {
            content.body = topInsight.title
        } else {
            content.body = "Discover patterns from your week."
        }
        
        content.sound = .default
        content.userInfo = [
            "type": "weekly_report",
            "reportId": report.id.uuidString
        ]
        
        // Schedule for Monday morning at user's preferred time
        var dateComponents = DateComponents()
        dateComponents.weekday = 2 // Monday
        dateComponents.hour = UserSettings.shared.insightDeliveryHour
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "weekly-report-\(report.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
        } catch {
            print("Failed to schedule weekly report notification: \(error)")
        }
    }
    
    // MARK: - Reflection Reminder
    
    /// Schedule daily reflection reminder
    func scheduleReflectionReminder() async {
        guard UserSettings.shared.reflectionRemindersEnabled else { return }
        
        // Cancel existing reflection reminders
        center.removePendingNotificationRequests(withIdentifiers: ["reflection-reminder"])
        
        let content = UNMutableNotificationContent()
        content.title = "Time to reflect"
        content.body = ReflectionReminderCopy.random()
        content.sound = .default
        content.userInfo = [
            "type": "reflection_reminder"
        ]
        
        // Schedule at user's preferred time
        var dateComponents = DateComponents()
        dateComponents.hour = UserSettings.shared.reflectionReminderHour
        dateComponents.minute = UserSettings.shared.reflectionReminderMinute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "reflection-reminder",
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
        } catch {
            print("Failed to schedule reflection reminder: \(error)")
        }
    }
    
    /// Cancel reflection reminders
    func cancelReflectionReminders() {
        center.removePendingNotificationRequests(withIdentifiers: ["reflection-reminder"])
    }
    
    // MARK: - Trial Notifications
    
    /// Schedule trial ending notifications
    func scheduleTrialNotifications(trialStartDate: Date) async {
        // Day 5 notification
        if let day5 = Calendar.current.date(byAdding: .day, value: 5, to: trialStartDate) {
            await scheduleTrialWarningNotification(for: day5, daysRemaining: 2)
        }
        
        // Day 7 notification (trial ended)
        if let day7 = Calendar.current.date(byAdding: .day, value: 7, to: trialStartDate) {
            await scheduleTrialEndedNotification(for: day7)
        }
    }
    
    private func scheduleTrialWarningNotification(for date: Date, daysRemaining: Int) async {
        let content = UNMutableNotificationContent()
        content.title = "Your free trial ends soon"
        content.body = "You have \(daysRemaining) days left. Subscribe to keep your insights flowing."
        content.sound = .default
        content.userInfo = [
            "type": "trial_ending"
        ]
        
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: date)
        dateComponents.hour = 10
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "trial-warning",
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
        } catch {
            print("Failed to schedule trial warning: \(error)")
        }
    }
    
    private func scheduleTrialEndedNotification(for date: Date) async {
        let content = UNMutableNotificationContent()
        content.title = "Your trial has ended"
        content.body = "Subscribe to Signals to continue discovering patterns — $3.99/month."
        content.sound = .default
        content.userInfo = [
            "type": "trial_ended"
        ]
        
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: date)
        dateComponents.hour = 10
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "trial-ended",
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
        } catch {
            print("Failed to schedule trial ended notification: \(error)")
        }
    }
    
    /// Cancel trial notifications (e.g., user subscribed)
    func cancelTrialNotifications() {
        center.removePendingNotificationRequests(withIdentifiers: ["trial-warning", "trial-ended"])
    }
    
    // MARK: - Milestone Notifications
    
    /// Schedule a milestone notification
    func scheduleMilestoneNotification(title: String, body: String) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = [
            "type": "milestone"
        ]
        
        // Deliver immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "milestone-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
        } catch {
            print("Failed to schedule milestone notification: \(error)")
        }
    }
    
    // MARK: - Insight Notification
    
    /// Schedule notification for a new insight
    func scheduleInsightNotification(insight: Insight) async {
        guard UserSettings.shared.insightNotificationsEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "New insight"
        content.body = insight.title
        content.sound = .default
        content.userInfo = [
            "type": "insight",
            "insightId": insight.id.uuidString
        ]
        
        // Deliver at user's preferred insight time
        var dateComponents = DateComponents()
        dateComponents.hour = UserSettings.shared.insightDeliveryHour
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "insight-\(insight.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
        } catch {
            print("Failed to schedule insight notification: \(error)")
        }
    }
    
    // MARK: - Cancel All
    
    /// Cancel all pending notifications
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }
    
    /// Update badge count
    func updateBadgeCount(_ count: Int) async {
        do {
            try await center.setBadgeCount(count)
        } catch {
            print("Failed to update badge count: \(error)")
        }
    }
}

// MARK: - Reflection Reminder Copy

enum ReflectionReminderCopy {
    static let variations: [String] = [
        "A quick thought before bed?",
        "How did today go?",
        "Anything worth remembering from today?",
        "What's one thing that stood out today?",
        "How are you feeling right now?",
        "What made you smile today?",
        "What challenged you today?",
        "One thought before the day ends?",
        "What would you tell yourself this morning?",
        "Any small wins today?",
        "What are you grateful for right now?",
        "How's your energy feeling?",
        "What surprised you today?",
        "Anything you'd do differently?",
        "What's on your mind tonight?",
        "How did today compare to yesterday?",
        "What drained you today?",
        "What energized you today?",
        "Any patterns you're noticing?",
        "What's one thing you learned today?",
        "How present were you today?",
        "What do you want to remember about today?",
        "Ready to reflect on your day?",
        "Take a moment to check in with yourself.",
        "Your future self might appreciate a note.",
        "A few words about today?",
        "What would make tomorrow better?",
        "How are you feeling about this week?",
        "Anything weighing on you?",
        "What brought you peace today?"
    ]
    
    static func random() -> String {
        variations.randomElement() ?? "How was your day?"
    }
}
