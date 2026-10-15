//
//  ReflectTabView.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import SwiftUI
import SwiftData

/// Main reflect tab - private space for micro-journaling
struct ReflectTabView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Reflection.createdAt, order: .reverse)
    private var allReflections: [Reflection]
    
    @State private var showingEditor = false
    @State private var selectedPrompt: String?
    @State private var viewMode: ReflectViewMode = .today
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // View mode picker
                    viewModePicker
                    
                    switch viewMode {
                    case .today:
                        todayView
                    case .history:
                        historyView
                    }
                    
                    // Bottom padding
                    Color.clear.frame(height: 20)
                }
                .padding(.horizontal)
            }
            .background(ColorPalette.background)
            .navigationTitle("Reflect")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingEditor = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingEditor) {
                ReflectionEditorView(prompt: selectedPrompt) { _ in
                    selectedPrompt = nil
                }
            }
        }
    }
    
    // MARK: - View Mode Picker
    
    private var viewModePicker: some View {
        HStack(spacing: 0) {
            ForEach(ReflectViewMode.allCases) { mode in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewMode = mode
                    }
                    Haptics.selection()
                }) {
                    Text(mode.displayName)
                        .font(Typography.body)
                        .fontWeight(viewMode == mode ? .semibold : .regular)
                        .foregroundStyle(viewMode == mode ? ColorPalette.primaryText : ColorPalette.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(viewMode == mode ? ColorPalette.secondaryBackground : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(ColorPalette.tertiaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Today View
    
    private var todayView: some View {
        VStack(spacing: 24) {
            // Prompt suggestions
            PromptView { prompt in
                selectedPrompt = prompt
                showingEditor = true
            }
            
            // Quick reflection entry
            quickReflectionSection
            
            // Today's reflections
            todayReflectionsSection
            
            // Stats
            reflectionStatsSection
        }
    }
    
    // MARK: - Quick Reflection Section
    
    private var quickReflectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Entry")
                .font(Typography.headline)
                .foregroundStyle(ColorPalette.primaryText)
            
            InlineReflectionEditor(
                placeholder: "What's on your mind?"
            )
        }
    }
    
    // MARK: - Today's Reflections
    
    private var todayReflectionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today")
                    .font(Typography.headline)
                    .foregroundStyle(ColorPalette.primaryText)
                
                Spacer()
                
                Text("\(todaysReflections.count) reflections")
                    .font(Typography.caption)
                    .foregroundStyle(ColorPalette.secondaryText)
            }
            
            if todaysReflections.isEmpty {
                emptyTodayView
            } else {
                ForEach(todaysReflections, id: \.id) { reflection in
                    TodayReflectionCard(reflection: reflection)
                }
            }
        }
    }
    
    private var emptyTodayView: some View {
        VStack(spacing: 12) {
            Image(systemName: "text.quote")
                .font(.title)
                .foregroundStyle(ColorPalette.tertiaryText)
            
            Text("No reflections yet today")
                .font(Typography.body)
                .foregroundStyle(ColorPalette.secondaryText)
            
            Button(action: { showingEditor = true }) {
                Text("Write one now")
                    .font(Typography.body)
                    .foregroundStyle(ColorPalette.accent)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(ColorPalette.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Reflection Stats
    
    private var reflectionStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Stats")
                .font(Typography.headline)
                .foregroundStyle(ColorPalette.primaryText)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ReflectionStatCard(
                    title: "Total",
                    value: "\(allReflections.count)",
                    icon: "text.quote",
                    color: ColorPalette.reflection
                )
                
                ReflectionStatCard(
                    title: "This Week",
                    value: "\(thisWeekCount)",
                    icon: "calendar",
                    color: ColorPalette.accent
                )
                
                ReflectionStatCard(
                    title: "Streak",
                    value: "\(currentStreak)",
                    icon: "flame.fill",
                    color: .orange
                )
                
                ReflectionStatCard(
                    title: "Avg Length",
                    value: "\(averageLength)",
                    icon: "character.cursor.ibeam",
                    color: .teal
                )
            }
        }
    }
    
    // MARK: - History View
    
    private var historyView: some View {
        VStack(alignment: .leading, spacing: 16) {
            if allReflections.isEmpty {
                emptyHistoryView
            } else {
                ReflectionListView()
                    .frame(minHeight: 400)
            }
        }
    }
    
    private var emptyHistoryView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundStyle(ColorPalette.primaryGradient)
            
            VStack(spacing: 12) {
                Text("Your journal awaits")
                    .font(Typography.title)
                    .foregroundStyle(ColorPalette.primaryText)
                
                Text("Start writing reflections to build your personal journal over time.")
                    .font(Typography.body)
                    .foregroundStyle(ColorPalette.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: { showingEditor = true }) {
                Text("Write Your First Reflection")
                    .font(Typography.body)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(ColorPalette.accent)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            
            Spacer()
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Computed Properties
    
    private var todaysReflections: [Reflection] {
        let today = Calendar.current.startOfDay(for: Date())
        return allReflections.filter {
            Calendar.current.isDate($0.createdAt, inSameDayAs: today)
        }
    }
    
    private var thisWeekCount: Int {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        return allReflections.filter { $0.createdAt >= startOfWeek }.count
    }
    
    private var currentStreak: Int {
        let calendar = Calendar.current
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        while true {
            let hasReflection = allReflections.contains {
                calendar.isDate($0.createdAt, inSameDayAs: currentDate)
            }
            
            if hasReflection {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            } else {
                break
            }
        }
        
        return streak
    }
    
    private var averageLength: Int {
        guard !allReflections.isEmpty else { return 0 }
        let totalLength = allReflections.reduce(0) { $0 + $1.text.count }
        return totalLength / allReflections.count
    }
}

// MARK: - Reflect View Mode

enum ReflectViewMode: String, CaseIterable, Identifiable {
    case today
    case history
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .today: return "Today"
        case .history: return "History"
        }
    }
}

// MARK: - Today Reflection Card

struct TodayReflectionCard: View {
    let reflection: Reflection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(reflection.text)
                .font(Typography.body)
                .foregroundStyle(ColorPalette.primaryText)
            
            HStack {
                Text(reflection.createdAt.formatted(date: .omitted, time: .shortened))
                    .font(Typography.caption)
                    .foregroundStyle(ColorPalette.tertiaryText)
                
                if let sentiment = reflection.sentiment {
                    HStack(spacing: 4) {
                        Image(systemName: sentiment.icon)
                        Text(sentiment.rawValue.capitalized)
                    }
                    .font(Typography.caption)
                    .foregroundStyle(ColorPalette.color(for: sentiment))
                }
                
                Spacer()
            }
        }
        .padding()
        .background(ColorPalette.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Reflection Stat Card

struct ReflectionStatCard: View {
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
    ReflectTabView()
        .environment(AppState())
        .modelContainer(PersistenceController.preview().container)
}
