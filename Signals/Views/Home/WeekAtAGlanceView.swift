//
//  WeekAtAGlanceView.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import SwiftUI

/// Shows 7 dots for the current week, colored by activity/mood
struct WeekAtAGlanceView: View {
    let snapshots: [DailySnapshot]
    
    private let calendar = Calendar.current
    
    private var weekDays: [WeekDay] {
        let today = Date()
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) else {
            return []
        }
        
        return (0..<7).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStart)!
            let snapshot = snapshots.first { calendar.isDate($0.date, inSameDayAs: date) }
            let isToday = calendar.isDateInToday(date)
            
            return WeekDay(
                date: date,
                snapshot: snapshot,
                isToday: isToday,
                isFuture: date > today
            )
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(Typography.subheadline)
                .foregroundStyle(ColorPalette.secondaryText)
            
            HStack(spacing: 8) {
                ForEach(weekDays, id: \.date) { day in
                    WeekDayDot(weekDay: day)
                }
            }
        }
        .padding(16)
        .background(ColorPalette.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct WeekDay: Identifiable {
    let date: Date
    let snapshot: DailySnapshot?
    let isToday: Bool
    let isFuture: Bool
    
    var id: Date { date }
    
    var dayLetter: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEEE"
        return formatter.string(from: date)
    }
    
    var activityLevel: ActivityLevel {
        guard let snapshot = snapshot else { return .none }
        
        // Calculate activity level based on steps
        if let steps = snapshot.stepCount {
            if steps >= 10000 { return .high }
            if steps >= 6000 { return .medium }
            if steps >= 3000 { return .low }
        }
        
        // Fall back to checking if there's any data
        return snapshot.hasData ? .low : .none
    }
}

enum ActivityLevel {
    case none
    case low
    case medium
    case high
    
    var color: Color {
        switch self {
        case .none: return ColorPalette.tertiaryBackground
        case .low: return .green.opacity(0.4)
        case .medium: return .green.opacity(0.7)
        case .high: return .green
        }
    }
}

struct WeekDayDot: View {
    let weekDay: WeekDay
    
    var body: some View {
        VStack(spacing: 6) {
            // Day letter
            Text(weekDay.dayLetter)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(
                    weekDay.isToday 
                    ? ColorPalette.primaryText 
                    : ColorPalette.tertiaryText
                )
            
            // Activity dot
            ZStack {
                Circle()
                    .fill(weekDay.isFuture 
                          ? ColorPalette.tertiaryBackground.opacity(0.5) 
                          : weekDay.activityLevel.color)
                    .frame(width: 32, height: 32)
                
                if weekDay.isToday {
                    Circle()
                        .stroke(ColorPalette.primaryText, lineWidth: 2)
                        .frame(width: 32, height: 32)
                }
                
                // Show mood if available
                if let snapshot = weekDay.snapshot,
                   let mood = snapshot.averageMood {
                    Text(moodEmoji(for: mood))
                        .font(.system(size: 14))
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func moodEmoji(for moodValue: Double) -> String {
        if moodValue >= 4 { return "" }  // Only show for strong moods
        if moodValue <= 2 { return "" }
        return ""
    }
}

// MARK: - Latest Insight Card

struct LatestInsightCard: View {
    let insight: Insight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: insight.category.icon)
                    .foregroundStyle(ColorPalette.color(for: insight.category))
                
                Text("Latest Insight")
                    .font(Typography.subheadline)
                    .foregroundStyle(ColorPalette.secondaryText)
                
                Spacer()
                
                Text(insight.formattedDate)
                    .font(Typography.caption2)
                    .foregroundStyle(ColorPalette.tertiaryText)
            }
            
            Text(insight.title)
                .font(Typography.headline)
            
            Text(insight.body)
                .font(Typography.body)
                .foregroundStyle(ColorPalette.secondaryText)
                .lineLimit(3)
            
            // Signal indicators
            HStack(spacing: 6) {
                ForEach(insight.signalsInvolved, id: \.self) { signal in
                    HStack(spacing: 4) {
                        Image(systemName: signal.icon)
                            .font(.system(size: 10))
                        Text(signal.displayName)
                            .font(.system(size: 10))
                    }
                    .foregroundStyle(ColorPalette.color(for: signal))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(ColorPalette.color(for: signal).opacity(0.1))
                    .clipShape(Capsule())
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(ColorPalette.secondaryBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [.purple.opacity(0.3), .blue.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
}

// MARK: - Preview

#Preview {
    VStack {
        WeekAtAGlanceView(snapshots: [])
        LatestInsightCard(insight: Insight(
            category: .pattern,
            title: "Tuesday energy",
            body: "You tend to be most active on Tuesdays, with an average of 8,500 steps.",
            signalsInvolved: [.steps]
        ))
    }
    .padding()
}
