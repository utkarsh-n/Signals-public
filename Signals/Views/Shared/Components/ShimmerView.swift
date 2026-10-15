//
//  ShimmerView.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import SwiftUI

/// Loading placeholder with shimmer animation
struct ShimmerView: View {
    @State private var isAnimating = false
    
    var body: some View {
        GeometryReader { geometry in
            LinearGradient(
                colors: [
                    ColorPalette.tertiaryBackground,
                    ColorPalette.secondaryBackground,
                    ColorPalette.tertiaryBackground
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: geometry.size.width * 2)
            .offset(x: isAnimating ? geometry.size.width : -geometry.size.width)
        }
        .clipped()
        .onAppear {
            withAnimation(
                .linear(duration: 1.5)
                .repeatForever(autoreverses: false)
            ) {
                isAnimating = true
            }
        }
    }
}

/// Shimmer modifier for any view
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(0.3),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 0.5)
                    .offset(x: -geometry.size.width * 0.25 + phase * geometry.size.width * 1.5)
                }
                .mask(content)
            )
            .onAppear {
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Loading Placeholders

/// Card loading placeholder
struct LoadingCard: View {
    var height: CGFloat = 120
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                ShimmerView()
                    .frame(width: 80, height: 24)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                
                Spacer()
                
                ShimmerView()
                    .frame(width: 60, height: 16)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            
            // Title
            ShimmerView()
                .frame(height: 20)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            
            // Body
            VStack(spacing: 8) {
                ShimmerView()
                    .frame(height: 16)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                
                ShimmerView()
                    .frame(width: 200, height: 16)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
        .padding()
        .frame(height: height)
        .background(ColorPalette.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

/// List row loading placeholder
struct LoadingRow: View {
    var body: some View {
        HStack(spacing: 12) {
            ShimmerView()
                .frame(width: 44, height: 44)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 6) {
                ShimmerView()
                    .frame(width: 120, height: 16)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                
                ShimmerView()
                    .frame(width: 80, height: 12)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            
            Spacer()
        }
        .padding()
    }
}

/// Grid loading placeholder
struct LoadingGrid: View {
    let columns: Int
    let rows: Int
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<rows, id: \.self) { _ in
                HStack(spacing: 12) {
                    ForEach(0..<columns, id: \.self) { _ in
                        ShimmerView()
                            .frame(height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
    }
}

// MARK: - Widget Loading Placeholders

/// Widget loading placeholder for insights grid
struct LoadingWidget: View {
    var size: WidgetLoadingSize = .small
    
    enum WidgetLoadingSize {
        case small, medium, large
        
        var height: CGFloat {
            switch self {
            case .small: return 120
            case .medium: return 120
            case .large: return 260
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Header
            HStack(spacing: Spacing.xs) {
                ShimmerView()
                    .frame(width: 16, height: 16)
                    .clipShape(Circle())
                
                ShimmerView()
                    .frame(width: 60, height: 12)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                
                Spacer()
            }
            
            // Content area
            if size == .large {
                HStack(spacing: Spacing.lg) {
                    // Pie chart placeholder
                    ShimmerView()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                    
                    // Legend
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        ForEach(0..<4, id: \.self) { _ in
                            HStack(spacing: Spacing.sm) {
                                ShimmerView()
                                    .frame(width: 10, height: 10)
                                    .clipShape(Circle())
                                ShimmerView()
                                    .frame(width: 60, height: 12)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                        }
                    }
                }
                .padding(.top, Spacing.md)
            } else {
                // Metric placeholder
                ShimmerView()
                    .frame(width: 80, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                
                Spacer()
                
                // Sparkline placeholder
                ShimmerView()
                    .frame(height: 30)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
        .padding(Spacing.standard)
        .frame(height: size.height)
        .background(ColorPalette.secondaryBackground.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.standard))
    }
}

/// Timeline segment loading placeholder
struct LoadingTimelineSegment: View {
    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            // Time spine
            VStack(spacing: 0) {
                ShimmerView()
                    .frame(width: 40, height: 14)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(ColorPalette.border.opacity(0.3))
                        .frame(width: 2, height: 8)
                    
                    ShimmerView()
                        .frame(width: 10, height: 10)
                        .clipShape(Circle())
                    
                    Rectangle()
                        .fill(ColorPalette.border.opacity(0.3))
                        .frame(width: 2, height: 40)
                }
            }
            .frame(width: 50)
            
            // Segment content
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    ShimmerView()
                        .frame(width: 14, height: 14)
                        .clipShape(Circle())
                    
                    ShimmerView()
                        .frame(width: 80, height: 16)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    
                    Spacer()
                    
                    ShimmerView()
                        .frame(width: 50, height: 12)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                
                HStack(spacing: Spacing.md) {
                    ShimmerView()
                        .frame(width: 60, height: 20)
                        .clipShape(Capsule())
                    
                    ShimmerView()
                        .frame(width: 60, height: 20)
                        .clipShape(Capsule())
                }
            }
            .padding(Spacing.standard)
            .background(ColorPalette.secondaryBackground.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.standard))
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 24) {
            Text("Shimmer View")
                .font(Typography.headline)
            ShimmerView()
                .frame(height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Text("Loading Card")
                .font(Typography.headline)
            LoadingCard()
            
            Text("Loading Rows")
                .font(Typography.headline)
            VStack {
                LoadingRow()
                LoadingRow()
                LoadingRow()
            }
            .background(ColorPalette.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Text("Loading Grid")
                .font(Typography.headline)
            LoadingGrid(columns: 2, rows: 2)
        }
        .padding()
    }
}
