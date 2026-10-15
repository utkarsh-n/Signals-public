//
//  PaywallGateModifier.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import SwiftUI

/// Modifier that gates premium content behind the paywall
struct PaywallGateModifier: ViewModifier {
    let feature: PremiumFeature
    let style: PaywallGateStyle
    
    @State private var showingPaywall = false
    
    func body(content: Content) -> some View {
        let hasAccess = PaywallManager.shared.canAccess(feature)
        
        Group {
            if hasAccess {
                content
            } else {
                switch style {
                case .overlay:
                    content
                        .blur(radius: 8)
                        .overlay {
                            PaywallGateOverlay(
                                feature: feature,
                                onUnlock: { showingPaywall = true }
                            )
                        }
                        .allowsHitTesting(false)
                    
                case .replace:
                    PaywallGateReplacement(
                        feature: feature,
                        onUnlock: { showingPaywall = true }
                    )
                    
                case .softPrompt:
                    content
                        .onTapGesture {
                            showingPaywall = true
                        }
                }
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }
}

// MARK: - Gate Styles

enum PaywallGateStyle {
    case overlay    // Content visible but blurred with unlock prompt
    case replace    // Content completely replaced with unlock prompt
    case softPrompt // Content visible, tapping opens paywall
}

// MARK: - Gate Overlay

struct PaywallGateOverlay: View {
    let feature: PremiumFeature
    let onUnlock: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.fill")
                .font(.system(size: 32))
                .foregroundStyle(ColorPalette.accent)
            
            Text("Unlock with Signals")
                .font(Typography.headline)
                .foregroundStyle(ColorPalette.primaryText)
            
            Text(feature.lockedDescription)
                .font(Typography.body)
                .foregroundStyle(ColorPalette.secondaryText)
                .multilineTextAlignment(.center)
            
            Button(action: onUnlock) {
                Text("Learn More")
                    .font(Typography.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(ColorPalette.accent)
                    .clipShape(Capsule())
            }
        }
        .padding(32)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(24)
    }
}

// MARK: - Gate Replacement

struct PaywallGateReplacement: View {
    let feature: PremiumFeature
    let onUnlock: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: feature.icon)
                .font(.system(size: 60))
                .foregroundStyle(ColorPalette.primaryGradient)
            
            VStack(spacing: 8) {
                Text(feature.lockedTitle)
                    .font(Typography.title)
                    .foregroundStyle(ColorPalette.primaryText)
                
                Text(feature.lockedDescription)
                    .font(Typography.body)
                    .foregroundStyle(ColorPalette.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            
            Button(action: onUnlock) {
                HStack {
                    Image(systemName: "sparkles")
                    Text("Unlock Full Access")
                }
                .font(Typography.body)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(ColorPalette.accent)
                .clipShape(Capsule())
            }
            
            Spacer()
            Spacer()
        }
    }
}

// MARK: - View Extension

extension View {
    /// Gates this view behind a paywall for the specified feature
    func paywallGate(
        feature: PremiumFeature,
        style: PaywallGateStyle = .overlay
    ) -> some View {
        modifier(PaywallGateModifier(feature: feature, style: style))
    }
}

// MARK: - Premium Feature Extensions

extension PremiumFeature {
    var icon: String {
        switch self {
        case .viewRecentInsights, .viewFullInsightHistory:
            return "sparkles"
        case .viewWeeklyReports:
            return "doc.text"
        case .viewRecentTimeline, .viewFullTimeline:
            return "calendar"
        case .viewHeatmap:
            return "chart.xyaxis.line"
        case .writeReflections, .viewReflectionHistory:
            return "text.quote"
        case .viewReflectionPrompts:
            return "lightbulb"
        case .exportData:
            return "square.and.arrow.up"
        case .todayView:
            return "house"
        }
    }
    
    var lockedTitle: String {
        switch self {
        case .viewRecentInsights, .viewFullInsightHistory:
            return "Full Insight History"
        case .viewWeeklyReports:
            return "Weekly Reports"
        case .viewRecentTimeline, .viewFullTimeline:
            return "Full Timeline"
        case .viewHeatmap:
            return "Activity Heatmap"
        case .writeReflections, .viewReflectionHistory:
            return "Full Reflection History"
        case .viewReflectionPrompts:
            return "Reflection Prompts"
        case .exportData:
            return "Data Export"
        case .todayView:
            return "Today"
        }
    }
    
    var lockedDescription: String {
        switch self {
        case .viewRecentInsights, .viewFullInsightHistory:
            return "Subscribe to see all your insights and patterns over time."
        case .viewWeeklyReports:
            return "Get personalized weekly summaries of your patterns and trends."
        case .viewRecentTimeline, .viewFullTimeline:
            return "Browse your complete history beyond the last two weeks."
        case .viewHeatmap:
            return "Visualize your patterns with beautiful heatmaps."
        case .writeReflections, .viewReflectionHistory:
            return "Access your complete reflection archive."
        case .viewReflectionPrompts:
            return "Get personalized prompts based on your day."
        case .exportData:
            return "Export all your data in JSON format."
        case .todayView:
            return "Your daily summary."
        }
    }
}

// MARK: - List Gate Modifier

/// Modifier for gating list items (shows limited items + unlock prompt)
struct ListPaywallGateModifier<Item: Identifiable>: ViewModifier {
    let items: [Item]
    let feature: PremiumFeature
    let limit: Int
    
    @State private var showingPaywall = false
    
    var visibleItems: [Item] {
        let actualLimit = PaywallManager.shared.featureLimit(for: feature) ?? items.count
        return Array(items.prefix(min(actualLimit, limit)))
    }
    
    var hasMoreItems: Bool {
        items.count > visibleItems.count
    }
    
    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom) {
                if hasMoreItems && !PaywallManager.shared.hasFullAccess {
                    HStack {
                        Text("\(items.count - visibleItems.count) more with Signals")
                            .font(Typography.caption)
                            .foregroundStyle(ColorPalette.secondaryText)
                        
                        Spacer()
                        
                        Button("Unlock") {
                            showingPaywall = true
                        }
                        .font(Typography.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(ColorPalette.accent)
                    }
                    .padding()
                    .background(ColorPalette.secondaryBackground)
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
    }
}

extension View {
    /// Gates a list to show limited items with unlock prompt
    func listPaywallGate<Item: Identifiable>(
        items: [Item],
        feature: PremiumFeature,
        limit: Int
    ) -> some View {
        modifier(ListPaywallGateModifier(items: items, feature: feature, limit: limit))
    }
}
