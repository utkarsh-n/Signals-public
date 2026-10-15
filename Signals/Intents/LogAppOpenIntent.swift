//
//  LogAppOpenIntent.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import AppIntents
import SwiftData

/// An App Intent that logs when a user opens a specific category of app.
/// This is designed to be triggered via Shortcuts automation when the user
/// opens an app they want to track (similar to "one sec" style tracking).
struct LogAppOpenIntent: AppIntent {
    static var title: LocalizedStringResource = "Log App Open"
    static var description = IntentDescription("Logs when you open an app in a specific category to help track your app usage patterns.")
    
    // MARK: - Parameters
    
    @Parameter(
        title: "Category",
        description: "The category of app you're opening"
    )
    var category: AppCategoryEntity
    
    @Parameter(
        title: "Notes",
        description: "Optional notes about why you're opening this app",
        default: nil
    )
    var notes: String?
    
    // MARK: - Intent Execution
    
    static var parameterSummary: some ParameterSummary {
        Summary("Log opening a \(\.$category) app") {
            \.$notes
        }
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Use the shared persistence controller
        let context = PersistenceController.shared.mainContext
        
        // Create and save the log entry
        let logEntry = AppOpenLog(
            timestamp: Date(),
            category: category.appCategory,
            notes: notes
        )
        
        context.insert(logEntry)
        PersistenceController.shared.save()
        
        // Return confirmation
        let categoryName = category.appCategory.displayName
        return .result(dialog: "Logged \(categoryName) app open")
    }
}

// MARK: - App Category Entity

/// Entity wrapper for AppCategory to work with AppIntents
struct AppCategoryEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "App Category"
    static var defaultQuery = AppCategoryQuery()
    
    var id: String
    var displayName: String
    
    var appCategory: AppCategory {
        AppCategory(rawValue: id) ?? .other
    }
    
    init(category: AppCategory) {
        self.id = category.rawValue
        self.displayName = category.displayName
    }
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(displayName)",
            subtitle: nil,
            image: .init(systemName: appCategory.icon)
        )
    }
    
    static var allCategories: [AppCategoryEntity] {
        AppCategory.allCases.map { AppCategoryEntity(category: $0) }
    }
}

// MARK: - App Category Query

struct AppCategoryQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [AppCategoryEntity] {
        identifiers.compactMap { id in
            guard let category = AppCategory(rawValue: id) else { return nil }
            return AppCategoryEntity(category: category)
        }
    }
    
    func suggestedEntities() async throws -> [AppCategoryEntity] {
        AppCategoryEntity.allCategories
    }
    
    func defaultResult() async -> AppCategoryEntity? {
        AppCategoryEntity(category: .social)
    }
}

// MARK: - Quick Log Intents for Common Categories

/// Quick intent for logging social media app opens
struct LogSocialAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Social Media Open"
    static var description = IntentDescription("Quickly log opening a social media app")
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = PersistenceController.shared.mainContext
        
        let logEntry = AppOpenLog(timestamp: Date(), category: .social)
        context.insert(logEntry)
        PersistenceController.shared.save()
        
        return .result(dialog: "Logged social media open")
    }
}

/// Quick intent for logging entertainment app opens
struct LogEntertainmentAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Entertainment Open"
    static var description = IntentDescription("Quickly log opening an entertainment app")
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = PersistenceController.shared.mainContext
        
        let logEntry = AppOpenLog(timestamp: Date(), category: .entertainment)
        context.insert(logEntry)
        PersistenceController.shared.save()
        
        return .result(dialog: "Logged entertainment open")
    }
}

/// Quick intent for logging games
struct LogGameAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Game Open"
    static var description = IntentDescription("Quickly log opening a game")
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = PersistenceController.shared.mainContext
        
        let logEntry = AppOpenLog(timestamp: Date(), category: .games)
        context.insert(logEntry)
        PersistenceController.shared.save()
        
        return .result(dialog: "Logged game open")
    }
}
