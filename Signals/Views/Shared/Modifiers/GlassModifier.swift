//
//  GlassModifier.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//
//  Liquid Glass design system for iOS 26+
//  Provides beautiful, fluid glass effects that respond to touch and context
//

import SwiftUI

// MARK: - Liquid Glass Modifier (iOS 26+)

/// Modern Liquid Glass effect modifier using iOS 26 APIs
/// Falls back to material-based glass on earlier versions
struct LiquidGlassModifier: ViewModifier {
    var tint: Color?
    var isInteractive: Bool
    var cornerRadius: CGFloat
    
    init(tint: Color? = nil, isInteractive: Bool = false, cornerRadius: CGFloat = 16) {
        self.tint = tint
        self.isInteractive = isInteractive
        self.cornerRadius = cornerRadius
    }
    
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(glassConfiguration, in: .rect(cornerRadius: cornerRadius))
        } else {
            // Fallback for earlier iOS versions
            content
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
        }
    }
    
    @available(iOS 26.0, *)
    private var glassConfiguration: Glass {
        var glass = Glass.regular
        if let tint = tint {
            glass = glass.tint(tint)
        }
        if isInteractive {
            glass = glass.interactive()
        }
        return glass
    }
}

/// Capsule-shaped Liquid Glass for pills and buttons
struct LiquidGlassCapsuleModifier: ViewModifier {
    var tint: Color?
    var isInteractive: Bool
    
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(glassConfiguration, in: .capsule)
        } else {
            content
                .background(.ultraThinMaterial, in: Capsule())
        }
    }
    
    @available(iOS 26.0, *)
    private var glassConfiguration: Glass {
        var glass = Glass.regular
        if let tint = tint {
            glass = glass.tint(tint)
        }
        if isInteractive {
            glass = glass.interactive()
        }
        return glass
    }
}

// MARK: - Legacy Glass Modifiers (Compatibility)

/// Frosted glass effect modifier (legacy)
struct GlassModifier: ViewModifier {
    var cornerRadius: CGFloat = 16
    var opacity: Double = 0.8
    
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
    }
}

/// Glass card modifier with border (legacy)
struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 16
    
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.3), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}

// MARK: - View Extensions

extension View {
    // MARK: - Liquid Glass (iOS 26+)
    
    /// Applies Liquid Glass effect with rounded rectangle shape
    /// - Parameters:
    ///   - tint: Optional tint color for the glass
    ///   - isInteractive: Whether the glass responds to touch/pointer interactions
    ///   - cornerRadius: Corner radius for the glass shape
    func liquidGlass(
        tint: Color? = nil,
        isInteractive: Bool = false,
        cornerRadius: CGFloat = 16
    ) -> some View {
        modifier(LiquidGlassModifier(tint: tint, isInteractive: isInteractive, cornerRadius: cornerRadius))
    }
    
    /// Applies Liquid Glass effect with capsule shape (for buttons/pills)
    func liquidGlassCapsule(
        tint: Color? = nil,
        isInteractive: Bool = true
    ) -> some View {
        modifier(LiquidGlassCapsuleModifier(tint: tint, isInteractive: isInteractive))
    }
    
    /// Applies signal-specific Liquid Glass tint
    func liquidGlass(for signal: SignalType, cornerRadius: CGFloat = 16) -> some View {
        liquidGlass(tint: ColorPalette.glassTint(for: signal), cornerRadius: cornerRadius)
    }
    
    // MARK: - Legacy Glass (Backward Compatibility)
    
    /// Applies a frosted glass background (legacy)
    func glass(cornerRadius: CGFloat = 16) -> some View {
        modifier(GlassModifier(cornerRadius: cornerRadius))
    }
    
    /// Applies a glass card style with subtle border (legacy)
    func glassCard(cornerRadius: CGFloat = 16) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }
}

// MARK: - Liquid Glass Container

/// Container for combining multiple Liquid Glass effects
/// Allows glass shapes to morph and blend into each other
@available(iOS 26.0, *)
struct SignalsGlassContainer<Content: View>: View {
    let spacing: CGFloat
    let content: Content
    
    init(spacing: CGFloat = 20, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }
    
    var body: some View {
        GlassEffectContainer(spacing: spacing) {
            content
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        // Background gradient
        LinearGradient(
            colors: [.purple, .blue, .cyan],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        VStack(spacing: 24) {
            // Liquid Glass
            VStack(spacing: 8) {
                Text("Liquid Glass")
                    .font(Typography.headline)
                Text("iOS 26+ modern effect")
                    .font(Typography.caption)
            }
            .padding(24)
            .liquidGlass()
            
            // Liquid Glass with tint
            VStack(spacing: 8) {
                Text("Tinted Glass")
                    .font(Typography.headline)
                Text("With accent color")
                    .font(Typography.caption)
            }
            .padding(24)
            .liquidGlass(tint: .purple.opacity(0.2))
            
            // Capsule glass button
            HStack(spacing: 16) {
                Label("Steps", systemImage: "figure.walk")
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .liquidGlassCapsule(tint: ColorPalette.steps.opacity(0.15))
                
                Label("Sleep", systemImage: "bed.double")
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .liquidGlassCapsule(tint: ColorPalette.sleep.opacity(0.15))
            }
            
            // Legacy glass card
            VStack(spacing: 8) {
                Text("Legacy Glass")
                    .font(Typography.headline)
                Text("Material-based fallback")
                    .font(Typography.caption)
            }
            .padding(24)
            .glassCard()
        }
        .padding()
    }
}
