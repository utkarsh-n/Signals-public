//
//  InsightsTabView.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//
//  Insights tab with widget grid layout
//  Displays analytics widgets using Swift Charts and Liquid Glass
//

import SwiftUI
import SwiftData

/// Main insights tab showing a widget grid with analytics
struct InsightsTabView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \DailySnapshot.date, order: .reverse)
    private var recentSnapshots: [DailySnapshot]
    
    @Query(sort: \Insight.generatedDate, order: .reverse)
    private var allInsights: [Insight]
    
    @Query(sort: \WeeklyReport.weekStartDate, order: .reverse)
    private var weeklyReports: [WeeklyReport]
    
    @State private var selectedInsight: Insight?
    @State private var showingInsightList = false
    
    private var todaySnapshot: DailySnapshot? {
        recentSnapshots.first { Calendar.current.isDateInToday($0.date) }
    }
    
    private var weekSnapshots: [DailySnapshot] {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return recentSnapshots.filter { $0.date >= weekAgo }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if hasAnyData {
                    widgetGridView
                } else {
                    emptyStateView
                }
            }
            .navigationTitle("Insights")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.light()
                        showingInsightList = true
                    } label: {
                        Image(systemName: "list.bullet")
                    }
                }
            }
            .sheet(isPresented: $showingInsightList) {
                InsightListView(insights: allInsights, reports: weeklyReports)
                    .onAppear { Haptics.sheetPresented() }
            }
            .sheet(item: $selectedInsight) { insight in
                NavigationStack {
                    InsightDetailView(insight: insight)
                }
                .onAppear { Haptics.sheetPresented() }
            }
            .refreshable {
                Haptics.light()
            }
        }
    }
    
    private var hasAnyData: Bool {
        todaySnapshot?.hasData ?? false || !allInsights.isEmpty
    }
    
    // MARK: - Widget Grid
    
    private var widgetGridView: some View {
        LazyVStack(spacing: Spacing.standard) {
            // Day Composition (Large)
            if let snapshot = todaySnapshot {
                DayCompositionWidget(
                    sleepHours: snapshot.sleepHours ?? 0,
                    workHours: calculateWorkHours(snapshot),
                    screenTimeHours: Double(snapshot.screenTimeMinutes ?? 0) / 60,
                    activeHours: Double(snapshot.activeMinutes ?? snapshot.exerciseMinutes ?? 0) / 60,
                    homeIdleHours: calculateHomeIdleHours(snapshot)
                )
                .staggeredFadeIn(index: 0, stagger: 0.08)
            }
            
            // Steps + Sleep row
            HStack(spacing: Spacing.standard) {
                StepsWidget(
                    steps: todaySnapshot?.stepCount ?? 0,
                    average: calculateAverageSteps(),
                    distance: todaySnapshot?.distanceTraveled
                )
                
                SleepWidget(
                    hours: todaySnapshot?.sleepHours ?? 0,
                    quality: todaySnapshot?.sleepQuality,
                    weeklyTrend: weekSnapshots.reversed().compactMap { $0.sleepHours }
                )
            }
            .staggeredFadeIn(index: 1, stagger: 0.08)
            
            // Screen Time + Idle row (if screen time enabled)
            if todaySnapshot?.screenTimeMinutes != nil || !weekSnapshots.isEmpty {
                HStack(spacing: Spacing.standard) {
                    ScreenTimeWidget(
                        totalMinutes: todaySnapshot?.screenTimeMinutes ?? 0,
                        averageMinutes: calculateAverageScreenTime(),
                        pickups: todaySnapshot?.appPickups ?? 0,
                        hourlyData: [] // Would need hourly data
                    )
                    
                    IdleScoreWidget(
                        idleHours: calculateIdleHours(todaySnapshot),
                        weeklyTrend: weekSnapshots.reversed().map { calculateIdleHours($0) }
                    )
                }
                .staggeredFadeIn(index: 2, stagger: 0.08)
            }
            
            // Trend Card
            if let trend = generateTrend() {
                TrendCardWidget(
                    trendText: trend.text,
                    trendType: trend.type,
                    sparklineData: trend.data
                )
                .staggeredFadeIn(index: 3, stagger: 0.08)
            }
            
            // Weekly Insight
            WeeklyInsightWidget(
                insight: allInsights.first,
                onTap: {
                    selectedInsight = allInsights.first
                }
            )
            .staggeredFadeIn(index: 4, stagger: 0.08)
            
            // Location Breakdown (if location enabled)
            if let snapshot = todaySnapshot, snapshot.locationClusters != nil {
                LocationBreakdownWidget(
                    homeHours: calculateLocationHours(snapshot, type: "Home"),
                    workHours: calculateLocationHours(snapshot, type: "Work"),
                    transitHours: calculateLocationHours(snapshot, type: "Transit"),
                    otherHours: calculateLocationHours(snapshot, type: "Other"),
                    placesCount: snapshot.placesVisited ?? 0
                )
                .staggeredFadeIn(index: 5, stagger: 0.08)
            }
            
            // Paywall prompt for free users
            if !PaywallManager.shared.hasFullAccess {
                unlockPremiumCard
                    .staggeredFadeIn(index: 6, stagger: 0.08)
            }
            
            // Bottom padding
            Color.clear.frame(height: 100)
        }
        .padding(.horizontal, Spacing.standard)
        .padding(.top, Spacing.sm)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()
            
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundStyle(ColorPalette.primaryGradient)
            
            VStack(spacing: Spacing.md) {
                Text("Your insights will appear here")
                    .font(Typography.title)
                    .foregroundStyle(ColorPalette.primaryText)
                
                Text("Signals analyzes your patterns over time and generates personalized insights every week.")
                    .font(Typography.body)
                    .foregroundStyle(ColorPalette.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xxl)
            }
            
            // Progress indicator
            VStack(spacing: Spacing.sm) {
                ProgressView(value: appState.daysOfData, total: 7)
                    .tint(ColorPalette.accent)
                    .frame(width: 200)
                
                Text("\(Int(appState.daysOfData)) of 7 days collected")
                    .font(Typography.caption)
                    .foregroundStyle(ColorPalette.tertiaryText)
            }
            .padding(.top, Spacing.standard)
            
            Spacer()
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Unlock Premium Card
    
    @State private var showingPaywall = false
    
    private var unlockPremiumCard: some View {
        VStack(spacing: Spacing.md) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(ColorPalette.accent)
                
                Text("Unlock all insights and analytics")
                    .font(Typography.body)
                    .foregroundStyle(ColorPalette.primaryText)
                
                Spacer()
            }
            
            Button {
                showingPaywall = true
            } label: {
                Text("Subscribe to Signals")
                    .font(Typography.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(ColorPalette.accent)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
            }
        }
        .padding(Spacing.standard)
        .liquidGlass(tint: ColorPalette.accent.opacity(0.05), cornerRadius: CornerRadius.standard)
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }
    
    // MARK: - Calculation Helpers
    
    private func calculateAverageSteps() -> Int {
        let steps = weekSnapshots.compactMap { $0.stepCount }
        guard !steps.isEmpty else { return 7500 }
        return steps.reduce(0, +) / steps.count
    }
    
    private func calculateAverageScreenTime() -> Int {
        let times = weekSnapshots.compactMap { $0.screenTimeMinutes }
        guard !times.isEmpty else { return 180 }
        return times.reduce(0, +) / times.count
    }
    
    private func calculateWorkHours(_ snapshot: DailySnapshot?) -> Double {
        // Estimate from location clusters
        guard let clusters = snapshot?.locationClusters else { return 0 }
        let workMinutes = clusters.filter { $0.label.lowercased().contains("work") || $0.label.lowercased().contains("office") }
            .reduce(0) { $0 + $1.timeSpentMinutes }
        return Double(workMinutes) / 60
    }
    
    private func calculateHomeIdleHours(_ snapshot: DailySnapshot?) -> Double {
        guard let snapshot = snapshot else { return 0 }
        let awakeHours: Double = 16 // Assume 16 waking hours
        let activeHours = Double(snapshot.activeMinutes ?? snapshot.exerciseMinutes ?? 0) / 60
        let screenHours = Double(snapshot.screenTimeMinutes ?? 0) / 60
        let workHours = calculateWorkHours(snapshot)
        return max(0, awakeHours - activeHours - screenHours - workHours)
    }
    
    private func calculateIdleHours(_ snapshot: DailySnapshot?) -> Double {
        guard let snapshot = snapshot else { return 0 }
        let awakeHours: Double = 16
        let activeHours = Double(snapshot.activeMinutes ?? snapshot.exerciseMinutes ?? 0) / 60
        return max(0, awakeHours - activeHours)
    }
    
    private func calculateLocationHours(_ snapshot: DailySnapshot?, type: String) -> Double {
        guard let clusters = snapshot?.locationClusters else { return 0 }
        let minutes = clusters.filter { $0.label.lowercased().contains(type.lowercased()) }
            .reduce(0) { $0 + $1.timeSpentMinutes }
        return Double(minutes) / 60
    }
    
    private func generateTrend() -> (text: String, type: TrendCardWidget.TrendType, data: [Double])? {
        guard weekSnapshots.count >= 3 else { return nil }
        
        // Check screen time trend
        let screenTimes = weekSnapshots.reversed().compactMap { $0.screenTimeMinutes }.map { Double($0) }
        if screenTimes.count >= 3 {
            let recent = screenTimes.suffix(3).reduce(0, +) / 3
            let earlier = screenTimes.prefix(3).reduce(0, +) / max(Double(screenTimes.prefix(3).count), 1)
            let change = ((recent - earlier) / max(earlier, 1)) * 100
            
            if abs(change) >= 10 {
                let type: TrendCardWidget.TrendType = change < 0 ? .down : .up
                let text = change < 0 ? "Your screen time is down \(Int(abs(change)))% this week" : "Your screen time is up \(Int(change))% this week"
                return (text, type, screenTimes)
            }
        }
        
        // Check sleep trend
        let sleepHours = weekSnapshots.reversed().compactMap { $0.sleepHours }
        if sleepHours.count >= 3 {
            let recent = sleepHours.suffix(3).reduce(0, +) / 3
            let earlier = sleepHours.prefix(3).reduce(0, +) / max(Double(sleepHours.prefix(3).count), 1)
            let diff = recent - earlier
            
            if abs(diff) >= 0.3 {
                let type: TrendCardWidget.TrendType = diff > 0 ? .up : .down
                let text = diff > 0 ? "You're sleeping \(Int(diff * 60)) minutes more on average" : "You're sleeping \(Int(abs(diff) * 60)) minutes less on average"
                return (text, type, sleepHours)
            }
        }
        
        return ("Keep collecting data for personalized trends", .neutral, [])
    }
}

