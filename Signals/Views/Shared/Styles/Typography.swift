//
//  Typography.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import SwiftUI

/// App-wide typography definitions
enum Typography {
    // MARK: - Title Styles
    
    /// Large title for main screens
    static var largeTitle: Font {
        .largeTitle.weight(.bold)
    }
    
    /// Title for section headers
    static var title: Font {
        .title.weight(.semibold)
    }
    
    /// Secondary title
    static var title2: Font {
        .title2.weight(.semibold)
    }
    
    /// Tertiary title
    static var title3: Font {
        .title3.weight(.medium)
    }
    
    // MARK: - Headline Styles
    
    /// Headline for card titles
    static var headline: Font {
        .headline.weight(.semibold)
    }
    
    /// Subheadline for supporting text
    static var subheadline: Font {
        .subheadline
    }
    
    // MARK: - Body Styles
    
    /// Primary body text
    static var body: Font {
        .body
    }
    
    /// Secondary body text
    static var bodySecondary: Font {
        .body.weight(.regular)
    }
    
    /// Callout for emphasis
    static var callout: Font {
        .callout
    }
    
    // MARK: - Caption Styles
    
    /// Primary caption
    static var caption: Font {
        .caption
    }
    
    /// Secondary caption
    static var caption2: Font {
        .caption2
    }
    
    // MARK: - Special Styles
    
    /// For displaying numbers/stats
    static var metric: Font {
        .system(.title, design: .rounded).weight(.bold)
    }
    
    /// For large stat displays - uses relative sizing for Dynamic Type support
    static var largeMetric: Font {
        .system(.largeTitle, design: .rounded).weight(.bold)
    }
    
    /// For small stat displays
    static var smallMetric: Font {
        .system(.headline, design: .rounded).weight(.semibold)
    }
    
    /// Monospaced for timestamps
    static var timestamp: Font {
        .system(.caption, design: .monospaced)
    }
    
    /// For insight body text - slightly larger for readability
    static var insightBody: Font {
        .system(.body, design: .serif)
    }
    
    /// For reflection text
    static var reflection: Font {
        .system(.body, design: .serif).italic()
    }
}

// MARK: - Text Style Modifiers

extension View {
    /// Applies the large title style
    func largeTitleStyle() -> some View {
        self.font(Typography.largeTitle)
            .foregroundStyle(ColorPalette.primaryText)
    }
    
    /// Applies the title style
    func titleStyle() -> some View {
        self.font(Typography.title)
            .foregroundStyle(ColorPalette.primaryText)
    }
    
    /// Applies the headline style
    func headlineStyle() -> some View {
        self.font(Typography.headline)
            .foregroundStyle(ColorPalette.primaryText)
    }
    
    /// Applies the body style
    func bodyStyle() -> some View {
        self.font(Typography.body)
            .foregroundStyle(ColorPalette.primaryText)
    }
    
    /// Applies the secondary text style
    func secondaryStyle() -> some View {
        self.font(Typography.subheadline)
            .foregroundStyle(ColorPalette.secondaryText)
    }
    
    /// Applies the caption style
    func captionStyle() -> some View {
        self.font(Typography.caption)
            .foregroundStyle(ColorPalette.tertiaryText)
    }
    
    /// Applies the metric style
    func metricStyle() -> some View {
        self.font(Typography.metric)
            .foregroundStyle(ColorPalette.primaryText)
    }
    
    /// Applies the large metric style
    func largeMetricStyle() -> some View {
        self.font(Typography.largeMetric)
            .foregroundStyle(ColorPalette.primaryText)
    }
}
