//
//  ManualEvent.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import Foundation
import SwiftUI
import SwiftData

// MARK: - Event Category

/// Categories for timeline events - both preset and custom
enum EventCategory: Codable, Equatable, Hashable, Identifiable {
    case sleep
    case driving
    case work
    case eating
    case school
    case exercise
    case custom(CustomEventCategory)
    
    var id: String {
        switch self {
        case .sleep: return "sleep"
        case .driving: return "driving"
        case .work: return "work"
        case .eating: return "eating"
        case .school: return "school"
        case .exercise: return "exercise"
        case .custom(let custom): return "custom_\(custom.name)"
        }
    }
    
    var displayName: String {
        switch self {
        case .sleep: return "Sleep"
        case .driving: return "Driving"
        case .work: return "Work"
        case .eating: return "Eating"
        case .school: return "School"
        case .exercise: return "Exercise"
        case .custom(let custom): return custom.name
        }
    }
    
    var icon: String {
        switch self {
        case .sleep: return "moon.zzz.fill"
        case .driving: return "car.fill"
        case .work: return "briefcase.fill"
        case .eating: return "fork.knife"
        case .school: return "graduationcap.fill"
        case .exercise: return "figure.run"
        case .custom(let custom): return custom.icon
        }
    }
    
    var color: Color {
        switch self {
        case .sleep: return .indigo
        case .driving: return .green
        case .work: return .purple
        case .eating: return .orange
        case .school: return .teal
        case .exercise: return .red
        case .custom(let custom): return custom.color
        }
    }
    
    /// All preset categories (excluding custom)
    static var presets: [EventCategory] {
        [.sleep, .driving, .work, .eating, .school, .exercise]
    }
}

// MARK: - Custom Event Category

/// A user-defined event category with custom icon and color
struct CustomEventCategory: Codable, Equatable, Hashable, Identifiable {
    let id: UUID
    var name: String
    var iconName: String
    var colorHex: String
    
    init(id: UUID = UUID(), name: String, iconName: String, colorHex: String) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
    }
    
    var icon: String { iconName }
    
    var color: Color {
        Color(hex: colorHex) ?? .gray
    }
}

// MARK: - Manual Event Model

/// A user-created event that appears on the timeline
@Model
final class ManualEvent {
    var id: UUID
    var startTime: Date
    var endTime: Date
    var categoryData: Data  // Encoded EventCategory
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        startTime: Date,
        endTime: Date,
        category: EventCategory,
        notes: String? = nil
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.categoryData = (try? JSONEncoder().encode(category)) ?? Data()
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var category: EventCategory {
        get {
            (try? JSONDecoder().decode(EventCategory.self, from: categoryData)) ?? .work
        }
        set {
            categoryData = (try? JSONEncoder().encode(newValue)) ?? Data()
            updatedAt = Date()
        }
    }
    
    var durationMinutes: Int {
        Int(endTime.timeIntervalSince(startTime) / 60)
    }
    
    var formattedDuration: String {
        let hours = durationMinutes / 60
        let mins = durationMinutes % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins)m"
    }
    
    var timeRangeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: startTime)) – \(formatter.string(from: endTime))"
    }
}

// MARK: - Recent Custom Events Storage

/// Stores recently used custom events for autocomplete
@MainActor
@Observable
final class RecentCustomEvents {
    static let shared = RecentCustomEvents()
    
    private let userDefaultsKey = "recentCustomEvents"
    private let maxRecentEvents = 10
    
    private(set) var recentEvents: [CustomEventCategory] = []
    
    private init() {
        loadRecentEvents()
    }
    
    func addRecentEvent(_ event: CustomEventCategory) {
        // Remove if already exists (to move to front)
        recentEvents.removeAll { $0.name.lowercased() == event.name.lowercased() }
        
        // Add to front
        recentEvents.insert(event, at: 0)
        
        // Trim to max size
        if recentEvents.count > maxRecentEvents {
            recentEvents = Array(recentEvents.prefix(maxRecentEvents))
        }
        
        saveRecentEvents()
    }
    
    func matchingEvents(for query: String) -> [CustomEventCategory] {
        guard !query.isEmpty else { return recentEvents }
        return recentEvents.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }
    
