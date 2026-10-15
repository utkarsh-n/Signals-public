//
//  DataSourcesSettingsView.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import SwiftUI

/// Settings view for managing tracked data sources
struct DataSourcesSettingsView: View {
    @State private var enabledSignals: Set<SignalType> = Set(UserSettings.shared.enabledSignals)
    @State private var showingPermissionAlert = false
    @State private var pendingSignal: SignalType?
    
    var body: some View {
        List {
            // Health signals
            Section {
                SignalToggleRow(signal: .steps, isEnabled: binding(for: .steps))
                SignalToggleRow(signal: .sleep, isEnabled: binding(for: .sleep))
                SignalToggleRow(signal: .exercise, isEnabled: binding(for: .exercise))
                SignalToggleRow(signal: .heartRate, isEnabled: binding(for: .heartRate))
                SignalToggleRow(signal: .hrv, isEnabled: binding(for: .hrv))
            } header: {
                Text("Health")
            } footer: {
                Text("Requires Health app permission")
            }
            
            // Activity signals
            Section {
                SignalToggleRow(signal: .screenTime, isEnabled: binding(for: .screenTime))
                SignalToggleRow(signal: .appPickups, isEnabled: binding(for: .appPickups))
            } header: {
                Text("Screen Time")
            } footer: {
                Text("Requires Screen Time permission")
            }
            
            // Location signals
            Section {
                SignalToggleRow(signal: .location, isEnabled: binding(for: .location))
                SignalToggleRow(signal: .distance, isEnabled: binding(for: .distance))
                SignalToggleRow(signal: .places, isEnabled: binding(for: .places))
            } header: {
                Text("Location")
            } footer: {
                Text("Uses significant location changes only. Never stores exact coordinates.")
            }
            
            // Motion signals
            Section {
                SignalToggleRow(signal: .motion, isEnabled: binding(for: .motion))
            } header: {
                Text("Motion")
            } footer: {
                Text("Detects walking, running, driving, etc.")
            }
            
            // Weather
            Section {
                SignalToggleRow(signal: .weather, isEnabled: binding(for: .weather))
            } header: {
                Text("Weather")
            } footer: {
                Text("Fetches daily weather for your general location")
            }
            
            // Sync status
            Section {
                HStack {
                    Text("Last Sync")
                    Spacer()
                    Text(lastSyncText)
                        .foregroundStyle(ColorPalette.secondaryText)
                }
                
                Button("Sync Now") {
                    syncNow()
                }
            } header: {
                Text("Sync")
            }
        }
        .navigationTitle("Data Sources")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Permission Required", isPresented: $showingPermissionAlert) {
            Button("Open Settings") {
                openSettings()
            }
            Button("Cancel", role: .cancel) {
                // Revert the toggle
                if let signal = pendingSignal {
                    enabledSignals.remove(signal)
                }
            }
        } message: {
            Text("Please enable the required permission in Settings to track this signal.")
        }
    }
    
    // MARK: - Binding Helper
    
    private func binding(for signal: SignalType) -> Binding<Bool> {
        Binding(
            get: { enabledSignals.contains(signal) },
            set: { isEnabled in
                if isEnabled {
                    // Check permission before enabling
                    if hasPermission(for: signal) {
                        enabledSignals.insert(signal)
                        saveSettings()
                    } else {
                        pendingSignal = signal
                        showingPermissionAlert = true
                    }
                } else {
                    enabledSignals.remove(signal)
                    saveSettings()
                }
                Haptics.toggleChanged()
            }
        )
    }
    
    private func hasPermission(for signal: SignalType) -> Bool {
        // In a real implementation, check actual permission status
        // For now, return true to allow toggling
        return true
    }
    
    private func saveSettings() {
        UserSettings.shared.enabledSignals = enabledSignals
    }
    
    private var lastSyncText: String {
        if let lastSync = UserSettings.shared.lastSyncDate {
            return lastSync.formatted(.relative(presentation: .named))
        }
        return "Never"
    }
    
    private func syncNow() {
        Haptics.medium()
        // Trigger data collection
        UserSettings.shared.lastSyncDate = Date()
    }
    
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Signal Toggle Row

struct SignalToggleRow: View {
    let signal: SignalType
    @Binding var isEnabled: Bool
    
    var body: some View {
        Toggle(isOn: $isEnabled) {
            HStack(spacing: 12) {
                Image(systemName: signal.icon)
                    .foregroundStyle(ColorPalette.color(for: signal))
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(signal.displayName)
                        .font(Typography.body)
                    
                    Text(signal.description)
                        .font(Typography.caption)
                        .foregroundStyle(ColorPalette.secondaryText)
                }
            }
        }
        .tint(ColorPalette.accent)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DataSourcesSettingsView()
    }
}
