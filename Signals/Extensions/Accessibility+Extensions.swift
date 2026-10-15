//
//  Accessibility+Extensions.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import SwiftUI

// MARK: - Accessibility Labels

/// Standard accessibility labels for common UI elements
enum AccessibilityLabels {
    // MARK: - Tabs
    
    static func tab(_ tab: Tab) -> String {
        switch tab {
        case .home: return "Home tab. View today's status and latest insights."
        case .insights: return "Insights tab. View your weekly patterns and discoveries."
        case .timeline: return "Timeline tab. Browse your daily history."
        case .reflect: return "Reflect tab. Write and view your reflections."
        case .settings: return "Settings tab. Configure app preferences."
        }
    }
    
    // MARK: - Signals
    
    static func signal(_ signal: SignalType, isActive: Bool) -> String {
        let status = isActive ? "active" : "inactive"
        return "\(signal.displayName) signal, \(status)"
    }
    
    static func signalValue(_ signal: SignalType, value: String) -> String {
        return "\(signal.displayName): \(value)"
    }
    
    // MARK: - Insights
    
    static func insight(_ insight: Insight) -> String {
        let readStatus = insight.isRead ? "" : "Unread. "
        return "\(readStatus)\(insight.title). \(insight.body)"
    }
    
    static func insightCategory(_ category: InsightCategory) -> String {
        switch category {
        case .pattern: return "Pattern insight"
        case .correlation: return "Correlation insight"
        case .trend: return "Trend insight"
        case .milestone: return "Milestone insight"
        case .seasonal: return "Seasonal insight"
        case .anomaly: return "Unusual activity insight"
        }
    }
    
    // MARK: - Mood
    
    static func moodLevel(_ level: MoodLevel) -> String {
        switch level {
        case .one: return "Mood level 1 of 5"
        case .two: return "Mood level 2 of 5"
        case .three: return "Mood level 3 of 5"
        case .four: return "Mood level 4 of 5"
        case .five: return "Mood level 5 of 5"
        }
    }
    
    // MARK: - Charts
    
    static func chartValue(label: String, value: Double, unit: String) -> String {
        return "\(label): \(String(format: "%.1f", value)) \(unit)"
    }
    
    static func trendDirection(_ isUp: Bool, percentage: Double) -> String {
        let direction = isUp ? "up" : "down"
        return "Trending \(direction) \(String(format: "%.0f", abs(percentage))) percent"
    }
}

// MARK: - View Extensions for Accessibility

extension View {
    /// Adds standard accessibility for a signal indicator
    func signalAccessibility(_ signal: SignalType, isActive: Bool) -> some View {
        self
            .accessibilityLabel(AccessibilityLabels.signal(signal, isActive: isActive))
            .accessibilityAddTraits(isActive ? .updatesFrequently : [])
    }
    
    /// Adds standard accessibility for an insight card
    func insightAccessibility(_ insight: Insight) -> some View {
        self
            .accessibilityLabel(AccessibilityLabels.insight(insight))
            .accessibilityHint("Double tap to view details")
            .accessibilityAddTraits(.isButton)
    }
    
    /// Adds accessibility for a mood button
    func moodButtonAccessibility(_ level: MoodLevel, isSelected: Bool) -> some View {
        self
            .accessibilityLabel(AccessibilityLabels.moodLevel(level))
            .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
    
    /// Groups children for VoiceOver
    func accessibilityGroup(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
    }
    
    /// Hides decorative elements from VoiceOver
    func accessibilityDecorative() -> some View {
        self.accessibilityHidden(true)
    }
    
    /// Adds announcement when value changes
    func accessibilityAnnounce(_ announcement: String, when condition: Bool) -> some View {
        self.onChange(of: condition) { _, newValue in
            if newValue {
                UIAccessibility.post(notification: .announcement, argument: announcement)
            }
        }
    }
}

// MARK: - Dynamic Type Helpers

extension View {
    /// Scales text appropriately for accessibility sizes
    @ViewBuilder
    func scaledFont(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> some View {
        self.font(.system(style, weight: weight))
    }
    
    /// Adjusts layout for large accessibility text sizes
    @ViewBuilder
    func adaptiveStack<Content: View>(
        threshold: DynamicTypeSize = .accessibility1,
        horizontalAlignment: HorizontalAlignment = .center,
        verticalAlignment: VerticalAlignment = .center,
        spacing: CGFloat = 8,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ViewThatFits {
            HStack(alignment: verticalAlignment, spacing: spacing) {
                content()
            }
            
            VStack(alignment: horizontalAlignment, spacing: spacing) {
                content()
            }
        }
    }
    
    /// Scales a size value based on Dynamic Type category
    func scaledValue(_ baseValue: CGFloat, relativeTo textStyle: Font.TextStyle = .body) -> CGFloat {
        UIFontMetrics(forTextStyle: textStyle.uiTextStyle).scaledValue(for: baseValue)
    }
    
    /// Limits text scaling to a maximum size for layout-sensitive elements
    func limitedScaling(maxSize: DynamicTypeSize = .accessibility1) -> some View {
        self.dynamicTypeSize(...maxSize)
    }
}

extension Font.TextStyle {
    var uiTextStyle: UIFont.TextStyle {
        switch self {
        case .largeTitle: return .largeTitle
        case .title: return .title1
        case .title2: return .title2
        case .title3: return .title3
        case .headline: return .headline
        case .subheadline: return .subheadline
        case .body: return .body
        case .callout: return .callout
        case .footnote: return .footnote
        case .caption: return .caption1
        case .caption2: return .caption2
        @unknown default: return .body
        }
    }
}

// MARK: - Accessibility Environment Reader

struct AccessibilityAwareView<Content: View>: View {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency
    @Environment(\.accessibilityDifferentiateWithoutColor) var differentiateWithoutColor
    
    let content: (AccessibilityContext) -> Content
    
    var body: some View {
        content(AccessibilityContext(
            isLargeText: dynamicTypeSize >= .accessibility1,
            reduceMotion: reduceMotion,
            reduceTransparency: reduceTransparency,
            differentiateWithoutColor: differentiateWithoutColor
        ))
    }
}

struct AccessibilityContext {
    let isLargeText: Bool
    let reduceMotion: Bool
    let reduceTransparency: Bool
    let differentiateWithoutColor: Bool
}

// MARK: - Reduced Motion Modifier

extension View {
    /// Applies animation only if reduce motion is not enabled
    func animationRespectingMotion<V: Equatable>(
        _ animation: Animation?,
        value: V
    ) -> some View {
        modifier(ReducedMotionAnimationModifier(animation: animation, value: value))
    }
}

private struct ReducedMotionAnimationModifier<V: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    let animation: Animation?
    let value: V
    
    func body(content: Content) -> some View {
        content.animation(reduceMotion ? nil : animation, value: value)
    }
}

// MARK: - Accessibility Rotor

extension View {
    /// Adds a custom accessibility rotor for insights
    func insightsRotor(_ insights: [Insight]) -> some View {
        self.accessibilityRotor("Insights") {
            ForEach(insights) { insight in
                AccessibilityRotorEntry(insight.title, id: insight.id)
            }
        }
    }
    
    /// Adds a custom accessibility rotor for reflections
    func reflectionsRotor(_ reflections: [Reflection]) -> some View {
        self.accessibilityRotor("Reflections") {
            ForEach(reflections) { reflection in
                AccessibilityRotorEntry(
                    reflection.text.prefix(50) + "...",
                    id: reflection.id
                )
            }
        }
    }
}
