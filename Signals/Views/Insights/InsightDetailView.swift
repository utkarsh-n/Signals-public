//
//  InsightDetailView.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import SwiftUI
import SwiftData

/// Detailed view for a single insight with supporting data visualization
struct InsightDetailView: View {
    let insight: Insight
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showingRatingSheet = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                headerSection
                
                // Main content
                contentSection
                
                // Supporting data visualization
                if insight.supportingData != nil {
                    dataVisualizationSection
                }
                
                // Signals involved
                signalsSection
                
                // Actions
                actionsSection
                
                // Metadata
                metadataSection
            }
            .padding()
        }
        .background(ColorPalette.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: toggleSaved) {
                    Image(systemName: insight.isSaved ? "bookmark.fill" : "bookmark")
                }
            }
        }
        .onAppear {
            markAsRead()
        }
        .sheet(isPresented: $showingRatingSheet) {
            RatingSheet(insight: insight)
                .presentationDetents([.height(200)])
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            CategoryBadge(category: insight.category)
            
            Text(insight.title)
                .font(Typography.largeTitle)
                .foregroundStyle(ColorPalette.primaryText)
            
            HStack {
                Text(insight.generatedDate.formatted(date: .long, time: .omitted))
                    .font(Typography.caption)
                    .foregroundStyle(ColorPalette.secondaryText)
                
                Text("•")
                    .foregroundStyle(ColorPalette.tertiaryText)
                
                Text(timeSpanLabel)
                    .font(Typography.caption)
                    .foregroundStyle(ColorPalette.secondaryText)
            }
        }
    }
    
    // MARK: - Content Section
    
    private var contentSection: some View {
        Text(insight.body)
            .font(Typography.body)
            .foregroundStyle(ColorPalette.primaryText)
            .lineSpacing(4)
    }
    
    // MARK: - Data Visualization Section
    
    private var dataVisualizationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Supporting Data")
                .font(Typography.headline)
                .foregroundStyle(ColorPalette.primaryText)
            
            if let data = insight.supportingData {
                // Metrics visualization
                if let metrics = data.metrics, !metrics.isEmpty {
                    MetricsGridView(metrics: metrics)
                }
                
                // Additional context
                if let strings = data.strings, !strings.isEmpty {
                    ContextCardsView(context: strings)
                }
            }
        }
        .padding()
        .background(ColorPalette.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Signals Section
    
    private var signalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Signals Involved")
                .font(Typography.headline)
                .foregroundStyle(ColorPalette.primaryText)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                ForEach(insight.signalsInvolved, id: \.self) { signal in
                    SignalDetailBadge(signal: signal)
                }
            }
        }
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        VStack(spacing: 12) {
            Button(action: { showingRatingSheet = true }) {
                HStack {
                    Image(systemName: ratingIcon)
                    Text(ratingButtonText)
                }
                .font(Typography.body)
                .frame(maxWidth: .infinity)
                .padding()
                .background(ColorPalette.secondaryBackground)
                .foregroundStyle(ColorPalette.primaryText)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Metadata Section
    
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Confidence")
                    .font(Typography.caption)
                    .foregroundStyle(ColorPalette.secondaryText)
                
                Spacer()
                
                ConfidenceIndicator(confidence: insight.confidence)
            }
            
            Divider()
            
            HStack {
                Text("Time span analyzed")
                    .font(Typography.caption)
                    .foregroundStyle(ColorPalette.secondaryText)
                
                Spacer()
                
                Text(timeSpanLabel)
                    .font(Typography.caption)
                    .foregroundStyle(ColorPalette.primaryText)
            }
        }
        .padding()
        .background(ColorPalette.tertiaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Helpers
    
    private var timeSpanLabel: String {
        switch insight.timeSpan {
        case .week: return "Past week"
        case .month: return "Past month"
        case .quarter: return "Past 3 months"
        case .allTime: return "All time"
        }
    }
    
    private var ratingButtonText: String {
        if let rating = insight.feedbackRating {
            return "Rated: \(rating.rawValue.capitalized)"
        }
        return "Rate this insight"
    }
    
    private var ratingIcon: String {
        switch insight.feedbackRating {
        case .helpful: return "hand.thumbsup.fill"
        case .notHelpful: return "hand.thumbsdown.fill"
        case .surprising: return "lightbulb.fill"
        case .none: return "face.smiling"
        }
    }
    
    private func toggleSaved() {
        Haptics.light()
        insight.toggleSaved()
    }
    
    private func markAsRead() {
        if !insight.isRead {
            insight.markAsRead()
        }
    }
}

// MARK: - Supporting Views

struct MetricsGridView: View {
    let metrics: [String: Double]
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(Array(metrics.keys.sorted()), id: \.self) { key in
                if let value = metrics[key] {
                    MetricCard(label: key.formatMetricKey(), value: value)
                }
            }
        }
    }
}

struct MetricCard: View {
    let label: String
    let value: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(Typography.caption)
                .foregroundStyle(ColorPalette.secondaryText)
            
            Text(formattedValue)
                .font(Typography.metric)
                .foregroundStyle(ColorPalette.primaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(ColorPalette.tertiaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var formattedValue: String {
        if value >= 1000 {
            return String(format: "%.1fk", value / 1000)
        } else if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        } else {
            return String(format: "%.1f", value)
        }
    }
}

struct ContextCardsView: View {
    let context: [String: String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(context.keys.sorted()), id: \.self) { key in
                if let value = context[key] {
                    HStack {
                        Text(key.formatMetricKey())
                            .font(Typography.caption)
                            .foregroundStyle(ColorPalette.secondaryText)
                        
                        Spacer()
                        
                        Text(value)
                            .font(Typography.body)
                            .foregroundStyle(ColorPalette.primaryText)
                    }
                }
            }
        }
    }
}

struct SignalDetailBadge: View {
    let signal: SignalType
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: signal.icon)
                .foregroundStyle(ColorPalette.color(for: signal))
            
            Text(signal.displayName)
                .font(Typography.caption)
                .foregroundStyle(ColorPalette.primaryText)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(ColorPalette.color(for: signal).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct ConfidenceIndicator: View {
    let confidence: Double
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<5) { index in
                Circle()
                    .fill(index < confidenceLevel ? ColorPalette.accent : ColorPalette.tertiaryBackground)
                    .frame(width: 6, height: 6)
            }
            
            Text("\(Int(confidence * 100))%")
                .font(Typography.caption)
                .foregroundStyle(ColorPalette.secondaryText)
        }
    }
    
    private var confidenceLevel: Int {
        Int(confidence * 5)
    }
}

// MARK: - String Extension

extension String {
    func formatMetricKey() -> String {
        // Convert camelCase to Title Case with spaces
        var result = ""
        for (index, char) in self.enumerated() {
            if char.isUppercase && index > 0 {
                result += " "
            }
            result += index == 0 ? String(char).uppercased() : String(char)
        }
        return result
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        InsightDetailView(insight: Insight(
            category: .correlation,
            title: "Sleep and Steps Connection",
            body: "On days when you sleep more than 7 hours, you tend to walk about 2,000 more steps the next day. This pattern has been consistent over the past 3 weeks.",
            supportingData: InsightData(
                metrics: ["averageSleep": 7.2, "averageSteps": 8500, "correlation": 0.65],
                strings: ["bestDay": "Tuesday", "dataPoints": "21 days"]
            ),
            signalsInvolved: [.sleep, .steps],
            confidence: 0.85
        ))
    }
    .modelContainer(PersistenceController.preview().container)
}
