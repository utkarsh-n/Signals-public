//
//  HolographicModifier.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//
//  Holographic/iridescent effect for SwiftUI views
//  Inspired by the Shiny framework - uses device motion for dynamic lighting
//

import SwiftUI
import CoreMotion
import Combine

// MARK: - Motion Manager

/// Singleton motion manager for holographic effects
@MainActor
final class HolographicMotionManager: ObservableObject {
    static let shared = HolographicMotionManager()
    
    @Published var pitch: Double = 0
    @Published var roll: Double = 0
    
    private let motionManager = CMMotionManager()
    private var isUpdating = false
    private var observerCount = 0
    
    private init() {}
    
    func startUpdates() {
        observerCount += 1
        guard !isUpdating, motionManager.isDeviceMotionAvailable else { return }
        
        isUpdating = true
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] data, error in
            guard let self = self, let data = data else { return }
            
            var adjustedPitch = data.attitude.pitch
            if data.gravity.z > 0 {
                adjustedPitch = adjustedPitch > 0 ? .pi - adjustedPitch : -(.pi + adjustedPitch)
            }
            
            // Normalize to -1...1 range for easier use
            self.pitch = adjustedPitch / .pi
            self.roll = data.attitude.roll / .pi
        }
    }
    
    func stopUpdates() {
        observerCount -= 1
        guard observerCount <= 0 else { return }
        
        observerCount = 0
        motionManager.stopDeviceMotionUpdates()
        isUpdating = false
    }
}

// MARK: - Holographic Gradient

/// Creates an animated holographic gradient based on device motion
struct HolographicGradient: View {
    @ObservedObject private var motion = HolographicMotionManager.shared
    
    let colors: [Color]
    let intensity: Double
    
    init(colors: [Color] = [.red, .orange, .yellow, .green, .cyan, .blue, .purple, .pink],
         intensity: Double = 1.0) {
        self.colors = colors
        self.intensity = intensity
    }
    
    var body: some View {
        GeometryReader { geometry in
            // Create animated gradient that responds to motion
            LinearGradient(
                colors: colors + colors, // Repeat for seamless animation
                startPoint: startPoint,
                endPoint: endPoint
            )
            .blur(radius: 20)
            .opacity(0.6 * intensity)
        }
    }
    
    private var startPoint: UnitPoint {
        let x = 0.5 + motion.roll * 0.5
        let y = 0.5 + motion.pitch * 0.5
        return UnitPoint(x: x, y: y)
    }
    
    private var endPoint: UnitPoint {
        let x = 0.5 - motion.roll * 0.5
        let y = 0.5 - motion.pitch * 0.5
        return UnitPoint(x: x, y: y)
    }
}

// MARK: - Holographic Effect Modifier

/// Applies a holographic/iridescent shine effect to any view
struct HolographicModifier: ViewModifier {
    @ObservedObject private var motion = HolographicMotionManager.shared
    @State private var animationPhase: CGFloat = 0
    
    let colors: [Color]
    let intensity: Double
    let animated: Bool
    
    init(colors: [Color]? = nil,
         intensity: Double = 0.5,
         animated: Bool = true) {
        self.colors = colors ?? [
            Color(hue: 0.0, saturation: 0.8, brightness: 1.0),   // Red
            Color(hue: 0.1, saturation: 0.8, brightness: 1.0),   // Orange
            Color(hue: 0.15, saturation: 0.8, brightness: 1.0),  // Yellow
            Color(hue: 0.35, saturation: 0.8, brightness: 1.0),  // Green
            Color(hue: 0.5, saturation: 0.8, brightness: 1.0),   // Cyan
            Color(hue: 0.65, saturation: 0.8, brightness: 1.0),  // Blue
            Color(hue: 0.8, saturation: 0.8, brightness: 1.0),   // Purple
            Color(hue: 0.9, saturation: 0.8, brightness: 1.0),   // Pink
        ]
        self.intensity = intensity
        self.animated = animated
    }
    
    func body(content: Content) -> some View {
        content
            .overlay {
                // Holographic shimmer overlay
                GeometryReader { geometry in
                    LinearGradient(
                        colors: colors,
                        startPoint: gradientStart,
                        endPoint: gradientEnd
                    )
                    .opacity(intensity)
                    .blendMode(.overlay)
                }
                .allowsHitTesting(false)
            }
            .onAppear {
                motion.startUpdates()
                if animated {
                    withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                        animationPhase = 1
                    }
                }
            }
            .onDisappear {
                motion.stopUpdates()
            }
    }
    
    private var gradientStart: UnitPoint {
        let baseX = animated ? animationPhase : 0
        let x = (baseX + motion.roll * 0.3).truncatingRemainder(dividingBy: 1)
        let y = (0.0 + motion.pitch * 0.3).truncatingRemainder(dividingBy: 1)
        return UnitPoint(x: max(0, min(1, x)), y: max(0, min(1, y)))
    }
    
    private var gradientEnd: UnitPoint {
        let baseX = animated ? animationPhase + 1 : 1
        let x = (baseX + motion.roll * 0.3).truncatingRemainder(dividingBy: 1)
        let y = (1.0 + motion.pitch * 0.3).truncatingRemainder(dividingBy: 1)
        return UnitPoint(x: max(0, min(1, x)), y: max(0, min(1, y)))
    }
}

