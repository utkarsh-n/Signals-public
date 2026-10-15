//
//  TrialStartView.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import SwiftUI

/// Screen explaining the trial and showing selected signals summary
struct TrialStartView: View {
    @Bindable var onboardingManager: OnboardingStateManager
    
    @State private var showContent = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Trial badge
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple.opacity(0.2), .blue.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                    
                    Text("7")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(ColorPalette.primaryGradient)
                }
                
                Text("days free")
                    .font(Typography.headline)
                    .foregroundStyle(ColorPalette.secondaryText)
            }
            .opacity(showContent ? 1 : 0)
            .scaleEffect(showContent ? 1 : 0.8)
            
            Spacer()
                .frame(height: 40)
            
            // Header
            VStack(spacing: 16) {
                Text("Your free trial starts now")
                    .font(Typography.title)
                
                Text("Full access to all features for 7 days, then $9.99/year")
                    .font(Typography.body)
                    .foregroundStyle(ColorPalette.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .opacity(showContent ? 1 : 0)
            
            Spacer()
                .frame(height: 30)
            
            // Selected signals summary
            VStack(alignment: .leading, spacing: 12) {
                Text("Your signals")
                    .font(Typography.subheadline)
                    .foregroundStyle(ColorPalette.secondaryText)
                
                FlowLayout(spacing: 8) {
                    ForEach(Array(onboardingManager.selectedSignals), id: \.self) { signal in
                        SignalChip(signal: signal)
                    }
                }
            }
            .padding(.horizontal, 40)
            .opacity(showContent ? 1 : 0)
            
            Spacer()
            
            // What's included
            VStack(alignment: .leading, spacing: 12) {
                TrialFeatureRow(icon: "lightbulb.fill", text: "Weekly pattern insights")
                TrialFeatureRow(icon: "calendar", text: "Full timeline history")
                TrialFeatureRow(icon: "square.and.arrow.up", text: "Data export")
                TrialFeatureRow(icon: "bell.fill", text: "Smart notifications")
            }
            .padding(.horizontal, 40)
            .opacity(showContent ? 1 : 0)
            
            Spacer()
            
            // Start trial button
            VStack(spacing: 12) {
                OnboardingButton(title: "Start Free Trial") {
                    onboardingManager.goToNext()
                }
                
                Text("Cancel anytime. No commitment.")
                    .font(Typography.caption)
                    .foregroundStyle(ColorPalette.tertiaryText)
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

struct SignalChip: View {
    let signal: SignalType
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: signal.icon)
                .font(.system(size: 12))
            Text(signal.displayName)
                .font(Typography.caption)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(ColorPalette.color(for: signal).opacity(0.15))
        .foregroundStyle(ColorPalette.color(for: signal))
        .clipShape(Capsule())
    }
}

struct TrialFeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.purple)
                .frame(width: 24)
            
            Text(text)
                .font(Typography.body)
                .foregroundStyle(ColorPalette.primaryText)
            
            Spacer()
        }
    }
}

/// Simple flow layout for signal chips
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > width && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
                
                self.size.width = max(self.size.width, x)
            }
            
            self.size.height = y + rowHeight
        }
    }
}

#Preview {
    TrialStartView(onboardingManager: {
        let manager = OnboardingStateManager()
        manager.selectedSignals = [.steps, .sleep, .screenTime, .location]
        return manager
    }())
}
