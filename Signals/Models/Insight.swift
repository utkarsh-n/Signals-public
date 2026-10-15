//
//  Insight.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import Foundation
import SwiftData

@Model
final class Insight {
    var id: UUID
    var generatedDate: Date
    var category: InsightCategory
    var title: String
    var body: String
    var supportingDataRaw: Data?  // Encoded InsightData
    var signalsInvolvedRaw: [String]
    var confidence: Double
    var timeSpan: InsightTimeSpan
    var isRead: Bool
    var isSaved: Bool
    var feedbackRating: InsightRating?
    var createdAt: Date
    
    @Relationship(inverse: \WeeklyReport.insights)
    var weeklyReport: WeeklyReport?
    
    init(
        id: UUID = UUID(),
        generatedDate: Date = Date(),
        category: InsightCategory,
        title: String,
        body: String,
        supportingData: InsightData? = nil,
        signalsInvolved: [SignalType] = [],
        confidence: Double = 0.7,
        timeSpan: InsightTimeSpan = .week,
        isRead: Bool = false,
        isSaved: Bool = false,
        feedbackRating: InsightRating? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.generatedDate = generatedDate
        self.category = category
        self.title = title
        self.body = body
        self.supportingDataRaw = try? JSONEncoder().encode(supportingData)
        self.signalsInvolvedRaw = signalsInvolved.map { $0.rawValue }
        self.confidence = confidence
        self.timeSpan = timeSpan
        self.isRead = isRead
        self.isSaved = isSaved
        self.feedbackRating = feedbackRating
        self.createdAt = createdAt
    }
    
    // MARK: - Computed Accessors
    
    var supportingData: InsightData? {
        get {
            guard let data = supportingDataRaw else { return nil }
            return try? JSONDecoder().decode(InsightData.self, from: data)
        }
        set {
            supportingDataRaw = try? JSONEncoder().encode(newValue)
        }
    }
    
    var signalsInvolved: [SignalType] {
        get {
            signalsInvolvedRaw.compactMap { SignalType(rawValue: $0) }
        }
        set {
            signalsInvolvedRaw = newValue.map { $0.rawValue }
        }
    }
}

// MARK: - Convenience Methods

extension Insight {
    var formattedDate: String {
        generatedDate.formatted(date: .abbreviated, time: .omitted)
    }
    
    var isHighConfidence: Bool {
        confidence >= 0.7
    }
    
    /// Marks the insight as read
    func markAsRead() {
        isRead = true
    }
    
    /// Toggles the saved state
    func toggleSaved() {
        isSaved.toggle()
    }
    
    /// Sets the feedback rating
    func rate(_ rating: InsightRating) {
        feedbackRating = rating
    }
}
