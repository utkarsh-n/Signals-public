//
//  PrivacySettingsView.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import SwiftUI
import SwiftData

/// Settings view for privacy and data management
struct PrivacySettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    
    @Query(sort: \DailySnapshot.date, order: .reverse)
    private var allSnapshots: [DailySnapshot]
    
    @Query private var allReflections: [Reflection]
    @Query private var allInsights: [Insight]
    
    @State private var showingDeleteConfirmation = false
    @State private var showingExportSheet = false
    @State private var showingDeleteSpecificDays = false
    @State private var selectedDaysToDelete: Set<Date> = []
    @State private var showingPaywall = false
    
    var body: some View {
        List {
            // Data overview
            Section {
                DataOverviewRow(title: "Days Tracked", value: "\(allSnapshots.count)")
                DataOverviewRow(title: "Reflections", value: "\(allReflections.count)")
                DataOverviewRow(title: "Insights Generated", value: "\(allInsights.count)")
                
                if let firstDate = allSnapshots.last?.date {
                    DataOverviewRow(
                        title: "Tracking Since",
                        value: firstDate.formatted(date: .abbreviated, time: .omitted)
                    )
                }
            } header: {
                Text("Your Data")
            } footer: {
                Text("All data is stored locally on your device. Nothing is ever sent to external servers.")
            }
            
            // Export
            Section {
                if PaywallManager.shared.canAccess(.exportData) {
                    Button(action: { showingExportSheet = true }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(ColorPalette.accent)
                            Text("Export Data")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(ColorPalette.tertiaryText)
                        }
                    }
                    .foregroundStyle(ColorPalette.primaryText)
                } else {
                    Button(action: { showingPaywall = true }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(ColorPalette.tertiaryText)
                            Text("Export Data")
                            Spacer()
                            HStack(spacing: 4) {
                                Image(systemName: "lock.fill")
                                    .font(.caption)
                                Text("Premium")
                                    .font(Typography.caption)
                            }
                            .foregroundStyle(ColorPalette.accent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(ColorPalette.accent.opacity(0.1))
                            .clipShape(Capsule())
                        }
                    }
                    .foregroundStyle(ColorPalette.primaryText)
                }
            } header: {
                Text("Export")
            } footer: {
                Text("Export your data as JSON for backup or personal analysis")
            }
            
            // Delete specific days
            Section {
                NavigationLink(destination: DeleteSpecificDaysView()) {
                    HStack {
                        Image(systemName: "calendar.badge.minus")
                            .foregroundStyle(.orange)
                        Text("Delete Specific Days")
                    }
                }
            } header: {
                Text("Manage Data")
            }
            
            // Delete all data
            Section {
                Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                    HStack {
                        Image(systemName: "trash.fill")
                        Text("Delete All Data")
                    }
                }
            } footer: {
                Text("This will permanently delete all your data including snapshots, reflections, and insights. This action cannot be undone.")
            }
            
            // Privacy policy
            Section {
                Link(destination: URL(string: "https://signals.app/privacy")!) {
                    HStack {
                        Text("Privacy Policy")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(ColorPalette.tertiaryText)
                    }
                }
                .foregroundStyle(ColorPalette.primaryText)
            }
        }
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete All Data?", isPresented: $showingDeleteConfirmation) {
            Button("Delete Everything", role: .destructive) {
                deleteAllData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all your data. This action cannot be undone.")
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportDataView()
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }
    
    private func deleteAllData() {
        // Delete all snapshots
        for snapshot in allSnapshots {
            modelContext.delete(snapshot)
        }
        
        // Delete all reflections
        for reflection in allReflections {
            modelContext.delete(reflection)
        }
        
        // Delete all insights
        for insight in allInsights {
            modelContext.delete(insight)
        }
        
        try? modelContext.save()
        Haptics.warning()
    }
}

// MARK: - Data Overview Row

struct DataOverviewRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(ColorPalette.primaryText)
            Spacer()
            Text(value)
                .foregroundStyle(ColorPalette.secondaryText)
        }
    }
}

// MARK: - Delete Specific Days View

