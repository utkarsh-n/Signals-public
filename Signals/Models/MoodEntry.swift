//
//  MoodEntry.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import Foundation
import SwiftData

@Model
final class MoodEntry {
    var id: UUID
    var date: Date
    var timestamp: Date
    var mood: MoodLevel
    var energy: EnergyLevel?
    var note: String?
    
    @Relationship(inverse: \DailySnapshot.moodEntries)
    var linkedSnapshot: DailySnapshot?
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        timestamp: Date = Date(),
        mood: MoodLevel,
        energy: EnergyLevel? = nil,
        note: String? = nil
    ) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.timestamp = timestamp
        self.mood = mood
        self.energy = energy
        self.note = note
    }
}

extension MoodEntry {
    static var maxNoteLength: Int { 100 }
    
    var formattedTime: String {
        timestamp.formatted(date: .omitted, time: .shortened)
    }
}
