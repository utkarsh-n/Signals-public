//
//  EmptyStateView.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import SwiftUI

/// Beautiful empty state view for when there's no content
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    var useGradientIcon: Bool = true
    var isAnimated: Bool = true
    
    @State private var iconScale: CGFloat = 0.8
    @State private var contentOpacity: Double = 0
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icon with gentle animation
            Group {
                if useGradientIcon {
                    Image(systemName: icon)
                        .font(.system(size: 60))
                        .foregroundStyle(ColorPalette.primaryGradient)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 60))
                        .foregroundStyle(ColorPalette.tertiaryText)
                }
            }
            .scaleEffect(iconScale)
            .opacity(contentOpacity)
            
            // Text
            VStack(spacing: 8) {
                Text(title)
                    .font(Typography.title)
                    .foregroundStyle(ColorPalette.primaryText)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(Typography.body)
                    .foregroundStyle(ColorPalette.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            .opacity(contentOpacity)
            
            // Action button
            if let actionTitle, let action {
                Button(action: {
                    Haptics.buttonPressed()
                    action()
                }) {
                    Text(actionTitle)
                        .font(Typography.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(ColorPalette.accent)
                        .clipShape(Capsule())
                }
                .padding(.top, 8)
                .opacity(contentOpacity)
            }
            
            Spacer()
            Spacer()
        }
        .onAppear {
            guard isAnimated else {
                iconScale = 1.0
                contentOpacity = 1.0
                return
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                iconScale = 1.0
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
                contentOpacity = 1.0
            }
        }
    }
}

/// Compact empty state for inline use
struct CompactEmptyState: View {
    let icon: String
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(ColorPalette.tertiaryText)
            
            Text(message)
                .font(Typography.body)
                .foregroundStyle(ColorPalette.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
    }
}

/// Empty state for lists
struct ListEmptyState: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundStyle(ColorPalette.tertiaryText)
            
            VStack(spacing: 4) {
                Text(title)
                    .font(Typography.headline)
                    .foregroundStyle(ColorPalette.primaryText)
                
                Text(message)
                    .font(Typography.caption)
                    .foregroundStyle(ColorPalette.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(48)
    }
}

// MARK: - Preset Empty States

extension EmptyStateView {
    static var noInsights: EmptyStateView {
        EmptyStateView(
            icon: "sparkles",
            title: "Your insights will appear here",
            message: "Signals analyzes your patterns over time and generates personalized insights every week."
        )
    }
    
    static var noReflections: EmptyStateView {
        EmptyStateView(
            icon: "text.quote",
            title: "No reflections yet",
            message: "Start writing reflections to capture your thoughts and see patterns emerge."
        )
    }
    
    static var noData: EmptyStateView {
        EmptyStateView(
            icon: "chart.bar.xaxis",
            title: "No data yet",
            message: "As Signals collects data, you'll see your patterns visualized here."
        )
    }
    
    static var noTimeline: EmptyStateView {
        EmptyStateView(
            icon: "calendar",
            title: "Your timeline will appear here",
            message: "Track your days and watch your personal history unfold."
        )
    }
    
    // MARK: - First-use States (warm & encouraging)
    
    static var firstDayTimeline: EmptyStateView {
        EmptyStateView(
            icon: "waveform.path.ecg",
            title: "Signals is listening",
            message: "Your timeline will fill in as your day unfolds. Just go about your day — we'll capture the moments."
        )
    }
    
    static var firstInsights: EmptyStateView {
        EmptyStateView(
            icon: "sparkles",
            title: "Your first insights arrive Sunday",
            message: "Signals needs about a week of data to discover your patterns. Keep going — you're building your story."
        )
    }
    
    static var firstReflection: EmptyStateView {
        EmptyStateView(
            icon: "pencil.and.outline",
            title: "Capture a moment",
            message: "Write your first reflection. It can be anything — a thought, a highlight, or how you're feeling right now.",
            actionTitle: "Start Writing"
        )
    }
    
    // MARK: - Signal-specific Empty States
    
    static var noLocationData: EmptyStateView {
        EmptyStateView(
            icon: "location.slash",
            title: "Location unavailable",
            message: "Enable location access in Settings to see where you spend your time.",
            useGradientIcon: false
        )
    }
    
    static var noScreenTimeData: EmptyStateView {
        EmptyStateView(
            icon: "iphone.slash",
            title: "Screen Time unavailable",
            message: "Enable Screen Time access in Settings to track your digital habits.",
            useGradientIcon: false
        )
    }
    
    static var noHealthData: EmptyStateView {
        EmptyStateView(
            icon: "heart.slash",
            title: "Health data unavailable",
            message: "Connect Apple Health in Settings to see your steps, sleep, and more.",
            useGradientIcon: false
        )
    }
    
    // MARK: - Error States
    
    static var loadingFailed: EmptyStateView {
        EmptyStateView(
            icon: "exclamationmark.triangle",
            title: "Couldn't load data",
            message: "Pull down to refresh and try again.",
            useGradientIcon: false
        )
    }
}

// MARK: - Preview

#Preview {
    VStack {
        EmptyStateView(
            icon: "sparkles",
            title: "No insights yet",
            message: "Your first insights will appear after 7 days of tracking.",
            actionTitle: "Learn More",
            action: { }
        )
    }
}
