//
//  SignalsAppShortcuts.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import AppIntents

/// Provides app shortcuts for Signals to the Shortcuts app.
/// Users can use these shortcuts in automations to track app usage.
struct SignalsAppShortcuts: AppShortcutsProvider {
    
    /// The shortcuts that appear in the Shortcuts app
    static var appShortcuts: [AppShortcut] {
        // Main logging shortcut with category picker
        AppShortcut(
            intent: LogAppOpenIntent(),
            phrases: [
                "Log app open in \(.applicationName)",
                "Track app usage with \(.applicationName)",
                "Log \(\.$category) open in \(.applicationName)",
                "I opened a \(\.$category) app in \(.applicationName)"
            ],
            shortTitle: "Log App Open",
            systemImageName: "square.and.pencil"
        )
        
        // Quick social media shortcut
        AppShortcut(
            intent: LogSocialAppIntent(),
            phrases: [
                "Log social media in \(.applicationName)",
                "Track social media with \(.applicationName)",
                "I opened social media in \(.applicationName)"
            ],
            shortTitle: "Log Social",
            systemImageName: "person.2.fill"
        )
        
        // Quick entertainment shortcut
        AppShortcut(
            intent: LogEntertainmentAppIntent(),
            phrases: [
                "Log entertainment in \(.applicationName)",
                "Track entertainment with \(.applicationName)",
                "I'm watching something in \(.applicationName)"
            ],
            shortTitle: "Log Entertainment",
            systemImageName: "play.tv.fill"
        )
        
        // Quick game shortcut
        AppShortcut(
            intent: LogGameAppIntent(),
            phrases: [
                "Log game in \(.applicationName)",
                "Track gaming with \(.applicationName)",
                "I'm playing a game in \(.applicationName)"
            ],
            shortTitle: "Log Game",
            systemImageName: "gamecontroller.fill"
        )
    }
}
