//
//  InsightTemplates.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import Foundation

/// Collection of insight templates for generating natural language insights
enum InsightTemplates {
    
    // MARK: - Pattern Templates
    
    static let patternTemplates: [String: [String]] = [
        // Day of week - high
        "highest_on_day": [
            "You tend to be most active on {dayName}s.",
            "{dayName}s are your most active days.",
            "Your {metric} tends to peak on {dayName}s.",
            "You consistently have higher {metric} on {dayName}s.",
        ],
        
        // Day of week - low
        "lowest_on_day": [
            "Your {metric} tends to be lowest on {dayName}s.",
            "{dayName}s are typically your quietest days for {metric}.",
            "You tend to have less {metric} on {dayName}s.",
        ],
        
        // Weekend patterns
        "more_active_weekdays": [
            "You're more active on weekdays than weekends.",
            "Weekdays see more movement than your weekends.",
            "Your step count drops on weekends compared to weekdays.",
        ],
        "more_active_weekends": [
            "You're more active on weekends than weekdays.",
            "Weekends are when you really get moving.",
            "Your activity picks up on the weekends.",
        ],
        
        // Streaks
        "high_steps_streak": [
            "You've walked over 8,000 steps {streakDays} days in a row.",
            "{streakDays}-day streak of high activity — impressive!",
            "You've been consistently active for {streakDays} days straight.",
        ],
        "good_sleep_streak": [
            "You've slept well {streakDays} nights in a row.",
            "{streakDays}-night streak of quality sleep.",
            "Your sleep has been solid for {streakDays} consecutive nights.",
        ],
        "reflection_streak": [
            "You've written reflections {streakDays} days in a row.",
            "{streakDays}-day reflection streak — nice consistency!",
            "You've been journaling daily for {streakDays} days straight.",
        ],
        "low_screen_time_streak": [
            "You've kept screen time under 2 hours for {streakDays} days.",
            "{streakDays} days of mindful screen time.",
            "Your screen time has stayed low for {streakDays} consecutive days.",
        ],
        
        // Time of day
        "morning_reflection_preference": [
            "You tend to write reflections in the morning.",
            "Mornings seem to be your time for reflection.",
            "Most of your reflections are written before noon.",
        ],
        "evening_reflection_preference": [
            "You tend to reflect in the evenings.",
            "Nighttime is when you usually write reflections.",
            "Most of your reflections come in the evening hours.",
        ],
        
        // Anomalies
        "unusually_high_steps": [
            "Yesterday was unusually active for you.",
            "Your step count yesterday was well above your usual.",
            "That was a particularly active day compared to your norm.",
        ],
        "unusually_low_steps": [
            "Yesterday was quieter than usual for you.",
            "Your activity was lower than typical yesterday.",
            "That was a particularly low-activity day for you.",
        ],
        "unusually_high_sleep": [
            "You slept more than usual last night.",
            "That was an unusually long sleep for you.",
            "Your sleep was well above your average last night.",
        ],
        "unusually_low_sleep": [
            "You slept less than usual last night.",
            "That was a shorter night than typical for you.",
            "Your sleep was below your usual amount.",
        ],
    ]
    
    // MARK: - Correlation Templates
    
    static let correlationTemplates: [CorrelationRelationship: [String]] = [
        .sleepToNextDayActivity: [
            "On days after you sleep well, you tend to be more active.",
            "Good sleep seems to fuel your next day's activity.",
            "Your step count is higher following nights of quality sleep.",
            "Better sleep appears to lead to more movement the next day.",
        ],
        .sleepToNextDayMood: [
            "Your mood tends to be better after a good night's sleep.",
            "Sleep quality seems connected to how you feel the next day.",
            "Better rest appears to brighten your following day.",
        ],
        .sleepToNextDayScreenTime: [
            "After sleeping well, you spend less time on your phone.",
            "Good sleep seems to reduce your next-day screen time.",
            "Your phone use is lower following restful nights.",
        ],
        .screenTimeToSleep: [
            "High screen time days tend to precede shorter sleep.",
            "Heavy phone use seems to affect your sleep that night.",
            "Your sleep suffers on days with lots of screen time.",
        ],
        .screenTimeToMood: [
            "Your mood tends to be lower on high screen time days.",
            "More screen time seems to correlate with lower mood.",
            "Days with less phone use tend to feel better for you.",
        ],
        .stepsToMood: [
            "On days you walk more, your mood tends to be better.",
            "More movement seems to lift your spirits.",
            "Active days correlate with better moods for you.",
            "Your mood improves on days with higher step counts.",
        ],
        .stepsToReflectionSentiment: [
            "Your reflections tend to be more positive on active days.",
            "More movement correlates with more positive writing.",
            "When you walk more, your reflections are more upbeat.",
        ],
        .exerciseToSleep: [
            "Days with exercise tend to lead to better sleep.",
            "Working out seems to help you sleep better that night.",
            "Your sleep improves on days you exercise.",
        ],
        .weatherToActivity: [
            "Your activity level varies with the weather.",
            "Good weather gets you moving more.",
            "Sunny days correlate with higher step counts for you.",
        ],
        .weatherToMood: [
            "The weather seems to affect your mood.",
            "Your mood tends to track with weather conditions.",
            "Sunny days correlate with better moods for you.",
        ],
    ]
    
