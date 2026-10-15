//
//  SubscriptionSettingsView.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import SwiftUI

/// Settings view for managing subscription
struct SubscriptionSettingsView: View {
    @Environment(AppState.self) private var appState
    
    @State private var isRestoring = false
    @State private var showingManageSubscription = false
    
    var body: some View {
        List {
            // Current status
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    // Status badge
                    HStack {
                        Image(systemName: statusIcon)
                            .font(.title2)
                            .foregroundStyle(statusColor)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(statusTitle)
                                .font(Typography.headline)
                            
                            Text(statusSubtitle)
                                .font(Typography.caption)
                                .foregroundStyle(ColorPalette.secondaryText)
                        }
                    }
                    
                    // Trial progress (if in trial)
                    if UserSettings.shared.isInTrial {
                        trialProgressView
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("Status")
            }
            
            // Subscription benefits
            if !UserSettings.shared.isSubscribed {
                Section {
                    BenefitRow(
                        icon: "lightbulb.fill",
                        title: "Unlimited Insights",
                        description: "Get all your weekly insights without limits"
                    )
                    
                    BenefitRow(
                        icon: "calendar",
                        title: "Full Timeline Access",
                        description: "View your complete history"
                    )
                    
                    BenefitRow(
                        icon: "square.and.arrow.up",
                        title: "Data Export",
                        description: "Export your data anytime"
                    )
                    
                    BenefitRow(
                        icon: "heart.fill",
                        title: "Support Development",
                        description: "Help us keep improving Signals"
                    )
                } header: {
                    Text("Premium Benefits")
                }
            }
            
            // Actions
            Section {
                if UserSettings.shared.isSubscribed {
                    Button(action: manageSubscription) {
                        HStack {
                            Text("Manage Subscription")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(ColorPalette.tertiaryText)
                        }
                    }
                } else {
                    Button(action: subscribe) {
                        HStack {
                            Text("Subscribe Now")
                            Spacer()
                            Text("$9.99/year")
                                .foregroundStyle(ColorPalette.secondaryText)
                        }
                    }
                    .foregroundStyle(ColorPalette.accent)
                }
                
                Button(action: restorePurchases) {
                    HStack {
                        Text("Restore Purchases")
                        Spacer()
                        if isRestoring {
                            ProgressView()
                        }
                    }
                }
                .disabled(isRestoring)
            }
            
            // Legal
            Section {
                Link(destination: URL(string: "https://signals.app/terms")!) {
                    HStack {
                        Text("Terms of Service")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(ColorPalette.tertiaryText)
                    }
                }
                .foregroundStyle(ColorPalette.primaryText)
                
                Link(destination: URL(string: "https://signals.app/privacy")!) {
                    HStack {
                        Text("Privacy Policy")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(ColorPalette.tertiaryText)
                    }
                }
                .foregroundStyle(ColorPalette.primaryText)
            } footer: {
                Text("Subscription automatically renews unless cancelled at least 24 hours before the end of the current period.")
                    .font(.caption2)
            }
        }
        .navigationTitle("Subscription")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Status Helpers
    
    private var statusIcon: String {
        if UserSettings.shared.isSubscribed {
            return "checkmark.seal.fill"
        } else if UserSettings.shared.isInTrial {
            return "clock.fill"
        } else {
            return "star"
        }
    }
    
    private var statusColor: Color {
        if UserSettings.shared.isSubscribed {
            return .green
        } else if UserSettings.shared.isInTrial {
            return .orange
        } else {
            return ColorPalette.secondaryText
        }
    }
    
    private var statusTitle: String {
        if UserSettings.shared.isSubscribed {
            return "Signals Premium"
        } else if UserSettings.shared.isInTrial {
            return "Free Trial"
        } else {
            return "Free"
        }
    }
    
    private var statusSubtitle: String {
        if UserSettings.shared.isSubscribed {
            if let renewalDate = UserSettings.shared.subscriptionExpirationDate {
                return "Renews \(renewalDate.formatted(date: .abbreviated, time: .omitted))"
            }
            return "Active subscription"
        } else if UserSettings.shared.isInTrial {
            return "\(trialDaysRemaining) days remaining"
        } else {
            return "Limited features"
        }
    }
    
    private var trialDaysRemaining: Int {
        guard let trialEnd = UserSettings.shared.trialEndDate else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: trialEnd).day ?? 0
        return max(0, days)
    }
    
    private var trialProgressView: some View {
        VStack(alignment: .leading, spacing: 8) {
            ProgressView(value: Double(7 - trialDaysRemaining), total: 7)
                .tint(.orange)
            
            Text("\(trialDaysRemaining) days left in your free trial")
                .font(Typography.caption)
                .foregroundStyle(ColorPalette.secondaryText)
        }
    }
    
    // MARK: - Actions
    
    private func subscribe() {
        appState.showingPaywall = true
        Haptics.light()
    }
    
    private func manageSubscription() {
        // Open App Store subscription management
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            UIApplication.shared.open(url)
        }
    }
    
    private func restorePurchases() {
        isRestoring = true
        Haptics.light()
        
        // Simulate restore
        Task {
            try? await Task.sleep(for: .seconds(2))
            
            await MainActor.run {
                isRestoring = false
                Haptics.success()
            }
        }
    }
}

// MARK: - Benefit Row

struct BenefitRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(ColorPalette.accent)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Typography.body)
                
                Text(description)
                    .font(Typography.caption)
                    .foregroundStyle(ColorPalette.secondaryText)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SubscriptionSettingsView()
    }
    .environment(AppState())
}
