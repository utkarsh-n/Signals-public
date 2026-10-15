//
//  EditEventView.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import SwiftUI
import SwiftData

/// Sheet for editing an existing timeline segment (relabeling, adjusting time, etc.)
struct EditEventView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let segment: TimelineSegment
    let onSave: (TimelineSegment) -> Void
    let onDelete: (() -> Void)?
    
    @State private var editedLabel: String
    @State private var selectedCategory: EventCategory?
    @State private var showingOtherPicker = false
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var notes: String
    @State private var showDeleteConfirmation = false
    
    init(segment: TimelineSegment, onSave: @escaping (TimelineSegment) -> Void, onDelete: (() -> Void)? = nil) {
        self.segment = segment
        self.onSave = onSave
        self.onDelete = onDelete
        
        _editedLabel = State(initialValue: segment.locationLabel)
        _startTime = State(initialValue: segment.startTime)
        _endTime = State(initialValue: segment.endTime ?? Date())
        _notes = State(initialValue: "")
        
        // Try to match to a category
        _selectedCategory = State(initialValue: Self.matchCategory(for: segment))
    }
    
    private static func matchCategory(for segment: TimelineSegment) -> EventCategory? {
        // Check if it's a manual event with custom category
        if let icon = segment.customIcon, let hex = segment.customColorHex {
            return .custom(CustomEventCategory(
                name: segment.locationLabel,
                iconName: icon,
                colorHex: hex
            ))
        }
        
        // Try to match preset categories
        let label = segment.locationLabel.lowercased()
        if label.contains("sleep") { return .sleep }
        if label.contains("driv") || label.contains("commut") { return .driving }
        if label.contains("work") || label.contains("office") { return .work }
        if label.contains("eat") || label.contains("lunch") || label.contains("dinner") || label.contains("breakfast") { return .eating }
        if label.contains("school") || label.contains("class") || label.contains("university") { return .school }
        if label.contains("gym") || label.contains("exercise") || label.contains("workout") { return .exercise }
        
        return nil
    }
    
    private var isValid: Bool {
        !editedLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && endTime > startTime
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Current segment info
                    currentSegmentHeader
                    
                    // Label / Category editing
                    labelSection
                    
                    // Time adjustment
                    timeSection
                    
                    // Delete option (if allowed)
                    if segment.isEditable && onDelete != nil {
                        deleteSection
                    }
                }
                .padding(Spacing.standard)
            }
            .navigationTitle("Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingOtherPicker) {
                OtherEventPickerView { customCategory in
                    selectedCategory = .custom(customCategory)
                    editedLabel = customCategory.name
                    RecentCustomEvents.shared.addRecentEvent(customCategory)
                }
            }
            .confirmationDialog("Delete Event", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    onDelete?()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this event? This cannot be undone.")
            }
        }
    }
    
    // MARK: - Current Segment Header
    
    private var currentSegmentHeader: some View {
        VStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(displayColor.opacity(0.2))
                    .frame(width: 56, height: 56)
                
                Image(systemName: displayIcon)
                    .font(.system(size: 24))
                    .foregroundStyle(displayColor)
            }
            
            Text(editedLabel)
                .font(Typography.headline)
            
            Text(segment.timeRangeString)
                .font(Typography.caption)
                .foregroundStyle(ColorPalette.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.lg)
        .liquidGlass(tint: displayColor.opacity(0.08), cornerRadius: CornerRadius.lg)
    }
    
    private var displayIcon: String {
        if case .custom(let custom) = selectedCategory {
            return custom.icon
        }
        return selectedCategory?.icon ?? segment.displayIcon
    }
    
    private var displayColor: Color {
        if case .custom(let custom) = selectedCategory {
            return custom.color
        }
        return selectedCategory?.color ?? segment.displayColor
    }
    
    // MARK: - Label Section
    
    private var labelSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("What was this?")
                .font(Typography.headline)
            
            // Quick relabel options
            Text("Quick labels")
                .font(Typography.caption)
                .foregroundStyle(ColorPalette.secondaryText)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Spacing.sm) {
                ForEach(EventCategory.presets, id: \.id) { category in
                    Button {
                        selectedCategory = category
                        editedLabel = category.displayName
                        Haptics.selection()
                    } label: {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: category.icon)
                                .font(.caption)
                            Text(category.displayName)
                                .font(Typography.caption)
                        }
                        .foregroundStyle(selectedCategory == category ? .white : category.color)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .frame(maxWidth: .infinity)
                        .background(selectedCategory == category ? category.color : category.color.opacity(0.15))
                        .clipShape(Capsule())
                    }
                }
                
                // Custom option
                Button {
                    showingOtherPicker = true
                    Haptics.selection()
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "plus")
                            .font(.caption)
                        Text("Custom")
                            .font(Typography.caption)
                    }
                    .foregroundStyle(isCustomSelected ? .white : ColorPalette.accent)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .frame(maxWidth: .infinity)
                    .background(isCustomSelected ? ColorPalette.accent : ColorPalette.accent.opacity(0.15))
                    .clipShape(Capsule())
                }
            }
            
            // Custom label input
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Or type a custom label")
                    .font(Typography.caption)
                    .foregroundStyle(ColorPalette.secondaryText)
                
                TextField("e.g., Watching TikToks, Gaming, Nap", text: $editedLabel)
                    .textFieldStyle(.plain)
                    .padding(Spacing.md)
                    .background(ColorPalette.tertiaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                    .onChange(of: editedLabel) { _, newValue in
                        // Clear category selection if typing custom label
                        if !EventCategory.presets.map({ $0.displayName }).contains(newValue) {
                            if case .custom = selectedCategory {} else {
                                selectedCategory = nil
                            }
                        }
                    }
            }
        }
        .padding(Spacing.standard)
        .liquidGlass(cornerRadius: CornerRadius.standard)
    }
    
    private var isCustomSelected: Bool {
        if case .custom = selectedCategory {
            return true
        }
        return false
    }
    
    // MARK: - Time Section
    
    private var timeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Adjust Time")
                .font(Typography.headline)
            
            HStack(spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Start")
                        .font(Typography.caption)
                        .foregroundStyle(ColorPalette.secondaryText)
                    
                    DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .onChange(of: startTime) { _, newValue in
                            if endTime <= newValue {
                                endTime = Calendar.current.date(byAdding: .minute, value: 30, to: newValue) ?? newValue
                            }
                        }
                }
                
                Image(systemName: "arrow.right")
                    .foregroundStyle(ColorPalette.tertiaryText)
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("End")
                        .font(Typography.caption)
                        .foregroundStyle(ColorPalette.secondaryText)
                    
                    DatePicker("", selection: $endTime, in: startTime..., displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: Spacing.xs) {
                    Text("Duration")
                        .font(Typography.caption)
                        .foregroundStyle(ColorPalette.secondaryText)
                    
                    Text(formattedDuration)
                        .font(Typography.headline)
                        .foregroundStyle(ColorPalette.accent)
                }
            }
        }
        .padding(Spacing.standard)
        .liquidGlass(cornerRadius: CornerRadius.standard)
    }
    
    private var formattedDuration: String {
        let minutes = Int(endTime.timeIntervalSince(startTime) / 60)
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins)m"
    }
    
    // MARK: - Delete Section
    
    private var deleteSection: some View {
        Button(role: .destructive) {
            showDeleteConfirmation = true
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("Delete Event")
            }
            .font(Typography.body)
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity)
            .padding(Spacing.md)
            .background(Color.red.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
        }
    }
    
    // MARK: - Save
    
    private func saveChanges() {
        var updatedSegment = segment
        updatedSegment.locationLabel = editedLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedSegment.endTime = endTime
        
        // Update custom icon/color if category selected
        if case .custom(let custom) = selectedCategory {
            updatedSegment.customIcon = custom.icon
            updatedSegment.customColorHex = custom.colorHex
            updatedSegment.source = .manual
        } else if let category = selectedCategory {
            updatedSegment.customIcon = category.icon
            updatedSegment.customColorHex = category.color.hexString
        }
        
        onSave(updatedSegment)
        Haptics.success()
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    let segment = TimelineSegment(
        startTime: Date().addingTimeInterval(-3600),
        endTime: Date(),
        locationType: .home,
        locationLabel: "Home"
    )
    
    EditEventView(segment: segment, onSave: { _ in }, onDelete: {})
}
