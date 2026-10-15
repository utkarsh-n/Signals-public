//
//  ReflectionListView.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import SwiftUI
import SwiftData

/// Scrollable list of past reflections grouped by time period
struct ReflectionListView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Reflection.createdAt, order: .reverse)
    private var allReflections: [Reflection]
    
    @State private var searchText = ""
    @State private var selectedSentiment: Sentiment?
    @State private var showingFilters = false
    @State private var selectedReflection: Reflection?
    @State private var showingEditor = false
    
    var body: some View {
        Group {
            if allReflections.isEmpty {
                emptyStateView
            } else {
                reflectionsList
            }
        }
        .searchable(text: $searchText, prompt: "Search reflections")
        .sheet(isPresented: $showingEditor) {
            if let reflection = selectedReflection {
                ReflectionEditorView(existingReflection: reflection)
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "text.quote")
                .font(.system(size: 60))
                .foregroundStyle(ColorPalette.primaryGradient)
            
            VStack(spacing: 12) {
                Text("No reflections yet")
                    .font(Typography.title)
                    .foregroundStyle(ColorPalette.primaryText)
                
                Text("Tap the + button to write your first reflection.")
                    .font(Typography.body)
                    .foregroundStyle(ColorPalette.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Reflections List
    
    @State private var showingPaywall = false
    
    private var reflectionsList: some View {
        List {
            // Sentiment filter
            if !allReflections.isEmpty {
                sentimentFilterSection
            }
            
            // Grouped reflections
            ForEach(groupedReflections.keys.sorted(by: >), id: \.self) { date in
                Section {
                    ForEach(groupedReflections[date] ?? [], id: \.id) { reflection in
                        ReflectionRow(reflection: reflection)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedReflection = reflection
                                showingEditor = true
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    deleteReflection(reflection)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                } header: {
                    Text(sectionHeader(for: date))
                        .font(Typography.caption)
                        .foregroundStyle(ColorPalette.secondaryText)
                }
            }
            
            // Paywall prompt if user has more reflections
            if showPaywallPrompt {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "text.quote")
                            .font(.title)
                            .foregroundStyle(ColorPalette.primaryGradient)
                        
                        Text("\(allReflections.count - filteredReflections.count) more reflections available")
                            .font(Typography.body)
                            .foregroundStyle(ColorPalette.primaryText)
                        
                        Button {
                            showingPaywall = true
                        } label: {
                            Text("Unlock Full History")
                                .font(Typography.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(ColorPalette.accent)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
            }
        }
        .listStyle(.insetGrouped)
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }
    
    // MARK: - Sentiment Filter
    
    private var sentimentFilterSection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    SentimentFilterChip(
                        title: "All",
                        isSelected: selectedSentiment == nil
                    ) {
                        selectedSentiment = nil
                    }
                    
                    ForEach([Sentiment.positive, .neutral, .negative], id: \.self) { sentiment in
                        SentimentFilterChip(
                            title: sentiment.rawValue.capitalized,
                            icon: sentiment.icon,
                            color: ColorPalette.color(for: sentiment),
                            isSelected: selectedSentiment == sentiment
                        ) {
                            selectedSentiment = sentiment
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
    }
    
    // MARK: - Grouped Reflections
    
    private var groupedReflections: [Date: [Reflection]] {
        let filtered = filteredReflections
        let calendar = Calendar.current
        
        return Dictionary(grouping: filtered) { reflection in
            calendar.startOfDay(for: reflection.createdAt)
        }
    }
    
    private var filteredReflections: [Reflection] {
        var reflections = allReflections
        
        // Filter by sentiment
        if let sentiment = selectedSentiment {
            reflections = reflections.filter { $0.sentiment == sentiment }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            reflections = reflections.filter { reflection in
                reflection.text.localizedCaseInsensitiveContains(searchText) ||
                reflection.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Apply paywall limit for free users
        if let limit = PaywallManager.shared.featureLimit(for: .viewReflectionHistory) {
            reflections = Array(reflections.prefix(limit))
        }
        
        return reflections
    }
    
    private var showPaywallPrompt: Bool {
        !PaywallManager.shared.hasFullAccess && allReflections.count > (PaywallManager.shared.featureLimit(for: .viewReflectionHistory) ?? 0)
    }
    
    // MARK: - Helpers
    
    private func sectionHeader(for date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            return date.formatted(.dateTime.weekday(.wide))
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .month) {
            return date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
        } else {
            return date.formatted(.dateTime.month(.wide).day().year())
        }
    }
    
    private func deleteReflection(_ reflection: Reflection) {
        modelContext.delete(reflection)
        Haptics.light()
    }
}

// MARK: - Reflection Row

struct ReflectionRow: View {
    let reflection: Reflection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Text content
            Text(reflection.text)
                .font(Typography.body)
                .foregroundStyle(ColorPalette.primaryText)
                .lineLimit(3)
            
            // Metadata row
            HStack(spacing: 12) {
                // Time
                Text(reflection.createdAt.formatted(date: .omitted, time: .shortened))
                    .font(Typography.caption)
                    .foregroundStyle(ColorPalette.tertiaryText)
                
                // Sentiment indicator
                if let sentiment = reflection.sentiment {
                    HStack(spacing: 4) {
                        Image(systemName: sentiment.icon)
                            .font(.caption2)
                        Text(sentiment.rawValue.capitalized)
                            .font(Typography.caption)
                    }
                    .foregroundStyle(ColorPalette.color(for: sentiment))
                }
                
                // Tags
                if !reflection.tags.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "tag")
                            .font(.caption2)
                        Text(reflection.tags.prefix(2).joined(separator: ", "))
                            .font(Typography.caption)
                            .lineLimit(1)
                    }
                    .foregroundStyle(ColorPalette.tertiaryText)
                }
                
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Sentiment Filter Chip

struct SentimentFilterChip: View {
    let title: String
    var icon: String? = nil
    var color: Color = ColorPalette.accent
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            Haptics.selection()
            action()
        }) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption2)
                }
                Text(title)
                    .font(Typography.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? color.opacity(0.15) : ColorPalette.secondaryBackground)
            .foregroundStyle(isSelected ? color : ColorPalette.secondaryText)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ReflectionListView()
            .navigationTitle("Reflections")
    }
    .modelContainer(PersistenceController.preview().container)
}