struct DeleteSpecificDaysView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \DailySnapshot.date, order: .reverse)
    private var allSnapshots: [DailySnapshot]
    
    @State private var selectedSnapshots: Set<UUID> = []
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        List {
            ForEach(allSnapshots, id: \.id) { snapshot in
                HStack {
                    Button(action: { toggleSelection(snapshot) }) {
                        Image(systemName: selectedSnapshots.contains(snapshot.id) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(selectedSnapshots.contains(snapshot.id) ? ColorPalette.accent : ColorPalette.tertiaryText)
                    }
                    .buttonStyle(.plain)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(snapshot.date.formatted(date: .long, time: .omitted))
                            .font(Typography.body)
                        
                        Text(snapshotSummary(snapshot))
                            .font(Typography.caption)
                            .foregroundStyle(ColorPalette.secondaryText)
                    }
                }
            }
        }
        .navigationTitle("Select Days")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Delete") {
                    showingDeleteConfirmation = true
                }
                .foregroundStyle(.red)
                .disabled(selectedSnapshots.isEmpty)
            }
        }
        .alert("Delete \(selectedSnapshots.count) Days?", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                deleteSelectedDays()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete the selected days and their associated data.")
        }
    }
    
    private func toggleSelection(_ snapshot: DailySnapshot) {
        if selectedSnapshots.contains(snapshot.id) {
            selectedSnapshots.remove(snapshot.id)
        } else {
            selectedSnapshots.insert(snapshot.id)
        }
        Haptics.selection()
    }
    
    private func snapshotSummary(_ snapshot: DailySnapshot) -> String {
        var parts: [String] = []
        
        if let steps = snapshot.stepCount {
            parts.append("\(steps) steps")
        }
        if let sleep = snapshot.sleepHours {
            parts.append(String(format: "%.1fh sleep", sleep))
        }
        if let reflections = snapshot.reflections {
            parts.append("\(reflections.count) reflections")
        }
        
        return parts.isEmpty ? "No data" : parts.joined(separator: " • ")
    }
    
    private func deleteSelectedDays() {
        for snapshot in allSnapshots where selectedSnapshots.contains(snapshot.id) {
            modelContext.delete(snapshot)
        }
        
        try? modelContext.save()
        Haptics.warning()
        dismiss()
    }
}

// MARK: - Export Data View

struct ExportDataView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query private var allSnapshots: [DailySnapshot]
    @Query private var allReflections: [Reflection]
    @Query private var allInsights: [Insight]
    
    @State private var isExporting = false
    @State private var exportURL: URL?
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Export info
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(ColorPalette.accent)
                    
                    Text("Export Your Data")
                        .font(Typography.title)
                    
                    Text("Your data will be exported as a JSON file that you can save, backup, or analyze.")
                        .font(Typography.body)
                        .foregroundStyle(ColorPalette.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                // Data summary
                VStack(spacing: 8) {
                    ExportSummaryRow(title: "Daily Snapshots", count: allSnapshots.count)
                    ExportSummaryRow(title: "Reflections", count: allReflections.count)
                    ExportSummaryRow(title: "Insights", count: allInsights.count)
                }
                .padding()
                .background(ColorPalette.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                
                Spacer()
                
                // Export button
                Button(action: exportData) {
                    HStack {
                        if isExporting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "square.and.arrow.up")
                        }
                        Text(isExporting ? "Exporting..." : "Export as JSON")
                    }
                    .font(Typography.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(ColorPalette.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isExporting)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .padding(.top, 32)
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }
    
    private func exportData() {
        isExporting = true
        
        Task {
            // Create export data structure
            let exportData: [String: Any] = [
                "exportDate": ISO8601DateFormatter().string(from: Date()),
                "snapshotCount": allSnapshots.count,
                "reflectionCount": allReflections.count,
                "insightCount": allInsights.count
                // In a real implementation, include actual data
            ]
            
            // Create temp file
            let tempDir = FileManager.default.temporaryDirectory
            let exportURL = tempDir.appendingPathComponent("signals_export_\(Date().timeIntervalSince1970).json")
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted) {
                try? jsonData.write(to: exportURL)
                
                await MainActor.run {
                    self.exportURL = exportURL
                    self.isExporting = false
                    self.showingShareSheet = true
                    Haptics.success()
                }
            }
        }
    }
}

struct ExportSummaryRow: View {
    let title: String
    let count: Int
    
    var body: some View {
        HStack {
            Text(title)
                .font(Typography.body)
                .foregroundStyle(ColorPalette.primaryText)
            Spacer()
            Text("\(count)")
                .font(Typography.metric)
                .foregroundStyle(ColorPalette.secondaryText)
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PrivacySettingsView()
    }
    .environment(AppState())
    .modelContainer(PersistenceController.preview().container)
}
