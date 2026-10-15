//
//  TimelineTabView.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import SwiftUI
import SwiftData

/// Main timeline tab with month grid and heatmap views
struct TimelineTabView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \DailySnapshot.date, order: .reverse)
    private var allSnapshots: [DailySnapshot]
    
    @State private var viewMode: TimelineViewMode = .calendar
    @State private var selectedMonth: Date = Date()
    @State private var selectedColorSignal: ColorSignal = .steps
    @State private var selectedDate: Date?
    @State private var showingDayDetail = false
    
    private let calendar = Calendar.current
    
    var body: some View {
        NavigationStack {
            Group {
                if allSnapshots.isEmpty {
                    emptyStateView
                } else {
                    timelineContent
                }
            }
            .navigationTitle("Timeline")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("View", selection: $viewMode) {
                            ForEach(TimelineViewMode.allCases) { mode in
                                Label(mode.displayName, systemImage: mode.icon)
                                    .tag(mode)
                            }
                        }
                        
                        Divider()
                        
                        Menu("Color by") {
                            ForEach(ColorSignal.allCases) { signal in
                                Button {
                                    selectedColorSignal = signal
                                } label: {
                                    HStack {
                                        Image(systemName: signal.icon)
                                        Text(signal.displayName)
                                        if selectedColorSignal == signal {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingDayDetail) {
                if let date = selectedDate {
                    NavigationStack {
                        DayDetailView(
                            date: date,
                            snapshot: snapshotFor(date)
                        )
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Done") {
                                    showingDayDetail = false
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "calendar")
                .font(.system(size: 60))
                .foregroundStyle(ColorPalette.primaryGradient)
            
            VStack(spacing: 12) {
                Text("Your timeline will appear here")
                    .font(Typography.title)
                    .foregroundStyle(ColorPalette.primaryText)
                
                Text("As Signals collects data, you'll see your days visualized on a calendar with patterns emerging over time.")
                    .font(Typography.body)
                    .foregroundStyle(ColorPalette.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
            Spacer()
        }
    }
    
    // MARK: - Timeline Content
    
    private var timelineContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Signal selector
                signalSelector
                
                // View content based on mode
                switch viewMode {
                case .calendar:
                    calendarView
                case .heatmap:
                    heatmapView
                }
                
                // Stats summary
                statsSummary
                
                // Bottom padding
                Color.clear.frame(height: 20)
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Signal Selector
    
    private var signalSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ColorSignal.allCases) { signal in
                    SignalSelectorButton(
                        signal: signal,
                        isSelected: selectedColorSignal == signal
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedColorSignal = signal
                        }
                        Haptics.selection()
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Calendar View
    
    private var calendarView: some View {
        VStack(spacing: 24) {
            // Month navigation
            monthNavigator
            
            // Month grid
            MonthGridView(
                month: selectedMonth,
                snapshots: snapshotsForMonth(selectedMonth),
                colorSignal: selectedColorSignal
            ) { date in
                selectedDate = date
                showingDayDetail = true
            }
            .padding()
            .background(ColorPalette.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
    
    // MARK: - Month Navigator
    
    private var monthNavigator: some View {
        HStack {
            Button {
                let previousMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
                
                // Check if previous month is accessible for free users
                if !PaywallManager.shared.hasFullAccess {
                    let limit = PaywallManager.shared.featureLimit(for: .viewRecentTimeline) ?? 14
                    let cutoffDate = Calendar.current.date(byAdding: .day, value: -limit, to: Date()) ?? Date()
                    let endOfPrevMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: calendar.date(from: calendar.dateComponents([.year, .month], from: previousMonth))!)!
                    
                    if endOfPrevMonth < cutoffDate {
                        // Show paywall for older months
                        showingPaywall = true
                        return
                    }
                }
                
                withAnimation {
                    selectedMonth = previousMonth
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                    
                    // Show lock icon if going back would hit paywall
                    if !PaywallManager.shared.hasFullAccess && wouldHitPaywallGoingBack {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                    }
                }
                .foregroundStyle(ColorPalette.accent)
            }
            
            Spacer()
            
            Text(selectedMonth.formatted(.dateTime.month(.wide).year()))
                .font(Typography.headline)
                .foregroundStyle(ColorPalette.primaryText)
            
            Spacer()
            
            Button {
                withAnimation {
                    if !calendar.isDate(selectedMonth, equalTo: Date(), toGranularity: .month) {
                        selectedMonth = calendar.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
                    }
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundStyle(
                        calendar.isDate(selectedMonth, equalTo: Date(), toGranularity: .month)
                        ? ColorPalette.tertiaryText
                        : ColorPalette.accent
                    )
            }
            .disabled(calendar.isDate(selectedMonth, equalTo: Date(), toGranularity: .month))
        }
    }
    
    /// Check if navigating back one more month would hit the paywall
    private var wouldHitPaywallGoingBack: Bool {
        let twoMonthsBack = calendar.date(byAdding: .month, value: -2, to: selectedMonth) ?? selectedMonth
        let limit = PaywallManager.shared.featureLimit(for: .viewRecentTimeline) ?? 14
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -limit, to: Date()) ?? Date()
        let endOfTwoMonthsBack = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: calendar.date(from: calendar.dateComponents([.year, .month], from: twoMonthsBack))!)!
        
        return endOfTwoMonthsBack < cutoffDate
    }
    
    // MARK: - Heatmap View
    
    @State private var showingPaywall = false
    
    private var heatmapView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Last 16 weeks")
                .font(Typography.headline)
                .foregroundStyle(ColorPalette.primaryText)
            
            if PaywallManager.shared.canAccess(.viewHeatmap) {
                HeatmapView(
                    snapshots: allSnapshots,
                    colorSignal: selectedColorSignal,
                    weeksToShow: 16
                ) { date in
                    selectedDate = date
                    showingDayDetail = true
                }
                .padding()
                .background(ColorPalette.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            } else {
                lockedHeatmapView
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }
    
    private var lockedHeatmapView: some View {
        VStack(spacing: 20) {
            // Show a preview of the heatmap (blurred)
            HeatmapView(
                snapshots: allSnapshots,
                colorSignal: selectedColorSignal,
                weeksToShow: 16
            ) { _ in }
            .blur(radius: 8)
            .allowsHitTesting(false)
            .overlay {
                VStack(spacing: 16) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(ColorPalette.accent)
                    
                    Text("Unlock Activity Heatmap")
                        .font(Typography.headline)
                        .foregroundStyle(ColorPalette.primaryText)
                    
                    Text("Visualize your patterns with beautiful heatmaps")
                        .font(Typography.body)
                        .foregroundStyle(ColorPalette.secondaryText)
                        .multilineTextAlignment(.center)
                    
                    Button {
                        showingPaywall = true
                    } label: {
                        Text("Learn More")
                            .font(Typography.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(ColorPalette.accent)
                            .clipShape(Capsule())
                    }
                }
                .padding(32)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
        }
        .padding()
        .background(ColorPalette.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    // MARK: - Stats Summary
    
    private var statsSummary: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Summary")
                .font(Typography.headline)
                .foregroundStyle(ColorPalette.primaryText)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                SummaryStatCard(
                    title: "Days Tracked",
                    value: "\(allSnapshots.count)",
                    icon: "calendar",
                    color: ColorPalette.accent
                )
                
                SummaryStatCard(
                    title: "Current Streak",
                    value: "\(currentStreak)",
                    icon: "flame.fill",
                    color: .orange
                )
                
                if let avgSteps = averageSteps {
                    SummaryStatCard(
                        title: "Avg Steps",
                        value: formatNumber(avgSteps),
                        icon: "figure.walk",
                        color: ColorPalette.steps
                    )
                }
                
                if let avgSleep = averageSleep {
                    SummaryStatCard(
                        title: "Avg Sleep",
                        value: String(format: "%.1fh", avgSleep),
                        icon: "moon.fill",
                        color: ColorPalette.sleep
                    )
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Snapshots accessible based on subscription status
    private var accessibleSnapshots: [DailySnapshot] {
        if PaywallManager.shared.hasFullAccess {
            return allSnapshots
        }
        
        // Free users only see last 14 days
        let limit = PaywallManager.shared.featureLimit(for: .viewRecentTimeline) ?? 14
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -limit, to: Date()) ?? Date()
        return allSnapshots.filter { $0.date >= cutoffDate }
    }
    
    /// Whether the selected month is accessible for free users
    private var isSelectedMonthAccessible: Bool {
        if PaywallManager.shared.hasFullAccess {
            return true
        }
        
        let limit = PaywallManager.shared.featureLimit(for: .viewRecentTimeline) ?? 14
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -limit, to: Date()) ?? Date()
        
        // Check if selected month contains any accessible dates
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
        
        return endOfMonth >= cutoffDate
    }
    
    private func snapshotsForMonth(_ month: Date) -> [DailySnapshot] {
        let components = calendar.dateComponents([.year, .month], from: month)
        let monthSnapshots = allSnapshots.filter { snapshot in
            let snapshotComponents = calendar.dateComponents([.year, .month], from: snapshot.date)
            return snapshotComponents.year == components.year && snapshotComponents.month == components.month
        }
        
        // For free users, filter to only show accessible dates
        if !PaywallManager.shared.hasFullAccess {
            let limit = PaywallManager.shared.featureLimit(for: .viewRecentTimeline) ?? 14
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -limit, to: Date()) ?? Date()
            return monthSnapshots.filter { $0.date >= cutoffDate }
        }
        
        return monthSnapshots
    }
    
    private func snapshotFor(_ date: Date) -> DailySnapshot? {
        let startOfDay = calendar.startOfDay(for: date)
        return allSnapshots.first { calendar.isDate($0.date, inSameDayAs: startOfDay) }
    }
    
    private var currentStreak: Int {
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        while let _ = snapshotFor(currentDate) {
            streak += 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
        }
        
        return streak
    }
    
    private var averageSteps: Int? {
        let stepsArray = allSnapshots.compactMap { $0.stepCount }
        guard !stepsArray.isEmpty else { return nil }
        return stepsArray.reduce(0, +) / stepsArray.count
    }
    
    private var averageSleep: Double? {
        let sleepArray = allSnapshots.compactMap { $0.sleepHours }
        guard !sleepArray.isEmpty else { return nil }
        return sleepArray.reduce(0, +) / Double(sleepArray.count)
    }
    
    private func formatNumber(_ number: Int) -> String {
        if number >= 1000 {
            return String(format: "%.1fk", Double(number) / 1000)
        }
        return "\(number)"
    }
}

// MARK: - Timeline View Mode

enum TimelineViewMode: String, CaseIterable, Identifiable {
    case calendar
    case heatmap
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .calendar: return "Calendar"
        case .heatmap: return "Heatmap"
        }
    }
    
    var icon: String {
        switch self {
        case .calendar: return "calendar"
        case .heatmap: return "square.grid.3x3"
        }
    }
}

// MARK: - Signal Selector Button

struct SignalSelectorButton: View {
    let signal: ColorSignal
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: signal.icon)
                    .font(.caption)
                Text(signal.displayName)
                    .font(Typography.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? signal.baseColor.opacity(0.15) : ColorPalette.secondaryBackground)
            .foregroundStyle(isSelected ? signal.baseColor : ColorPalette.secondaryText)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Summary Stat Card

struct SummaryStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
            
            Text(value)
                .font(Typography.largeMetric)
                .foregroundStyle(ColorPalette.primaryText)
            
            Text(title)
                .font(Typography.caption)
                .foregroundStyle(ColorPalette.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(ColorPalette.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview

#Preview {
    TimelineTabView()
        .environment(AppState())
        .modelContainer(PersistenceController.preview().container)
}
