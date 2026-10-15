//
//  GradientCard.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import SwiftUI

/// Reusable gradient card component
struct GradientCard<Content: View>: View {
    let gradient: LinearGradient
    let cornerRadius: CGFloat
    @ViewBuilder let content: Content
    
    init(
        gradient: LinearGradient = ColorPalette.primaryGradient,
        cornerRadius: CGFloat = 16,
        @ViewBuilder content: () -> Content
    ) {
        self.gradient = gradient
        self.cornerRadius = cornerRadius
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(gradient)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

/// Preset gradient cards for common uses
struct InsightGradientCard<Content: View>: View {
    @ViewBuilder let content: Content
    
    var body: some View {
        GradientCard(
            gradient: LinearGradient(
                colors: [.purple.opacity(0.8), .blue.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            content: { content }
        )
    }
}

struct AccentGradientCard<Content: View>: View {
    @ViewBuilder let content: Content
    
    var body: some View {
        GradientCard(
            gradient: LinearGradient(
                colors: [ColorPalette.accent.opacity(0.8), ColorPalette.accent.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            content: { content }
        )
    }
}

struct SubtleGradientCard<Content: View>: View {
    @ViewBuilder let content: Content
    
    var body: some View {
        GradientCard(
            gradient: LinearGradient(
                colors: [
                    ColorPalette.secondaryBackground,
                    ColorPalette.tertiaryBackground
                ],
                startPoint: .top,
                endPoint: .bottom
            ),
            content: { content }
        )
    }
}

/// Liquid Glass card for iOS 26+ with beautiful glass effects
struct LiquidGlassCard<Content: View>: View {
    var tint: Color?
    var cornerRadius: CGFloat
    var isInteractive: Bool
    @ViewBuilder let content: Content
    
    init(
        tint: Color? = nil,
        cornerRadius: CGFloat = CornerRadius.standard,
        isInteractive: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.tint = tint
        self.cornerRadius = cornerRadius
        self.isInteractive = isInteractive
        self.content = content()
    }
    
    var body: some View {
        content
            .cardPadding()
            .liquidGlass(tint: tint, isInteractive: isInteractive, cornerRadius: cornerRadius)
    }
}

/// Signal-specific Liquid Glass card
struct SignalGlassCard<Content: View>: View {
    let signal: SignalType
    @ViewBuilder let content: Content
    
    var body: some View {
        LiquidGlassCard(
            tint: ColorPalette.glassTint(for: signal),
            content: { content }
        )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        LinearGradient(
            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        ScrollView {
            VStack(spacing: Spacing.standard) {
                GradientCard {
                    VStack(alignment: .leading) {
                        Text("Default Gradient")
                            .font(Typography.headline)
                            .foregroundStyle(.white)
                        Text("With primary gradient")
                            .font(Typography.caption)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                InsightGradientCard {
                    Text("Insight Card")
                        .font(Typography.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                AccentGradientCard {
                    Text("Accent Card")
                        .font(Typography.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                SubtleGradientCard {
                    Text("Subtle Card")
                        .font(Typography.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                LiquidGlassCard {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Liquid Glass Card")
                            .font(Typography.headline)
                        Text("Beautiful iOS 26+ glass effect")
                            .font(Typography.caption)
                            .foregroundStyle(ColorPalette.secondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                LiquidGlassCard(tint: .purple.opacity(0.15)) {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Tinted Glass")
                            .font(Typography.headline)
                        Text("With purple tint")
                            .font(Typography.caption)
                            .foregroundStyle(ColorPalette.secondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                SignalGlassCard(signal: .steps) {
                    HStack {
                        Image(systemName: "figure.walk")
                            .font(.title2)
                            .foregroundStyle(ColorPalette.steps)
                        VStack(alignment: .leading) {
                            Text("8,432 steps")
                                .font(Typography.headline)
                            Text("Today's progress")
                                .font(Typography.caption)
                                .foregroundStyle(ColorPalette.secondaryText)
                        }
                        Spacer()
                    }
                }
            }
            .padding()
        }
    }
}
