//
//  DataSourceSelectionView.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import SwiftUI

/// Screen for selecting which signals to track
struct DataSourceSelectionView: View {
    @Bindable var onboardingManager: OnboardingStateManager
    
    @State private var showContent = false
    
    // Group signals by category for display
    private let signalGroups: [(title: String, signals: [SignalType])] = [
        ("Health", [.steps, .sleep, .exercise, .heartRate]),
        ("Activity", [.screenTime, .motion]),
        ("Location", [.location]),
        ("Context", [.weather])
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            OnboardingHeader(
                "Choose your signals",
                subtitle: "Select at least 2 data sources for Signals to observe"
            )
            .padding(.top, 20)
            .padding(.horizontal, 20)
            .opacity(showContent ? 1 : 0)
            
            // Signal selection grid
            ScrollView {
                VStack(spacing: 24) {
                    ForEach(signalGroups, id: \.title) { group in
                        SignalGroupView(
                            title: group.title,
                            signals: group.signals,
                            selectedSignals: onboardingManager.selectedSignals,
                            onToggle: { signal in
                                onboardingManager.toggleSignal(signal)
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 30)
                .padding(.bottom, 20)
            }
            .opacity(showContent ? 1 : 0)
            
            // Selection count and hint
            VStack(spacing: 8) {
                Text("\(onboardingManager.selectedSignals.count) selected")
                    .font(Typography.headline)
                    .foregroundStyle(
                        onboardingManager.selectedSignals.count >= 2 
                        ? Color.green 
                        : ColorPalette.secondaryText
                    )
                
                if onboardingManager.selectedSignals.count < 2 {
                    Text("Select at least 2 to continue")
                        .font(Typography.caption)
                        .foregroundStyle(ColorPalette.tertiaryText)
                }
            }
            .padding(.vertical, 12)
            
            // Continue button
            OnboardingButton(
                title: "Continue",
                action: { onboardingManager.goToNext() },
                isEnabled: onboardingManager.canProceed
            )
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
        }
    }
}

struct SignalGroupView: View {
    let title: String
    let signals: [SignalType]
    let selectedSignals: Set<SignalType>
    let onToggle: (SignalType) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(Typography.subheadline)
                .foregroundStyle(ColorPalette.secondaryText)
                .padding(.leading, 4)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(signals, id: \.self) { signal in
                    SignalToggleCard(
                        signal: signal,
                        isSelected: selectedSignals.contains(signal),
                        onToggle: { onToggle(signal) }
                    )
                }
            }
        }
    }
}

struct SignalToggleCard: View {
    let signal: SignalType
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(isSelected 
                              ? ColorPalette.color(for: signal).opacity(0.2) 
                              : ColorPalette.tertiaryBackground)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: signal.icon)
                        .font(.system(size: 22))
                        .foregroundStyle(isSelected 
                                         ? ColorPalette.color(for: signal) 
                                         : ColorPalette.secondaryText)
                }
                
                Text(signal.displayName)
                    .font(Typography.caption)
                    .foregroundStyle(isSelected 
                                     ? ColorPalette.primaryText 
                                     : ColorPalette.secondaryText)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected 
                          ? ColorPalette.color(for: signal).opacity(0.1) 
                          : ColorPalette.secondaryBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected 
                            ? ColorPalette.color(for: signal) 
                            : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

#Preview {
    DataSourceSelectionView(onboardingManager: OnboardingStateManager())
}
