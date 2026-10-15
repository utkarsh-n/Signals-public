//
//  ContentView.swift
//  Signals
//
//  Created by utkarsh on 2/7/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    
    @State private var showingSplash = true
    
    var body: some View {
        ZStack {
            // Main content
            Group {
                if appState.showingOnboarding {
                    OnboardingContainerView()
                } else {
                    MainTabView()
                }
            }
            .opacity(showingSplash ? 0 : 1)
            
            // Splash screen overlay
            if showingSplash {
                SplashView {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showingSplash = false
                    }
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            appState.refreshTodayData(from: modelContext)
        }
        .sheet(isPresented: Binding(
            get: { appState.showingPaywall },
            set: { appState.showingPaywall = $0 }
        )) {
            PaywallView()
        }
        .onOpenURL { url in
            _ = NavigationRouter.shared.handleDeepLink(url)
            NavigationRouter.shared.processPendingDeepLink(with: appState)
        }
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        @Bindable var appState = appState
        
        TabView(selection: $appState.selectedTab) {
            HomeView()
                .tabItem {
                    Label(Tab.home.title, systemImage: Tab.home.icon)
                }
                .tag(Tab.home)
            
            InsightsTabView()
                .tabItem {
                    Label(Tab.insights.title, systemImage: Tab.insights.icon)
                }
                .tag(Tab.insights)
            
            TimelineTabView()
                .tabItem {
                    Label(Tab.timeline.title, systemImage: Tab.timeline.icon)
                }
                .tag(Tab.timeline)
            
            ReflectTabView()
                .tabItem {
                    Label(Tab.reflect.title, systemImage: Tab.reflect.icon)
                }
                .tag(Tab.reflect)
            
            SettingsView()
                .tabItem {
                    Label(Tab.settings.title, systemImage: Tab.settings.icon)
                }
                .tag(Tab.settings)
        }
        .onChange(of: appState.selectedTab) { _, _ in
            Haptics.tabChanged()
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environment(AppState())
        .modelContainer(PersistenceController.preview().container)
}
