//
//  AboutView.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import SwiftUI

/// About screen with app info, credits, and links
struct AboutView: View {
    var body: some View {
        List {
            // App info header
            Section {
                VStack(spacing: 16) {
                    // App icon
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 60))
                        .foregroundStyle(ColorPalette.primaryGradient)
                    
                    VStack(spacing: 4) {
                        Text("Signals")
                            .font(Typography.largeTitle)
                        
                        Text("Your personal pattern mirror")
                            .font(Typography.body)
                            .foregroundStyle(ColorPalette.secondaryText)
                    }
                    
                    Text("Version \(appVersion) (\(buildNumber))")
                        .font(Typography.caption)
                        .foregroundStyle(ColorPalette.tertiaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }
            .listRowBackground(Color.clear)
            
            // Links
            Section {
                Link(destination: URL(string: "https://signals.app")!) {
                    AboutRow(icon: "globe", title: "Website")
                }
                
                Link(destination: URL(string: "https://signals.app/privacy")!) {
                    AboutRow(icon: "lock.shield", title: "Privacy Policy")
                }
                
                Link(destination: URL(string: "https://signals.app/terms")!) {
                    AboutRow(icon: "doc.text", title: "Terms of Service")
                }
            } header: {
                Text("Resources")
            }
            
            // Support
            Section {
                Link(destination: URL(string: "mailto:support@signals.app")!) {
                    AboutRow(icon: "envelope", title: "Contact Support")
                }
                
                Link(destination: URL(string: "https://signals.app/faq")!) {
                    AboutRow(icon: "questionmark.circle", title: "FAQ")
                }
                
                Button(action: rateApp) {
                    AboutRow(icon: "star", title: "Rate Signals")
                }
            } header: {
                Text("Support")
            }
            
            // Social
            Section {
                Link(destination: URL(string: "https://twitter.com/signalsapp")!) {
                    AboutRow(icon: "at", title: "Follow on X")
                }
                
                Link(destination: URL(string: "https://instagram.com/signalsapp")!) {
                    AboutRow(icon: "camera", title: "Instagram")
                }
            } header: {
                Text("Connect")
            }
            
            // Credits
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Credits")
                        .font(Typography.headline)
                    
                    Text("Signals is designed and developed with care to help you understand yourself better through gentle observation and reflection.")
                        .font(Typography.body)
                        .foregroundStyle(ColorPalette.secondaryText)
                    
                    Text("Built with SwiftUI, SwiftData, HealthKit, and lots of ☕️")
                        .font(Typography.caption)
                        .foregroundStyle(ColorPalette.tertiaryText)
                }
                .padding(.vertical, 8)
            }
            
            // Acknowledgments
            Section {
                NavigationLink(destination: AcknowledgmentsView()) {
                    AboutRow(icon: "heart", title: "Acknowledgments")
                }
            }
            
            // Footer
            Section {
                VStack(spacing: 8) {
                    Text("Made with love")
                        .font(Typography.caption)
                        .foregroundStyle(ColorPalette.tertiaryText)
                    
                    Text("© \(currentYear) Signals")
                        .font(Typography.caption)
                        .foregroundStyle(ColorPalette.tertiaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .listRowBackground(Color.clear)
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Helpers
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    private var currentYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: Date())
    }
    
    private func rateApp() {
        // Open App Store review page
        if let url = URL(string: "https://apps.apple.com/app/idXXXXXXXXX?action=write-review") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - About Row

struct AboutRow: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(ColorPalette.accent)
                .frame(width: 24)
            
            Text(title)
                .foregroundStyle(ColorPalette.primaryText)
            
            Spacer()
            
            Image(systemName: "arrow.up.right")
                .font(.caption)
                .foregroundStyle(ColorPalette.tertiaryText)
        }
    }
}

// MARK: - Acknowledgments View

struct AcknowledgmentsView: View {
    var body: some View {
        List {
            Section {
                Text("Signals wouldn't be possible without the amazing open-source community and the frameworks provided by Apple.")
                    .font(Typography.body)
                    .foregroundStyle(ColorPalette.secondaryText)
            }
            
            Section("Apple Frameworks") {
                AcknowledgmentRow(name: "SwiftUI", description: "User interface framework")
                AcknowledgmentRow(name: "SwiftData", description: "Data persistence")
                AcknowledgmentRow(name: "HealthKit", description: "Health data access")
                AcknowledgmentRow(name: "CoreLocation", description: "Location services")
                AcknowledgmentRow(name: "CoreMotion", description: "Motion data")
                AcknowledgmentRow(name: "WeatherKit", description: "Weather data")
                AcknowledgmentRow(name: "StoreKit 2", description: "In-app purchases")
                AcknowledgmentRow(name: "NaturalLanguage", description: "Text analysis")
            }
            
            Section("Special Thanks") {
                Text("To everyone who believes that understanding yourself shouldn't require judgment or goals — just gentle awareness.")
                    .font(Typography.body)
                    .foregroundStyle(ColorPalette.secondaryText)
                    .padding(.vertical, 8)
            }
        }
        .navigationTitle("Acknowledgments")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AcknowledgmentRow: View {
    let name: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(name)
                .font(Typography.body)
            Text(description)
                .font(Typography.caption)
                .foregroundStyle(ColorPalette.secondaryText)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AboutView()
    }
}