// MARK: - Insight List View (Sheet)

struct InsightListView: View {
    let insights: [Insight]
    let reports: [WeeklyReport]
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFilter: InsightFilter = .all
    @State private var searchText = ""
    @State private var showingSavedOnly = false
    
    var body: some View {
        NavigationStack {
            List {
                // Weekly Reports Section
                if !reports.isEmpty {
                    Section("Weekly Reports") {
                        ForEach(reports.prefix(3)) { report in
                            NavigationLink(destination: WeeklyReportView(report: report)) {
                                HStack {
                                    VStack(alignment: .leading, spacing: Spacing.xs) {
                                        Text("Week \(report.weekNumber)")
                                            .font(Typography.body)
                                        Text(report.formattedDateRange)
                                            .font(Typography.caption)
                                            .foregroundStyle(ColorPalette.secondaryText)
                                    }
                                    Spacer()
                                    if !report.isRead {
                                        Circle()
                                            .fill(ColorPalette.accent)
                                            .frame(width: 8, height: 8)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Insights Section
                Section("Insights") {
                    ForEach(filteredInsights) { insight in
                        NavigationLink(destination: InsightDetailView(insight: insight)) {
                            HStack(spacing: Spacing.md) {
                                Image(systemName: insight.category.icon)
                                    .foregroundStyle(ColorPalette.color(for: insight.category))
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: Spacing.xs) {
                                    Text(insight.title)
                                        .font(Typography.body)
                                        .lineLimit(1)
                                    Text(insight.generatedDate.formatted(date: .abbreviated, time: .omitted))
                                        .font(Typography.caption)
                                        .foregroundStyle(ColorPalette.secondaryText)
                                }
                                
                                Spacer()
                                
                                if insight.isSaved {
                                    Image(systemName: "bookmark.fill")
                                        .font(.caption)
                                        .foregroundStyle(ColorPalette.accent)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("All Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showingSavedOnly.toggle()
                        } label: {
                            Label(showingSavedOnly ? "Show All" : "Saved Only", systemImage: showingSavedOnly ? "bookmark.slash" : "bookmark")
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search insights")
        }
    }
    
    private var filteredInsights: [Insight] {
        var result = insights
        
        if showingSavedOnly {
            result = result.filter { $0.isSaved }
        }
        
        if !searchText.isEmpty {
            result = result.filter { insight in
                insight.title.localizedCaseInsensitiveContains(searchText) ||
                insight.body.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return result
    }
}

// MARK: - Filter Types

enum InsightFilter: Hashable, CaseIterable {
    case all
    case category(InsightCategory)
    
    static var allCases: [InsightFilter] {
        [.all] + InsightCategory.allCases.map { .category($0) }
    }
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .category(let cat): return cat.displayName
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    var color: Color = ColorPalette.accent
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            Haptics.light()
            action()
        }) {
            HStack(spacing: Spacing.xs) {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption2)
                }
                Text(title)
                    .font(Typography.caption)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .foregroundStyle(isSelected ? color : ColorPalette.secondaryText)
            .liquidGlassCapsule(tint: isSelected ? color.opacity(0.15) : nil)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Past Report Row

struct PastReportRow: View {
    let report: WeeklyReport
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Week \(report.weekNumber)")
                    .font(Typography.body)
                    .foregroundStyle(ColorPalette.primaryText)
                
                Text(report.formattedDateRange)
                    .font(Typography.caption)
                    .foregroundStyle(ColorPalette.secondaryText)
            }
            
            Spacer()
            
            HStack(spacing: Spacing.xs) {
                Text("\(report.insightCount)")
                    .font(Typography.metric)
                    .foregroundStyle(ColorPalette.primaryText)
                
                Text("insights")
                    .font(Typography.caption)
                    .foregroundStyle(ColorPalette.secondaryText)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(ColorPalette.tertiaryText)
        }
        .padding(Spacing.standard)
        .liquidGlass(cornerRadius: CornerRadius.md)
    }
}

// MARK: - Report History View

struct ReportHistoryView: View {
    let reports: [WeeklyReport]
    
    var body: some View {
        List(reports) { report in
            NavigationLink(destination: WeeklyReportView(report: report)) {
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Week \(report.weekNumber)")
                            .font(Typography.body)
                        
                        Text(report.formattedDateRange)
                            .font(Typography.caption)
                            .foregroundStyle(ColorPalette.secondaryText)
                    }
                    
                    Spacer()
                    
                    if !report.isRead {
                        Circle()
                            .fill(ColorPalette.accent)
                            .frame(width: 8, height: 8)
                    }
                }
            }
        }
        .navigationTitle("Past Reports")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview {
    InsightsTabView()
        .environment(AppState())
        .modelContainer(PersistenceController.preview().container)
}
