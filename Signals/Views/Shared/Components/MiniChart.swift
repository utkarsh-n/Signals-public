//
//  MiniChart.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import SwiftUI

/// Sparkline chart component for compact data visualization
struct MiniChart: View {
    let data: [Double]
    var color: Color = ColorPalette.accent
    var showDots: Bool = false
    var height: CGFloat = 40
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let chartHeight = geometry.size.height
            
            if data.count > 1, let minVal = data.min(), let maxVal = data.max() {
                let range = maxVal - minVal
                let normalizedData = range > 0 
                    ? data.map { ($0 - minVal) / range }
                    : data.map { _ in 0.5 }
                
                ZStack {
                    // Line
                    Path { path in
                        for (index, value) in normalizedData.enumerated() {
                            let x = width * CGFloat(index) / CGFloat(data.count - 1)
                            let y = chartHeight * (1 - CGFloat(value))
                            
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    
                    // Dots
                    if showDots {
                        ForEach(normalizedData.indices, id: \.self) { index in
                            let x = width * CGFloat(index) / CGFloat(data.count - 1)
                            let y = chartHeight * (1 - CGFloat(normalizedData[index]))
                            
                            Circle()
                                .fill(color)
                                .frame(width: 6, height: 6)
                                .position(x: x, y: y)
                        }
                    }
                }
            } else {
                // No data or single point
                Rectangle()
                    .fill(ColorPalette.tertiaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
        .frame(height: height)
    }
}

/// Sparkline with trend indicator
struct MiniChartWithTrend: View {
    let data: [Double]
    var color: Color = ColorPalette.accent
    var height: CGFloat = 40
    
    var body: some View {
        HStack(spacing: 8) {
            MiniChart(data: data, color: color, height: height)
            
            // Trend indicator
            if data.count >= 2 {
                let trend = data.last! - data.first!
                VStack(spacing: 2) {
                    Image(systemName: trend >= 0 ? "arrow.up" : "arrow.down")
                        .font(.caption2)
                    Text(String(format: "%.0f%%", abs(trend / max(data.first!, 1) * 100)))
                        .font(.caption2)
                }
                .foregroundStyle(trend >= 0 ? .green : .orange)
                .frame(width: 36)
            }
        }
    }
}

/// Bar chart variant
struct MiniBarChart: View {
    let data: [Double]
    var color: Color = ColorPalette.accent
    var height: CGFloat = 40
    var spacing: CGFloat = 2
    
    var body: some View {
        GeometryReader { geometry in
            let maxVal = data.max() ?? 1
            let barWidth = (geometry.size.width - CGFloat(data.count - 1) * spacing) / CGFloat(data.count)
            
            HStack(spacing: spacing) {
                ForEach(data.indices, id: \.self) { index in
                    let normalizedHeight = maxVal > 0 ? data[index] / maxVal : 0
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color.opacity(0.3 + normalizedHeight * 0.7))
                        .frame(width: barWidth, height: geometry.size.height * CGFloat(normalizedHeight))
                        .frame(maxHeight: .infinity, alignment: .bottom)
                }
            }
        }
        .frame(height: height)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 24) {
        VStack(alignment: .leading, spacing: 8) {
            Text("Line Chart")
                .font(Typography.caption)
            MiniChart(data: [3, 5, 2, 8, 4, 7, 6], color: ColorPalette.steps)
        }
        
        VStack(alignment: .leading, spacing: 8) {
            Text("Line Chart with Dots")
                .font(Typography.caption)
            MiniChart(data: [3, 5, 2, 8, 4, 7, 6], color: ColorPalette.sleep, showDots: true)
        }
        
        VStack(alignment: .leading, spacing: 8) {
            Text("Chart with Trend")
                .font(Typography.caption)
            MiniChartWithTrend(data: [3, 5, 2, 8, 4, 7, 9], color: ColorPalette.exercise)
        }
        
        VStack(alignment: .leading, spacing: 8) {
            Text("Bar Chart")
                .font(Typography.caption)
            MiniBarChart(data: [3, 5, 2, 8, 4, 7, 6], color: ColorPalette.screenTime)
        }
    }
    .padding()
}
