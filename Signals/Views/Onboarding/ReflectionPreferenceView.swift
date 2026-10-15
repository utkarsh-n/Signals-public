//
//  ReflectionPreferenceView.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import SwiftUI

/// Screen for setting reflection reminder preferences
struct ReflectionPreferenceView: View {
    @Bindable var onboardingManager: OnboardingStateManager
    
    @State private var showContent = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(ColorPalette.reflection.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "pencil.and.outline")
                    .font(.system(size: 44))
                    .foregroundStyle(ColorPalette.reflection)
            }
            .opacity(showContent ? 1 : 0)
            .scaleEffect(showContent ? 1 : 0.8)
            
            Spacer()
                .frame(height: 40)
            
            // Header
            VStack(spacing: 16) {
                Text("Quick reflections")
                    .font(Typography.title)
                
                Text("Would you like gentle reminders to write a quick thought each day?")
                    .font(Typography.body)
                    .foregroundStyle(ColorPalette.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .opacity(showContent ? 1 : 0)
            
            Spacer()
                .frame(height: 40)
            
            // Options
            VStack(spacing: 12) {
                ForEach(ReflectionFrequency.allCases, id: \.self) { frequency in
                    ReflectionOptionCard(
                        frequency: frequency,
                        isSelected: onboardingManager.reflectionPreference == frequency,
                        onSelect: {
                            onboardingManager.reflectionPreference = frequency
                            Haptics.selection()
                        }
                    )
                }
            }
            .padding(.horizontal, 30)
            .opacity(showContent ? 1 : 0)
            
            Spacer()
            
            // Continue button
            OnboardingButton(title: "Continue") {
                onboardingManager.goToNext()
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
            .opacity(showContent ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
        }
    }
}

struct ReflectionOptionCard: View {
    let frequency: ReflectionFrequency
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(frequency.displayName)
                        .font(Typography.headline)
                        .foregroundStyle(ColorPalette.primaryText)
                    
                    Text(descriptionFor(frequency))
                        .font(Typography.caption)
                        .foregroundStyle(ColorPalette.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundStyle(isSelected ? ColorPalette.reflection : ColorPalette.tertiaryText)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected 
                          ? ColorPalette.reflection.opacity(0.1) 
                          : ColorPalette.secondaryBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? ColorPalette.reflection : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    private func descriptionFor(_ frequency: ReflectionFrequency) -> String {
        switch frequency {
        case .daily:
            return "Get a gentle nudge each evening"
        case .sometimes:
            return "Occasional reminders, not every day"
        case .never:
            return "I'll write when I feel like it"
        }
    }
}

#Preview {
    ReflectionPreferenceView(onboardingManager: OnboardingStateManager())
}
