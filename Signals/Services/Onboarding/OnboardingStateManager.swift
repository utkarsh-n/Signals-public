//
//  OnboardingStateManager.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import Foundation
import SwiftUI

/// Manages the state and progress of the onboarding flow
@MainActor
@Observable
final class OnboardingStateManager {
    // MARK: - State
    
    var currentStep: OnboardingStep = .welcome
    var selectedSignals: Set<SignalType> = []
    var permissionResults: [PermissionGroup: PermissionStatus] = [:]
    var reflectionPreference: ReflectionFrequency = .sometimes
    var isAnimating = false
    
    // MARK: - Computed Properties
    
    var progress: Double {
        Double(currentStep.rawValue) / Double(OnboardingStep.allCases.count - 1)
    }
    
    var canProceed: Bool {
        switch currentStep {
        case .welcome, .philosophy:
            return true
        case .signalSelection:
            return selectedSignals.count >= 2
        case .permissions:
            return true // Can proceed even if permissions denied
        case .reflectionPreference:
            return true
        case .trialStart:
            return true
        case .allSet:
            return true
        }
    }
    
    var requiredPermissionGroups: [PermissionGroup] {
        var groups = Set<PermissionGroup>()
        for signal in selectedSignals {
            if signal.permissionGroup != .none {
                groups.insert(signal.permissionGroup)
            }
        }
        return Array(groups).sorted { $0.rawValue < $1.rawValue }
    }
    
    // MARK: - Navigation
    
    func goToNext() {
        guard canProceed else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            if let nextStep = OnboardingStep(rawValue: currentStep.rawValue + 1) {
                currentStep = nextStep
            }
        }
        
        Haptics.light()
    }
    
    func goToPrevious() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if let previousStep = OnboardingStep(rawValue: currentStep.rawValue - 1) {
                currentStep = previousStep
            }
        }
        
        Haptics.light()
    }
    
    func goTo(_ step: OnboardingStep) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = step
        }
    }
    
    // MARK: - Signal Selection
    
    func toggleSignal(_ signal: SignalType) {
        if selectedSignals.contains(signal) {
            selectedSignals.remove(signal)
        } else {
            selectedSignals.insert(signal)
        }
        Haptics.selection()
    }
    
    func isSignalSelected(_ signal: SignalType) -> Bool {
        selectedSignals.contains(signal)
    }
    
    // MARK: - Completion
    
    func completeOnboarding() {
        // Save selected signals
        UserSettings.shared.enabledSignals = selectedSignals
        
        // Save reflection preference
        switch reflectionPreference {
        case .daily:
            UserSettings.shared.reflectionRemindersEnabled = true
        case .sometimes:
            UserSettings.shared.reflectionRemindersEnabled = false
        case .never:
            UserSettings.shared.reflectionRemindersEnabled = false
        }
        
        // Mark onboarding complete
        UserSettings.shared.hasCompletedOnboarding = true
        
        // Start trial
        UserSettings.shared.subscriptionStatus = .trial
        UserSettings.shared.trialStartDate = Date()
        
        Haptics.success()
    }
    
    // MARK: - Reset
    
    func reset() {
        currentStep = .welcome
        selectedSignals = []
        permissionResults = [:]
        reflectionPreference = .sometimes
    }
}

// MARK: - Onboarding Steps

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case philosophy = 1
    case signalSelection = 2
    case permissions = 3
    case reflectionPreference = 4
    case trialStart = 5
    case allSet = 6
    
    var title: String {
        switch self {
        case .welcome: return "Welcome"
        case .philosophy: return "Philosophy"
        case .signalSelection: return "Choose Signals"
        case .permissions: return "Permissions"
        case .reflectionPreference: return "Reflections"
        case .trialStart: return "Start Trial"
        case .allSet: return "All Set"
        }
    }
    
    var showsBackButton: Bool {
        switch self {
        case .welcome: return false
        default: return true
        }
    }
    
    var showsSkipButton: Bool {
        switch self {
        case .permissions: return true
        default: return false
        }
    }
}
