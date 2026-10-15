//
//  DayDetailView.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import SwiftUI
import SwiftData

/// Detailed view for a single day's snapshot with all available signals
struct DayDetailView: View {
    let date: Date
    let snapshot: DailySnapshot?
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query private var insightsForDay: [Insight]
    
    init(date: Date, snapshot: DailySnapshot?) {
        self.date = date
        self.snapshot = snapshot
        
        // Query insights that reference this date
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        _insightsForDay = Query(filter: #Predicate<Insight> { insight in
            insight.generatedDate >= startOfDay && insight.generatedDate < endOfDay
        })
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                headerSection
                
                if let snapshot = snapshot {
                    // Health signals
                    if hasHealthData(snapshot) {
                        healthSection(snapshot)
                    }
                    
                    // Activity signals
                    if hasActivityData(snapshot) {
                        activitySection(snapshot)
                    }
                    
                    // Location signals
                    if hasLocationData(snapshot) {
                        locationSection(snapshot)
                    }
                    
                    // Weather
                    if let weather = snapshot.weatherCondition {
                        weatherSection(weather)
                    }
                    
                    // Reflections
                    if let reflections = snapshot.reflections, !reflections.isEmpty {
                        reflectionsSection(reflections)
                    }
                    
                    // Mood entries
                    if let moods = snapshot.moodEntries, !moods.isEmpty {
                        moodSection(moods)
                    }
                } else {
                    emptyDayView
                }
                