// MARK: - Shine Effect Modifier (Simpler version)

/// A simpler shine/shimmer effect that sweeps across the view
struct ShineModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    let color: Color
    let duration: Double
    let angle: Angle
    
    init(color: Color = .white, duration: Double = 2.0, angle: Angle = .degrees(30)) {
        self.color = color
        self.duration = duration
        self.angle = angle
    }
    
    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geometry in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: color.opacity(0.3), location: 0.45),
                            .init(color: color.opacity(0.6), location: 0.5),
                            .init(color: color.opacity(0.3), location: 0.55),
                            .init(color: .clear, location: 1)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: width * 0.5)
                    .rotationEffect(angle)
                    .offset(x: phase * width * 2 - width)
                    .blendMode(.overlay)
                }
                .allowsHitTesting(false)
            }
            .clipShape(Rectangle())
            .onAppear {
                withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

// MARK: - Icon Holographic Effect

/// Specialized holographic effect for SF Symbol icons
struct IconHolographicModifier: ViewModifier {
    @ObservedObject private var motion = HolographicMotionManager.shared
    
    let baseColor: Color
    let intensity: Double
    
    init(baseColor: Color, intensity: Double = 0.4) {
        self.baseColor = baseColor
        self.intensity = intensity
    }
    
    func body(content: Content) -> some View {
        content
            .overlay {
                // Rainbow shimmer that responds to motion
                content
                    .foregroundStyle(
                        AngularGradient(
                            colors: [
                                baseColor,
                                baseColor.adjusted(hue: 0.1),
                                baseColor.adjusted(hue: 0.2),
                                baseColor.adjusted(hue: -0.1),
                                baseColor
                            ],
                            center: .center,
                            angle: .degrees(motion.roll * 180 + motion.pitch * 90)
                        )
                    )
                    .opacity(intensity)
                    .blendMode(.overlay)
            }
            .onAppear { motion.startUpdates() }
            .onDisappear { motion.stopUpdates() }
    }
}

// MARK: - Color Extension for Hue Adjustment

extension Color {
    /// Adjusts the hue of the color by the given amount (0-1 range wraps around)
    func adjusted(hue adjustment: Double) -> Color {
        // Convert to HSB and adjust
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        UIColor(self).getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        let newHue = (hue + CGFloat(adjustment)).truncatingRemainder(dividingBy: 1.0)
        let adjustedHue = newHue < 0 ? newHue + 1 : newHue
        
        return Color(hue: Double(adjustedHue), saturation: Double(saturation), brightness: Double(brightness), opacity: Double(alpha))
    }
}

// MARK: - View Extensions

extension View {
    /// Applies a holographic/iridescent effect that responds to device motion
    /// - Parameters:
    ///   - colors: Custom colors for the holographic effect (defaults to rainbow)
    ///   - intensity: Intensity of the effect (0-1)
    ///   - animated: Whether to animate the gradient continuously
    func holographic(
        colors: [Color]? = nil,
        intensity: Double = 0.5,
        animated: Bool = true
    ) -> some View {
        modifier(HolographicModifier(colors: colors, intensity: intensity, animated: animated))
    }
    
    /// Applies a simple shine/shimmer sweep effect
    /// - Parameters:
    ///   - color: The color of the shine (defaults to white)
    ///   - duration: Duration of one shine cycle
    ///   - angle: Angle of the shine sweep
    func shine(
        color: Color = .white,
        duration: Double = 2.0,
        angle: Angle = .degrees(30)
    ) -> some View {
        modifier(ShineModifier(color: color, duration: duration, angle: angle))
    }
    
    /// Applies a holographic effect specifically designed for icons
    /// - Parameters:
    ///   - baseColor: The base color of the icon
    ///   - intensity: Intensity of the holographic overlay
    func iconHolographic(
        baseColor: Color,
        intensity: Double = 0.4
    ) -> some View {
        modifier(IconHolographicModifier(baseColor: baseColor, intensity: intensity))
    }
}

// MARK: - Preview

#Preview("Holographic Effects") {
    VStack(spacing: 32) {
        // Holographic icon
        ZStack {
            Circle()
                .fill(Color.purple.opacity(0.15))
                .frame(width: 60, height: 60)
            
            Image(systemName: "star.fill")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(Color.purple)
                .iconHolographic(baseColor: .purple)
        }
        
        // Shine effect on text
        Text("Signals")
            .font(.largeTitle.bold())
            .foregroundStyle(.white)
            .padding()
            .background(Color.indigo)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shine()
        
        // Holographic card
        VStack {
            Text("Holographic Card")
                .font(.headline)
            Text("Tilt your device!")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .background(Color.black.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .holographic(intensity: 0.6)
        
        // Icon grid with holographic effects
        HStack(spacing: 24) {
            ForEach(["figure.walk", "bed.double.fill", "car.fill", "book.fill"], id: \.self) { icon in
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundStyle(Color.blue)
                        .iconHolographic(baseColor: .blue, intensity: 0.5)
                }
            }
        }
    }
    .padding()
    .background(Color.black.opacity(0.9))
}
