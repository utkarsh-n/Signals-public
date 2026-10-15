//
//  HomeView.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//
//  Main home tab - vertical timeline showing the day as it unfolds
//

import SwiftUI
import SwiftData
import Combine
import Sticker
import ShaderKit

/// Main home tab showing today's timeline with segments and activities
struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    
    @State private var viewModel = TimelineViewModel()
    @State private var showQuickReflection = false
    @State private var expandedSegmentID: UUID?
    @State private var showAddEvent = false
    @State private var segmentToEdit: TimelineSegment?
    @State private var showDayBreakdown = false
    
    /// Extract "Your Day" segment for sticky header display
    private var yourDaySegment: TimelineSegment? {
        viewModel.timeline?.segments.first { 
            $0.locationLabel == "Your Day" || $0.locationLabel == "Starting your day" 
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 0) {
                            // Date Navigation Header
                            TimelineDateHeader(
                                viewModel: viewModel,
                                onPreviousDay: { 
                                    Haptics.pageChanged()
                                    viewModel.goToPreviousDay() 
                                },
                                onNextDay: { 
                                    Haptics.pageChanged()
                                    viewModel.goToNextDay() 
                                },
                                onToday: { 
                                    Haptics.selection()
                                    viewModel.goToToday()
                                    scrollToCurrentSegment(proxy: proxy)
                                }
                            )
                            .padding(.horizontal, Spacing.standard)
                            .padding(.bottom, Spacing.md)
                            
                            if let timeline = viewModel.timeline {
                                // Sleep Block
                                if let sleepBlock = timeline.sleepBlock {
                                    SleepBlockView(sleepBlock: sleepBlock)
                                        .padding(.horizontal, Spacing.standard)
                                        .fadeIn(delay: 0.05)
                                }
                                
                                // "Your Day" header - inline, not sticky (tappable for pie chart)
                                if let yourDay = yourDaySegment, timeline.isToday {
                                    YourDayHeaderView(
                                        segment: yourDay,
                                        allSegments: timeline.segments,
                                        onTap: { showDayBreakdown = true }
                                    )
                                    .padding(.horizontal, Spacing.standard)
                                    .padding(.top, Spacing.lg) // Spacing between sleep and Your Day
                                    .fadeIn(delay: 0.1)
                                }
                                
                                // Timeline Segments (excluding "Your Day" - shown above)
                                if timeline.segments.isEmpty {
                                    TimelineEmptyState(isToday: timeline.isToday)
                                        .padding(.horizontal, Spacing.standard)
                                        .padding(.top, Spacing.xxl)
                                } else {
                                    TimelineView(
                                        segments: timeline.segments,
                                        expandedSegmentID: $expandedSegmentID,
                                        onEditSegment: { segment in
                                            segmentToEdit = segment
                                        },
                                        onDeleteSegment: { segment in
                                            handleSegmentDelete(segment)
                                        }
                                    )
                                    .padding(.horizontal, Spacing.standard)
                                    .padding(.top, Spacing.lg) // Spacing between Your Day and timeline
                                }
                                
                                // Add Event Button (replaces reflection button for today)
                                if timeline.isToday {
                                    AddEventButton(
                                        onAddEvent: { showAddEvent = true },
                                        onAddReflection: { showQuickReflection = true }
                                    )
                                    .padding(.horizontal, Spacing.standard)
                                    .padding(.top, Spacing.xl)
                                }
                            } else if viewModel.isLoading {
                                TimelineLoadingView()
                                    .padding(.horizontal, Spacing.standard)
                            }
                            
                            Spacer(minLength: 120)
                        }
                        .padding(.top, Spacing.sm)
                    }
                    .refreshable {
                        await refreshData()
                    }
                }
                
            }
            .navigationTitle(viewModel.timeline?.dateHeader ?? "Today")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                viewModel.setup(context: modelContext)
            }
            .sheet(isPresented: $showAddEvent) {
                AddEventView(selectedDate: viewModel.selectedDate) { event in
                    viewModel.loadTimeline()
                }
            }
            .sheet(item: $segmentToEdit) { segment in
                EditEventView(
                    segment: segment,
                    onSave: { updatedSegment in
                        handleSegmentUpdate(updatedSegment)
                    },
                    onDelete: segment.isManualEvent ? {
                        handleSegmentDelete(segment)
                    } : nil
                )
            }
            .sheet(isPresented: $showQuickReflection) {
                QuickReflectionSheet(onSave: { text in
                    saveReflection(text)
                })
            }
            .sheet(isPresented: $showDayBreakdown) {
                if let timeline = viewModel.timeline {
                    DayBreakdownModal(segments: timeline.segments)
                        .presentationDetents([.medium])
                        .presentationDragIndicator(.visible)
                }
            }
        }
    }
    
    private func handleSegmentUpdate(_ segment: TimelineSegment) {
        // If it's a manual event, update the ManualEvent model
        if let eventID = segment.manualEventID {
            let descriptor = FetchDescriptor<ManualEvent>(
                predicate: #Predicate { event in
                    event.id == eventID
                }
            )
            if let events = try? modelContext.fetch(descriptor),
               let event = events.first {
                // Update start/end times
                event.startTime = segment.startTime
                if let endTime = segment.endTime {
                    event.endTime = endTime
                }
                
                // Update category based on segment data
                if let customIcon = segment.customIcon,
                   let customColorHex = segment.customColorHex {
                    // Custom category
                    let customCategory = CustomEventCategory(
                        name: segment.locationLabel,
                        iconName: customIcon,
                        colorHex: customColorHex
                    )
                    event.category = .custom(customCategory)
                } else {
                    // Try to match preset category or create custom one
                    let label = segment.locationLabel.lowercased()
                    if label.contains("sleep") {
                        event.category = .sleep
                    } else if label.contains("driv") || label.contains("commut") {
                        event.category = .driving
                    } else if label.contains("work") || label.contains("office") {
                        event.category = .work
                    } else if label.contains("eat") || label.contains("lunch") || label.contains("dinner") || label.contains("breakfast") {
                        event.category = .eating
                    } else if label.contains("school") || label.contains("class") || label.contains("university") {
                        event.category = .school
                    } else if label.contains("gym") || label.contains("exercise") || label.contains("workout") {
                        event.category = .exercise
                    } else {
                        // Create a custom category with the label
                        let customCategory = CustomEventCategory(
                            name: segment.locationLabel,
                            iconName: segment.displayIcon,
                            colorHex: segment.displayColor.hexString
                        )
                        event.category = .custom(customCategory)
                    }
                }
                
                event.updatedAt = Date()
                try? modelContext.save()
            }
        }
        viewModel.loadTimeline()
    }
    
    private func handleSegmentDelete(_ segment: TimelineSegment) {
        if let eventID = segment.manualEventID {
            let descriptor = FetchDescriptor<ManualEvent>(
                predicate: #Predicate { event in
                    event.id == eventID
                }
            )
            if let events = try? modelContext.fetch(descriptor),
               let event = events.first {
                modelContext.delete(event)
            }
        }
        viewModel.loadTimeline()
    }
    
    private func scrollToCurrentSegment(proxy: ScrollViewProxy) {
        if let currentSegment = viewModel.timeline?.currentSegment {
            withAnimation(AnimationTokens.smooth) {
                proxy.scrollTo(currentSegment.id, anchor: .center)
            }
        }
    }
    
    private func saveReflection(_ text: String) {
        let reflection = Reflection(text: text)
        
        // Link to today's snapshot
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let descriptor = FetchDescriptor<DailySnapshot>(
            predicate: #Predicate { snapshot in
                snapshot.date >= today
            }
        )
        
        if let snapshots = try? modelContext.fetch(descriptor),
           let snapshot = snapshots.first {
            reflection.linkedSnapshot = snapshot
            if snapshot.reflections == nil {
                snapshot.reflections = []
            }
            snapshot.reflections?.append(reflection)
        }
        
        modelContext.insert(reflection)
        
        // Analyze sentiment
        Task {
            await MainActor.run {
                SentimentAnalyzer.shared.analyzeAndUpdate(reflection)
            }
        }
        
        Haptics.reflectionSaved()
        showQuickReflection = false
        
        // Reload timeline to show new reflection
        viewModel.loadTimeline()
    }
    
    private func refreshData() async {
        let _ = await DataOrchestrator.shared.refreshToday(context: modelContext)
        await MainActor.run {
            appState.refreshTodayData(from: modelContext)
            viewModel.loadTimeline()
        }
    }
}

