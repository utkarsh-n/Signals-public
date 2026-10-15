//
//  HeatmapView.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import SwiftUI
import SwiftData

/// A 7-column heatmap showing patterns across weekdays
struct HeatmapView: View {
    let snapshots: [DailySnapshot]
    let colorSignal: ColorSignal
    let weeksToShow: Int
    var onDaySelected: ((Date) -> Void)? = nil
    
    private let calendar = Calendar.current
    private let cellSize: CGFloat = 20
    private let cellSpacing: CGFloat = 3
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Legend
            legendView
            
            // Heatmap grid
            HStack(alignment: .top, spacing: cellSpacing) {
                // Weekday labels
                weekdayLabels
                
                // Weeks columns
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: cellSpacing) {
                        ForEach(weeksData.indices, id: \.self) { weekIndex in
                            WeekColumn(
                                days: weeksData[weekIndex],
                                colorSignal: colorSignal,
                                cellSize: cellSize,
                                onDaySelected: onDaySelected
                            )
                        }
                    }
                }
            }
            
            // Month labels
            monthLabels
        }
    }
    
    // MARK: - Legend
    
    private var legendView: some View {
        HStack {
            Text("Less")
                .font(Typography.caption)
                .foregroundStyle(ColorPalette.tertiaryText)
            
            HStack(spacing: 2) {
                ForEach(0..<5) { level in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(colorSignal.baseColor.opacity(0.1 + Double(level) * 0.2))
                        .frame(width: 12, height: 12)
                }
            }
            
            Text("More")
                .font(Typography.caption)
                .foregroundStyle(ColorPalette.tertiaryText)
            
            Spacer()
            
            // Signal selector indicator
            HStack(spacing: 4) {
                Image(systemName: colorSignal.icon)
                Text(colorSignal.displayName)
            }
            .font(Typography.caption)
            .foregroundStyle(colorSignal.baseColor)
        }
    }
    
    // MARK: - Weekday Labels
    
    private var weekdayLabels: some View {
        VStack(spacing: cellSpacing) {
            ForEach(0..<7, id: \.self) { dayIndex in
                Text(weekdayLabel(for: dayIndex))
                    .font(.system(size: 10))
                    .foregroundStyle(ColorPalette.tertiaryText)
                    .frame(width: 20, height: cellSize)
            }
        }
    }
    
    private func weekdayLabel(for index: Int) -> String {
        let weekday = (calendar.firstWeekday + index - 1) % 7
        let symbols = calendar.shortWeekdaySymbols
        return String(symbols[weekday].prefix(2))
    }
    
    // MARK: - Month Labels
    
    private var monthLabels: some View {
        HStack(spacing: 0) {
            Spacer()
                .frame(width: 24)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(monthPositions, id: \.month) { position in
                        Text(position.month)
                            .font(.system(size: 10))
                            .foregroundStyle(ColorPalette.secondaryText)
                            .frame(width: CGFloat(position.weeks) * (cellSize + cellSpacing), alignment: .leading)
                    }
                }
            }
        }
    }
    
    // MARK: - Data Preparation
    
    private var weeksData: [[DayData?]] {
        var weeks: [[DayData?]] = []
        let today = calendar.startOfDay(for: Date())
        
        // Calculate start date (weeksToShow weeks ago, aligned to week start)
        guard let startDate = calendar.date(byAdding: .weekOfYear, value: -weeksToShow + 1, to: today) else {
            return []
        }
        
        // Align to start of week
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: startDate))!
        
        var currentDate = weekStart
        var currentWeek: [DayData?] = []
        
        while currentDate <= today {
            let snapshot = snapshotFor(currentDate)
            let dayData = DayData(date: currentDate, snapshot: snapshot)
            
            currentWeek.append(dayData)
            
            if currentWeek.count == 7 {
                weeks.append(currentWeek)
                currentWeek = []
            }
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        // Add partial final week if needed
        if !currentWeek.isEmpty {
            while currentWeek.count < 7 {
                currentWeek.append(nil)
            }
            weeks.append(currentWeek)
        }
        
        return weeks
    }
    
    private var monthPositions: [(month: String, weeks: Int)] {
        var positions: [(month: String, weeks: Int)] = []
        var currentMonth = ""
        var weekCount = 0
        
        for week in weeksData {
            if let firstDay = week.compactMap({ $0 }).first {
                let month = firstDay.date.formatted(.dateTime.month(.abbreviated))
                if month != currentMonth {
                    if !currentMonth.isEmpty {
                        positions.append((currentMonth, weekCount))
                    }
                    currentMonth = month
                    weekCount = 1
                } else {
                    weekCount += 1
                }
            }
        }
        
        if !currentMonth.isEmpty {
            positions.append((currentMonth, weekCount))
        }
        
        return positions
    }
    
    private func snapshotFor(_ date: Date) -> DailySnapshot? {
        let startOfDay = calendar.startOfDay(for: date)
        return snapshots.first { calendar.isDate($0.date, inSameDayAs: startOfDay) }
    }
}

// MARK: - Week Column

struct WeekColumn: View {
    let days: [DayData?]
    let colorSignal: ColorSignal
    let cellSize: CGFloat
    var onDaySelected: ((Date) -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 3) {
            ForEach(0..<7, id: \.self) { dayIndex in
                if let dayData = days[safe: dayIndex] ?? nil {
                    HeatmapCell(
                        dayData: dayData,
                        colorSignal: colorSignal,
                        size: cellSize,
                        onTap: { onDaySelected?(dayData.date) }
                    )
                } else {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.clear)
                        .frame(width: cellSize, height: cellSize)
                }
            }
        }
    }
}

// MARK: - Heatmap Cell

struct HeatmapCell: View {
    let dayData: DayData
    let colorSignal: ColorSignal
    let size: CGFloat
    let onTap: () -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        Button(action: onTap) {
            RoundedRectangle(cornerRadius: 2)
                .fill(cellColor)
                .frame(width: size, height: size)
                .overlay {
                    if calendar.isDateInToday(dayData.date) {
                        RoundedRectangle(cornerRadius: 2)
                            .strokeBorder(ColorPalette.accent, lineWidth: 1)
                    }
                }
        }
        .buttonStyle(.plain)
        .disabled(dayData.date > Date())
        .opacity(dayData.date > Date() ? 0.3 : 1.0)
    }
    
    private var cellColor: Color {
        guard let snapshot = dayData.snapshot else {
            return ColorPalette.tertiaryBackground
        }
        
        let intensity = colorSignal.intensity(for: snapshot)
        return colorSignal.baseColor.opacity(0.15 + (intensity * 0.7))
    }
}

// MARK: - Day Data

struct DayData {
    let date: Date
    let snapshot: DailySnapshot?
}

// MARK: - Array Extension

extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Preview

#Preview {
    HeatmapView(
        snapshots: [],
        colorSignal: .steps,
        weeksToShow: 16
    )
    .padding()
}
