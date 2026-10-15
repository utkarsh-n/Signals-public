//
//  QuickReflectionView.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import SwiftUI

/// Inline reflection entry on home screen
struct QuickReflectionView: View {
    @Binding var isExpanded: Bool
    let onSave: (String) -> Void
    
    @State private var reflectionText = ""
    @FocusState private var isFocused: Bool
    
    private var characterCount: Int {
        reflectionText.count
    }
    
    private var isValid: Bool {
        !reflectionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        characterCount <= Reflection.maxCharacterCount
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "pencil.and.outline")
                    .foregroundStyle(ColorPalette.reflection)
                
                Text("Quick reflection")
                    .font(Typography.subheadline)
                    .foregroundStyle(ColorPalette.secondaryText)
                
                Spacer()
                
                if isExpanded {
                    Button("Cancel") {
                        cancelReflection()
                    }
                    .font(Typography.caption)
                    .foregroundStyle(ColorPalette.secondaryText)
                }
            }
            
            if isExpanded {
                // Expanded editor
                VStack(alignment: .leading, spacing: 8) {
                    TextEditor(text: $reflectionText)
                        .font(Typography.body)
                        .frame(minHeight: 100, maxHeight: 150)
                        .scrollContentBackground(.hidden)
                        .focused($isFocused)
                    
                    HStack {
                        // Character count
                        Text("\(characterCount)/\(Reflection.maxCharacterCount)")
                            .font(Typography.caption2)
                            .foregroundStyle(
                                characterCount > Reflection.maxCharacterCount 
                                ? .red 
                                : ColorPalette.tertiaryText
                            )
                        
                        Spacer()
                        
                        // Save button
                        Button {
                            saveReflection()
                        } label: {
                            Text("Save")
                                .font(Typography.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(
                                    isValid 
                                    ? ColorPalette.reflection 
                                    : ColorPalette.tertiaryText
                                )
                                .clipShape(Capsule())
                        }
                        .disabled(!isValid)
                    }
                }
            } else {
                // Collapsed prompt
                Button {
                    expandEditor()
                } label: {
                    HStack {
                        Text("What's on your mind?")
                            .font(Typography.body)
                            .foregroundStyle(ColorPalette.tertiaryText)
                        
                        Spacer()
                    }
                    .padding(.vertical, 12)
                }
            }
        }
        .padding(16)
        .background(ColorPalette.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }
    
    private func expandEditor() {
        isExpanded = true
        isFocused = true
        Haptics.light()
    }
    
    private func cancelReflection() {
        reflectionText = ""
        isExpanded = false
        isFocused = false
        Haptics.light()
    }
    
    private func saveReflection() {
        guard isValid else { return }
        onSave(reflectionText.trimmingCharacters(in: .whitespacesAndNewlines))
        reflectionText = ""
        isFocused = false
    }
}

// MARK: - Preview

#Preview {
    VStack {
        QuickReflectionView(isExpanded: .constant(false), onSave: { _ in })
        QuickReflectionView(isExpanded: .constant(true), onSave: { _ in })
    }
    .padding()
}
