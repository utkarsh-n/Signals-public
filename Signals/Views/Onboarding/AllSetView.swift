//
//  AllSetView.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import SwiftUI

/// Final onboarding screen with activation animation
struct AllSetView: View {
    @Bindable var onboardingManager: OnboardingStateManager
    let onComplete: () -> Void
    
    @State private var showContent = false
    @State private var animateSignals = false
    @State private var showButton = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Animated activation visualization
            ZStack {
                // Pulse rings
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(
                            Color.purple.opacity(0.3 - Double(index) * 0.1),
                            lineWidth: 2
                        )
                        .frame(
                            width: 100 + CGFloat(index) * 40,
                            height: 100 + CGFloat(index) * 40
                        )
                        .scaleEffect(animateSignals ? 1.2 : 1.0)
                        .opacity(animateSignals ? 0.3 : 0.8)
                        .animation(
                            .easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                            value: animateSignals
                        )
                }
                
                // Center circle
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "waveform")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(.white)
                }
                .scaleEffect(showContent ? 1 : 0)
                
                // Orbiting signal dots
                ForEach(Array(onboardingManager.selectedSignals.enumerated()), id: \.element) { index, signal in
                    SignalActivationDot(
                        signal: signal,
                        angle: Double(index) * (360.0 / Double(onboardingManager.selectedSignals.count)),
                        isAnimating: animateSignals
                    )
                }
            }
            .frame(height: 220)
            .opacity(showContent ? 1 : 0)
            
            Spacer()
                .frame(height: 40)
            
            // Message
            VStack(spacing: 16) {
                Text("Signals is now listening")
                    .font(Typography.title)
                    .opacity(showContent ? 1 : 0)
                
                Text("Your first weekly insight arrives in 7 days")
                    .font(Typography.body)
                    .foregroundStyle(ColorPalette.secondaryText)
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1 : 0)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
                .frame(height: 20)
            
            // Active signals list
            VStack(spacing: 8) {
                ForEach(Array(onboardingManager.selectedSignals), id: \.self) { signal in
                    ActiveSignalRow(signal: signal, isActive: animateSignals)
                }
            }
            .padding(.horizontal, 40)
            .opacity(showContent ? 1 : 0)
            
            Spacer()
            
            // Enter app button
            OnboardingButton(title: "Enter Signals") {
                Haptics.success()
                onComplete()
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
            .opacity(showButton ? 1 : 0)
            .offset(y: showButton ? 0 : 20)
        }
        .onAppear {
            // Staggered animations
            withAnimation(.easeOut(duration: 0.6)) {
                showContent = true
            }
            
            withAnimation(.easeInOut(duration: 1).delay(0.3)) {
                animateSignals = true
            }
            
            withAnimation(.easeOut(duration: 0.4).delay(0.8)) {
                showButton = true
            }
        }
    }
}

struct SignalActivationDot: View {
    let signal: SignalType
    let angle: Double
    let isAnimating: Bool
    
    private let radius: CGFloat = 90
    
    var body: some View {
        ZStack {
            Circle()
                .fill(ColorPalette.color(for: signal))
                .frame(width: 16, height: 16)
            
            Circle()
                .fill(ColorPalette.color(for: signal).opacity(0.3))
                .frame(width: 24, height: 24)
                .scaleEffect(isAnimating ? 1.5 : 1)
                .opacity(isAnimating ? 0 : 1)
                .animation(
                    .easeOut(duration: 1)
                    .repeatForever(autoreverses: false),
                    value: isAnimating
                )
        }
        .offset(
            x: cos((angle + (isAnimating ? 10 : 0)) * .pi / 180) * radius,
            y: sin((angle + (isAnimating ? 10 : 0)) * .pi / 180) * radius
        )
        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
    }
}

struct ActiveSignalRow: View {
    let signal: SignalType
    let isActive: Bool
    
    @State private var showRow = false
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(ColorPalette.color(for: signal).opacity(0.2))
                    .frame(width: 32, height: 32)
                
                Image(systemName: signal.icon)
                    .font(.system(size: 14))
                    .foregroundStyle(ColorPalette.color(for: signal))
            }
            
            Text(signal.displayName)
                .font(Typography.body)
                .foregroundStyle(ColorPalette.primaryText)
            
            Spacer()
            
            // Animated status indicator
            HStack(spacing: 4) {
                Circle()
                    .fill(isActive ? .green : ColorPalette.tertiaryText)
                    .frame(width: 8, height: 8)
                
                Text(isActive ? "Active" : "...")
                    .font(Typography.caption)
                    .foregroundStyle(isActive ? .green : ColorPalette.tertiaryText)
            }
        }
        .padding(.vertical, 8)
        .opacity(showRow ? 1 : 0)
        .offset(x: showRow ? 0 : -20)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4).delay(Double.random(in: 0.1...0.5))) {
                showRow = true
            }
        }
    }
}

#Preview {
    AllSetView(onboardingManager: {
        let manager = OnboardingStateManager()
        manager.selectedSignals = [.steps, .sleep, .screenTime, .location]
        return manager
    }(), onComplete: {})
}
