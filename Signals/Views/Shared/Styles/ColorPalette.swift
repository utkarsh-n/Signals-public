//
//  ColorPalette.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import SwiftUI

/// App-wide color definitions with Liquid Glass support
enum ColorPalette {
    // MARK: - Primary Colors
    
    /// The main accent color for the app
    static let accent = Color("AccentColor")
    
    /// Secondary accent color
    static let secondary = Color.purple
    
    /// Tertiary accent color
    static let tertiary = Color.teal
    
    /// Quaternary accent color
    static let quaternary = Color.orange
    
    /// Border color
    static var border: Color {
        Color(.separator)
    }
    
    /// Primary brand gradient
    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [.purple.opacity(0.8), .blue.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Secondary gradient for cards
    static var secondaryGradient: LinearGradient {
        LinearGradient(
            colors: [.blue.opacity(0.6), .cyan.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Liquid Glass Tint Colors
    
    /// Subtle tint for standard glass effects
    static var glassTint: Color {
        Color.white.opacity(0.1)
    }
    
    /// Accent tint for highlighted glass effects
    static var glassAccentTint: Color {
        accent.opacity(0.15)
    }
    
    /// Signal-specific glass tints
    static func glassTint(for signalType: SignalType) -> Color {
        color(for: signalType).opacity(0.12)
    }
    
    // MARK: - Semantic Colors
    
    /// Background for the main view
    static var background: Color {
        Color(.systemBackground)
    }
    
    /// Secondary background for cards and grouped content
    static var secondaryBackground: Color {
        Color(.secondarySystemBackground)
    }
    
    /// Tertiary background for nested elements
    static var tertiaryBackground: Color {
        Color(.tertiarySystemBackground)
    }
    
    /// Primary text color
    static var primaryText: Color {
        Color(.label)
    }
    
    /// Secondary text color
    static var secondaryText: Color {
        Color(.secondaryLabel)
    }
    
    /// Tertiary text color
    static var tertiaryText: Color {
        Color(.tertiaryLabel)
    }
    
    // MARK: - Signal Colors
    
    /// Color for steps-related UI
    static let steps = Color.orange
    
    /// Color for sleep-related UI
    static let sleep = Color.indigo
    
    /// Color for exercise-related UI
    static let exercise = Color.green
    
    /// Color for heart rate-related UI
    static let heartRate = Color.red
    
    /// Color for screen time-related UI
    static let screenTime = Color.blue
    
    /// Color for location-related UI
    static let location = Color.teal
    
    /// Color for mood-related UI
    static let mood = Color.pink
    
    /// Color for reflection-related UI
    static let reflection = Color.purple
    
    /// Returns the color associated with a signal type
    static func color(for signalType: SignalType) -> Color {
        switch signalType {
        case .steps: return steps
        case .sleep: return sleep
        case .exercise: return exercise
        case .heartRate, .hrv: return heartRate
        case .screenTime, .appPickups: return screenTime
        case .location, .distance, .places: return location
        case .motion: return exercise
        case .mood: return mood
        case .reflection: return reflection
        case .weather: return .cyan
        }
    }
    
    // MARK: - Insight Category Colors
    
    static func color(for category: InsightCategory) -> Color {
        switch category {
        case .pattern: return .purple
        case .correlation: return .blue
        case .trend: return .green
        case .milestone: return .orange
        case .seasonal: return .teal
        case .anomaly: return .red
        }
    }
    
    // MARK: - Mood Colors
    
    /// Colors for mood levels (1-5)
    static let moodColors: [Color] = [
        .gray,          // 1 - neutral/low
        .blue.opacity(0.6),
        .teal,
        .green.opacity(0.8),
        .yellow         // 5 - high energy/positive
    ]
    
    static func color(for moodLevel: MoodLevel) -> Color {
        moodColors[moodLevel.rawValue - 1]
    }
    
    // MARK: - Sentiment Colors
    
    static func color(for sentiment: Sentiment) -> Color {
        switch sentiment {
        case .positive: return .green
        case .neutral: return .gray
        case .negative: return .blue.opacity(0.7)
        }
    }
    
    // MARK: - Sleep Quality Colors
    
    static func color(for sleepQuality: SleepQuality) -> Color {
        switch sleepQuality {
        case .poor: return .red.opacity(0.7)
        case .fair: return .orange
        case .good: return .green.opacity(0.8)
        case .excellent: return .green
        }
    }
    
    // MARK: - Weather Colors
    
    static func color(for weather: WeatherCondition) -> Color {
        switch weather {
        case .clear: return .yellow
        case .cloudy: return .gray
        case .rainy: return .blue
        case .snowy: return .cyan
        case .stormy: return .purple
        }
    }
    
    // MARK: - Accent Color Options
    
    static let accentOptions: [(name: String, color: Color)] = [
        ("blue", .blue),
        ("purple", .purple),
        ("pink", .pink),
        ("orange", .orange),
        ("teal", .teal),
        ("green", .green)
    ]
    
    static func accentColor(named name: String) -> Color {
        accentOptions.first { $0.name == name }?.color ?? .blue
    }
}

// MARK: - Color Extensions

extension Color {
    /// Creates a subtle gradient version of the color
    func gradient(opacity: Double = 0.8) -> LinearGradient {
        LinearGradient(
            colors: [self.opacity(opacity), self.opacity(opacity * 0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
