//
//  AppearanceSettingsView.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import SwiftUI

/// Settings view for appearance customization
struct AppearanceSettingsView: View {
    @State private var selectedTheme = UserSettings.shared.theme
    @State private var selectedAccentColor = UserSettings.shared.accentColorName
    
    var body: some View {
        List {
            // Theme selection
            Section {
                ForEach(AppTheme.allCases) { theme in
                    ThemeRow(
                        theme: theme,
                        isSelected: selectedTheme == theme
                    ) {
                        selectedTheme = theme
                        UserSettings.shared.theme = theme
                        Haptics.selection()
                    }
                }
            } header: {
                Text("Theme")
            } footer: {
                Text("Choose how Signals appears")
            }
            
            // Accent color selection
            Section {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 16) {
                    ForEach(ColorPalette.accentOptions, id: \.name) { option in
                        AccentColorButton(
                            color: option.color,
                            name: option.name,
                            isSelected: selectedAccentColor == option.name
                        ) {
                            selectedAccentColor = option.name
                            UserSettings.shared.accentColorName = option.name
                            Haptics.selection()
                        }
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("Accent Color")
            }
            
            // Preview
            Section {
                AppearancePreview(
                    theme: selectedTheme,
                    accentColorName: selectedAccentColor
                )
            } header: {
                Text("Preview")
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Theme Row

struct ThemeRow: View {
    let theme: AppTheme
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: theme.icon)
                    .foregroundStyle(ColorPalette.accent)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(theme.displayName)
                        .font(Typography.body)
                        .foregroundStyle(ColorPalette.primaryText)
                    
                    Text(theme.description)
                        .font(Typography.caption)
                        .foregroundStyle(ColorPalette.secondaryText)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(ColorPalette.accent)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - App Theme

enum AppTheme: String, CaseIterable, Identifiable, Codable {
    case system
    case light
    case dark
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
    
    var description: String {
        switch self {
        case .system: return "Follow system setting"
        case .light: return "Always light mode"
        case .dark: return "Always dark mode"
        }
    }
    
    var icon: String {
        switch self {
        case .system: return "gear"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - Accent Color Button

struct AccentColorButton: View {
    let color: Color
    let name: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 44, height: 44)
                
                if isSelected {
                    Circle()
                        .strokeBorder(.white, lineWidth: 3)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "checkmark")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Appearance Preview

struct AppearancePreview: View {
    let theme: AppTheme
    let accentColorName: String
    
    var body: some View {
        VStack(spacing: 12) {
            // Sample card
            HStack {
                Circle()
                    .fill(ColorPalette.accentColor(named: accentColorName))
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sample Insight")
                        .font(Typography.headline)
                    Text("This is how content will look")
                        .font(Typography.caption)
                        .foregroundStyle(ColorPalette.secondaryText)
                }
                
                Spacer()
            }
            .padding()
            .background(ColorPalette.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Sample button
            Text("Sample Button")
                .font(Typography.body)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(ColorPalette.accentColor(named: accentColorName))
                .clipShape(Capsule())
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AppearanceSettingsView()
    }
}
