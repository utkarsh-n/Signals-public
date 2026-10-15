//
//  TrialExpiringView.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import SwiftUI

/// Gentle nudge shown when trial is about to expire
struct TrialExpiringView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    
    let daysRemaining: Int
    var onSubscribe: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "clock.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.orange)
            }
            
            // Message
            VStack(spacing: 8) {
                Text(titleText)
                    .font(Typography.title)
                    .foregroundStyle(ColorPalette.primaryText)
                    .multilineTextAlignment(.center)
                
                Text(subtitleText)
                    .font(Typography.body)
                    .foregroundStyle(ColorPalette.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            // What you'll keep
            VStack(alignment: .leading, spacing: 12) {
                Text("What you'll keep:")
                    .font(Typography.caption)
                    .foregroundStyle(ColorPalette.secondaryText)
                
                TrialStatusFeatureRow(icon: "checkmark.circle.fill", text: "All your collected data", included: true)
                TrialStatusFeatureRow(icon: "checkmark.circle.fill", text: "Your reflections", included: true)
                TrialStatusFeatureRow(icon: "checkmark.circle.fill", text: "Past insights", included: true)
            }
            .padding()
            .background(ColorPalette.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // What requires subscription
            VStack(alignment: .leading, spacing: 12) {
                Text("Requires subscription:")
                    .font(Typography.caption)
                    .foregroundStyle(ColorPalette.secondaryText)
                
                TrialStatusFeatureRow(icon: "xmark.circle.fill", text: "New weekly insights", included: false)
                TrialStatusFeatureRow(icon: "xmark.circle.fill", text: "Timeline beyond 2 weeks", included: false)
                TrialStatusFeatureRow(icon: "xmark.circle.fill", text: "Data export", included: false)
            }
            .padding()
            .background(ColorPalette.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Spacer()
            
            // Actions
            VStack(spacing: 12) {
                Button(action: {
                    onSubscribe?()
                    dismiss()
                }) {
                    Text("Subscribe Now")
                        .font(Typography.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(ColorPalette.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Button("Maybe Later") {
                    dismiss()
                }
                .font(Typography.body)
                .foregroundStyle(ColorPalette.secondaryText)
            }
        }
        .padding()
        .background(ColorPalette.background)
    }
    
    private var titleText: String {
        if daysRemaining <= 0 {
            return "Your trial has ended"
        } else if daysRemaining == 1 {
            return "Your trial ends tomorrow"
        } else {
            return "Your trial ends in \(daysRemaining) days"
        }
    }
    
    private var subtitleText: String {
        if daysRemaining <= 0 {
            return "Subscribe to keep your insights flowing."
        } else {
            return "Subscribe to continue discovering your patterns."
        }
    }
}

// MARK: - Trial Status Feature Row

struct TrialStatusFeatureRow: View {
    let icon: String
    let text: String
    let included: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(included ? .green : .orange)
            
            Text(text)
                .font(Typography.body)
                .foregroundStyle(ColorPalette.primaryText)
        }
    }
}

// MARK: - Trial Ended Banner

/// A banner to show when trial has ended (for use in other views)
struct TrialEndedBanner: View {
    var onSubscribe: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Trial Ended")
                    .font(Typography.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(ColorPalette.primaryText)
                
                Text("Subscribe to unlock insights")
                    .font(.caption2)
                    .foregroundStyle(ColorPalette.secondaryText)
            }
            
            Spacer()
            
            Button("Subscribe") {
                onSubscribe()
            }
            .font(Typography.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(ColorPalette.accent)
            .clipShape(Capsule())
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview

#Preview {
    TrialExpiringView(daysRemaining: 2)
        .environment(AppState())
}
