//
//  PromptView.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import SwiftUI
import SwiftData

/// View displaying AI-generated reflection prompts based on recent data
struct PromptView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \DailySnapshot.date, order: .reverse)
    private var recentSnapshots: [DailySnapshot]
    
    @State private var currentPromptIndex = 0
    @State private var isAnimating = false
    @State private var showingPaywall = false
    
    var onPromptSelected: ((String) -> Void)? = nil
    
    /// Whether personalized prompts are available (premium feature)
    private var hasPersonalizedPrompts: Bool {
        PaywallManager.shared.canAccess(.viewReflectionPrompts)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(ColorPalette.accent)
                
                Text("Reflection Prompts")
                    .font(Typography.headline)
                    .foregroundStyle(ColorPalette.primaryText)
                
                if !hasPersonalizedPrompts {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(ColorPalette.tertiaryText)
                }
                
                Spacer()
                
                Button(action: nextPrompt) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.body)
                        .foregroundStyle(ColorPalette.accent)
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))
                }
                .buttonStyle(.plain)
            }
            
            // Current prompt - personalized or default based on subscription
            if hasPersonalizedPrompts && !availablePrompts.isEmpty {
                PromptCard(
                    prompt: availablePrompts[currentPromptIndex % availablePrompts.count],
                    onSelect: {
                        onPromptSelected?(availablePrompts[currentPromptIndex % availablePrompts.count])
                    }
                )
            } else {
                // Free users see default prompts with upgrade prompt
                VStack(spacing: 12) {
                    PromptCard(
                        prompt: defaultPrompts[currentPromptIndex % defaultPrompts.count],
                        onSelect: {
                            onPromptSelected?(defaultPrompts[currentPromptIndex % defaultPrompts.count])
                        }
                    )
                    
                    if !hasPersonalizedPrompts && !recentSnapshots.isEmpty {
                        // Show upgrade hint if there's data that could generate personalized prompts
                        Button {
                            showingPaywall = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                    .font(.caption)
                                Text("Unlock personalized prompts based on your data")
                                    .font(Typography.caption)
                            }
                            .foregroundStyle(ColorPalette.accent)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(ColorPalette.accent.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding()
        .background(ColorPalette.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }
    
    // MARK: - Prompts
    
    private var availablePrompts: [String] {
        var prompts: [String] = []
        
        guard let todaySnapshot = recentSnapshots.first else {
            return defaultPrompts
        }
        
        // Steps-based prompts
        if let steps = todaySnapshot.stepCount {
            if steps > 8000 {
                prompts.append("You walked a lot today. Where did you go?")
            } else if steps < 3000 {
                prompts.append("It was a quiet day for movement. How are you feeling?")
            }
        }
        
        // Sleep-based prompts
        if let sleep = todaySnapshot.sleepHours {
            if sleep > 8 {
                prompts.append("You slept really well last night. Did you do anything differently?")
            } else if sleep < 6 {
                prompts.append("Sleep was short last night. What kept you up?")
            }
        }
        
        // Screen time prompts
        if let screenTime = todaySnapshot.screenTimeMinutes {
            if screenTime > 240 {
                prompts.append("Your screen time was high today. What were you doing?")
            }
        }
        
        // Location-based prompts
        if let clusters = todaySnapshot.locationClusters {
            if clusters.contains(where: { $0.isNew }) {
                prompts.append("You visited somewhere new today. How was it?")
            }
            if !clusters.contains(where: { $0.label.lowercased() == "home" }) {
                prompts.append("You were out and about today. What was the highlight?")
            }
        }
        
        // Weather-based prompts
        if let weather = todaySnapshot.weatherCondition {
            switch weather {
            case .rainy, .stormy:
                prompts.append("It's been a gray day. How has the weather affected your mood?")
            case .clear:
                prompts.append("Beautiful weather today! Did you get to enjoy it?")
            default:
                break
            }
        }
        
        // Day-of-week prompts
        let weekday = Calendar.current.component(.weekday, from: Date())
        if weekday == 1 { // Sunday
            prompts.append("Sunday reflection: What are you grateful for this week?")
        } else if weekday == 2 { // Monday
            prompts.append("New week ahead. What's one thing you're looking forward to?")
        } else if weekday == 6 { // Friday
            prompts.append("Week's almost done. What went well?")
        }
        
        // Comparison prompts
        if recentSnapshots.count >= 2 {
            let yesterday = recentSnapshots[1]
            
            if let todaySteps = todaySnapshot.stepCount,
               let yesterdaySteps = yesterday.stepCount,
               abs(todaySteps - yesterdaySteps) > 5000 {
                prompts.append("What made today different from yesterday?")
            }
        }
        
        // Weekly pattern prompts
        if recentSnapshots.count >= 7 {
            prompts.append("Looking back at your week, what stands out?")
        }
        
        // Add some default prompts if we don't have enough contextual ones
        if prompts.count < 3 {
            prompts.append(contentsOf: defaultPrompts.prefix(3 - prompts.count))
        }
        
        return prompts
    }
    
    private var defaultPrompts: [String] {
        [
            "What's on your mind right now?",
            "What's one good thing that happened today?",
            "What are you looking forward to?",
            "How would you describe your energy level today?",
            "What made you smile recently?",
            "What's something you learned today?",
            "What would make tomorrow a good day?",
            "What are you grateful for?",
            "What's been taking up your mental space lately?",
            "How are you really feeling?"
        ]
    }
    
    private func nextPrompt() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            isAnimating = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            currentPromptIndex += 1
            Haptics.selection()
            
            withAnimation {
                isAnimating = false
            }
        }
    }
}

// MARK: - Prompt Card

struct PromptCard: View {
    let prompt: String
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: {
            Haptics.light()
            onSelect()
        }) {
            HStack {
                Text(prompt)
                    .font(Typography.body)
                    .foregroundStyle(ColorPalette.primaryText)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(ColorPalette.tertiaryText)
            }
            .padding()
            .background(ColorPalette.tertiaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    PromptView()
        .padding()
        .modelContainer(PersistenceController.preview().container)
}
