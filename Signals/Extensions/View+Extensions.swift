//
//  View+Extensions.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import SwiftUI

extension View {
    /// Applies a card-style background with rounded corners
    func cardStyle(padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .background(ColorPalette.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    /// Applies a subtle shadow
    func subtleShadow() -> some View {
        self.shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    /// Conditionally applies a modifier
    @ViewBuilder
    func `if`<Transform: View>(
        _ condition: Bool,
        transform: (Self) -> Transform
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// Applies a redacted placeholder effect when loading
    func loading(_ isLoading: Bool) -> some View {
        self.redacted(reason: isLoading ? .placeholder : [])
    }
    
    /// Hides the view based on a condition
    @ViewBuilder
    func hidden(_ shouldHide: Bool) -> some View {
        if shouldHide {
            self.hidden()
        } else {
            self
        }
    }
    
    /// Applies a gradient overlay
    func gradientOverlay(_ gradient: LinearGradient) -> some View {
        self.overlay(gradient)
    }
    
    /// Reads the view's size
    func readSize(_ onChange: @escaping (CGSize) -> Void) -> some View {
        background(
            GeometryReader { geometry in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: geometry.size)
            }
        )
        .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
    }
}

// MARK: - Preference Keys

private struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

// MARK: - Conditional Modifiers

extension View {
    /// Shows a paywall sheet if the user doesn't have full access
    func requiresSubscription(
        isPresented: Binding<Bool>,
        hasAccess: Bool
    ) -> some View {
        self.sheet(isPresented: isPresented) {
            if !hasAccess {
                PaywallView()
            }
        }
    }
}

// MARK: - Animation Extensions

extension View {
    /// Applies a bounce animation
    func bounceAnimation() -> some View {
        self.animation(.spring(response: 0.3, dampingFraction: 0.6), value: UUID())
    }
    
    /// Applies a smooth entrance animation
    func entranceAnimation(delay: Double = 0) -> some View {
        self.transition(.opacity.combined(with: .move(edge: .bottom)))
            .animation(.easeOut(duration: 0.3).delay(delay), value: UUID())
    }
}