// MARK: - Timeline Date Header

struct TimelineDateHeader: View {
    let viewModel: TimelineViewModel
    let onPreviousDay: () -> Void
    let onNextDay: () -> Void
    let onToday: () -> Void
    
    var body: some View {
        HStack {
            // Previous day button
            Button(action: onPreviousDay) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(ColorPalette.secondaryText)
            }
            .padding(Spacing.sm)
            .liquidGlassCapsule()
            
            Spacer()
            
            // Date display with "Today" button
            VStack(spacing: Spacing.xs) {
                Text(viewModel.selectedDate.formatted(.dateTime.weekday(.wide)))
                    .font(Typography.headline)
                Text(viewModel.selectedDate.formatted(.dateTime.month().day().year()))
                    .font(Typography.caption)
                    .foregroundStyle(ColorPalette.secondaryText)
            }
            
            Spacer()
            
            // Next day / Today button
            if viewModel.canGoForward {
                Button(action: onNextDay) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(ColorPalette.secondaryText)
                }
                .padding(Spacing.sm)
                .liquidGlassCapsule()
            } else if !viewModel.isViewingToday {
                Button(action: onToday) {
                    Text("Today")
                        .font(Typography.caption)
                        .foregroundStyle(ColorPalette.accent)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .liquidGlassCapsule(tint: ColorPalette.accent.opacity(0.1))
            } else {
                // Placeholder to maintain layout
                Color.clear
                    .frame(width: 44, height: 44)
            }
        }
    }
}

