//
//  WeeklyReportView.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import SwiftUI
import SwiftData

/// Full weekly report view with summary, insights, and data visualizations
struct WeeklyReportView: View {
    let report: WeeklyReport
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Hero header
                headerSection
                
                // Summary
                summarySection
                
                // Week statistics
                statisticsSection
                
                // Week comparison
                if report.comparisonToPrevious != nil {
                    comparisonSection
                }
                
                // Insights
                insightsSection
            }
            .padding()
        }
        .background(ColorPalette.background)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            markAsRead()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Week \(report.weekNumber)")
                .font(Typography.caption)
                .foregroundStyle(ColorPalette.secondaryText)
            
            Text("Weekly Report")
                .font(Typography.largeTitle)
                .foregroundStyle(ColorPalette.primaryText)
            
            Text(report.formattedDateRange)
                .font(Typography.body)
                .foregroundStyle(ColorPalette.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(
            LinearGradient(
                colors: [.purple.opacity(0.3), .blue.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    // MARK: - Summary Section
    
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Summary")
                .font(Typography.headline)
                .foregroundStyle(ColorPalette.primaryText)
            
            Text(report.summary.isEmpty ? "Your week at a glance." : report.summary)
                .font(Typography.body)
                .foregroundStyle(ColorPalette.secondaryText)
                .lineSpacing(4)
        }
    }
    
    // MARK: - Statistics Section
    
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("This Week")
                .font(Typography.headline)
                .foregroundStyle(ColorPalette.primaryText)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                if let steps = report.averageSteps {
                    WeekStatCard(
                        title: "Avg Steps",
                        value: formatNumber(steps),
                        icon: "figure.walk",
                        color: ColorPalette.steps
                    )
                }
                
                if let sleep = report.averageSleep {
                    WeekStatCard(
                        title: "Avg Sleep",
                        value: String(format: "%.1fh", sleep),
                        icon: "moon.fill",
                        color: ColorPalette.sleep
                    )
                }
                
                if let screenTime = report.averageScreenTime {
                    WeekStatCard(
                        title: "Avg Screen",
                        value: formatMinutes(screenTime),
                        icon: "iphone",
                        color: ColorPalette.screenTime
                    )
                }
                
                WeekStatCard(
                    title: "Reflections",
                    value: "\(report.totalReflections)",
                    icon: "text.quote",
                    color: ColorPalette.reflection
                )
            }
        }
    }
    
    // MARK: - Comparison Section
    
    private var comparisonSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("vs Last Week")
                .font(Typography.headline)
                .foregroundStyle(ColorPalette.primaryText)
            
            if let comparison = report.comparisonToPrevious {
                VStack(spacing: 12) {
                    if let stepsChange = comparison.stepsChange {
                        ComparisonRow(
                            label: "Steps",
                            change: stepsChange,
                            icon: "figure.walk"
                        )
                    }
                    
                    if let sleepChange = comparison.sleepChange {
                        ComparisonRow(
                            label: "Sleep",
                            change: sleepChange,
                            icon: "moon.fill"
                        )
                    }
                    
                    if let screenTimeChange = comparison.screenTimeChange {
                        ComparisonRow(
                            label: "Screen time",
                            change: screenTimeChange,
                            icon: "iphone",
                            invertColor: true
                        )
                    }
                    
                    if let moodChange = comparison.moodChange {
                        ComparisonRow(
                            label: "Mood",
                            change: moodChange,
                            icon: "face.smiling"
                        )
                    }
                }
                .padding()
                .background(ColorPalette.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }
    
    // MARK: - Insights Section
    
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Insights")
                    .font(Typography.headline)
                    .foregroundStyle(ColorPalette.primaryText)
                
                Spacer()
                
                Text("\(report.insightCount) this week")
                    .font(Typography.caption)
                    .foregroundStyle(ColorPalette.secondaryText)
            }
            
            if let insights = report.insights, !insights.isEmpty {
                ForEach(insights) { insight in
                    NavigationLink(destination: InsightDetailView(insight: insight)) {
                        InsightCardView(insight: insight)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                EmptyInsightsView()
            }
        }
    }
    
    // MARK: - Helpers
    
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
    
    private func markAsRead() {
        if !report.isRead {
            report.markAsRead()
        }
    }
}

