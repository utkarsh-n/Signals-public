//
//  ReflectionEditorView.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import SwiftUI
import SwiftData

/// Minimal reflection editor with character count and auto-save
struct ReflectionEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var text: String = ""
    @State private var isSaving = false
    @FocusState private var isTextFieldFocused: Bool
    
    var prompt: String? = nil
    var existingReflection: Reflection? = nil
    var onSave: ((Reflection) -> Void)? = nil
    
    private let maxCharacters = Reflection.maxCharacterCount
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Prompt suggestion (if any)
                if let prompt = prompt {
                    promptView(prompt)
                }
                
                // Text editor
                editorView
                
                // Character count & status
                footerView
            }
            .background(ColorPalette.background)
            .navigationTitle(existingReflection == nil ? "New Reflection" : "Edit Reflection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(ColorPalette.secondaryText)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveReflection()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSave)
                }
            }
            .onAppear {
                if let existing = existingReflection {
                    text = existing.text
                }
                isTextFieldFocused = true
            }
        }
    }
    
    // MARK: - Prompt View
    
    private func promptView(_ prompt: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(.caption)
                Text("Suggested prompt")
                    .font(Typography.caption)
            }
            .foregroundStyle(ColorPalette.accent)
            
            Text(prompt)
                .font(Typography.body)
                .foregroundStyle(ColorPalette.primaryText)
                .italic()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(ColorPalette.accent.opacity(0.1))
    }
    
    // MARK: - Editor View
    
    private var editorView: some View {
        TextEditor(text: $text)
            .font(Typography.body)
            .foregroundStyle(ColorPalette.primaryText)
            .scrollContentBackground(.hidden)
            .background(ColorPalette.background)
            .focused($isTextFieldFocused)
            .padding()
            .onChange(of: text) { _, newValue in
                // Limit character count
                if newValue.count > maxCharacters {
                    text = String(newValue.prefix(maxCharacters))
                }
            }
    }
    
    // MARK: - Footer View
    
    private var footerView: some View {
        HStack {
            // Date & time info
            VStack(alignment: .leading, spacing: 2) {
                Text(Date().formatted(.dateTime.weekday(.wide).month().day()))
                    .font(Typography.caption)
                    .foregroundStyle(ColorPalette.secondaryText)
                
                Text(Date().formatted(date: .omitted, time: .shortened))
                    .font(Typography.caption)
                    .foregroundStyle(ColorPalette.tertiaryText)
            }
            
            Spacer()
            
            // Character count
            Text("\(text.count)/\(maxCharacters)")
                .font(Typography.caption)
                .foregroundStyle(characterCountColor)
        }
        .padding()
        .background(ColorPalette.secondaryBackground)
    }
    
    // MARK: - Helpers
    
    private var canSave: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        text.count <= maxCharacters
    }
    
    private var characterCountColor: Color {
        if text.count >= maxCharacters {
            return .red
        } else if text.count >= maxCharacters - 50 {
            return .orange
        }
        return ColorPalette.tertiaryText
    }
    
    private func saveReflection() {
        guard canSave else { return }
        
        isSaving = true
        
        let reflection: Reflection
        
        if let existing = existingReflection {
            // Update existing
            existing.text = text.trimmingCharacters(in: .whitespacesAndNewlines)
            reflection = existing
        } else {
            // Create new
            reflection = Reflection(
                date: Date(),
                text: text.trimmingCharacters(in: .whitespacesAndNewlines),
                promptUsed: prompt
            )
            modelContext.insert(reflection)
        }
        
        // Link to today's snapshot if available
        let today = Calendar.current.startOfDay(for: Date())
        let descriptor = FetchDescriptor<DailySnapshot>(
            predicate: #Predicate { $0.date == today }
        )
        
        if let snapshots = try? modelContext.fetch(descriptor),
           let todaySnapshot = snapshots.first {
            reflection.linkedSnapshot = todaySnapshot
        }
        
        Haptics.reflectionSaved()
        onSave?(reflection)
        dismiss()
    }
}

// MARK: - Inline Reflection Editor

/// A compact inline reflection editor for quick entry
struct InlineReflectionEditor: View {
    @Environment(\.modelContext) private var modelContext
    
    @State private var text = ""
    @State private var isExpanded = false
    @FocusState private var isFocused: Bool
    
    var placeholder: String = "What's on your mind?"
    var onSave: ((Reflection) -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 12) {
            // Text field
            HStack(alignment: .top) {
                TextField(placeholder, text: $text, axis: .vertical)
                    .font(Typography.body)
                    .lineLimit(isExpanded ? 5 : 2)
                    .focused($isFocused)
                    .onChange(of: isFocused) { _, focused in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isExpanded = focused
                        }
                    }
                
                if !text.isEmpty {
                    Button(action: save) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(ColorPalette.accent)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .background(ColorPalette.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Character count when expanded
            if isExpanded && !text.isEmpty {
                HStack {
                    Spacer()
                    Text("\(text.count)/\(Reflection.maxCharacterCount)")
                        .font(Typography.caption)
                        .foregroundStyle(
                            text.count > Reflection.maxCharacterCount
                            ? .red
                            : ColorPalette.tertiaryText
                        )
                }
            }
        }
    }
    
    private func save() {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              text.count <= Reflection.maxCharacterCount else { return }
        
        let reflection = Reflection(
            date: Date(),
            text: text.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        modelContext.insert(reflection)
        
        // Link to today's snapshot
        let today = Calendar.current.startOfDay(for: Date())
        let descriptor = FetchDescriptor<DailySnapshot>(
            predicate: #Predicate { $0.date == today }
        )
        
        if let snapshots = try? modelContext.fetch(descriptor),
           let todaySnapshot = snapshots.first {
            reflection.linkedSnapshot = todaySnapshot
        }
        
        Haptics.reflectionSaved()
        onSave?(reflection)
        
        text = ""
        isFocused = false
    }
}

// MARK: - Preview

#Preview {
    ReflectionEditorView(
        prompt: "What made today different from yesterday?"
    )
    .modelContainer(PersistenceController.preview().container)
}