// MARK: - Sleep Block View

struct SleepBlockView: View {
    let sleepBlock: SleepBlock
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            // Sleep icon with night theme
            ZStack {
                Circle()
                    .fill(ColorPalette.sleep.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(ColorPalette.sleep)
            }
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Sleep")
                    .font(Typography.caption)
                    .foregroundStyle(ColorPalette.secondaryText)
                
                HStack(spacing: Spacing.sm) {
                    Text(sleepBlock.formattedDuration)
                        .font(Typography.headline)
                    
                    if let quality = sleepBlock.quality {
                        Text("•")
                            .foregroundStyle(ColorPalette.tertiaryText)
                        Text(quality.displayName)
                            .font(Typography.caption)
                            .foregroundStyle(ColorPalette.color(for: quality))
                    }
                }
            }
            
            Spacer()
            
            // Wake time
            VStack(alignment: .trailing, spacing: Spacing.xs) {
                Text("Woke up")
                    .font(Typography.caption)
                    .foregroundStyle(ColorPalette.tertiaryText)
                Text(sleepBlock.formattedWakeTime)
                    .font(Typography.subheadline)
            }
        }
        .padding(Spacing.standard)
        .liquidGlass(tint: ColorPalette.sleep.opacity(0.08), cornerRadius: CornerRadius.standard)
    }
}

// MARK: - Your Day Header View

struct YourDayHeaderView: View {
    let segment: TimelineSegment
    let allSegments: [TimelineSegment]
    let onTap: () -> Void
    
    @State private var isPulsing = false
    
    /// Calculate total tracked time today (excluding "Your Day" segment)
    private var trackedMinutes: Int {
        allSegments
            .filter { $0.locationLabel != "Your Day" && $0.locationLabel != "Starting your day" }
            .reduce(0) { $0 + $1.durationMinutes }
    }
    
    private var trackedTimeString: String {
        let hours = trackedMinutes / 60
        let minutes = trackedMinutes % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m tracked"
        }
        return "\(minutes)m tracked"
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.md) {
                // Icon with warm sun color and holographic effect
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(Color.orange)
                }
                .stickerEffect()
                .stickerColorIntensity(0.7)
                .stickerBlend(0.35)
                .stickerLightIntensity(0.3)
                .stickerMotionEffect(.accelerometer(intensity: 0.8))
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack(spacing: Spacing.xs) {
                        Text("Your Day")
                            .font(Typography.headline)
                            .foregroundStyle(ColorPalette.primaryText)
                        
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 8, height: 8)
                            .scaleEffect(isPulsing ? 1.3 : 1.0)
                    }
                    
                    Text(trackedMinutes > 0 ? trackedTimeString : "Tap to see breakdown")
                        .font(Typography.caption)
                        .foregroundStyle(ColorPalette.secondaryText)
                }
                
                Spacer()
                
                // Duration elapsed since day start
                VStack(alignment: .trailing, spacing: Spacing.xs) {
                    Text(segment.formattedDuration)
                        .font(Typography.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.orange)
                    
                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(ColorPalette.tertiaryText)
                }
            }
            .padding(Spacing.standard)
            .liquidGlass(tint: Color.orange.opacity(0.08), cornerRadius: CornerRadius.standard)
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}

// MARK: - Day Breakdown Modal

struct DayBreakdownModal: View {
    let segments: [TimelineSegment]
    @Environment(\.dismiss) private var dismiss
    
    /// Filter out "Your Day" placeholder for breakdown calculation
    private var activitySegments: [TimelineSegment] {
        segments.filter { $0.locationLabel != "Your Day" && $0.locationLabel != "Starting your day" }
    }
    
    /// Group segments by category and calculate totals
    private var categoryBreakdown: [(category: String, minutes: Int, color: Color, icon: String)] {
        var grouped: [String: (minutes: Int, color: Color, icon: String)] = [:]
        
        for segment in activitySegments {
            let category = segment.locationLabel
            if var existing = grouped[category] {
                existing.minutes += segment.durationMinutes
                grouped[category] = existing
            } else {
                grouped[category] = (
                    minutes: segment.durationMinutes,
                    color: segment.displayColor,
                    icon: segment.displayIcon
                )
            }
        }
        
        return grouped.map { (category: $0.key, minutes: $0.value.minutes, color: $0.value.color, icon: $0.value.icon) }
            .sorted { $0.minutes > $1.minutes }
    }
    
