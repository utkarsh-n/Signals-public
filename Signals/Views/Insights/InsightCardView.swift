//
//  InsightCardView.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import SwiftUI
import SwiftData

/// A card displaying a single insight with category, title, body, and actions
struct InsightCardView: View {
    let insight: Insight
    var onTap: (() -> Void)? = nil
    
    @Environment(\.modelContext) private var modelContext
    @State private var showingRatingSheet = false
    
    var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: 12) {
                // Header: Category + Date
                HStack {
                    CategoryBadge(category: insight.category)
                    
                    Spacer()
                    
                    Text(insight.formattedDate)
                        .font(Typography.caption)
                        .foregroundStyle(ColorPalette.tertiaryText)
                    
                    if !insight.isRead {
                        Circle()
                            .fill(ColorPalette.accent)
                            .frame(width: 8, height: 8)
                    }
                }
                
                // Title
                Text(insight.title)
                    .font(Typography.headline)
                    .foregroundStyle(ColorPalette.primaryText)
                    .multilineTextAlignment(.leading)
                
                // Body
                Text(insight.body)
                    .font(Typography.body)
                    .foregroundStyle(ColorPalette.secondaryText)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                
                // Signals involved
                if !insight.signalsInvolved.isEmpty {
                    SignalTagsView(signals: insight.signalsInvolved)
                }
                
                // Actions
                HStack(spacing: 16) {
                    // Save button
                    Button(action: toggleSaved) {
                        Label(
                            insight.isSaved ? "Saved" : "Save",
                            systemImage: insight.isSaved ? "bookmark.fill" : "bookmark"
                        )
                        .font(Typography.caption)
                        .foregroundStyle(insight.isSaved ? ColorPalette.accent : ColorPalette.secondaryText)
                    }
                    .buttonStyle(.plain)
                    
                    // Rate button
                    Button(action: { showingRatingSheet = true }) {
                        Label(
                            ratingLabel,
                            systemImage: ratingIcon
                        )
                        .font(Typography.caption)
                        .foregroundStyle(insight.feedbackRating != nil ? ratingColor : ColorPalette.secondaryText)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    // Confidence indicator
                    if insight.isHighConfidence {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption2)
                            Text("High confidence")
                                .font(Typography.caption)
                        }
                        .foregroundStyle(ColorPalette.tertiaryText)
                    }
                }
            }
            .padding(16)
            .background(ColorPalette.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingRatingSheet) {
            RatingSheet(insight: insight)
                .presentationDetents([.height(200)])
        }
    }
    
    private var ratingLabel: String {
        switch insight.feedbackRating {
        case .helpful: return "Helpful"
        case .notHelpful: return "Not helpful"
        case .surprising: return "Surprising"
        case .none: return "Rate"
        }
    }
    
    private var ratingIcon: String {
        switch insight.feedbackRating {
        case .helpful: return "hand.thumbsup.fill"
        case .notHelpful: return "hand.thumbsdown.fill"
        case .surprising: return "lightbulb.fill"
        case .none: return "face.smiling"
        }
    }
    
    private var ratingColor: Color {
        switch insight.feedbackRating {
        case .helpful: return .green
        case .notHelpful: return .orange
        case .surprising: return .yellow
        case .none: return ColorPalette.secondaryText
        }
    }
    
    private func toggleSaved() {
        Haptics.light()
        insight.toggleSaved()
    }
}

// MARK: - Category Badge

struct CategoryBadge: View {
    let category: InsightCategory
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: category.icon)
                .font(.caption)
            Text(category.displayName)
                .font(Typography.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(ColorPalette.color(for: category).opacity(0.15))
        .foregroundStyle(ColorPalette.color(for: category))
        .clipShape(Capsule())
    }
}

// MARK: - Signal Tags View

struct SignalTagsView: View {
    let signals: [SignalType]
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(signals.prefix(4), id: \.self) { signal in
                HStack(spacing: 2) {
                    Image(systemName: signal.icon)
                        .font(.caption2)
                    Text(signal.shortName)
                        .font(Typography.caption)
                }
                .foregroundStyle(ColorPalette.color(for: signal))
            }
            
            if signals.count > 4 {
                Text("+\(signals.count - 4)")
                    .font(Typography.caption)
                    .foregroundStyle(ColorPalette.tertiaryText)
            }
        }
    }
}

// MARK: - Rating Sheet

struct RatingSheet: View {
    let insight: Insight
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("How was this insight?")
                .font(Typography.headline)
            
            HStack(spacing: 24) {
                RatingButton(
                    title: "Helpful",
                    icon: "hand.thumbsup.fill",
                    color: .green,
                    isSelected: insight.feedbackRating == .helpful
                ) {
                    rate(.helpful)
                }
                
                RatingButton(
                    title: "Surprising",
                    icon: "lightbulb.fill",
                    color: .yellow,
                    isSelected: insight.feedbackRating == .surprising
                ) {
                    rate(.surprising)
                }
                
                RatingButton(
                    title: "Not helpful",
                    icon: "hand.thumbsdown.fill",
                    color: .orange,
                    isSelected: insight.feedbackRating == .notHelpful
                ) {
                    rate(.notHelpful)
                }
            }
            
            Button("Done") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private func rate(_ rating: InsightRating) {
        Haptics.light()
        insight.rate(rating)
    }
}

struct RatingButton: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(Typography.caption)
            }
            .foregroundStyle(isSelected ? color : ColorPalette.secondaryText)
            .padding(12)
            .background(isSelected ? color.opacity(0.15) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    let insight = Insight(
        category: .correlation,
        title: "Sleep and Steps Connection",
        body: "On days when you sleep more than 7 hours, you tend to walk about 2,000 more steps the next day.",
        signalsInvolved: [.sleep, .steps],
        confidence: 0.85
    )
    
    return InsightCardView(insight: insight)
        .padding()
        .modelContainer(PersistenceController.preview().container)
}
