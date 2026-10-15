//
//  SettingsView.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import SwiftUI

/// Main settings view with all configuration options
struct SettingsView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        NavigationStack {
            List {
                // Data Sources
                Section {
                    NavigationLink(destination: DataSourcesSettingsView()) {
                        SettingsRow(
                            icon: "waveform.path.ecg",
                            iconColor: ColorPalette.accent,
                            title: "Data Sources",
                            subtitle: "Manage tracked signals"
                        )
                    }
                }
                
                // Notifications
                Section {
                    NavigationLink(destination: NotificationSettingsView()) {
                        SettingsRow(
                            icon: "bell.fill",
                            iconColor: .orange,
                            title: "Notifications",
                            subtitle: "Reminders & alerts"
                        )
                    }
                }
                
                // Appearance
                Section {
                    NavigationLink(destination: AppearanceSettingsView()) {
                        SettingsRow(
                            icon: "paintbrush.fill",
                            iconColor: .purple,
                            title: "Appearance",
                            subtitle: "Theme & colors"
                        )
                    }
                }
                
                // Privacy
                Section {
                    NavigationLink(destination: PrivacySettingsView()) {
                        SettingsRow(
                            icon: "lock.shield.fill",
                            iconColor: .green,
                            title: "Privacy",
                            subtitle: "Data & export"
                        )
                    }
                }
                
                // Subscription
                Section {
                    NavigationLink(destination: SubscriptionSettingsView()) {
                        SettingsRow(
                            icon: "star.fill",
                            iconColor: .yellow,
                            title: "Subscription",
                            subtitle: subscriptionStatus
                        )
                    }
                }
                
                // About
                Section {
                    NavigationLink(destination: AboutView()) {
                        SettingsRow(
                            icon: "info.circle.fill",
                            iconColor: .blue,
                            title: "About",
                            subtitle: "Version \(appVersion)"
                        )
                    }
                }
                
                // Debug section (only in debug builds)
                #if DEBUG
                Section("Debug") {
                    Button("Reset Onboarding") {
                        UserSettings.shared.hasCompletedOnboarding = false
                        appState.showingOnboarding = true
                    }
                    .foregroundStyle(.red)
                    
                    Button("Show Paywall") {
                        appState.showingPaywall = true
                    }
                }
                #endif
            }
            .navigationTitle("Settings")
        }
    }
    
    private var subscriptionStatus: String {
        if UserSettings.shared.isSubscribed {
            return "Active"
        } else if UserSettings.shared.isInTrial {
            return "Trial"
        } else {
            return "Not subscribed"
        }
    }
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}

// MARK: - Settings Row

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(iconColor)
                .frame(width: 28, height: 28)
                .background(iconColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Typography.body)
                    .foregroundStyle(ColorPalette.primaryText)
                
                Text(subtitle)
                    .font(Typography.caption)
                    .foregroundStyle(ColorPalette.secondaryText)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environment(AppState())
}