    /// Total tracked time in minutes
    private var totalTrackedMinutes: Int {
        activitySegments.reduce(0) { $0 + $1.durationMinutes }
    }
    
    /// Time since 7 AM (approximate day start)
    private var dayElapsedMinutes: Int {
        let calendar = Calendar.current
        let now = Date()
        let dayStart = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: now) ?? now
        return max(0, Int(now.timeIntervalSince(dayStart) / 60))
    }
    
    /// Remaining untracked time
    private var untrackedMinutes: Int {
        max(0, dayElapsedMinutes - totalTrackedMinutes)
    }
    
    var body: some View {
        VStack(spacing: Spacing.xl) {
            // Header
            HStack {
                Text("Day Breakdown")
                    .font(Typography.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(ColorPalette.tertiaryText)
                }
            }
            .padding(.horizontal, Spacing.standard)
            .padding(.top, Spacing.lg)
            
            // Pie Chart
            ZStack {
                // Background circle (remaining time)
                Circle()
                    .fill(ColorPalette.tertiaryBackground)
                    .frame(width: 200, height: 200)
                
                // Category slices
                PieChartView(
                    slices: buildPieSlices(),
                    size: 200
                )
                
                // Center label
                VStack(spacing: Spacing.xs) {
                    Text(formatMinutes(totalTrackedMinutes))
                        .font(Typography.title2)
                        .fontWeight(.bold)
                    Text("tracked")
                        .font(Typography.caption)
                        .foregroundStyle(ColorPalette.secondaryText)
                }
            }
            .frame(width: 200, height: 200)
            
            // Legend
            VStack(spacing: Spacing.md) {
                ForEach(categoryBreakdown, id: \.category) { item in
                    HStack(spacing: Spacing.md) {
                        // Color indicator
                        Circle()
                            .fill(item.color)
                            .frame(width: 12, height: 12)
                        
                        // Icon
                        Image(systemName: item.icon)
                            .font(.system(size: 14))
                            .foregroundStyle(item.color)
                            .frame(width: 20)
                        
                        // Category name
                        Text(item.category)
                            .font(Typography.subheadline)
                            .foregroundStyle(ColorPalette.primaryText)
                        
                        Spacer()
                        
                        // Duration
                        Text(formatMinutes(item.minutes))
                            .font(Typography.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(ColorPalette.secondaryText)
                        
                        // Percentage
                        Text("(\(Int(Double(item.minutes) / Double(max(dayElapsedMinutes, 1)) * 100))%)")
                            .font(Typography.caption)
                            .foregroundStyle(ColorPalette.tertiaryText)
                    }
                }
                
                // Untracked time
                if untrackedMinutes > 0 {
                    HStack(spacing: Spacing.md) {
                        Circle()
                            .fill(ColorPalette.tertiaryBackground)
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .strokeBorder(ColorPalette.border, lineWidth: 1)
                            )
                        
                        Image(systemName: "clock")
                            .font(.system(size: 14))
                            .foregroundStyle(ColorPalette.tertiaryText)
                            .frame(width: 20)
                        
                        Text("Untracked")
                            .font(Typography.subheadline)
                            .foregroundStyle(ColorPalette.secondaryText)
                        
                        Spacer()
                        
                        Text(formatMinutes(untrackedMinutes))
                            .font(Typography.subheadline)
                            .foregroundStyle(ColorPalette.tertiaryText)
                        
                        Text("(\(Int(Double(untrackedMinutes) / Double(max(dayElapsedMinutes, 1)) * 100))%)")
                            .font(Typography.caption)
                            .foregroundStyle(ColorPalette.tertiaryText)
                    }
                }
            }
            .padding(.horizontal, Spacing.standard)
            
            Spacer()
        }
    }
    
    private func buildPieSlices() -> [PieSlice] {
        guard dayElapsedMinutes > 0 else { return [] }
        
        var slices: [PieSlice] = []
        var currentAngle: Double = -90 // Start from top
        
        for item in categoryBreakdown {
            let fraction = Double(item.minutes) / Double(dayElapsedMinutes)
            let angle = fraction * 360
            slices.append(PieSlice(
                startAngle: currentAngle,
                endAngle: currentAngle + angle,
                color: item.color
            ))
            currentAngle += angle
        }
        
        return slices
    }
    
    private func formatMinutes(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins)m"
    }
}

// MARK: - Pie Chart View