                // Related insights
                if !insightsForDay.isEmpty {
                    insightsSection
                }
            }
            .padding()
        }
        .background(ColorPalette.background)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(date.formatted(.dateTime.weekday(.wide)))
                .font(Typography.caption)
                .foregroundStyle(ColorPalette.secondaryText)
            
            Text(date.formatted(.dateTime.month(.wide).day().year()))
                .font(Typography.largeTitle)
                .foregroundStyle(ColorPalette.primaryText)
            
            if Calendar.current.isDateInToday(date) {
                Text("Today")
                    .font(Typography.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(ColorPalette.accent.opacity(0.15))
                    .foregroundStyle(ColorPalette.accent)
                    .clipShape(Capsule())
            }
        }
    }
    
    // MARK: - Health Section
    
    private func healthSection(_ snapshot: DailySnapshot) -> some View {
        SignalSection(title: "Health", icon: "heart.fill") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                if let steps = snapshot.stepCount {
                    SignalMetricCard(
                        title: "Steps",
                        value: formatNumber(steps),
                        icon: "figure.walk",
                        color: ColorPalette.steps
                    )
                }
                
                if let sleep = snapshot.sleepHours {
                    SignalMetricCard(
                        title: "Sleep",
                        value: String(format: "%.1fh", sleep),
                        icon: "moon.fill",
                        color: ColorPalette.sleep,
                        subtitle: snapshot.sleepQuality?.displayName
                    )
                }
                
                if let exercise = snapshot.exerciseMinutes {
                    SignalMetricCard(
                        title: "Exercise",
                        value: "\(exercise)m",
                        icon: "flame.fill",
                        color: ColorPalette.exercise
                    )
                }
                
                if let hr = snapshot.restingHeartRate {
                    SignalMetricCard(
                        title: "Resting HR",
                        value: String(format: "%.0f", hr),
                        icon: "heart.fill",
                        color: ColorPalette.heartRate,
                        subtitle: "bpm"
                    )
                }
                
                if let hrv = snapshot.hrvAverage {
                    SignalMetricCard(
                        title: "HRV",
                        value: String(format: "%.0f", hrv),
                        icon: "waveform.path.ecg",
                        color: ColorPalette.heartRate,
                        subtitle: "ms"
                    )
                }
            }
        }
    }
    
    // MARK: - Activity Section
    
    private func activitySection(_ snapshot: DailySnapshot) -> some View {
        SignalSection(title: "Activity", icon: "iphone") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                if let screenTime = snapshot.screenTimeMinutes {
                    SignalMetricCard(
                        title: "Screen Time",
                        value: formatMinutes(screenTime),
                        icon: "iphone",
                        color: ColorPalette.screenTime
                    )
                }
                
                if let pickups = snapshot.appPickups {
                    SignalMetricCard(
                        title: "Pickups",
                        value: "\(pickups)",
                        icon: "hand.tap.fill",
                        color: ColorPalette.screenTime
                    )
                }
                
                if let activity = snapshot.activityType {
                    SignalMetricCard(
                        title: "Primary Activity",
                        value: activity.displayName,
                        icon: activity.icon,
                        color: ColorPalette.exercise
                    )
                }
                
                if let activeMinutes = snapshot.activeMinutes {
                    SignalMetricCard(
                        title: "Active Time",
                        value: "\(activeMinutes)m",
                        icon: "figure.run",
                        color: ColorPalette.exercise
                    )
                }
            }
        }
    }
    
    // MARK: - Location Section
    
    private func locationSection(_ snapshot: DailySnapshot) -> some View {
        SignalSection(title: "Places", icon: "location.fill") {
            VStack(alignment: .leading, spacing: 12) {
                if let clusters = snapshot.locationClusters {
                    ForEach(clusters, id: \.label) { cluster in
                        HStack {
                            Image(systemName: cluster.isNew ? "sparkles" : "mappin.circle.fill")
                                .foregroundStyle(cluster.isNew ? .yellow : ColorPalette.location)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(cluster.label)
                                    .font(Typography.body)
                                    .foregroundStyle(ColorPalette.primaryText)
                                
                                Text(formatMinutes(cluster.timeSpentMinutes))
                                    .font(Typography.caption)
                                    .foregroundStyle(ColorPalette.secondaryText)
                            }
                            
                            Spacer()
                            
                            if cluster.isNew {
                                Text("New")
                                    .font(Typography.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(.yellow.opacity(0.2))
                                    .foregroundStyle(.yellow)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                
                HStack(spacing: 16) {
                    if let distance = snapshot.distanceTraveled {
                        HStack(spacing: 4) {
                            Image(systemName: "map.fill")
                                .foregroundStyle(ColorPalette.location)
                            Text(formatDistance(distance))
                                .font(Typography.caption)
                                .foregroundStyle(ColorPalette.secondaryText)
                        }
                    }
                    
                    if let places = snapshot.placesVisited {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundStyle(ColorPalette.location)
                            Text("\(places) places")
                                .font(Typography.caption)
                                .foregroundStyle(ColorPalette.secondaryText)
                        }
                    }
                    
                    if let leftHome = snapshot.leftHome {
                        HStack(spacing: 4) {
                            Image(systemName: leftHome ? "house" : "house.fill")
                                .foregroundStyle(ColorPalette.location)
                            Text(leftHome ? "Left home" : "Home day")
                                .font(Typography.caption)
                                .foregroundStyle(ColorPalette.secondaryText)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Weather Section
    
    private func weatherSection(_ weather: WeatherCondition) -> some View {
        SignalSection(title: "Weather", icon: "cloud.sun.fill") {
            HStack {
                Image(systemName: weather.icon)
                    .font(.title2)
                    .foregroundStyle(ColorPalette.color(for: weather))
                
                Text(weather.displayName)
                    .font(Typography.body)
                    .foregroundStyle(ColorPalette.primaryText)
                
                Spacer()
            }
        }
    }
    
    // MARK: - Reflections Section
    
    private func reflectionsSection(_ reflections: [Reflection]) -> some View {
        SignalSection(title: "Reflections", icon: "pencil.and.outline") {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(reflections, id: \.id) { reflection in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(reflection.text)
                            .font(Typography.body)
                            .foregroundStyle(ColorPalette.primaryText)
                        
                        HStack {
                            if let sentiment = reflection.sentiment {
                                Image(systemName: sentiment.icon)
                                    .foregroundStyle(ColorPalette.color(for: sentiment))
                            }
                            
                            Text(reflection.createdAt.formatted(date: .omitted, time: .shortened))
                                .font(Typography.caption)
                                .foregroundStyle(ColorPalette.tertiaryText)
                        }
                    }
                    .padding()
                    .background(ColorPalette.tertiaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
    
    // MARK: - Mood Section
    
    private func moodSection(_ moods: [MoodEntry]) -> some View {
        SignalSection(title: "Mood", icon: "face.smiling") {
            HStack(spacing: 12) {
                ForEach(moods, id: \.id) { moodEntry in
                    VStack(spacing: 4) {
                        Circle()
                            .fill(ColorPalette.color(for: moodEntry.mood))
                            .frame(width: 32, height: 32)
                            .overlay {
                                Text("\(moodEntry.mood.rawValue)")
                                    .font(Typography.caption)
                                    .foregroundStyle(.white)
                            }
                        
                        Text(moodEntry.timestamp.formatted(date: .omitted, time: .shortened))
                            .font(.caption2)
                            .foregroundStyle(ColorPalette.tertiaryText)
                    }
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Insights Section
    
    private var insightsSection: some View {
        SignalSection(title: "Related Insights", icon: "lightbulb.fill") {
            ForEach(insightsForDay) { insight in
                NavigationLink(destination: InsightDetailView(insight: insight)) {
                    InsightCardView(insight: insight)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Empty Day View
    
    private var emptyDayView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundStyle(ColorPalette.tertiaryText)
            
            Text("No data for this day")
                .font(Typography.body)
                .foregroundStyle(ColorPalette.secondaryText)
            
            if date > Date() {
                Text("This day hasn't happened yet.")
                    .font(Typography.caption)
                    .foregroundStyle(ColorPalette.tertiaryText)
            } else {
                Text("Signals wasn't collecting data on this day.")
                    .font(Typography.caption)
                    .foregroundStyle(ColorPalette.tertiaryText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(48)
    }
    
    // MARK: - Helpers
    
    private func hasHealthData(_ snapshot: DailySnapshot) -> Bool {
        snapshot.stepCount != nil ||
        snapshot.sleepHours != nil ||
        snapshot.exerciseMinutes != nil ||
        snapshot.restingHeartRate != nil ||
        snapshot.hrvAverage != nil
    }
    
    private func hasActivityData(_ snapshot: DailySnapshot) -> Bool {
        snapshot.screenTimeMinutes != nil ||
        snapshot.appPickups != nil ||
        snapshot.activityType != nil ||
        snapshot.activeMinutes != nil
    }
    
    private func hasLocationData(_ snapshot: DailySnapshot) -> Bool {
        (snapshot.locationClusters != nil && !snapshot.locationClusters!.isEmpty) ||
        snapshot.distanceTraveled != nil ||
        snapshot.placesVisited != nil
    }
    
    private func formatNumber(_ number: Int) -> String {
        if number >= 1000 {
            return String(format: "%.1fk", Double(number) / 1000)
        }
        return "\(number)"
    }
    
    private func formatMinutes(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins)m"
    }
    
    private func formatDistance(_ meters: Double) -> String {
        if meters >= 1000 {
            return String(format: "%.1f km", meters / 1000)
        }
        return String(format: "%.0f m", meters)
    }
}

// MARK: - Supporting Views

struct SignalSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(ColorPalette.accent)
                
                Text(title)
                    .font(Typography.headline)
                    .foregroundStyle(ColorPalette.primaryText)
            }
            
            content
        }
        .padding()
        .background(ColorPalette.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct SignalMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var subtitle: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(Typography.metric)
                    .foregroundStyle(ColorPalette.primaryText)
                
                HStack(spacing: 4) {
                    Text(title)
                        .font(Typography.caption)
                        .foregroundStyle(ColorPalette.secondaryText)
                    
                    if let subtitle {
                        Text("•")
                            .foregroundStyle(ColorPalette.tertiaryText)
                        Text(subtitle)
                            .font(Typography.caption)
                            .foregroundStyle(ColorPalette.tertiaryText)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(ColorPalette.tertiaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DayDetailView(date: Date(), snapshot: nil)
    }
    .modelContainer(PersistenceController.preview().container)
}