    private func loadRecentEvents() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let events = try? JSONDecoder().decode([CustomEventCategory].self, from: data) else {
            return
        }
        recentEvents = events
    }
    
    private func saveRecentEvents() {
        guard let data = try? JSONEncoder().encode(recentEvents) else { return }
        UserDefaults.standard.set(data, forKey: userDefaultsKey)
    }
}

// MARK: - App Open Aggregation

/// Aggregated app opens for a time window (for timeline display)
struct AppOpenAggregation: Identifiable, Equatable {
    let id = UUID()
    let category: AppCategory
    let count: Int
    let startTime: Date
    let endTime: Date
    
    var displayText: String {
        if count == 1 {
            return "Opened \(category.displayName)"
        }
        return "Opened \(category.displayName) \(count)×"
    }
    
    var timeRangeText: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let start = formatter.string(from: startTime)
        let end = formatter.string(from: endTime)
        return "\(start) – \(end)"
    }
}

// MARK: - Color Hex Extension

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
    
    var hexString: String {
        guard let components = UIColor(self).cgColor.components else { return "808080" }
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "%02X%02X%02X", r, g, b)
    }
}

// MARK: - Available SF Symbols for Custom Events

struct EventSymbols {
    /// Curated list of SF Symbols suitable for personal events
    static let available: [String] = [
        // Activities
        "figure.walk", "figure.run", "figure.yoga", "figure.dance",
        "figure.skiing.downhill", "figure.swimming", "bicycle",
        "dumbbell.fill", "sportscourt.fill",
        
        // Social & Communication
        "person.2.fill", "person.3.fill", "phone.fill", "video.fill",
        "bubble.left.and.bubble.right.fill", "envelope.fill",
        
        // Entertainment
        "tv.fill", "gamecontroller.fill", "headphones", "music.note",
        "film.fill", "book.fill", "magazine.fill", "theatermasks.fill",
        
        // Food & Drink
        "fork.knife", "cup.and.saucer.fill", "mug.fill", "wineglass.fill",
        "takeoutbag.and.cup.and.straw.fill", "birthday.cake.fill",
        
        // Home & Life
        "house.fill", "bed.double.fill", "bathtub.fill", "washer.fill",
        "sink.fill", "sofa.fill", "lamp.desk.fill",
        
        // Travel & Transport
        "car.fill", "bus.fill", "tram.fill", "airplane", "ferry.fill",
        "figure.walk.motion", "mappin.and.ellipse",
        
        // Work & Productivity
        "briefcase.fill", "laptopcomputer", "desktopcomputer",
        "doc.text.fill", "calendar", "clock.fill", "chart.bar.fill",
        
        // Health & Wellness
        "heart.fill", "brain.head.profile", "stethoscope", "cross.fill",
        "pills.fill", "bandage.fill",
        
        // Shopping & Errands
        "cart.fill", "bag.fill", "creditcard.fill", "dollarsign.circle.fill",
        "storefront.fill", "shippingbox.fill",
        
        // Nature & Outdoors
        "sun.max.fill", "moon.stars.fill", "cloud.fill", "leaf.fill",
        "tree.fill", "pawprint.fill", "drop.fill",
        
        // Creative
        "paintbrush.fill", "pencil", "camera.fill", "photo.fill",
        "paintpalette.fill", "guitars.fill", "pianokeys",
        
        // Misc
        "star.fill", "heart.text.square.fill", "lightbulb.fill",
        "gift.fill", "balloon.fill", "party.popper.fill",
        "sparkles", "hand.thumbsup.fill", "checkmark.circle.fill"
    ]
    
    /// Color presets for custom events
    static let availableColors: [Color] = [
        .red, .orange, .yellow, .green, .mint, .teal,
        .cyan, .blue, .indigo, .purple, .pink, .brown,
        .gray
    ]
    
    /// Color presets as hex strings
    static let availableColorHexes: [String] = [
        "FF3B30", "FF9500", "FFCC00", "34C759", "00C7BE", "30B0C7",
        "32ADE6", "007AFF", "5856D6", "AF52DE", "FF2D55", "A2845E",
        "8E8E93"
    ]
}