struct PieSlice: Identifiable {
    let id = UUID()
    let startAngle: Double
    let endAngle: Double
    let color: Color
}

struct PieChartView: View {
    let slices: [PieSlice]
    let size: CGFloat
    
    var body: some View {
        ZStack {
            ForEach(slices) { slice in
                PieSliceShape(startAngle: slice.startAngle, endAngle: slice.endAngle)
                    .fill(slice.color)
            }
        }
        .frame(width: size, height: size)
    }
}

struct PieSliceShape: Shape {
    let startAngle: Double
    let endAngle: Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(startAngle),
            endAngle: .degrees(endAngle),
            clockwise: false
        )
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Timeline View

struct TimelineView: View {
    let segments: [TimelineSegment]
    @Binding var expandedSegmentID: UUID?
    var onEditSegment: ((TimelineSegment) -> Void)?
    var onDeleteSegment: ((TimelineSegment) -> Void)?
    
    /// Filter out "Your Day" placeholder - it's shown as sticky header
    private var displaySegments: [TimelineSegment] {
        segments.filter { $0.locationLabel != "Your Day" && $0.locationLabel != "Starting your day" }
    }
    
    var body: some View {
        let segmentsArray = displaySegments
        let segmentCount = segmentsArray.count
        
        VStack(spacing: 0) {
            ForEach(Array(segmentsArray.enumerated()), id: \.element.id) { index, segment in
                TimelineSegmentView(
                    segment: segment,
                    isExpanded: expandedSegmentID == segment.id,
                    isFirst: index == 0,
                    isLast: index == segmentCount - 1,
                    onTap: {
                        withAnimation(AnimationTokens.snappy) {
                            if expandedSegmentID == segment.id {
                                expandedSegmentID = nil
                            } else {
                                expandedSegmentID = segment.id
                            }
                        }
                        Haptics.cardExpanded()
                    },
                    onEdit: segment.isEditable ? {
                        onEditSegment?(segment)
                    } : nil,
                    onDelete: segment.isManualEvent ? {
                        onDeleteSegment?(segment)
                    } : nil
                )
                .id(segment.id)
                .staggeredFadeIn(index: index, baseDelay: 0.1, stagger: 0.06)
            }
        }
    }
}

// MARK: - Timeline Segment View

struct TimelineSegmentView: View {
    let segment: TimelineSegment
    let isExpanded: Bool
    let isFirst: Bool
    let isLast: Bool
    let onTap: () -> Void
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?
    
    @State private var isPulsing = false
    @State private var swipeOffset: CGFloat = 0
    @State private var showDeleteConfirmation = false
    
    private let swipeThreshold: CGFloat = -80
    private let maxSwipeOffset: CGFloat = -160
    private let baseHeight: CGFloat = 80 // Standard height for events up to 1 hour
    
    /// Calculate height multiplier based on duration (1x for ≤1 hour, proportional for longer)
    /// "Your Day" and active segments are always standard size since they grow over time
    private var heightMultiplier: CGFloat {
        // Don't scale "Your Day" placeholder or active segments - they grow throughout the day
        if segment.locationLabel == "Your Day" || segment.isActive {
            return 1.0
        }
        
        let durationMinutes = segment.durationMinutes
        if durationMinutes <= 60 {
            return 1.0
        }
        // For events longer than 1 hour, scale proportionally
        return CGFloat(durationMinutes) / 60.0
    }
    
    private var accessibilityLabel: String {
        var parts = ["\(segment.locationLabel)", "from \(segment.formattedStartTime)", segment.formattedDuration]
        if segment.isActive {
            parts.insert("Currently active.", at: 0)
        }
        if segment.stepCount > 0 {
            parts.append("\(segment.stepCount) steps")
        }
        if segment.screenTimeMinutes > 0 {
            parts.append("\(segment.screenTimeMinutes) minutes screen time")
        }
        return parts.joined(separator: ", ")
    }
    
