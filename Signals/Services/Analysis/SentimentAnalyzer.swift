//
//  SentimentAnalyzer.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import Foundation
import NaturalLanguage

/// Analyzes sentiment and extracts tags from reflection text
@MainActor
final class SentimentAnalyzer {
    static let shared = SentimentAnalyzer()
    
    private let tagger = NLTagger(tagSchemes: [.sentimentScore, .lemma, .nameType])
    
    // MARK: - Sentiment Analysis
    
    /// Analyze the sentiment of a text
    func analyzeSentiment(_ text: String) -> Sentiment {
        let score = sentimentScore(for: text)
        
        if score > 0.2 {
            return .positive
        } else if score < -0.2 {
            return .negative
        } else {
            return .neutral
        }
    }
    
    /// Get the raw sentiment score (-1.0 to 1.0)
    func sentimentScore(for text: String) -> Double {
        tagger.string = text
        
        let range = text.startIndex..<text.endIndex
        
        var totalScore: Double = 0
        var count: Double = 0
        
        tagger.enumerateTags(in: range, unit: .sentence, scheme: .sentimentScore, options: []) { tag, _ in
            if let tag = tag, let score = Double(tag.rawValue) {
                totalScore += score
                count += 1
            }
            return true
        }
        
        return count > 0 ? totalScore / count : 0
    }
    
    /// Analyze sentiment for a reflection and update it
    func analyzeAndUpdate(_ reflection: Reflection) {
        reflection.sentiment = analyzeSentiment(reflection.text)
        reflection.tags = extractTags(from: reflection.text)
    }
    
    // MARK: - Tag Extraction
    
    /// Extract meaningful tags from text
    func extractTags(from text: String) -> [String] {
        var tags: [String] = []
        
        // Extract named entities
        tags.append(contentsOf: extractNamedEntities(from: text))
        
        // Extract topic keywords
        tags.append(contentsOf: extractKeywords(from: text))
        
        // Extract emotional keywords
        tags.append(contentsOf: extractEmotionalKeywords(from: text))
        
        // Deduplicate and limit
        let uniqueTags = Array(Set(tags))
        return Array(uniqueTags.prefix(5))
    }
    
    private func extractNamedEntities(from text: String) -> [String] {
        var entities: [String] = []
        
        tagger.string = text
        let range = text.startIndex..<text.endIndex
        
        tagger.enumerateTags(in: range, unit: .word, scheme: .nameType, options: [.omitWhitespace, .omitPunctuation]) { tag, tokenRange in
            if let tag = tag {
                let word = String(text[tokenRange])
                switch tag {
                case .placeName:
                    entities.append("place:\(word.lowercased())")
                case .personalName:
                    entities.append("person:\(word.lowercased())")
                default:
                    break
                }
            }
            return true
        }
        
        return entities
    }
    
    private func extractKeywords(from text: String) -> [String] {
        var keywords: [String] = []
        
        tagger.string = text.lowercased()
        let range = text.startIndex..<text.endIndex
        
        // Look for nouns and verbs that might be topical
        let topicWords = Set([
            "work", "job", "meeting", "project",
            "family", "friend", "friends", "kids", "children", "partner",
            "exercise", "gym", "run", "walk", "workout",
            "sleep", "rest", "tired", "exhausted", "energy",
            "food", "eat", "cooking", "dinner", "lunch",
            "travel", "trip", "vacation",
            "health", "doctor", "sick",
            "read", "book", "movie", "music",
            "nature", "outside", "park", "beach",
            "stress", "anxiety", "calm", "relax",
            "goal", "progress", "achievement",
            "grateful", "thankful", "appreciate"
        ])
        
        tagger.enumerateTags(in: range, unit: .word, scheme: .lemma, options: [.omitWhitespace, .omitPunctuation]) { tag, tokenRange in
            let word = tag?.rawValue ?? String(text[tokenRange])
            if topicWords.contains(word.lowercased()) {
                keywords.append(word.lowercased())
            }
            return true
        }
        
        return keywords
    }
    
    private func extractEmotionalKeywords(from text: String) -> [String] {
        let lowercased = text.lowercased()
        var emotions: [String] = []
        
        // Positive emotions
        let positiveWords = ["happy", "excited", "grateful", "proud", "joy", "love", "hopeful", "peaceful", "content", "inspired"]
        for word in positiveWords {
            if lowercased.contains(word) {
                emotions.append("feeling:\(word)")
            }
        }
        
        // Challenging emotions
        let challengingWords = ["anxious", "stressed", "worried", "sad", "frustrated", "overwhelmed", "tired", "lonely"]
        for word in challengingWords {
            if lowercased.contains(word) {
                emotions.append("feeling:\(word)")
            }
        }
        
        return emotions
    }
    
