//
//  AnimatedRing.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import SwiftUI

/// Circular data visualization component with animation
struct AnimatedRing: View {
    let progress: Double // 0.0 to 1.0
    var color: Color = ColorPalette.accent
    var lineWidth: CGFloat = 8
    var size: CGFloat = 100
    var showPercentage: Bool = true
    var animate: Bool = true
    
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            
            // Center content
            if showPercentage {
                Text("\(Int(animatedProgress * 100))%")
                    .font(Typography.metric)
                    .foregroundStyle(ColorPalette.primaryText)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            if animate {
                withAnimation(.easeOut(duration: 1.0)) {
                    animatedProgress = progress
                }
            } else {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            if animate {
                withAnimation(.easeOut(duration: 0.5)) {
                    animatedProgress = newValue
                }
            } else {
                animatedProgress = newValue
            }
        }
    }
}

/// Multiple ring visualization
struct MultiRing: View {
    let rings: [(progress: Double, color: Color, label: String)]
    var lineWidth: CGFloat = 8
    var size: CGFloat = 120
    var spacing: CGFloat = 12
    
    var body: some View {
        ZStack {
            ForEach(rings.indices.reversed(), id: \.self) { index in
                let ringSize = size - CGFloat(index) * spacing * 2
                
                AnimatedRing(
                    progress: rings[index].progress,
                    color: rings[index].color,
                    lineWidth: lineWidth,
                    size: ringSize,
                    showPercentage: false
                )
            }
        }
        .frame(width: size, height: size)
    }
}

/// Ring with icon in center
struct IconRing: View {
    let progress: Double
    let icon: String
    var color: Color = ColorPalette.accent
    var lineWidth: CGFloat = 6
    var size: CGFloat = 60
    
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            
            // Icon
            Image(systemName: icon)
                .font(.system(size: size * 0.3))
                .foregroundStyle(color)
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animatedProgress = progress
            }
        }
    }
}

/// Activity ring similar to Apple Watch style
struct ActivityRing: View {
    let move: Double // 0-1
    let exercise: Double // 0-1
    let stand: Double // 0-1
    var size: CGFloat = 100
    
    var body: some View {
        MultiRing(
            rings: [
                (move, .red, "Move"),
                (exercise, .green, "Exercise"),
                (stand, .cyan, "Stand")
            ],
            lineWidth: size * 0.08,
            size: size,
            spacing: size * 0.1
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 32) {
        HStack(spacing: 24) {
            AnimatedRing(progress: 0.75, color: ColorPalette.steps)
            AnimatedRing(progress: 0.5, color: ColorPalette.sleep, showPercentage: false)
        }
        
        MultiRing(rings: [
            (0.8, ColorPalette.steps, "Steps"),
            (0.6, ColorPalette.exercise, "Exercise"),
            (0.9, ColorPalette.sleep, "Sleep")
        ])
        
        HStack(spacing: 16) {
            IconRing(progress: 0.7, icon: "figure.walk", color: ColorPalette.steps)
            IconRing(progress: 0.5, icon: "moon.fill", color: ColorPalette.sleep)
            IconRing(progress: 0.3, icon: "flame.fill", color: ColorPalette.exercise)
        }
        
        ActivityRing(move: 0.8, exercise: 0.6, stand: 0.9)
    }
    .padding()
}