    var body: some View {
        // Full-width swipeable container
        ZStack(alignment: .trailing) {
            // Swipe action buttons (behind the card) - only visible when swiping
            if (segment.isEditable || segment.isManualEvent) && swipeOffset < 0 {
                HStack(spacing: 8) {
                    Spacer()
                    
                    // Edit button
                    if onEdit != nil {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                swipeOffset = 0
                            }
                            onEdit?()
                            Haptics.light()
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 18, weight: .medium))
                                Text("Edit")
                                    .font(Typography.caption)
                            }
                            .foregroundStyle(.yellow)
                            .frame(width: 70)
                            .frame(minHeight: 60)
                            .background(Color.yellow.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Delete button (only for manual events)
                    if onDelete != nil {
                        Button {
                            showDeleteConfirmation = true
                            Haptics.warning()
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "trash")
                                    .font(.system(size: 18, weight: .medium))
                                Text("Delete")
                                    .font(Typography.caption)
                            }
                            .foregroundStyle(.red)
                            .frame(width: 70)
                            .frame(minHeight: 60)
                            .background(Color.red.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.trailing, 4)
            }
            
            // Main segment content (full width, swipeable)
            HStack(alignment: .top, spacing: Spacing.md) {
                // Left side: Icon + Event details
                HStack(alignment: .top, spacing: Spacing.md) {
                    // Icon anchored to top with holographic effect
                    ZStack {
                        Circle()
                            .fill(segment.displayColor.opacity(0.15))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: segment.displayIcon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(segment.displayColor)
                    }
                    .stickerEffect()
                    .stickerColorIntensity(0.7)
                    .stickerBlend(0.35)
                    .stickerLightIntensity(0.3)
                    .stickerMotionEffect(.accelerometer(intensity: 0.8))
                    
                    // Event details
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        // Event name row
                        HStack(spacing: Spacing.xs) {
                            Text(segment.locationLabel)
                                .font(Typography.headline)
                            
                            // Manual event indicator
                            if segment.isManualEvent {
                                Image(systemName: "hand.draw.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(ColorPalette.tertiaryText)
                            }
                            
                            if segment.isActive {
                                Circle()
                                    .fill(ColorPalette.accent)
                                    .frame(width: 8, height: 8)
                                    .scaleEffect(isPulsing ? 1.3 : 1.0)
                            }
                        }
                        
                        // Stats row (if any activity)
                        if segment.hasActivity {
                            SegmentStatsRow(segment: segment)
                        }
                        
                        // Flexible space for longer events
                        if heightMultiplier > 1.0 && !isExpanded {
                            Spacer(minLength: 0)
                        }
                        
                        // Expanded details
                        if isExpanded {
                            SegmentExpandedDetails(segment: segment)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                }
                
                Spacer()
                
                // Right side: Time info (top: start time, bottom: duration)
                VStack(alignment: .trailing, spacing: Spacing.xs) {
                    // Start time at top-right
                    Text(segment.formattedStartTime)
                        .font(Typography.caption)
                        .foregroundStyle(ColorPalette.secondaryText)
                    
                    // Flexible space for taller cells
                    if heightMultiplier > 1.0 && !isExpanded {
                        Spacer(minLength: 0)
                    }
                    
                    // Duration at bottom-right
                    Text(segment.formattedDuration)
                        .font(Typography.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(segment.displayColor)
                    
                    // Swipe hint chevron
                    if (onEdit != nil || onDelete != nil) && swipeOffset == 0 {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(ColorPalette.tertiaryText)
                            .opacity(0.5)
                    }
                }
            }
            .padding(Spacing.standard)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: baseHeight * min(heightMultiplier, 4.0)) // Cap at 4x height
            .liquidGlass(
                tint: segment.isActive ? ColorPalette.accent.opacity(0.08) : (segment.isManualEvent ? segment.displayColor.opacity(0.08) : nil),
                cornerRadius: CornerRadius.standard
            )
            .offset(x: swipeOffset)
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onChanged { value in
                        guard onEdit != nil || onDelete != nil else { return }
                        let translation = value.translation.width
                        // Only allow left swipe (negative)
                        if translation < 0 {
                            swipeOffset = max(translation, maxSwipeOffset)
                        } else if swipeOffset < 0 {
                            // Allow closing swipe
                            swipeOffset = min(0, swipeOffset + translation)
                        }
                    }
                    .onEnded { value in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            if swipeOffset < swipeThreshold {
                                // Snap to reveal actions
                                swipeOffset = maxSwipeOffset
                            } else {
                                // Snap back closed
                                swipeOffset = 0
                            }
                        }
                    }
            )
            .onTapGesture {
                if swipeOffset < 0 {
                    // Close swipe if open
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        swipeOffset = 0
                    }
                } else {
                    onTap()
                }
            }
        }
        .padding(.bottom, Spacing.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(isExpanded ? "Double tap to collapse. Swipe left for actions." : "Double tap to expand. Swipe left for actions.")
        .accessibilityAddTraits(.isButton)
        .onAppear {
            if segment.isActive {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
        }
        .confirmationDialog("Delete Event", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    swipeOffset = 0
                }
                onDelete?()
            }
            Button("Cancel", role: .cancel) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    swipeOffset = 0
                }
            }
        } message: {
            Text("Are you sure you want to delete this event? This cannot be undone.")
        }
    }
    
    private var locationColor: Color {
        switch segment.locationType {
        case .home: return .blue
        case .work: return .purple
        case .transit: return .green
        case .gym: return .orange
        case .school: return .teal
        case .newPlace: return .pink
        case .unknown: return .gray
        }
    }
}

