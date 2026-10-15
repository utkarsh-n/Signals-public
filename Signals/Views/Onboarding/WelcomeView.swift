//
//  WelcomeView.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import SwiftUI

/// First onboarding screen with animated signal visualization
struct WelcomeView: View {
    @Bindable var onboardingManager: OnboardingStateManager
    
    @State private var showContent = false
    @State private var animateSignals = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Animated signal visualization
            SignalVisualization(isAnimating: $animateSignals)
                .frame(height: 200)
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.8)
            
            Spacer()
                .frame(height: 40)
            
            // App name and tagline
            VStack(spacing: 16) {
                Text("Signals")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(ColorPalette.primaryGradient)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                
                Text("Your life, noticed.")
                    .font(Typography.title3)
                    .foregroundStyle(ColorPalette.secondaryText)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
            }
            
            Spacer()
            
            // Get started button
            OnboardingButton(title: "Get Started") {
                onboardingManager.goToNext()
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                showContent = true
            }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true).delay(0.5)) {
                animateSignals = true
            }
        }
    }
}

/// Animated signal visualization for welcome screen
struct SignalVisualization: View {
    @Binding var isAnimating: Bool
    
    private let signalColors: [Color] = [.purple, .blue, .cyan, .teal, .green]
    
    var body: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [.purple.opacity(0.3), .blue.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .frame(width: 180, height: 180)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
            
            // Middle ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [.purple.opacity(0.5), .blue.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .frame(width: 120, height: 120)
                .scaleEffect(isAnimating ? 1.05 : 0.95)
            
            // Center icon
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(ColorPalette.primaryGradient)
                .scaleEffect(isAnimating ? 1.1 : 0.9)
            
            // Orbiting signal dots
            ForEach(0..<5, id: \.self) { index in
                SignalDot(
                    color: signalColors[index],
                    angle: Double(index) * (360.0 / 5.0),
                    radius: 80,
                    isAnimating: isAnimating
                )
            }
        }
    }
}

struct SignalDot: View {
    let color: Color
    let angle: Double
    let radius: Double
    let isAnimating: Bool
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 12, height: 12)
            .shadow(color: color.opacity(0.5), radius: 4)
            .offset(
                x: cos((angle + (isAnimating ? 30 : 0)) * .pi / 180) * radius,
                y: sin((angle + (isAnimating ? 30 : 0)) * .pi / 180) * radius
            )
            .opacity(isAnimating ? 1 : 0.6)
    }
}

#Preview {
    WelcomeView(onboardingManager: OnboardingStateManager())
}
