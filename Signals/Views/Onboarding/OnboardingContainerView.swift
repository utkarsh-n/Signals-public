//
//  OnboardingContainerView.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import SwiftUI

/// Container view that manages the onboarding flow
struct OnboardingContainerView: View {
    @Environment(AppState.self) private var appState
    @State private var onboardingManager = OnboardingStateManager()
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color.purple.opacity(0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress indicator
                if onboardingManager.currentStep != .welcome && 
                   onboardingManager.currentStep != .allSet {
                    ProgressView(value: onboardingManager.progress)
                        .tint(Color.purple)
                        .padding(.horizontal, 40)
                        .padding(.top, 8)
                }
                
                // Content
                TabView(selection: Binding(
                    get: { onboardingManager.currentStep },
                    set: { onboardingManager.goTo($0) }
                )) {
                    WelcomeView(onboardingManager: onboardingManager)
                        .tag(OnboardingStep.welcome)
                    
                    PhilosophyView(onboardingManager: onboardingManager)
                        .tag(OnboardingStep.philosophy)
                    
                    DataSourceSelectionView(onboardingManager: onboardingManager)
                        .tag(OnboardingStep.signalSelection)
                    
                    PermissionsView(onboardingManager: onboardingManager)
                        .tag(OnboardingStep.permissions)
                    
                    ReflectionPreferenceView(onboardingManager: onboardingManager)
                        .tag(OnboardingStep.reflectionPreference)
                    
                    TrialStartView(onboardingManager: onboardingManager)
                        .tag(OnboardingStep.trialStart)
                    
                    AllSetView(onboardingManager: onboardingManager) {
                        completeOnboarding()
                    }
                    .tag(OnboardingStep.allSet)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: onboardingManager.currentStep)
            }
        }
    }
    
    private func completeOnboarding() {
        onboardingManager.completeOnboarding()
        appState.completeOnboarding()
    }
}

// MARK: - Shared Components

struct OnboardingButton: View {
    let title: String
    let action: () -> Void
    var isEnabled: Bool = true
    var style: ButtonStyle = .primary
    
    enum ButtonStyle {
        case primary
        case secondary
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Typography.headline)
                .foregroundStyle(style == .primary ? .white : ColorPalette.primaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    Group {
                        if style == .primary {
                            ColorPalette.primaryGradient
                        } else {
                            Color.clear
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(style == .secondary ? ColorPalette.secondaryText.opacity(0.3) : .clear, lineWidth: 1)
                )
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.5)
    }
}

struct OnboardingHeader: View {
    let title: String
    let subtitle: String?
    
    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(Typography.title)
                .multilineTextAlignment(.center)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(Typography.body)
                    .foregroundStyle(ColorPalette.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

#Preview {
    OnboardingContainerView()
        .environment(AppState())
}