// MARK: - Time Spine

struct TimeSpine: View {
    let time: String
    let isActive: Bool
    @Binding var isPulsing: Bool
    let isFirst: Bool
    let isLast: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Time label
            Text(time)
                .font(Typography.caption)
                .foregroundStyle(ColorPalette.secondaryText)
                .frame(width: 50)
            
            // Connector line and dot
            VStack(spacing: 0) {
                // Top line (if not first)
                if !isFirst {
                    Rectangle()
                        .fill(ColorPalette.border)
                        .frame(width: 2, height: 8)
                }
                
                // Dot
                Circle()
                    .fill(isActive ? ColorPalette.accent : ColorPalette.border)
                    .frame(width: 10, height: 10)
                    .scaleEffect(isActive && isPulsing ? 1.4 : 1.0)
                
                // Bottom line (if not last)
                if !isLast {
                    Rectangle()
                        .fill(ColorPalette.border)
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
        }
        .frame(width: 50)
    }
}

// MARK: - Segment Stats Row

struct SegmentStatsRow: View {
    let segment: TimelineSegment
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            if segment.screenTimeMinutes > 0 {
                StatPill(
                    icon: "iphone",
                    value: formatScreenTime(segment.screenTimeMinutes),
                    color: ColorPalette.screenTime
                )
            }
            
            if segment.stepCount > 0 {
                StatPill(
                    icon: "figure.walk",
                    value: segment.stepCount.formatted(),
                    color: ColorPalette.steps
                )
            }
            
            if !segment.reflections.isEmpty {
                StatPill(
                    icon: "pencil.and.outline",
                    value: "\(segment.reflections.count)",
                    color: ColorPalette.reflection
                )
            }
            
            if segment.appOpenCount > 0 {
                StatPill(
                    icon: "hand.tap",
                    value: "\(segment.appOpenCount)",
                    color: ColorPalette.tertiary
                )
            }
        }
    }
    
    private func formatScreenTime(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins)m"
    }
}

// MARK: - Stat Pill

struct StatPill: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(value)
                .font(Typography.caption)
        }
        .foregroundStyle(color)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }
}

// MARK: - Segment Expanded Details

struct SegmentExpandedDetails: View {
    let segment: TimelineSegment
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Divider()
            
            // Time range
            HStack {
                Image(systemName: "clock")
                    .font(.caption)
                    .foregroundStyle(ColorPalette.tertiaryText)
                Text(segment.timeRangeString)
                    .font(Typography.caption)
                    .foregroundStyle(ColorPalette.secondaryText)
            }
            
            // App Usage Aggregation
            if !segment.aggregatedAppOpens.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("App Activity")
                        .font(Typography.caption)
                        .foregroundStyle(ColorPalette.tertiaryText)
                    
                    ForEach(segment.aggregatedAppOpens) { appOpen in
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: appOpen.categoryIcon)
                                .font(.system(size: 12))
                                .foregroundStyle(appOpen.categoryColor)
                                .frame(width: 20)
                            
                            Text(appOpen.displayText)
                                .font(Typography.caption)
                                .foregroundStyle(ColorPalette.primaryText)
                            
                            Spacer()
                            
                            // Time indicator
                            if appOpen.count > 1 {
                                Text(formatTimeRange(appOpen.firstOpenTime, appOpen.lastOpenTime))
                                    .font(Typography.caption2)
                                    .foregroundStyle(ColorPalette.tertiaryText)
                            }
                        }
                        .padding(Spacing.sm)
                        .background(appOpen.categoryColor.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                    }
                }
            }
            
            // Reflections
            if !segment.reflections.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Reflections")
                        .font(Typography.caption)
                        .foregroundStyle(ColorPalette.tertiaryText)
                    
                    ForEach(segment.reflections) { reflection in
                        HStack(alignment: .top, spacing: Spacing.sm) {
                            if let sentiment = reflection.sentiment {
                                Image(systemName: sentiment.icon)
                                    .font(.caption)
                                    .foregroundStyle(ColorPalette.color(for: sentiment))
                            }
                            Text(reflection.preview)
                                .font(Typography.caption)
                                .foregroundStyle(ColorPalette.primaryText)
                        }
                        .padding(Spacing.sm)
                        .background(ColorPalette.tertiaryBackground)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                    }
                }
            }
        }
    }
    
    private func formatTimeRange(_ start: Date, _ end: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        if Calendar.current.isDate(start, equalTo: end, toGranularity: .hour) {
            return formatter.string(from: start)
        }
        return "\(formatter.string(from: start))–\(formatter.string(from: end))"
    }
}

