//
//  MonthGridView.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import SwiftUI
import SwiftData

/// Calendar-style grid view showing days of a month with color-coded activity levels
struct MonthGridView: View {
    let month: Date
    let snapshots: [DailySnapshot]
    let colorSignal: ColorSignal
    var onDaySelected: ((Date) -> Void)? = nil
    
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    
    var body: some View {
        VStack(spacing: 12) {
            // Month header
            monthHeader
            
            // Weekday labels
            weekdayLabels
            
            // Days grid
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(daysInMonth, id: \.self) { day in
                    if let date = day {
                        DayCell(
                            date: date,
                            snapshot: snapshotFor(date),
                            colorSignal: colorSignal,
                            isToday: calendar.isDateInToday(date),
                            onTap: { onDaySelected?(date) }
                        )
                    } else {
                        Color.clear
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
            }
        }
    }
    
    // MARK: - Month Header
    
    private var monthHeader: some View {
        Text(month.formatted(.dateTime.month(.wide).year()))
            .font(Typography.headline)
            .foregroundStyle(ColorPalette.primaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Weekday Labels
    
    private var weekdayLabels: some View {
        HStack(spacing: 4) {
            ForEach(calendar.shortWeekdaySymbols, id: \.self) { symbol in
                Text(symbol.prefix(1))
                    .font(Typography.caption)
                    .foregroundStyle(ColorPalette.tertiaryText)
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    // MARK: - Days Calculation
    
    private var daysInMonth: [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: month),
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month))
        else { return [] }
        
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let leadingEmptyDays = firstWeekday - calendar.firstWeekday
        let adjustedLeading = leadingEmptyDays < 0 ? leadingEmptyDays + 7 : leadingEmptyDays
        
        var days: [Date?] = Array(repeating: nil, count: adjustedLeading)
        
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                days.append(date)
            }
        }
        
        // Add trailing empty cells to complete the grid
        while days.count % 7 != 0 {
            days.append(nil)
        }
        
        return days
    }
    
    private func snapshotFor(_ date: Date) -> DailySnapshot? {
        let startOfDay = calendar.startOfDay(for: date)
        return snapshots.first { calendar.isDate($0.date, inSameDayAs: startOfDay) }
    }
}

// MARK: - Day Cell

struct DayCell: View {
    let date: Date
    let snapshot: DailySnapshot?
    let colorSignal: ColorSignal
    let isToday: Bool
    let onTap: () -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        Button(action: {
            Haptics.daySelected()
            onTap()
        }) {
            ZStack {
                // Background color based on signal
                Circle()
                    .fill(cellColor)
                
                // Today indicator
                if isToday {
                    Circle()
                        .strokeBorder(ColorPalette.accent, lineWidth: 2)
                }
                
                // Day number
                Text("\(calendar.component(.day, from: date))")
                    .font(Typography.caption)
                    .foregroundStyle(textColor)
            }
            .aspectRatio(1, contentMode: .fit)
        }
        .buttonStyle(.plain)
        .opacity(isFuture ? 0.3 : 1.0)
        .disabled(isFuture)
    }
    
    private var isFuture: Bool {
        date > Date()
    }
    
    private var cellColor: Color {
        guard let snapshot = snapshot else {
            return ColorPalette.tertiaryBackground
        }
        
        let intensity = colorSignal.intensity(for: snapshot)
        return colorSignal.baseColor.opacity(0.2 + (intensity * 0.6))
    }
    
    private var textColor: Color {
        if snapshot != nil {
            return ColorPalette.primaryText
        }
        return ColorPalette.tertiaryText
    }
}

// MARK: - Color Signal

enum ColorSignal: String, CaseIterable, Identifiable {
    case steps
    case sleep
    case screenTime
    case mood
    case activity
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .steps: return "Steps"
        case .sleep: return "Sleep"
        case .screenTime: return "Screen Time"
        case .mood: return "Mood"
        case .activity: return "Activity"
        }
    }
    
    var baseColor: Color {
        switch self {
        case .steps: return ColorPalette.steps
        case .sleep: return ColorPalette.sleep
        case .screenTime: return ColorPalette.screenTime
        case .mood: return ColorPalette.mood
        case .activity: return ColorPalette.exercise
        }
    }
    
    var icon: String {
        switch self {
        case .steps: return "figure.walk"
        case .sleep: return "moon.fill"
        case .screenTime: return "iphone"
        case .mood: return "face.smiling"
        case .activity: return "flame.fill"
        }
    }
    
    /// Returns intensity value 0.0-1.0 based on snapshot data
    func intensity(for snapshot: DailySnapshot) -> Double {
        switch self {
        case .steps:
            guard let steps = snapshot.stepCount else { return 0 }
            // Assume 10,000 steps is max
            return min(Double(steps) / 10000.0, 1.0)
            
        case .sleep:
            guard let hours = snapshot.sleepHours else { return 0 }
            // Assume 8 hours is optimal
            return min(hours / 8.0, 1.0)
            
        case .screenTime:
            guard let minutes = snapshot.screenTimeMinutes else { return 0 }
            // Invert: less screen time = higher intensity (better)
            let hours = Double(minutes) / 60.0
            return max(1.0 - (hours / 6.0), 0)
            
        case .mood:
            guard let entries = snapshot.moodEntries, let latest = entries.last else { return 0 }
            return Double(latest.mood.rawValue) / 5.0
            
        case .activity:
            guard let minutes = snapshot.exerciseMinutes else { return 0 }
            // Assume 60 minutes is max
            return min(Double(minutes) / 60.0, 1.0)
        }
    }
}

// MARK: - Preview

#Preview {
    MonthGridView(
        month: Date(),
        snapshots: [],
        colorSignal: .steps
    )
    .padding()
}
