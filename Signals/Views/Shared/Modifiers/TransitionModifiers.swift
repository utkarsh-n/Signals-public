//
//  TransitionModifiers.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import SwiftUI

// MARK: - Custom Transitions

extension AnyTransition {
    /// Slide up with fade
    static var slideUpFade: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .top).combined(with: .opacity)
        )
    }
    
    /// Scale with fade for cards
    static var cardAppear: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.9).combined(with: .opacity),
            removal: .scale(scale: 0.95).combined(with: .opacity)
        )
    }
    
    /// Blur transition
    static var blur: AnyTransition {
        .modifier(
            active: BlurModifier(radius: 10, opacity: 0),
            identity: BlurModifier(radius: 0, opacity: 1)
        )
    }
    
    /// Spring scale
    static var springScale: AnyTransition {
        .scale.animation(.spring(response: 0.3, dampingFraction: 0.6))
    }
    
    /// Slide from leading with fade
    static var slideFromLeading: AnyTransition {
        .move(edge: .leading).combined(with: .opacity)
    }
    
    /// Slide from trailing with fade
    static var slideFromTrailing: AnyTransition {
        .move(edge: .trailing).combined(with: .opacity)
    }
}

private struct BlurModifier: ViewModifier {
    let radius: CGFloat
    let opacity: Double
    
    func body(content: Content) -> some View {
        content
            .blur(radius: radius)
            .opacity(opacity)
    }
}

// MARK: - Animation Presets

extension Animation {
    /// Standard spring for UI interactions
    static var signalsSpring: Animation {
        .spring(response: 0.35, dampingFraction: 0.7)
    }
    
    /// Bouncy spring for celebratory moments
    static var signalsBounce: Animation {
        .spring(response: 0.4, dampingFraction: 0.5)
    }
    
    /// Smooth ease for subtle changes
    static var signalsSmooth: Animation {
        .easeInOut(duration: 0.3)
    }
    
    /// Quick snap for immediate feedback
    static var signalsSnap: Animation {
        .easeOut(duration: 0.15)
    }
    
    /// Slow ease for loading states
    static var signalsSlow: Animation {
        .easeInOut(duration: 0.6)
    }
}

// MARK: - Entrance Animation Modifier

struct EntranceAnimationModifier: ViewModifier {
    let delay: Double
    let animation: Animation
    
    @State private var isVisible = false
    
    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .onAppear {
                withAnimation(animation.delay(delay)) {
                    isVisible = true
                }
            }
    }
}

extension View {
    /// Applies entrance animation with delay
    func entranceAnimation(delay: Double = 0, animation: Animation = .signalsSpring) -> some View {
        modifier(EntranceAnimationModifier(delay: delay, animation: animation))
    }
}

// MARK: - Staggered List Animation

struct StaggeredListModifier: ViewModifier {
    let index: Int
    let baseDelay: Double
    let delayIncrement: Double
    
    @State private var isVisible = false
    
    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 15)
            .onAppear {
                let delay = baseDelay + (Double(index) * delayIncrement)
                withAnimation(.signalsSpring.delay(delay)) {
                    isVisible = true
                }
            }
    }
}

extension View {
    /// Applies staggered animation for list items
    func staggeredAnimation(
        index: Int,
        baseDelay: Double = 0.1,
        delayIncrement: Double = 0.05
    ) -> some View {
        modifier(StaggeredListModifier(
            index: index,
            baseDelay: baseDelay,
            delayIncrement: delayIncrement
        ))
    }
}

// MARK: - Scale on Press Modifier

struct ScaleOnPressModifier: ViewModifier {
    @State private var isPressed = false
    let scale: CGFloat
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? scale : 1.0)
            .animation(.signalsSnap, value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}

extension View {
    /// Scales down when pressed
    func scaleOnPress(_ scale: CGFloat = 0.95) -> some View {
        modifier(ScaleOnPressModifier(scale: scale))
    }
}

// MARK: - Shake Animation Modifier

struct ShakeModifier: ViewModifier {
    let trigger: Bool
    @State private var shakeOffset: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .offset(x: shakeOffset)
            .onChange(of: trigger) { _, newValue in
                if newValue {
                    shake()
                }
            }
    }
    
    private func shake() {
        withAnimation(.linear(duration: 0.05)) {
            shakeOffset = 10
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.linear(duration: 0.05)) {
                shakeOffset = -8
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.linear(duration: 0.05)) {
                shakeOffset = 5
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.linear(duration: 0.05)) {
                shakeOffset = 0
            }
        }
    }
}

extension View {
    /// Shakes the view when triggered
    func shake(trigger: Bool) -> some View {
        modifier(ShakeModifier(trigger: trigger))
    }
}

// MARK: - Success Animation Modifier

struct SuccessAnimationModifier: ViewModifier {
    let trigger: Bool
    @State private var scale: CGFloat = 1
    @State private var opacity: Double = 0
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            // Success ring
            Circle()
                .stroke(Color.green, lineWidth: 3)
                .scaleEffect(scale)
                .opacity(opacity)
        }
        .onChange(of: trigger) { _, newValue in
            if newValue {
                animateSuccess()
            }
        }
    }
    
    private func animateSuccess() {
        scale = 0.8
        opacity = 1
        
        withAnimation(.easeOut(duration: 0.4)) {
            scale = 1.5
            opacity = 0
        }
    }
}

extension View {
    /// Shows success ring animation when triggered
    func successAnimation(trigger: Bool) -> some View {
        modifier(SuccessAnimationModifier(trigger: trigger))
    }
}

// MARK: - Skeleton Loading Animation

struct SkeletonAnimationModifier: ViewModifier {
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.4),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: isAnimating ? 200 : -200)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
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

extension View {
    /// Applies skeleton loading animation
    func skeletonAnimation() -> some View {
        modifier(SkeletonAnimationModifier())
    }
}