// MARK: - Supporting Views

struct WeekStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
            }
            
            Text(value)
                .font(Typography.largeMetric)
                .foregroundStyle(ColorPalette.primaryText)
            
            Text(title)
                .font(Typography.caption)
                .foregroundStyle(ColorPalette.secondaryText)
        }
        .padding()
        .background(ColorPalette.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ComparisonRow: View {
    let label: String
    let change: Double
    let icon: String
    var invertColor: Bool = false
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(ColorPalette.secondaryText)
                .frame(width: 24)
            
            Text(label)
                .font(Typography.body)
                .foregroundStyle(ColorPalette.primaryText)
            
            Spacer()
            
            HStack(spacing: 4) {
                Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                    .font(.caption)
                
                Text(String(format: "%.0f%%", abs(change)))
                    .font(Typography.body)
            }
            .foregroundStyle(changeColor)
        }
    }
    
    private var changeColor: Color {
        if change == 0 {
            return ColorPalette.secondaryText
        }
        
        let isPositive = invertColor ? change < 0 : change > 0
        return isPositive ? .green : .orange
    }
}

struct EmptyInsightsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.largeTitle)
                .foregroundStyle(ColorPalette.tertiaryText)
            
            Text("No insights this week")
                .font(Typography.body)
                .foregroundStyle(ColorPalette.secondaryText)
            
            Text("Keep using Signals and insights will appear as patterns emerge.")
                .font(Typography.caption)
                .foregroundStyle(ColorPalette.tertiaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(ColorPalette.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Weekly Report Card (for feed display)

struct WeeklyReportCard: View {
    let report: WeeklyReport
    var onTap: (() -> Void)? = nil
    
    var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundStyle(.white)
                            Text("Weekly Report")
                                .font(Typography.headline)
                                .foregroundStyle(.white)
                        }
                        
                        Text(report.formattedDateRange)
                            .font(Typography.caption)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    if !report.isRead {
                        Text("New")
                            .font(Typography.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.white.opacity(0.2))
                            .clipShape(Capsule())
                            .foregroundStyle(.white)
                    }
                }
                
                // Summary preview
                if !report.summary.isEmpty {
                    Text(report.summary)
                        .font(Typography.body)
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(2)
                }
                
                // Stats preview
                HStack(spacing: 16) {
                    if let steps = report.averageSteps {
                        StatPreview(value: formatNumber(steps), label: "steps/day", icon: "figure.walk")
                    }
                    
                    if let sleep = report.averageSleep {
                        StatPreview(value: String(format: "%.1f", sleep), label: "hrs sleep", icon: "moon.fill")
                    }
                    
                    StatPreview(value: "\(report.insightCount)", label: "insights", icon: "sparkles")
                }
                
                // CTA
                HStack {
                    Spacer()
                    
                    Text("View Report")
                        .font(Typography.caption)
                        .foregroundStyle(.white)
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            .padding(20)
            .background(
                LinearGradient(
                    colors: [.purple, .blue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }
    
    private func formatNumber(_ number: Int) -> String {
        if number >= 1000 {
            return String(format: "%.1fk", Double(number) / 1000)
        }
        return "\(number)"
    }
}

struct StatPreview: View {
    let value: String
    let label: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(Typography.metric)
                Text(label)
                    .font(.caption2)
            }
        }
        .foregroundStyle(.white.opacity(0.9))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        WeeklyReportView(report: WeeklyReport(
            weekStartDate: Calendar.current.date(byAdding: .day, value: -7, to: Date())!,
            weekEndDate: Date(),
            summary: "A balanced week with steady activity levels and good sleep patterns.",
            comparisonToPrevious: WeekComparison(
                stepsChange: 12.5,
                sleepChange: -5.0,
                screenTimeChange: -8.0,
                moodChange: 10.0,
                reflectionCountChange: 2
            )
        ))
    }
    .modelContainer(PersistenceController.preview().container)
}
