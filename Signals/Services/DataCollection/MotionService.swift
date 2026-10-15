//
//  MotionService.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import Foundation
import CoreMotion

/// Service for collecting motion and activity data
@MainActor
final class MotionService {
    static let shared = MotionService()
    
    private let pedometer = CMPedometer()
    private let activityManager = CMMotionActivityManager()
    
    // MARK: - Availability
    
    var isPedometerAvailable: Bool {
        CMPedometer.isStepCountingAvailable()
    }
    
    var isActivityAvailable: Bool {
        CMMotionActivityManager.isActivityAvailable()
    }
    
    var isAvailable: Bool {
        isPedometerAvailable || isActivityAvailable
    }
    
    // MARK: - Authorization
    
    var authorizationStatus: CMAuthorizationStatus {
        CMMotionActivityManager.authorizationStatus()
    }
    
    var hasAuthorization: Bool {
        authorizationStatus == .authorized
    }
    
    /// Request motion authorization by starting a query
    func requestAuthorization() async throws {
        guard isActivityAvailable else {
            throw MotionError.notAvailable
        }
        
        // CoreMotion doesn't have an explicit authorization request
        // Authorization is requested when you start querying
        let now = Date()
        let oneHourAgo = now.addingTimeInterval(-3600)
        
        return try await withCheckedThrowingContinuation { continuation in
            activityManager.queryActivityStarting(from: oneHourAgo, to: now, to: .main) { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    // MARK: - Data Collection
    
    /// Fetch pedometer data for a specific date
    func fetchPedometerData(for date: Date) async throws -> PedometerDataResult? {
        guard isPedometerAvailable else {
            return nil
        }
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = min(startOfDay.addingTimeInterval(86400), Date())
        
        return try await withCheckedThrowingContinuation { continuation in
            pedometer.queryPedometerData(from: startOfDay, to: endOfDay) { data, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let data = data else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let result = PedometerDataResult(
                    steps: data.numberOfSteps.intValue,
                    distance: data.distance?.doubleValue,
                    floorsAscended: data.floorsAscended?.intValue,
                    floorsDescended: data.floorsDescended?.intValue
                )
                
                continuation.resume(returning: result)
            }
        }
    }
    
    /// Fetch primary activity type for a specific date
    func fetchPrimaryActivity(for date: Date) async throws -> PrimaryActivity? {
        guard isActivityAvailable else {
            return nil
        }
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = min(startOfDay.addingTimeInterval(86400), Date())
        
        return try await withCheckedThrowingContinuation { continuation in
            activityManager.queryActivityStarting(from: startOfDay, to: endOfDay, to: .main) { activities, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let activities = activities, !activities.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }
                
                // Count duration of each activity type
                var activityDurations: [PrimaryActivity: TimeInterval] = [:]
                
                for i in 0..<activities.count {
                    let activity = activities[i]
                    let nextTime: Date
                    
                    if i + 1 < activities.count {
                        nextTime = activities[i + 1].startDate
                    } else {
                        nextTime = endOfDay
                    }
                    
                    let duration = nextTime.timeIntervalSince(activity.startDate)
                    let primaryActivity = self.mapActivity(activity)
                    activityDurations[primaryActivity, default: 0] += duration
                }
                
                // Find the most common activity (excluding stationary for a more interesting result)
                let nonStationaryActivities = activityDurations.filter { $0.key != .stationary }
                
                if let primaryActivity = nonStationaryActivities.max(by: { $0.value < $1.value })?.key {
                    continuation.resume(returning: primaryActivity)
                } else if let primaryActivity = activityDurations.max(by: { $0.value < $1.value })?.key {
                    continuation.resume(returning: primaryActivity)
                } else {
                    continuation.resume(returning: .stationary)
                }
            }
        }
    }
    
    /// Fetch active minutes (non-stationary time) for a specific date
    func fetchActiveMinutes(for date: Date) async throws -> Int? {
        guard isActivityAvailable else {
            return nil
        }
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = min(startOfDay.addingTimeInterval(86400), Date())
        
        return try await withCheckedThrowingContinuation { continuation in
            activityManager.queryActivityStarting(from: startOfDay, to: endOfDay, to: .main) { activities, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let activities = activities, !activities.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }
                
                var activeSeconds: TimeInterval = 0
                
                for i in 0..<activities.count {
                    let activity = activities[i]
                    
                    // Only count non-stationary activities
                    guard activity.walking || activity.running || activity.cycling || activity.automotive else {
                        continue
                    }
                    
                    let nextTime: Date
                    if i + 1 < activities.count {
                        nextTime = activities[i + 1].startDate
                    } else {
                        nextTime = endOfDay
                    }
                    
                    activeSeconds += nextTime.timeIntervalSince(activity.startDate)
                }
                
                continuation.resume(returning: Int(activeSeconds / 60))
            }
        }
    }
    
    /// Fetch all motion data for a specific date
    func fetchAllMotionData(for date: Date) async -> MotionDataResult {
        var result = MotionDataResult()
        
        do {
            result.pedometerData = try await fetchPedometerData(for: date)
        } catch {
            print("Failed to fetch pedometer data: \(error)")
        }
        
        do {
            result.primaryActivity = try await fetchPrimaryActivity(for: date)
        } catch {
            print("Failed to fetch primary activity: \(error)")
        }
        
        do {
            result.activeMinutes = try await fetchActiveMinutes(for: date)
        } catch {
            print("Failed to fetch active minutes: \(error)")
        }
        
        return result
    }
    
    // MARK: - Private
    
    private func mapActivity(_ activity: CMMotionActivity) -> PrimaryActivity {
        if activity.running {
            return .running
        } else if activity.cycling {
            return .cycling
        } else if activity.automotive {
            return .driving
        } else if activity.walking {
            return .walking
        } else {
            return .stationary
        }
    }
    
    private init() {}
}

// MARK: - Supporting Types

struct PedometerDataResult {
    var steps: Int
    var distance: Double?  // meters
    var floorsAscended: Int?
    var floorsDescended: Int?
}

struct MotionDataResult {
    var pedometerData: PedometerDataResult?
    var primaryActivity: PrimaryActivity?
    var activeMinutes: Int?
    
    var collectedSignals: [SignalType] {
        var signals: [SignalType] = []
        if pedometerData != nil { signals.append(.steps) }
        if primaryActivity != nil { signals.append(.motion) }
        return signals
    }
}

enum MotionError: Error, LocalizedError {
    case notAvailable
    case notAuthorized
    case queryFailed
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Motion data is not available on this device"
        case .notAuthorized:
            return "Motion data access not authorized"
        case .queryFailed:
            return "Failed to query motion data"
        }
    }
}
