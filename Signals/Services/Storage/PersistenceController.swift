//
//  PersistenceController.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import Foundation
import SwiftData

/// Manages the SwiftData model container for the app
@MainActor
final class PersistenceController {
    static let shared = PersistenceController()
    
    let container: ModelContainer
    
    /// All model types used in the app
    static let modelTypes: [any PersistentModel.Type] = [
        DailySnapshot.self,
        Insight.self,
        Reflection.self,
        MoodEntry.self,
        WeeklyReport.self,
        AppOpenLog.self,
        ManualEvent.self
    ]
    
    /// The schema for all models
    static var schema: Schema {
        Schema(modelTypes)
    }
    
    private init() {
        let configuration = ModelConfiguration(
            schema: Self.schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        
        do {
            container = try ModelContainer(
                for: Self.schema,
                configurations: [configuration]
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    /// Creates an in-memory container for previews and testing
    static func preview() -> PersistenceController {
        let controller = PersistenceController(inMemory: true)
        
        // Add sample data for previews
        let context = controller.container.mainContext
        
        // Create sample snapshots for the past week
        let calendar = Calendar.current
        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            
            let snapshot = DailySnapshot(date: date)
            snapshot.stepCount = Int.random(in: 3000...12000)
            snapshot.sleepHours = Double.random(in: 5.5...9.0)
            snapshot.screenTimeMinutes = Int.random(in: 60...300)
            snapshot.signalsCollected = [.steps, .sleep, .screenTime]
            
            context.insert(snapshot)
            
            // Add a reflection for some days
            if Bool.random() {
                let reflection = Reflection(
                    date: date,
                    text: "Sample reflection for \(date.formatted(date: .abbreviated, time: .omitted))"
                )
                reflection.linkedSnapshot = snapshot
                context.insert(reflection)
            }
        }
        
        // Create a sample insight
        let insight = Insight(
            category: .pattern,
            title: "You walk more on weekdays",
            body: "Your step count tends to be about 2,000 steps higher on weekdays compared to weekends.",
            signalsInvolved: [.steps],
            confidence: 0.82
        )
        context.insert(insight)
        
        return controller
    }
    
    /// Private initializer for in-memory testing
    private init(inMemory: Bool) {
        let configuration = ModelConfiguration(
            schema: Self.schema,
            isStoredInMemoryOnly: inMemory,
            allowsSave: true
        )
        
        do {
            container = try ModelContainer(
                for: Self.schema,
                configurations: [configuration]
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}

// MARK: - Convenience Methods

extension PersistenceController {
    /// Returns the main context
    var mainContext: ModelContext {
        container.mainContext
    }
    
    /// Saves the main context if there are changes
    func save() {
        let context = mainContext
        guard context.hasChanges else { return }
        
        do {
            try context.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
}
