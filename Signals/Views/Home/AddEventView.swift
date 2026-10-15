//
//  AddEventView.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import SwiftUI
import SwiftData

/// Sheet for adding a new manual event to the timeline
struct AddEventView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let selectedDate: Date
    let onSave: (ManualEvent) -> Void
    
    @State private var selectedCategory: EventCategory?
    @State private var showingOtherPicker = false
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var notes: String = ""
    
    init(selectedDate: Date, onSave: @escaping (ManualEvent) -> Void) {
        self.selectedDate = selectedDate
        self.onSave = onSave
        
        // Default to current hour rounded down, 1 hour duration
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let startOfHour = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: selectedDate) ?? now
        _startTime = State(initialValue: startOfHour)
        _endTime = State(initialValue: calendar.date(byAdding: .hour, value: 1, to: startOfHour) ?? now)
    }
    
    private var isValid: Bool {
        selectedCategory != nil && endTime > startTime
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Category Selection
                    categorySection
                    
                    // Time Selection
                    timeSection
                    
                    // Notes (optional)
                    notesSection
                }
                .padding(Spacing.standard)
            }
            .navigationTitle("Add Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEvent()
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingOtherPicker) {
                OtherEventPickerView { customCategory in
                    selectedCategory = .custom(customCategory)
                    RecentCustomEvents.shared.addRecentEvent(customCategory)
                }
            }
        }
    }
    
    // MARK: - Category Section
    
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("What were you doing?")
                .font(Typography.headline)
            
            // Preset categories grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Spacing.md) {
                ForEach(EventCategory.presets, id: \.id) { category in
                    CategoryButton(
                        category: category,
                        isSelected: selectedCategory == category,
                        onTap: {
                            withAnimation(AnimationTokens.snappy) {
                                selectedCategory = category
                            }
                            Haptics.selection()
                        }
                    )
                }
                
                // "Other" button
                OtherCategoryButton(
                    isSelected: isCustomSelected,
                    customCategory: customCategoryIfSelected,
                    onTap: {
                        showingOtherPicker = true
                        Haptics.selection()
                    }
                )
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
    
    private var customCategoryIfSelected: CustomEventCategory? {
        if case .custom(let custom) = selectedCategory {
            return custom
        }
        return nil
    }
    
    // MARK: - Time Section
    
    private var timeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("When?")
                .font(Typography.headline)
            
            HStack(spacing: Spacing.lg) {
                // Start time
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Start")
                        .font(Typography.caption)
                        .foregroundStyle(ColorPalette.secondaryText)
                    
                    DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .onChange(of: startTime) { _, newValue in
                            // Ensure end time is after start time
                            if endTime <= newValue {
                                endTime = Calendar.current.date(byAdding: .hour, value: 1, to: newValue) ?? newValue
                            }
                        }
                }
                
                Image(systemName: "arrow.right")
                    .foregroundStyle(ColorPalette.tertiaryText)
                
                // End time
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("End")
                        .font(Typography.caption)
                        .foregroundStyle(ColorPalette.secondaryText)
                    
                    DatePicker("", selection: $endTime, in: startTime..., displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
                
                Spacer()
                
                // Duration display
                VStack(alignment: .trailing, spacing: Spacing.xs) {
                    Text("Duration")
                        .font(Typography.caption)
                        .foregroundStyle(ColorPalette.secondaryText)
                    
                    Text(formattedDuration)
                        .font(Typography.headline)
                        .foregroundStyle(ColorPalette.accent)
                }
            }
            
            // Quick duration buttons
            HStack(spacing: Spacing.sm) {
                ForEach([15, 30, 60, 120], id: \.self) { minutes in
                    Button {
                        endTime = Calendar.current.date(byAdding: .minute, value: minutes, to: startTime) ?? endTime
                        Haptics.light()
                    } label: {
                        Text(formatMinutes(minutes))
                            .font(Typography.caption)
                            .foregroundStyle(ColorPalette.secondaryText)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xs)
                            .background(ColorPalette.tertiaryBackground)
                            .clipShape(Capsule())
                    }
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
    
    private func formatMinutes(_ minutes: Int) -> String {
        if minutes >= 60 {
            return "\(minutes / 60)h"
        }
        return "\(minutes)m"
    }
    
    // MARK: - Notes Section
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Notes (optional)")
                .font(Typography.headline)
            
            TextField("Add details...", text: $notes, axis: .vertical)
                .lineLimit(3...6)
                .textFieldStyle(.plain)
                .padding(Spacing.md)
                .background(ColorPalette.tertiaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
        }
        .padding(Spacing.standard)
        .liquidGlass(cornerRadius: CornerRadius.standard)
    }
    
    // MARK: - Save
    
    private func saveEvent() {
        guard let category = selectedCategory else { return }
        
        let event = ManualEvent(
            startTime: startTime,
            endTime: endTime,
            category: category,
            notes: notes.isEmpty ? nil : notes
        )
        
        modelContext.insert(event)
        onSave(event)
        Haptics.success()
        dismiss()
    }
}

// MARK: - Category Button

struct CategoryButton: View {
    let category: EventCategory
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: Spacing.sm) {
                Image(systemName: category.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(isSelected ? .white : category.color)
                
                Text(category.displayName)
                    .font(Typography.caption)
                    .foregroundStyle(isSelected ? .white : ColorPalette.primaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(isSelected ? category.color : ColorPalette.tertiaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Other Category Button

struct OtherCategoryButton: View {
    let isSelected: Bool
    let customCategory: CustomEventCategory?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: Spacing.sm) {
                if let custom = customCategory {
                    Image(systemName: custom.icon)
                        .font(.system(size: 24))
                        .foregroundStyle(isSelected ? .white : custom.color)
                    
                    Text(custom.name)
                        .font(Typography.caption)
                        .foregroundStyle(isSelected ? .white : ColorPalette.primaryText)
                        .lineLimit(1)
                } else {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(isSelected ? .white : ColorPalette.accent)
                    
                    Text("Other")
                        .font(Typography.caption)
                        .foregroundStyle(isSelected ? .white : ColorPalette.primaryText)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(
                isSelected 
                    ? (customCategory?.color ?? ColorPalette.accent) 
                    : ColorPalette.tertiaryBackground
            )
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    AddEventView(selectedDate: Date()) { _ in }
}