    // MARK: - Batch Analysis
    
    /// Analyze sentiment for multiple reflections
    func analyzeBatch(_ reflections: [Reflection]) {
        for reflection in reflections {
            analyzeAndUpdate(reflection)
        }
    }
    
    /// Get sentiment distribution for a set of reflections
    func sentimentDistribution(for reflections: [Reflection]) -> SentimentDistribution {
        var positive = 0
        var neutral = 0
        var negative = 0
        
        for reflection in reflections {
            let sentiment = reflection.sentiment ?? analyzeSentiment(reflection.text)
            switch sentiment {
            case .positive: positive += 1
            case .neutral: neutral += 1
            case .negative: negative += 1
            }
        }
        
        let total = reflections.count
        guard total > 0 else {
            return SentimentDistribution(positive: 0, neutral: 0, negative: 0)
        }
        
        return SentimentDistribution(
            positive: Double(positive) / Double(total),
            neutral: Double(neutral) / Double(total),
            negative: Double(negative) / Double(total)
        )
    }
    
    /// Get the most common tags from a set of reflections
    func topTags(from reflections: [Reflection], limit: Int = 10) -> [(tag: String, count: Int)] {
        var tagCounts: [String: Int] = [:]
        
        for reflection in reflections {
            let tags = reflection.tags.isEmpty ? extractTags(from: reflection.text) : reflection.tags
            for tag in tags {
                tagCounts[tag, default: 0] += 1
            }
        }
        
        return tagCounts
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { (tag: $0.key, count: $0.value) }
    }
    
    // MARK: - Contextual Prompts
    
    /// Generate a contextual reflection prompt based on recent data
    func generatePrompt(for snapshot: DailySnapshot?, recentReflections: [Reflection]) -> String {
        // If no snapshot, use generic prompt
        guard let snapshot = snapshot else {
            return genericPrompts.randomElement() ?? "What's on your mind?"
        }
        
        // Activity-based prompts
        if let steps = snapshot.stepCount, steps > 8000 {
            return activityPrompts.randomElement() ?? "What got you moving today?"
        }
        
        // Sleep-based prompts
        if let sleep = snapshot.sleepHours, sleep > 8 {
            return sleepPrompts.randomElement() ?? "How did the extra rest feel?"
        }
        
        // Weather-based prompts
        if let weather = snapshot.weatherCondition {
            switch weather {
            case .clear:
                return "The weather was nice today. Did it affect your day?"
            case .rainy:
                return "A rainy day. How did you spend your time inside?"
            default:
                break
            }
        }
        
        // Check recent reflection sentiment
        let recentSentiments = recentReflections.prefix(5).compactMap { $0.sentiment }
        if recentSentiments.filter({ $0 == .negative }).count > 2 {
            return supportivePrompts.randomElement() ?? "How are you really doing?"
        }
        
        return genericPrompts.randomElement() ?? "What's on your mind?"
    }
    
    // MARK: - Prompt Collections
    
    private let genericPrompts = [
        "What's on your mind?",
        "How would you describe today?",
        "What stood out about today?",
        "Anything you want to remember about today?",
        "What's one thing that happened today?",
    ]
    
    private let activityPrompts = [
        "You walked a lot today. Where did you go?",
        "An active day! What got you moving?",
        "Lots of steps today. How did it feel?",
    ]
    
    private let sleepPrompts = [
        "You slept well last night. Notice any difference today?",
        "After that rest, how's your energy?",
        "Did the good sleep affect your day?",
    ]
    
    private let supportivePrompts = [
        "How are you really doing?",
        "It's been a week. How are you feeling?",
        "Anything you want to get off your chest?",
        "What would help right now?",
    ]
    
    private init() {}
}

// MARK: - Supporting Types

struct SentimentDistribution {
    let positive: Double  // 0-1
    let neutral: Double   // 0-1
    let negative: Double  // 0-1
    
    var dominantSentiment: Sentiment {
        if positive > neutral && positive > negative {
            return .positive
        } else if negative > neutral && negative > positive {
            return .negative
        } else {
            return .neutral
        }
    }
}
