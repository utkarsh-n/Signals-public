//
//  NotificationSettingsView.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import SwiftUI

/// Settings view for configuring notifications
struct NotificationSettingsView: View {
    @State private var insightNotifications = UserSettings.shared.insightNotificationsEnabled
    @State private var reflectionReminders = UserSettings.shared.reflectionRemindersEnabled
    @State private var weeklyReportNotifications = UserSettings.shared.weeklyReportNotificationsEnabled
    
    @State private var insightDeliveryTime = UserSettings.shared.insightDeliveryTime
    @State private var reflectionReminderTime = UserSettings.shared.reflectionReminderTime
    @State private var weeklyReportDay = UserSettings.shared.weeklyReportDay
    
    @State private var showingPermissionAlert = false
    
    var body: some View {
        List {
            // Insight notifications
            Section {
                Toggle("Weekly Insights", isOn: $insightNotifications)
                    .tint(ColorPalette.accent)
                    .onChange(of: insightNotifications) { _, newValue in
                        UserSettings.shared.insightNotificationsEnabled = newValue
                        Haptics.toggleChanged()
                    }
                
                if insightNotifications {
                    DatePicker(
                        "Delivery Time",
                        selection: $insightDeliveryTime,
                        displayedComponents: .hourAndMinute
                    )
                    .onChange(of: insightDeliveryTime) { _, newValue in
                        UserSettings.shared.insightDeliveryTime = newValue
                    }
                }
            } header: {
                Text("Insights")
            } footer: {
                Text("Get notified when new insights are ready")
            }
            
            // Reflection reminders
            Section {
                Toggle("Daily Reminders", isOn: $reflectionReminders)
                    .tint(ColorPalette.accent)
                    .onChange(of: reflectionReminders) { _, newValue in
                        UserSettings.shared.reflectionRemindersEnabled = newValue
                        Haptics.toggleChanged()
                    }
                
                if reflectionReminders {
                    DatePicker(
                        "Reminder Time",
                        selection: $reflectionReminderTime,
                        displayedComponents: .hourAndMinute
                    )
                    .onChange(of: reflectionReminderTime) { _, newValue in
                        UserSettings.shared.reflectionReminderTime = newValue
                    }
                }
            } header: {
                Text("Reflection Reminders")
            } footer: {
                Text("A gentle nudge to write a daily reflection")
            }
            
            // Weekly report
            Section {
                Toggle("Weekly Report", isOn: $weeklyReportNotifications)
                    .tint(ColorPalette.accent)
                    .onChange(of: weeklyReportNotifications) { _, newValue in
                        UserSettings.shared.weeklyReportNotificationsEnabled = newValue
                        Haptics.toggleChanged()
                    }
                
                if weeklyReportNotifications {
                    Picker("Report Day", selection: $weeklyReportDay) {
                        ForEach(Weekday.allCases) { day in
                            Text(day.displayName).tag(day)
                        }
                    }
                    .onChange(of: weeklyReportDay) { _, newValue in
                        UserSettings.shared.weeklyReportDay = newValue
                    }
                }
            } header: {
                Text("Weekly Report")
            } footer: {
                Text("Get your weekly summary delivered to you")
            }
            
            // Permission status
            Section {
                Button(action: requestNotificationPermission) {
                    HStack {
                        Text("Notification Permission")
                        Spacer()
                        Text(notificationPermissionStatus)
                            .foregroundStyle(ColorPalette.secondaryText)
                    }
                }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Notifications Disabled", isPresented: $showingPermissionAlert) {
            Button("Open Settings") {
                openSettings()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable notifications in Settings to receive reminders and updates.")
        }
    }
    
    private var notificationPermissionStatus: String {
        // In a real implementation, check actual permission status
        return "Enabled"
    }
    
    private func requestNotificationPermission() {
        // Request notification permission
        Haptics.light()
    }
    
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Weekday Enum

enum Weekday: Int, CaseIterable, Identifiable, Codable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
    
    var id: Int { rawValue }
    
    var displayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        let date = Calendar.current.date(from: DateComponents(weekday: rawValue))!
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
}
