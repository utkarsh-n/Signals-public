//
//  FadeInModifier.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import SwiftUI

/// Staggered fade-in animation modifier
struct FadeInModifier: ViewModifier {
    var delay: Double = 0
    var duration: Double = 0.3
    var offset: CGFloat = 20
    
    @State private var isVisible = false
    
    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : offset)
            .onAppear {
                withAnimation(.easeOut(duration: duration).delay(delay)) {
                    isVisible = true
                }
            }
    }
}

/// Fade in from a specific direction
struct DirectionalFadeInModifier: ViewModifier {
    enum Direction {
        case top, bottom, leading, trailing
    }
    
    var direction: Direction = .bottom
    var delay: Double = 0
    var duration: Double = 0.3
    var distance: CGFloat = 20
    
    @State private var isVisible = false
    
    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(x: xOffset, y: yOffset)
            .onAppear {
                withAnimation(.easeOut(duration: duration).delay(delay)) {
                    isVisible = true
                }
            }
    }
    
    private var xOffset: CGFloat {
        guard !isVisible else { return 0 }
        switch direction {
        case .leading: return -distance
        case .trailing: return distance
        default: return 0
        }
    }
    
    private var yOffset: CGFloat {
        guard !isVisible else { return 0 }
        switch direction {
        case .top: return -distance
        case .bottom: return distance
        default: return 0
        }
    }
}

/// Scale fade in modifier
struct ScaleFadeInModifier: ViewModifier {
    var delay: Double = 0
    var duration: Double = 0.3
    var initialScale: CGFloat = 0.8
    
    @State private var isVisible = false
    
    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : initialScale)
            .onAppear {
                withAnimation(.spring(response: duration, dampingFraction: 0.7).delay(delay)) {
                    isVisible = true
                }
            }
    }
}

extension View {
    /// Applies a fade-in animation with vertical offset
    func fadeIn(delay: Double = 0, duration: Double = 0.3, offset: CGFloat = 20) -> some View {
        modifier(FadeInModifier(delay: delay, duration: duration, offset: offset))
    }
    
    /// Applies a fade-in animation from a specific direction
    func fadeIn(from direction: DirectionalFadeInModifier.Direction, delay: Double = 0, duration: Double = 0.3, distance: CGFloat = 20) -> some View {
        modifier(DirectionalFadeInModifier(direction: direction, delay: delay, duration: duration, distance: distance))
    }
    
    /// Applies a scale fade-in animation
    func scaleFadeIn(delay: Double = 0, duration: Double = 0.3, initialScale: CGFloat = 0.8) -> some View {
        modifier(ScaleFadeInModifier(delay: delay, duration: duration, initialScale: initialScale))
    }
    
    /// Applies staggered fade-in to a collection of views
    func staggeredFadeIn(index: Int, baseDelay: Double = 0, stagger: Double = 0.05) -> some View {
        fadeIn(delay: baseDelay + Double(index) * stagger)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 24) {
        // Basic fade in
        Text("Fade In")
            .font(Typography.headline)
            .fadeIn()
        
        // Directional fade ins
        HStack(spacing: 16) {
            Text("Left")
                .padding()
                .background(ColorPalette.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .fadeIn(from: .leading, delay: 0.2)
            
            Text("Right")
                .padding()
                .background(ColorPalette.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .fadeIn(from: .trailing, delay: 0.4)
        }
        
        // Scale fade in
        Circle()
            .fill(ColorPalette.accent)
            .frame(width: 60, height: 60)
            .scaleFadeIn(delay: 0.6)
        
        // Staggered
        VStack(spacing: 8) {
            ForEach(0..<5, id: \.self) { index in
                Text("Item \(index + 1)")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(ColorPalette.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .staggeredFadeIn(index: index, baseDelay: 0.8)
            }
        }
    }
    .padding()
}
