//
//  InsightBubble.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import SwiftUI

/// Floating insight text bubble with Liquid Glass
struct InsightBubble: View {
    let text: String
    var category: InsightCategory? = nil
    var maxWidth: CGFloat = 280
    var showArrow: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Category badge (if provided)
            if let category {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: category.icon)
                        .font(.caption2)
                    Text(category.displayName)
                        .font(Typography.caption)
                }
                .foregroundStyle(ColorPalette.color(for: category))
            }
            
            // Text content
            Text(text)
                .font(Typography.body)
                .foregroundStyle(ColorPalette.primaryText)
                .multilineTextAlignment(.leading)
        }
        .padding(Spacing.standard)
        .frame(maxWidth: maxWidth, alignment: .leading)
        .liquidGlass(
            tint: category.map { ColorPalette.color(for: $0).opacity(0.1) },
            cornerRadius: CornerRadius.standard
        )
    }
}

/// Bubble shape with optional arrow
struct BubbleShape: Shape {
    var showArrow: Bool = true
    var arrowSize: CGFloat = 10
    var cornerRadius: CGFloat = 16
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let arrowOffset: CGFloat = 24
        
        // Start at top left
        path.move(to: CGPoint(x: rect.minX + cornerRadius, y: rect.minY))
        
        // Top edge
        path.addLine(to: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY))
        
        // Top right corner
        path.addArc(
            center: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY + cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(-90),
            endAngle: .degrees(0),
            clockwise: false
        )
        
        // Right edge
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerRadius))
        
        // Bottom right corner
        path.addArc(
            center: CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY - cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(0),
            endAngle: .degrees(90),
            clockwise: false
        )
        
        if showArrow {
            // Bottom edge with arrow
            path.addLine(to: CGPoint(x: rect.minX + arrowOffset + arrowSize, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX + arrowOffset, y: rect.maxY + arrowSize))
            path.addLine(to: CGPoint(x: rect.minX + arrowOffset - arrowSize, y: rect.maxY))
        }
        
        path.addLine(to: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY))
        
        // Bottom left corner
        path.addArc(
            center: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY - cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(90),
            endAngle: .degrees(180),
            clockwise: false
        )
        
        // Left edge
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cornerRadius))
        
        // Top left corner
        path.addArc(
            center: CGPoint(x: rect.minX + cornerRadius, y: rect.minY + cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(180),
            endAngle: .degrees(270),
            clockwise: false
        )
        
        return path
    }
}

/// Compact insight chip with Liquid Glass
struct InsightChip: View {
    let text: String
    var icon: String? = nil
    var color: Color = ColorPalette.accent
    
    var body: some View {
        HStack(spacing: Spacing.xs + 2) {
            if let icon {
                Image(systemName: icon)
                    .font(.caption)
            }
            
            Text(text)
                .font(Typography.caption)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .foregroundStyle(color)
        .liquidGlassCapsule(tint: color.opacity(0.15))
    }
}

/// Animated insight notification
struct InsightNotificationBadge: View {
    let count: Int
    
    @State private var isAnimating = false
    
    var body: some View {
        if count > 0 {
            ZStack {
                Circle()
                    .fill(ColorPalette.accent)
                    .frame(width: 24, height: 24)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                
                Text("\(min(count, 99))")
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
            }
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 0.8)
                    .repeatForever(autoreverses: true)
                ) {
                    isAnimating = true
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 32) {
        InsightBubble(
            text: "You tend to walk more on Tuesdays. This week you averaged 8,500 steps.",
            category: .pattern
        )
        
        InsightBubble(
            text: "Quick insight without category or arrow.",
            showArrow: false
        )
        
        HStack(spacing: 8) {
            InsightChip(text: "Pattern", icon: "repeat", color: .purple)
            InsightChip(text: "Trend", icon: "chart.line.uptrend.xyaxis", color: .green)
            InsightChip(text: "New", color: .orange)
        }
        
        HStack(spacing: 16) {
            Text("Notifications:")
            InsightNotificationBadge(count: 3)
            InsightNotificationBadge(count: 12)
        }
    }
    .padding()
}
