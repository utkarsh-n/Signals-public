//
//  ActiveSignalsView.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import SwiftUI

/// Shows which signals are actively collecting data
struct ActiveSignalsView: View {
    private let enabledSignals = Array(UserSettings.shared.enabledSignals)
    
    @State private var animateIndicators = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Active Signals")
                    .font(Typography.subheadline)
                    .foregroundStyle(ColorPalette.secondaryText)
                
                Spacer()
                
                // Status indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(.green)
                        .frame(width: 6, height: 6)
                        .opacity(animateIndicators ? 1 : 0.5)
                    
                    Text("Collecting")
                        .font(Typography.caption2)
                        .foregroundStyle(ColorPalette.tertiaryText)
                }
            }
            
            // Signal indicators
            HStack(spacing: 12) {
                ForEach(enabledSignals, id: \.self) { signal in
                    SignalBadge(
                        signal: signal,
                        isActive: true,
                        animate: animateIndicators
                    )
                }
                
                Spacer()
            }
        }
        .padding(16)
        .background(ColorPalette.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                animateIndicators = true
            }
        }
    }
}

/// Badge showing signal icon with name (larger than SignalIndicator dot)
private struct SignalBadge: View {
    let signal: SignalType
    let isActive: Bool
    var animate: Bool = false
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                // Pulse ring when active
                if isActive && animate {
                    Circle()
                        .stroke(ColorPalette.color(for: signal).opacity(0.3), lineWidth: 2)
                        .frame(width: 40, height: 40)
                        .scaleEffect(animate ? 1.3 : 1.0)
                        .opacity(animate ? 0 : 0.5)
                }
                
                Circle()
                    .fill(ColorPalette.color(for: signal).opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Image(systemName: signal.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(ColorPalette.color(for: signal))
            }
            
            Text(signal.displayName)
                .font(.system(size: 9))
                .foregroundStyle(ColorPalette.tertiaryText)
                .lineLimit(1)
        }
        .frame(width: 50)
    }
}

// MARK: - Preview

#Preview {
    ActiveSignalsView()
        .padding()
}
