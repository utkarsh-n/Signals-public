//
//  SignalIndicator.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import SwiftUI

/// Animated signal dot showing active tracking status
struct SignalIndicator: View {
    let signal: SignalType
    let isActive: Bool
    var size: CGFloat = 12
    var showPulse: Bool = true
    
    @State private var isPulsing = false
    
    var body: some View {
        ZStack {
            // Pulse ring (when active)
            if isActive && showPulse {
                Circle()
                    .stroke(ColorPalette.color(for: signal).opacity(0.3), lineWidth: 2)
                    .frame(width: size * 2, height: size * 2)
                    .scaleEffect(isPulsing ? 1.5 : 1.0)
                    .opacity(isPulsing ? 0 : 0.5)
            }
            
            // Main dot
            Circle()
                .fill(isActive ? ColorPalette.color(for: signal) : ColorPalette.tertiaryText)
                .frame(width: size, height: size)
        }
        .onAppear {
            if isActive && showPulse {
                withAnimation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    isPulsing = true
                }
            }
        }
    }
}

/// A row showing a signal with its indicator and name
struct SignalIndicatorRow: View {
    let signal: SignalType
    let isActive: Bool
    var showDescription: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            SignalIndicator(signal: signal, isActive: isActive)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(signal.displayName)
                    .font(Typography.body)
                    .foregroundStyle(isActive ? ColorPalette.primaryText : ColorPalette.secondaryText)
                
                if showDescription {
                    Text(signal.description)
                        .font(Typography.caption)
                        .foregroundStyle(ColorPalette.tertiaryText)
                }
            }
            
            Spacer()
            
            if isActive {
                Image(systemName: "checkmark")
                    .foregroundStyle(ColorPalette.color(for: signal))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 24) {
        HStack(spacing: 16) {
            SignalIndicator(signal: .steps, isActive: true)
            SignalIndicator(signal: .sleep, isActive: true)
            SignalIndicator(signal: .screenTime, isActive: false)
        }
        
        SignalIndicatorRow(signal: .steps, isActive: true, showDescription: true)
        SignalIndicatorRow(signal: .sleep, isActive: false, showDescription: true)
    }
    .padding()
}
