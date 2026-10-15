//
//  SplashView.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import SwiftUI

/// Animated splash screen shown on app launch
struct SplashView: View {
    @State private var isAnimating = false
    @State private var showTagline = false
    @State private var signalPulses: [Bool] = Array(repeating: false, count: 5)
    
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    ColorPalette.background,
                    ColorPalette.background.opacity(0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Animated signal visualization
                ZStack {
                    // Outer pulse rings
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .stroke(
                                ColorPalette.accent.opacity(0.2 - Double(index) * 0.05),
                                lineWidth: 2
                            )
                            .frame(width: 120 + CGFloat(index) * 40, height: 120 + CGFloat(index) * 40)
                            .scaleEffect(isAnimating ? 1.3 : 0.8)
                            .opacity(isAnimating ? 0 : 0.8)
                            .animation(
                                .easeOut(duration: 2.0)
                                .repeatForever(autoreverses: false)
                                .delay(Double(index) * 0.3),
                                value: isAnimating
                            )
                    }
                    
                    // Signal dots orbiting
                    ForEach(0..<5, id: \.self) { index in
                        SplashSignalDot(
                            color: signalColor(for: index),
                            size: 12,
                            isPulsing: signalPulses[index]
                        )
                        .offset(y: -50)
                        .rotationEffect(.degrees(Double(index) * 72 + (isAnimating ? 360 : 0)))
                        .animation(
                            .linear(duration: 8)
                            .repeatForever(autoreverses: false),
                            value: isAnimating
                        )
                    }
                    
                    // Center logo area
                    ZStack {
                        Circle()
                            .fill(ColorPalette.accent.opacity(0.1))
                            .frame(width: 80, height: 80)
                        
                        Circle()
                            .fill(ColorPalette.accent.opacity(0.2))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "waveform.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(ColorPalette.accent)
                            .scaleEffect(isAnimating ? 1.1 : 1.0)
                            .animation(
                                .easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true),
                                value: isAnimating
                            )
                    }
                }
                .frame(height: 220)
                
                // App name
                Text("Signals")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(ColorPalette.primaryText)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 20)
                    .animation(.easeOut(duration: 0.8).delay(0.3), value: isAnimating)
                
                // Tagline
                Text("Your life, noticed.")
                    .font(Typography.body)
                    .foregroundStyle(ColorPalette.secondaryText)
                    .opacity(showTagline ? 1 : 0)
                    .offset(y: showTagline ? 0 : 10)
                    .animation(.easeOut(duration: 0.6), value: showTagline)
                
                Spacer()
                Spacer()
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func signalColor(for index: Int) -> Color {
        let colors: [Color] = [
            ColorPalette.accent,
            ColorPalette.secondary,
            ColorPalette.tertiary,
            ColorPalette.quaternary,
            ColorPalette.accent.opacity(0.7)
        ]
        return colors[index % colors.count]
    }
    
    private func startAnimations() {
        // Start main animation
        isAnimating = true
        
        // Stagger signal pulses
        for index in 0..<5 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.15) {
                signalPulses[index] = true
            }
        }
        
        // Show tagline
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            showTagline = true
        }
        
        // Complete after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            onComplete()
        }
    }
}

/// Individual signal dot with pulse effect for splash screen
private struct SplashSignalDot: View {
    let color: Color
    let size: CGFloat
    let isPulsing: Bool
    
    var body: some View {
        ZStack {
            // Pulse ring
            Circle()
                .stroke(color.opacity(0.4), lineWidth: 2)
                .frame(width: size * 2, height: size * 2)
                .scaleEffect(isPulsing ? 1.5 : 1.0)
                .opacity(isPulsing ? 0 : 0.6)
                .animation(
                    .easeOut(duration: 1.2)
                    .repeatForever(autoreverses: false),
                    value: isPulsing
                )
            
            // Dot
            Circle()
                .fill(color)
                .frame(width: size, height: size)
        }
    }
}

// MARK: - Preview

#Preview {
    SplashView {
        print("Splash complete")
    }
}