    // MARK: - Trend Templates
    
    static let trendTemplates: [String: [String]] = [
        "steps_increasing": [
            "Your step count has been increasing — up {percentage}% over the past {period}.",
            "You've been getting more active lately, with steps up {percentage}%.",
            "Your activity has been trending upward over the past {period}.",
        ],
        "steps_decreasing": [
            "Your step count has decreased {percentage}% over the past {period}.",
            "Your activity has been a bit lower lately.",
            "You've been moving less over the past {period}.",
        ],
        "sleep_increasing": [
            "You've been sleeping more — up {percentage}% over the past {period}.",
            "Your sleep duration has been increasing lately.",
            "You've been getting more rest over the past {period}.",
        ],
        "sleep_decreasing": [
            "Your sleep has been shorter lately — down {percentage}%.",
            "You've been sleeping less over the past {period}.",
            "Your rest has decreased {percentage}% recently.",
        ],
        "screenTime_increasing": [
            "Your screen time has increased {percentage}% lately.",
            "You've been spending more time on your phone recently.",
            "Screen time is up {percentage}% over the past {period}.",
        ],
        "screenTime_decreasing": [
            "Your screen time has decreased {percentage}% — nice work!",
            "You've been using your phone less lately.",
            "Screen time is down {percentage}% over the past {period}.",
        ],
    ]
    
    // MARK: - Milestone Templates
    
    static let milestoneTemplates: [String: [String]] = [
        "first_week_complete": [
            "You've completed your first week with Signals!",
            "One week down — your patterns are starting to emerge.",
        ],
        "first_month_complete": [
            "You've been tracking for a whole month now!",
            "One month of signals — you're building a clear picture.",
        ],
        "steps_record": [
            "New personal record: {value} steps in one day!",
            "That's your highest step count ever recorded!",
        ],
        "sleep_record": [
            "You slept {value} hours — your best rest on record!",
            "That's the most sleep you've logged!",
        ],
        "reflection_count": [
            "You've written {value} reflections so far.",
            "{value} reflections and counting!",
        ],
        "streak_record": [
            "New record: {value} days in a row!",
            "That's your longest streak yet — {value} days!",
        ],
    ]
    
    // MARK: - Weekly Summary Templates
    
    static let weeklySummaryTemplates: [String] = [
        "This week you averaged {steps} steps, {sleep} hours of sleep, and wrote {reflections} reflections.",
        "Your week: {steps} daily steps on average, {sleep} hours of sleep nightly, {reflections} reflections.",
        "Weekly snapshot: averaging {steps} steps and {sleep} hours of sleep, with {reflections} moments of reflection.",
    ]
    
    // MARK: - Template Selection
    
    /// Get a random template for a pattern type
    static func template(for key: String) -> String? {
        patternTemplates[key]?.randomElement()
    }
    
    /// Get a random template for a correlation
    static func template(for relationship: CorrelationRelationship) -> String? {
        correlationTemplates[relationship]?.randomElement()
    }
    
    /// Get a random trend template
    static func trendTemplate(for key: String) -> String? {
        trendTemplates[key]?.randomElement()
    }
    
    /// Get a random milestone template
    static func milestoneTemplate(for key: String) -> String? {
        milestoneTemplates[key]?.randomElement()
    }
    
    /// Get a random weekly summary template
    static func weeklySummaryTemplate() -> String {
        weeklySummaryTemplates.randomElement() ?? weeklySummaryTemplates[0]
    }
}

// MARK: - Template Filling

extension String {
    /// Fill template placeholders with values
    func fillingTemplate(with values: [String: String]) -> String {
        var result = self
        for (key, value) in values {
            result = result.replacingOccurrences(of: "{\(key)}", with: value)
        }
        return result
    }
}
