//
//  CustomTabBar.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import SwiftUI

/// Custom tab bar with Liquid Glass styling
struct CustomTabBar: View {
    @Binding var selectedTab: Tab
    var unreadInsightCount: Int = 0
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases) { tab in
                TabBarButton(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    badgeCount: tab == .insights ? unreadInsightCount : 0
                ) {
                    withAnimation(AnimationTokens.snappy) {
                        selectedTab = tab
                    }
                    Haptics.tabChanged()
                }
            }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.top, Spacing.sm)
        .padding(.bottom, Spacing.xs)
        .background {
            tabBarBackground
        }
    }
    
    @ViewBuilder
    private var tabBarBackground: some View {
        if #available(iOS 26.0, *) {
            // Liquid Glass tab bar background
            Rectangle()
                .fill(.clear)
                .glassEffect(.regular, in: .rect)
                .ignoresSafeArea()
        } else {
            // Fallback for earlier iOS versions
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(ColorPalette.border.opacity(0.5))
                        .frame(height: 0.5)
                }
                .ignoresSafeArea()
        }
    }
}

/// Individual tab bar button
private struct TabBarButton: View {
    let tab: Tab
    let isSelected: Bool
    var badgeCount: Int = 0
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    // Icon with signal pulse effect when selected
                    ZStack {
                        // Pulse ring for selected state
                        if isSelected {
                            Circle()
                                .stroke(accentColor.opacity(0.3), lineWidth: 2)
                                .frame(width: 36, height: 36)
                                .scaleEffect(isSelected ? 1.2 : 1.0)
                                .opacity(isSelected ? 0 : 0.5)
                                .animation(
                                    .easeOut(duration: 1.5)
                                    .repeatForever(autoreverses: false),
                                    value: isSelected
                                )
                        }
                        
                        Image(systemName: tab.icon)
                            .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                            .foregroundStyle(isSelected ? accentColor : ColorPalette.tertiaryText)
                            .scaleEffect(isPressed ? 0.9 : 1.0)
                    }
                    .frame(width: 36, height: 36)
                    
                    // Badge
                    if badgeCount > 0 {
                        BadgeView(count: badgeCount)
                            .offset(x: 8, y: -4)
                    }
                }
                
                // Label
                Text(tab.title)
                    .font(.system(size: 10, weight: isSelected ? .medium : .regular))
                    .foregroundStyle(isSelected ? accentColor : ColorPalette.tertiaryText)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
    
    private var accentColor: Color {
        switch tab {
        case .home: return ColorPalette.accent
        case .insights: return ColorPalette.secondary
        case .timeline: return ColorPalette.tertiary
        case .reflect: return ColorPalette.quaternary
        case .settings: return ColorPalette.secondaryText
        }
    }
}

/// Badge view for notification counts with Liquid Glass
private struct BadgeView: View {
    let count: Int
    
    var body: some View {
        Text(count > 9 ? "9+" : "\(count)")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .liquidGlassCapsule(tint: ColorPalette.accent)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        Spacer()
        CustomTabBar(selectedTab: .constant(.home), unreadInsightCount: 3)
    }
}
