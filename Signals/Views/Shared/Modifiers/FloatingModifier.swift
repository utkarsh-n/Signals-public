//
//  FloatingModifier.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import SwiftUI

/// Subtle floating animation modifier
struct FloatingModifier: ViewModifier {
    var amount: CGFloat = 5
    var duration: Double = 2.0
    
    @State private var isFloating = false
    
    func body(content: Content) -> some View {
        content
            .offset(y: isFloating ? -amount : amount)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                ) {
                    isFloating = true
                }
            }
    }
}

/// Pulse scale animation modifier
struct PulseModifier: ViewModifier {
    var minScale: CGFloat = 0.95
    var maxScale: CGFloat = 1.05
    var duration: Double = 1.5
    
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? maxScale : minScale)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                ) {
                    isPulsing = true
                }
            }
    }
}

/// Gentle breathing animation modifier
struct BreathingModifier: ViewModifier {
    var minOpacity: Double = 0.6
    var maxOpacity: Double = 1.0
    var duration: Double = 2.0
    
    @State private var isBreathing = false
    
    func body(content: Content) -> some View {
        content
            .opacity(isBreathing ? maxOpacity : minOpacity)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                ) {
                    isBreathing = true
                }
            }
    }
}

/// Rotation animation modifier
struct RotatingModifier: ViewModifier {
    var duration: Double = 3.0
    var clockwise: Bool = true
    
    @State private var rotation: Double = 0
    
    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(
                    .linear(duration: duration)
                    .repeatForever(autoreverses: false)
                ) {
                    rotation = clockwise ? 360 : -360
                }
            }
    }
}

extension View {
    /// Applies a subtle floating animation
    func floating(amount: CGFloat = 5, duration: Double = 2.0) -> some View {
        modifier(FloatingModifier(amount: amount, duration: duration))
    }
    
    /// Applies a pulse scale animation
    func pulsing(minScale: CGFloat = 0.95, maxScale: CGFloat = 1.05, duration: Double = 1.5) -> some View {
        modifier(PulseModifier(minScale: minScale, maxScale: maxScale, duration: duration))
    }
    
    /// Applies a breathing opacity animation
    func breathing(minOpacity: Double = 0.6, maxOpacity: Double = 1.0, duration: Double = 2.0) -> some View {
        modifier(BreathingModifier(minOpacity: minOpacity, maxOpacity: maxOpacity, duration: duration))
    }
    
    /// Applies a rotation animation
    func rotating(duration: Double = 3.0, clockwise: Bool = true) -> some View {
        modifier(RotatingModifier(duration: duration, clockwise: clockwise))
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 48) {
        // Floating
        VStack {
            Image(systemName: "cloud.fill")
                .font(.largeTitle)
                .foregroundStyle(.blue)
                .floating()
            Text("Floating")
                .font(Typography.caption)
        }
        
        // Pulsing
        VStack {
            Circle()
                .fill(ColorPalette.accent)
                .frame(width: 50, height: 50)
                .pulsing()
            Text("Pulsing")
                .font(Typography.caption)
        }
        
        // Breathing
        VStack {
            Image(systemName: "sparkles")
                .font(.largeTitle)
                .foregroundStyle(.yellow)
                .breathing()
            Text("Breathing")
                .font(Typography.caption)
        }
        
        // Rotating
        VStack {
            Image(systemName: "gear")
                .font(.largeTitle)
                .foregroundStyle(.gray)
                .rotating()
            Text("Rotating")
                .font(Typography.caption)
        }
    }
    .padding()
}
