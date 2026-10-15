//
//  SignalsApp.swift
//  Signals
//
//  Created by utkarsh on 2/7/26.
//

import SwiftUI
import SwiftData
import AppIntents

@main
struct SignalsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .preferredColorScheme(UserSettings.shared.colorScheme)
                .onAppear {
                    UserSettings.shared.recordAppOpen()
                }
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
        .modelContainer(PersistenceController.shared.container)
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
    }
    
    // MARK: - Deep Link Handling
    
    private func handleDeepLink(_ url: URL) {
        if NavigationRouter.shared.handleDeepLink(url) {
            NavigationRouter.shared.processPendingDeepLink(with: appState)
        }
    }
    
    // MARK: - Scene Phase Handling
    
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            // App became active
            UserSettings.shared.recordAppOpen()
            
        case .inactive:
            // App is transitioning (e.g., multitasking view)
            break
            
        case .background:
            // App entered background
            UserSettings.shared.lastBackgroundDate = Date()
            
        @unknown default:
            break
        }
    }
}