// MARK: - Timeline Empty State

struct TimelineEmptyState: View {
    let isToday: Bool
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: isToday ? "waveform.path.ecg" : "calendar.badge.clock")
                .font(.system(size: 48))
                .foregroundStyle(ColorPalette.tertiaryText)
            
            Text(isToday ? "Signals is listening" : "No data for this day")
                .font(Typography.headline)
                .foregroundStyle(ColorPalette.primaryText)
            
            Text(isToday ? "Your timeline will fill in as your day unfolds." : "Check another day or pull to refresh.")
                .font(Typography.body)
                .foregroundStyle(ColorPalette.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(Spacing.xxl)
        .liquidGlass(cornerRadius: CornerRadius.lg)
    }
}

// MARK: - Timeline Loading View

struct TimelineLoadingView: View {
    var body: some View {
        VStack(spacing: Spacing.lg) {
            ForEach(0..<3, id: \.self) { _ in
                ShimmerView()
                    .frame(height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.standard))
            }
        }
        .padding(.top, Spacing.lg)
    }
}

// MARK: - Add Event Button

struct AddEventButton: View {
    let onAddEvent: () -> Void
    let onAddReflection: () -> Void
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            // Add Event (primary) - with subtle polished aluminum effect
            HolographicCardContainer(
                width: 135,
                height: 44,
                cornerRadius: 22,
                shadowColor: .blue.opacity(0.15)
            ) {
                Button {
                    onAddEvent()
                    Haptics.light()
                } label: {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                        Text("Add Event")
                            .font(Typography.body)
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .buttonStyle(.plain)
                .background(Color.blue.opacity(0.12))
                .overlay(
                    Capsule()
                        .strokeBorder(
                            Color.blue.opacity(0.25),
                            lineWidth: 1
                        )
                )
                .clipShape(Capsule())
                .shader(.polishedAluminum(intensity: 0.3))
            }
            
            // Add Reflection (secondary) - with subtle polished aluminum effect
            HolographicCardContainer(
                width: 115,
                height: 44,
                cornerRadius: 22,
                shadowColor: .purple.opacity(0.15)
            ) {
                Button {
                    onAddReflection()
                    Haptics.light()
                } label: {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                        Text("Reflect")
                            .font(Typography.body)
                    }
                    .foregroundColor(.purple)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .buttonStyle(.plain)
                .background(Color.purple.opacity(0.12))
                .overlay(
                    Capsule()
                        .strokeBorder(
                            Color.purple.opacity(0.25),
                            lineWidth: 1
                        )
                )
                .clipShape(Capsule())
                .shader(.polishedAluminum(intensity: 0.3))
            }
        }
    }
}

// MARK: - Quick Reflection Sheet

struct QuickReflectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (String) -> Void
    
    @State private var reflectionText = ""
    @FocusState private var isFocused: Bool
    
    private var isValid: Bool {
        !reflectionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                Text("What's on your mind?")
                    .font(Typography.headline)
                
                TextField("Capture a thought, feeling, or moment...", text: $reflectionText, axis: .vertical)
                    .font(Typography.body)
                    .lineLimit(5...10)
                    .focused($isFocused)
                    .padding(Spacing.md)
                    .background(ColorPalette.tertiaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                
                Spacer()
            }
            .padding(Spacing.standard)
            .navigationTitle("Quick Reflection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(reflectionText.trimmingCharacters(in: .whitespacesAndNewlines))
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                isFocused = true
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Preview

#Preview("Home Timeline") {
    HomeView()
        .environment(AppState())
        .modelContainer(PersistenceController.preview().container)
}

#Preview("Timeline Segment") {
    ZStack {
        ColorPalette.background.ignoresSafeArea()
        
        VStack(spacing: Spacing.lg) {
            TimelineSegmentView(
                segment: TimelineSegment(
                    startTime: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!,
                    endTime: Calendar.current.date(bySettingHour: 12, minute: 30, second: 0, of: Date())!,
                    locationType: .work,
                    locationLabel: "Office",
                    screenTimeMinutes: 45,
                    stepCount: 1250,
                    reflections: [
                        TimelineReflection(preview: "Had a productive morning meeting", sentiment: .positive)
                    ],
                    appOpenCount: 8
                ),
                isExpanded: false,
                isFirst: true,
                isLast: false,
                onTap: {}
            )
            
            TimelineSegmentView(
                segment: TimelineSegment(
                    startTime: Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: Date())!,
                    locationType: .home,
                    locationLabel: "Home",
                    screenTimeMinutes: 120,
                    stepCount: 500,
                    isActive: true
                ),
                isExpanded: true,
                isFirst: false,
                isLast: true,
                onTap: {}
            )
        }
        .padding()
    }
}
