//
//  DesignTokens.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//
//  Centralized design tokens for consistent spacing, sizing, and layout
//  Aligned with Apple Human Interface Guidelines and Liquid Glass design system
//

import SwiftUI

// MARK: - Spacing

/// Standardized spacing values for consistent layouts
enum Spacing {
    /// Extra small spacing (4pt)
    static let xs: CGFloat = 4
    
    /// Small spacing (8pt)
    static let sm: CGFloat = 8
    
    /// Medium spacing (12pt)
    static let md: CGFloat = 12
    
    /// Standard spacing (16pt) - default padding
    static let standard: CGFloat = 16
    
    /// Large spacing (20pt)
    static let lg: CGFloat = 20
    
    /// Extra large spacing (24pt)
    static let xl: CGFloat = 24
    
    /// Double extra large spacing (32pt)
    static let xxl: CGFloat = 32
    
    /// Triple extra large spacing (40pt)
    static let xxxl: CGFloat = 40
    
    /// Section spacing (48pt)
    static let section: CGFloat = 48
    
    // MARK: - Semantic Spacing
    
    /// Spacing between cards in a list
    static let cardGap: CGFloat = 16
    
    /// Spacing between items within a card
    static let cardInternalGap: CGFloat = 12
    
    /// Standard card padding
    static let cardPadding: CGFloat = 16
    
    /// Compact card padding
    static let cardPaddingCompact: CGFloat = 12
    
    /// Tab bar bottom padding
    static let tabBarPadding: CGFloat = 8
    
    /// Safe area additional padding
    static let safeAreaPadding: CGFloat = 16
}

// MARK: - Corner Radius

/// Standardized corner radii for consistent shapes
enum CornerRadius {
    /// Small radius (8pt) - for small elements like tags
    static let sm: CGFloat = 8
    
    /// Medium radius (12pt) - for buttons and small cards
    static let md: CGFloat = 12
    
    /// Standard radius (16pt) - default for cards
    static let standard: CGFloat = 16
    
    /// Large radius (20pt) - for larger cards
    static let lg: CGFloat = 20
    
    /// Extra large radius (24pt) - for sheets and modals
    static let xl: CGFloat = 24
    
    /// Full radius (999pt) - for pills and capsules
    static let full: CGFloat = 999
}

// MARK: - Size

/// Standardized sizes for icons, buttons, and other elements
enum Size {
    // MARK: - Icon Sizes
    
    /// Small icon (16pt)
    static let iconSm: CGFloat = 16
    
    /// Medium icon (20pt)
    static let iconMd: CGFloat = 20
    
    /// Standard icon (24pt)
    static let iconStandard: CGFloat = 24
    
    /// Large icon (28pt)
    static let iconLg: CGFloat = 28
    
    /// Extra large icon (32pt)
    static let iconXl: CGFloat = 32
    
    /// Hero icon (48pt)
    static let iconHero: CGFloat = 48
    
    // MARK: - Button Heights
    
    /// Small button height (32pt)
    static let buttonSm: CGFloat = 32
    
    /// Standard button height (44pt) - Apple's minimum touch target
    static let buttonStandard: CGFloat = 44
    
    /// Large button height (50pt)
    static let buttonLg: CGFloat = 50
    
    /// Extra large button height (56pt)
    static let buttonXl: CGFloat = 56
    
    // MARK: - Card Sizes
    
    /// Minimum card width
    static let cardMinWidth: CGFloat = 160
    
    /// Standard card height for widgets
    static let widgetHeight: CGFloat = 120
    
    /// Large widget height
    static let widgetHeightLg: CGFloat = 180
    
    // MARK: - Avatar Sizes
    
    /// Small avatar (32pt)
    static let avatarSm: CGFloat = 32
    
    /// Medium avatar (40pt)
    static let avatarMd: CGFloat = 40
    
    /// Large avatar (56pt)
    static let avatarLg: CGFloat = 56
    
    // MARK: - Misc
    
    /// Tab bar height
    static let tabBarHeight: CGFloat = 49
    
    /// Navigation bar height
    static let navBarHeight: CGFloat = 44
    
    /// Minimum touch target (Apple HIG)
    static let minTouchTarget: CGFloat = 44
}

// MARK: - Animation

/// Standardized animation durations and curves
enum AnimationTokens {
    /// Fast animation (0.15s) - for micro-interactions
    static let fast: Double = 0.15
    
    /// Standard animation (0.25s) - default
    static let standard: Double = 0.25
    
    /// Slow animation (0.35s) - for larger transitions
    static let slow: Double = 0.35
    
    /// Extra slow animation (0.5s) - for dramatic effects
    static let extraSlow: Double = 0.5
    
    // MARK: - Spring Animations
    
    /// Snappy spring for quick interactions
    static var snappy: Animation {
        .spring(response: 0.3, dampingFraction: 0.7)
    }
    
    /// Bouncy spring for playful interactions
    static var bouncy: Animation {
        .spring(response: 0.4, dampingFraction: 0.6)
    }
    
    /// Smooth spring for elegant transitions
    static var smooth: Animation {
        .spring(response: 0.5, dampingFraction: 0.8)
    }
    
    /// Liquid Glass morphing animation
    static var liquidGlass: Animation {
        .spring(response: 0.4, dampingFraction: 0.75)
    }
}

// MARK: - Shadow

/// Standardized shadow styles
enum Shadow {
    /// Subtle shadow for cards
    static func subtle(_ colorScheme: ColorScheme) -> some View {
        Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08)
    }
    
    /// Card shadow parameters
    static let cardRadius: CGFloat = 8
    static let cardY: CGFloat = 2
    
    /// Elevated shadow parameters
    static let elevatedRadius: CGFloat = 16
    static let elevatedY: CGFloat = 4
}

// MARK: - Liquid Glass Spacing

/// Spacing values optimized for Liquid Glass containers
enum GlassSpacing {
    /// Tight spacing - glass shapes merge at rest
    static let tight: CGFloat = 12
    
    /// Standard spacing - shapes blend during transitions
    static let standard: CGFloat = 20
    
    /// Loose spacing - shapes stay separate
    static let loose: CGFloat = 32
    
    /// Wide spacing - no blending occurs
    static let wide: CGFloat = 48
}

// MARK: - View Extensions

extension View {
    /// Applies standard card padding
    func cardPadding() -> some View {
        padding(Spacing.cardPadding)
    }
    
    /// Applies compact card padding
    func cardPaddingCompact() -> some View {
        padding(Spacing.cardPaddingCompact)
    }
    
    /// Applies standard horizontal padding
    func horizontalPadding() -> some View {
        padding(.horizontal, Spacing.standard)
    }
    
    /// Applies section spacing
    func sectionSpacing() -> some View {
        padding(.vertical, Spacing.section)
    }
    
    /// Standard corner radius
    func standardCornerRadius() -> some View {
        clipShape(RoundedRectangle(cornerRadius: CornerRadius.standard))
    }
    
    /// Large corner radius
    func largeCornerRadius() -> some View {
        clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
    }
}
