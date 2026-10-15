//
//  SignalType.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import Foundation

/// Represents the different types of signals that can be tracked
enum SignalType: String, Codable, CaseIterable, Identifiable {
    case steps
    case sleep
    case exercise
    case heartRate
    case hrv
    case screenTime
    case appPickups
    case location
    case distance
    case places
    case motion
    case mood
    case reflection
    case weather
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .steps: return "Steps"
        case .sleep: return "Sleep"
        case .exercise: return "Exercise"
        case .heartRate: return "Heart Rate"
        case .hrv: return "HRV"
        case .screenTime: return "Screen Time"
        case .appPickups: return "Phone Pickups"
        case .location: return "Location"
        case .distance: return "Distance"
        case .places: return "Places"
        case .motion: return "Motion"
        case .mood: return "Mood"
        case .reflection: return "Reflections"
        case .weather: return "Weather"
        }
    }
    
    var icon: String {
        switch self {
        case .steps: return "figure.walk"
        case .sleep: return "bed.double.fill"
        case .exercise: return "flame.fill"
        case .heartRate: return "heart.fill"
        case .hrv: return "waveform.path.ecg"
        case .screenTime: return "iphone"
        case .appPickups: return "hand.tap.fill"
        case .location: return "location.fill"
        case .distance: return "map.fill"
        case .places: return "mappin.and.ellipse"
        case .motion: return "figure.run"
        case .mood: return "face.smiling"
        case .reflection: return "pencil.and.outline"
        case .weather: return "cloud.sun.fill"
        }
    }
    
    var shortName: String {
        switch self {
        case .steps: return "Steps"
        case .sleep: return "Sleep"
        case .exercise: return "Exercise"
        case .heartRate: return "HR"
        case .hrv: return "HRV"
        case .screenTime: return "Screen"
        case .appPickups: return "Pickups"
        case .location: return "Location"
        case .distance: return "Distance"
        case .places: return "Places"
        case .motion: return "Motion"
        case .mood: return "Mood"
        case .reflection: return "Reflect"
        case .weather: return "Weather"
        }
    }
    
    var description: String {
        switch self {
        case .steps: return "Daily step count from your activity"
        case .sleep: return "Sleep duration and quality"
        case .exercise: return "Active exercise minutes"
        case .heartRate: return "Resting heart rate"
        case .hrv: return "Heart rate variability"
        case .screenTime: return "Time spent on your device"
        case .appPickups: return "How often you pick up your phone"
        case .location: return "Places you visit (never exact coordinates)"
        case .distance: return "Distance traveled each day"
        case .places: return "Number of unique places visited"
        case .motion: return "Your primary activity type"
        case .mood: return "Your mood check-ins"
        case .reflection: return "Your written reflections"
        case .weather: return "Daily weather conditions"
        }
    }
    
    /// Groups signals by their data source for permission requests
    var permissionGroup: PermissionGroup {
        switch self {
        case .steps, .sleep, .exercise, .heartRate, .hrv:
            return .health
        case .screenTime, .appPickups:
            return .screenTime
        case .location, .distance, .places:
            return .location
        case .motion:
            return .motion
        case .mood, .reflection:
            return .none
        case .weather:
            return .location // Weather uses general location
        }
    }
}

enum PermissionGroup: String, CaseIterable {
    case health
    case screenTime
    case location
    case motion
    case none
    
    var displayName: String {
        switch self {
        case .health: return "Health"
        case .screenTime: return "Screen Time"
        case .location: return "Location"
        case .motion: return "Motion"
        case .none: return "None Required"
        }
    }
}
