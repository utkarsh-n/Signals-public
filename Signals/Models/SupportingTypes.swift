//
//  SupportingTypes.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import Foundation

// MARK: - Insight Types

enum InsightCategory: String, Codable, CaseIterable {
    case pattern      // "You tend to..."
    case correlation  // "On days when X, you also Y"
    case trend        // "This week vs last week..."
    case milestone    // "First time you..."
    case seasonal     // "Every autumn you..."
    case anomaly      // "This was unusual for you..."
    
    var displayName: String {
        switch self {
        case .pattern: return "Pattern"
        case .correlation: return "Correlation"
        case .trend: return "Trend"
        case .milestone: return "Milestone"
        case .seasonal: return "Seasonal"
        case .anomaly: return "Anomaly"
        }
    }
    
    var icon: String {
        switch self {
        case .pattern: return "repeat"
        case .correlation: return "arrow.left.arrow.right"
        case .trend: return "chart.line.uptrend.xyaxis"
        case .milestone: return "flag.fill"
        case .seasonal: return "leaf.fill"
        case .anomaly: return "exclamationmark.circle"
        }
    }
}

enum InsightTimeSpan: String, Codable {
    case week
    case month
    case quarter
    case allTime
}

enum InsightRating: String, Codable {
    case helpful
    case notHelpful
    case surprising
}

// MARK: - Health Types

enum SleepQuality: String, Codable, CaseIterable {
    case poor
    case fair
    case good
    case excellent
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var sortOrder: Int {
        switch self {
        case .poor: return 0
        case .fair: return 1
        case .good: return 2
        case .excellent: return 3
        }
    }
}

enum PrimaryActivity: String, Codable, CaseIterable {
    case stationary
    case walking
    case running
    case driving
    case cycling
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var icon: String {
        switch self {
        case .stationary: return "figure.stand"
        case .walking: return "figure.walk"
        case .running: return "figure.run"
        case .driving: return "car.fill"
        case .cycling: return "bicycle"
        }
    }
}

// MARK: - Mood Types

enum MoodLevel: Int, Codable, CaseIterable {
    case one = 1
    case two = 2
    case three = 3
    case four = 4
    case five = 5
    
    var icon: String {
        switch self {
        case .one: return "circle"
        case .two: return "circle.lefthalf.filled"
        case .three: return "circle.fill"
        case .four: return "circle.inset.filled"
        case .five: return "circle.dashed.inset.filled"
        }
    }
}

enum EnergyLevel: Int, Codable, CaseIterable {
    case one = 1
    case two = 2
    case three = 3
    case four = 4
    case five = 5
}

enum Sentiment: String, Codable {
    case positive
    case neutral
    case negative
    
    var icon: String {
        switch self {
        case .positive: return "face.smiling"
        case .neutral: return "face.dashed"
        case .negative: return "cloud.rain"
        }
    }
}

// MARK: - Weather Types

enum WeatherCondition: String, Codable, CaseIterable {
    case clear
    case cloudy
    case rainy
    case snowy
    case stormy
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var icon: String {
        switch self {
        case .clear: return "sun.max.fill"
        case .cloudy: return "cloud.fill"
        case .rainy: return "cloud.rain.fill"
        case .snowy: return "cloud.snow.fill"
        case .stormy: return "cloud.bolt.fill"
        }
    }
}

// MARK: - Supporting Structs

struct AppUsageEntry: Codable, Equatable, Hashable {
    let category: String  // "Social", "Entertainment", "Productivity" — never raw app names
    let minutes: Int
}

struct LocationCluster: Codable, Equatable, Hashable {
    let label: String           // "Home", "Work", "Gym", "New place"
    let timeSpentMinutes: Int
    let isNew: Bool
}

struct WeekComparison: Codable {
    let stepsChange: Double?          // Percentage change
    let sleepChange: Double?
    let screenTimeChange: Double?
    let moodChange: Double?
    let reflectionCountChange: Int?
}

struct InsightData: Codable {
    // Flexible container for insight-specific supporting data
    var metrics: [String: Double]?
    var dates: [String: Date]?
    var strings: [String: String]?
    var signals: [SignalType]?
    
    init(metrics: [String: Double]? = nil, 
         dates: [String: Date]? = nil, 
         strings: [String: String]? = nil,
         signals: [SignalType]? = nil) {
        self.metrics = metrics
        self.dates = dates
        self.strings = strings
        self.signals = signals
    }
}

// MARK: - App Categories

/// Standard app categories for tracking app usage.
/// These are intentionally broad to protect privacy while still providing insight.
/// Used by both Screen Time tracking and Shortcuts-based app open logging.
enum AppCategory: String, Codable, CaseIterable, Identifiable {
    case social = "Social"
    case entertainment = "Entertainment"
    case productivity = "Productivity"
    case education = "Education"
    case healthFitness = "Health & Fitness"
    case games = "Games"
    case utilities = "Utilities"
    case creativity = "Creativity"
    case news = "News"
    case shopping = "Shopping"
    case travel = "Travel"
    case finance = "Finance"
    case communication = "Communication"
    case food = "Food"
    case other = "Other"
    
    var id: String { rawValue }
    
    var displayName: String { rawValue }
    
    var icon: String {
        switch self {
        case .social: return "person.2.fill"
        case .entertainment: return "play.tv.fill"
        case .productivity: return "briefcase.fill"
        case .education: return "book.fill"
        case .healthFitness: return "heart.fill"
        case .games: return "gamecontroller.fill"
        case .utilities: return "wrench.and.screwdriver.fill"
        case .creativity: return "paintbrush.fill"
        case .news: return "newspaper.fill"
        case .shopping: return "cart.fill"
        case .travel: return "airplane"
        case .finance: return "dollarsign.circle.fill"
        case .communication: return "message.fill"
        case .food: return "fork.knife"
        case .other: return "square.grid.2x2.fill"
        }
    }
    
    var color: String {
        switch self {
        case .social: return "blue"
        case .entertainment: return "purple"
        case .productivity: return "green"
        case .education: return "orange"
        case .healthFitness: return "red"
        case .games: return "pink"
        case .utilities: return "gray"
        case .creativity: return "yellow"
        case .news: return "indigo"
        case .shopping: return "teal"
        case .travel: return "cyan"
        case .finance: return "mint"
        case .communication: return "teal"
        case .food: return "yellow"
        case .other: return "secondary"
        }
    }
    
    /// Common apps that fall into this category (for user reference in setup)
    var exampleApps: [String] {
        switch self {
        case .social: return ["Instagram", "Twitter/X", "TikTok", "Snapchat", "Facebook"]
        case .entertainment: return ["YouTube", "Netflix", "Spotify", "Twitch"]
        case .productivity: return ["Notion", "Slack", "Gmail", "Calendar"]
        case .education: return ["Duolingo", "Khan Academy", "Coursera"]
        case .healthFitness: return ["Apple Health", "Strava", "MyFitnessPal"]
        case .games: return ["Any mobile games"]
        case .utilities: return ["Settings", "Files", "Calculator"]
        case .creativity: return ["Procreate", "GarageBand", "iMovie"]
        case .news: return ["Apple News", "CNN", "BBC", "Reddit"]
        case .shopping: return ["Amazon", "eBay", "Etsy", "Target"]
        case .travel: return ["Maps", "Uber", "Lyft", "Airlines"]
        case .finance: return ["Banks", "Venmo", "PayPal", "Robinhood"]
        case .communication: return ["Messages", "WhatsApp", "Telegram"]
        case .food: return ["DoorDash", "Uber Eats", "Yelp"]
        case .other: return ["Any other apps"]
        }
    }
}
