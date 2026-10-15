//
//  OtherEventPickerView.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import SwiftUI

/// Sheet for creating a custom event category with name, icon, and color
struct OtherEventPickerView: View {
    @Environment(\.dismiss) private var dismiss
    
    let onSelect: (CustomEventCategory) -> Void
    
    private var recentEvents: RecentCustomEvents { RecentCustomEvents.shared }
    
    @State private var eventName: String = ""
    @State private var selectedIcon: String = "star.fill"
    @State private var selectedColorHex: String = "007AFF"
    @State private var showingIconPicker = false
    
    @FocusState private var isNameFocused: Bool
    
    private var isValid: Bool {
        !eventName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var matchingRecent: [CustomEventCategory] {
        recentEvents.matchingEvents(for: eventName)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Preview card
                    previewCard
                    
                    // Name input with autocomplete
                    nameSection
                    
                    // Recent suggestions
                    if !matchingRecent.isEmpty && !eventName.isEmpty {
                        recentSuggestionsSection
                    }
                    
                    // Icon picker
                    iconSection
                    
                    // Color picker
                    colorSection
                }
                .padding(Spacing.standard)
            }
            .navigationTitle("Custom Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        saveAndDismiss()
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    // MARK: - Preview Card
    
    private var previewCard: some View {
        VStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(selectedColor.opacity(0.2))
                    .frame(width: 64, height: 64)
                
                Image(systemName: selectedIcon)
                    .font(.system(size: 28))
                    .foregroundStyle(selectedColor)
            }
            
            Text(eventName.isEmpty ? "Event Name" : eventName)
                .font(Typography.headline)
                .foregroundStyle(eventName.isEmpty ? ColorPalette.tertiaryText : ColorPalette.primaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
        .liquidGlass(tint: selectedColor.opacity(0.08), cornerRadius: CornerRadius.lg)
    }
    
    private var selectedColor: Color {
        Color(hex: selectedColorHex) ?? .blue
    }
    
    // MARK: - Name Section
    
    private var nameSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Event Name")
                .font(Typography.headline)
            
            TextField("e.g., Watching TV, Reading, Coffee break", text: $eventName)
                .textFieldStyle(.plain)
                .padding(Spacing.md)
                .background(ColorPalette.tertiaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                .focused($isNameFocused)
                .onSubmit {
                    isNameFocused = false
                }
        }
        .padding(Spacing.standard)
        .liquidGlass(cornerRadius: CornerRadius.standard)
    }
    
    // MARK: - Recent Suggestions
    
    private var recentSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Recent")
                .font(Typography.caption)
                .foregroundStyle(ColorPalette.secondaryText)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(matchingRecent) { recent in
                        Button {
                            selectRecentEvent(recent)
                        } label: {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: recent.icon)
                                    .font(.caption)
                                Text(recent.name)
                                    .font(Typography.caption)
                            }
                            .foregroundStyle(recent.color)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xs)
                            .background(recent.color.opacity(0.15))
                            .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding(.horizontal, Spacing.standard)
    }
    
    private func selectRecentEvent(_ event: CustomEventCategory) {
        eventName = event.name
        selectedIcon = event.iconName
        selectedColorHex = event.colorHex
        Haptics.selection()
    }
    
    // MARK: - Icon Section
    
    private var iconSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Icon")
                    .font(Typography.headline)
                
                Spacer()
                
                Button {
                    showingIconPicker.toggle()
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: selectedIcon)
                            .foregroundStyle(selectedColor)
                        Image(systemName: showingIconPicker ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundStyle(ColorPalette.secondaryText)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(ColorPalette.tertiaryBackground)
                    .clipShape(Capsule())
                }
            }
            
            if showingIconPicker {
                iconGrid
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(Spacing.standard)
        .liquidGlass(cornerRadius: CornerRadius.standard)
        .animation(AnimationTokens.snappy, value: showingIconPicker)
    }
    
    private var iconGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: Spacing.md) {
            ForEach(EventSymbols.available, id: \.self) { symbol in
                Button {
                    selectedIcon = symbol
                    Haptics.light()
                } label: {
                    Image(systemName: symbol)
                        .font(.system(size: 20))
                        .foregroundStyle(selectedIcon == symbol ? selectedColor : ColorPalette.secondaryText)
                        .frame(width: 40, height: 40)
                        .background(
                            selectedIcon == symbol 
                                ? selectedColor.opacity(0.15) 
                                : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                }
            }
        }
    }
    
    // MARK: - Color Section
    
    private var colorSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Color")
                .font(Typography.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: Spacing.md) {
                ForEach(Array(zip(EventSymbols.availableColors.indices, EventSymbols.availableColorHexes)), id: \.0) { index, hex in
                    let color = EventSymbols.availableColors[index]
                    Button {
                        selectedColorHex = hex
                        Haptics.light()
                    } label: {
                        Circle()
                            .fill(color)
                            .frame(width: 36, height: 36)
                            .overlay {
                                if selectedColorHex == hex {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                    }
                }
            }
        }
        .padding(Spacing.standard)
        .liquidGlass(cornerRadius: CornerRadius.standard)
    }
    
    // MARK: - Save
    
    private func saveAndDismiss() {
        let trimmedName = eventName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        let customCategory = CustomEventCategory(
            name: trimmedName,
            iconName: selectedIcon,
            colorHex: selectedColorHex
        )
        
        onSelect(customCategory)
        Haptics.success()
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    OtherEventPickerView { category in
        print("Selected: \(category.name)")
    }
}
