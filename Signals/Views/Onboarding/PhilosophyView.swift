//
//  PhilosophyView.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import SwiftUI

/// Explains the app philosophy - no goals, no judgment, just awareness
struct PhilosophyView: View {
    @Bindable var onboardingManager: OnboardingStateManager
    
    @State private var showContent = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Icon
            Image(systemName: "eye.circle")
                .font(.system(size: 70))
                .foregroundStyle(ColorPalette.primaryGradient)
                .padding(.bottom, 30)
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.8)
            
            // Main message
            VStack(spacing: 24) {
                Text("Awareness, not judgment")
                    .font(Typography.title)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 20) {
                    PhilosophyPoint(
                        icon: "xmark.circle",
                        text: "No goals to hit",
                        delay: 0.2
                    )
                    
                    PhilosophyPoint(
                        icon: "xmark.circle",
                        text: "No streaks to maintain",
                        delay: 0.3
                    )
                    
                    PhilosophyPoint(
                        icon: "xmark.circle",
                        text: "No judgment or shame",
                        delay: 0.4
                    )
                }
                .padding(.vertical, 10)
                
                Text("Signals quietly observes your patterns and gently shows you what it notices. That's it.")
                    .font(Typography.body)
                    .foregroundStyle(ColorPalette.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)
            
            Spacer()
            
            // Quote
            VStack(spacing: 8) {
                Text("\"We don't track to judge.")
                    .font(Typography.body)
                    .italic()
                Text("We observe to help you see.\"")
                    .font(Typography.body)
                    .italic()
            }
            .foregroundStyle(ColorPalette.secondaryText)
            .opacity(showContent ? 0.8 : 0)
            .padding(.bottom, 30)
            
            // Continue button
            OnboardingButton(title: "Continue") {
                onboardingManager.goToNext()
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
            .opacity(showContent ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                showContent = true
            }
        }
    }
}

struct PhilosophyPoint: View {
    let icon: String
    let text: String
    let delay: Double
    
    @State private var show = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.red.opacity(0.7))
                .font(.system(size: 20))
            
            Text(text)
                .font(Typography.body)
                .foregroundStyle(ColorPalette.primaryText)
            
            Spacer()
        }
        .padding(.horizontal, 40)
        .opacity(show ? 1 : 0)
        .offset(x: show ? 0 : -20)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4).delay(delay)) {
                show = true
            }
        }
    }
}

#Preview {
    PhilosophyView(onboardingManager: OnboardingStateManager())
}
