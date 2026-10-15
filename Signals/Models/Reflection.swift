//
//  Reflection.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import Foundation
import SwiftData

@Model
final class Reflection {
    var id: UUID
    var date: Date
    var text: String
    var promptUsed: String?
    var sentiment: Sentiment?
    var tags: [String]
    var createdAt: Date
    
    @Relationship(inverse: \DailySnapshot.reflections)
    var linkedSnapshot: DailySnapshot?
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        text: String,
        promptUsed: String? = nil,
        sentiment: Sentiment? = nil,
        tags: [String] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.text = text
        self.promptUsed = promptUsed
        self.sentiment = sentiment
        self.tags = tags
        self.createdAt = createdAt
    }
}

extension Reflection {
    static var maxCharacterCount: Int { 500 }
    
    var isValid: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        text.count <= Self.maxCharacterCount
    }
    
    var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
