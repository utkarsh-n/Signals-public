//
//  HealthKitService.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import Foundation
import HealthKit

/// Service for collecting health data from HealthKit
@MainActor
final class HealthKitService {
    static let shared = HealthKitService()
    
    private let healthStore = HKHealthStore()
    
    // MARK: - Health Data Types
    
    /// All health data types we want to read
    private var readTypes: Set<HKObjectType> {
        var types = Set<HKObjectType>()
        
        // Activity
        if let stepCount = HKObjectType.quantityType(forIdentifier: .stepCount) {
            types.insert(stepCount)
        }
        if let activeEnergy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
            types.insert(activeEnergy)
        }
        if let exerciseTime = HKObjectType.quantityType(forIdentifier: .appleExerciseTime) {
            types.insert(exerciseTime)
        }
        
        // Heart
        if let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate) {
            types.insert(heartRate)
        }
        if let restingHeartRate = HKObjectType.quantityType(forIdentifier: .restingHeartRate) {
            types.insert(restingHeartRate)
        }
        if let hrv = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) {
            types.insert(hrv)
        }
        
        // Sleep
        if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleep)
        }
        
        return types
    }
    
    // MARK: - Authorization
    
    /// Check if HealthKit is available on this device
    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }
    
    /// Request authorization to read health data
    func requestAuthorization() async throws {
        guard isAvailable else {
            throw HealthKitError.notAvailable
        }
        
        try await healthStore.requestAuthorization(toShare: [], read: readTypes)
    }
    
    /// Check authorization status for a specific type
    func authorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus {
        healthStore.authorizationStatus(for: type)
    }
    
    /// Check if we have authorization to read health data
    var hasAuthorization: Bool {
        // HealthKit doesn't tell us definitively if read access was granted
        // We can only check if we've requested it
        readTypes.allSatisfy { type in
            authorizationStatus(for: type) != .notDetermined
        }
    }
    
    // MARK: - Data Collection
    
    /// Fetch step count for a specific date
    func fetchStepCount(for date: Date) async throws -> Int? {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return nil
        }
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = startOfDay.addingTimeInterval(86400)
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let steps = result?.sumQuantity()?.doubleValue(for: .count())
                continuation.resume(returning: steps.map { Int($0) })
            }
            
            healthStore.execute(query)
        }
    }
    
    /// Fetch sleep hours for the night before a specific date
    func fetchSleepData(for date: Date) async throws -> (hours: Double, quality: SleepQuality)? {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            return nil
        }
        
        // Look at sleep from the previous evening to this morning
        let endOfDay = Calendar.current.startOfDay(for: date).addingTimeInterval(43200) // noon
        let startOfSleepWindow = endOfDay.addingTimeInterval(-43200 - 28800) // 20 hours before noon
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfSleepWindow,
            end: endOfDay,
            options: .strictStartDate
        )
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let sleepSamples = samples as? [HKCategorySample], !sleepSamples.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }
                
                // Calculate total sleep time (only asleep states)
                var totalSleepSeconds: TimeInterval = 0
                var deepSleepSeconds: TimeInterval = 0
                
                for sample in sleepSamples {
                    let value = HKCategoryValueSleepAnalysis(rawValue: sample.value)
                    let duration = sample.endDate.timeIntervalSince(sample.startDate)
                    
                    switch value {
                    case .asleepCore, .asleepDeep, .asleepREM, .asleepUnspecified:
                        totalSleepSeconds += duration
                        if value == .asleepDeep {
                            deepSleepSeconds += duration
                        }
                    default:
                        break
                    }
                }
                
                guard totalSleepSeconds > 0 else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let hours = totalSleepSeconds / 3600.0
                let deepSleepRatio = deepSleepSeconds / totalSleepSeconds
                
                // Determine sleep quality based on duration and deep sleep ratio
                let quality: SleepQuality
                if hours >= 7 && deepSleepRatio >= 0.15 {
                    quality = .excellent
                } else if hours >= 6 && deepSleepRatio >= 0.10 {
                    quality = .good
                } else if hours >= 5 {
                    quality = .fair
                } else {
                    quality = .poor
                }
                
                continuation.resume(returning: (hours, quality))
            }
            
            healthStore.execute(query)
        }
    }
    
    /// Fetch exercise minutes for a specific date
    func fetchExerciseMinutes(for date: Date) async throws -> Int? {
        guard let exerciseType = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime) else {
            return nil
        }
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = startOfDay.addingTimeInterval(86400)
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: exerciseType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let minutes = result?.sumQuantity()?.doubleValue(for: .minute())
                continuation.resume(returning: minutes.map { Int($0) })
            }
            
            healthStore.execute(query)
        }
    }
    
    /// Fetch resting heart rate for a specific date
    func fetchRestingHeartRate(for date: Date) async throws -> Double? {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else {
            return nil
        }
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = startOfDay.addingTimeInterval(86400)
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: heartRateType,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let bpm = result?.averageQuantity()?.doubleValue(for: HKUnit(from: "count/min"))
                continuation.resume(returning: bpm)
            }
            
            healthStore.execute(query)
        }
    }
    
    /// Fetch HRV average for a specific date
    func fetchHRV(for date: Date) async throws -> Double? {
        guard let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            return nil
        }
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = startOfDay.addingTimeInterval(86400)
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: hrvType,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let hrv = result?.averageQuantity()?.doubleValue(for: .secondUnit(with: .milli))
                continuation.resume(returning: hrv)
            }
            
            healthStore.execute(query)
        }
    }
    
    /// Fetch all health data for a specific date
    func fetchAllHealthData(for date: Date) async -> HealthDataResult {
        var result = HealthDataResult()
        
        do {
            result.stepCount = try await fetchStepCount(for: date)
        } catch {
            print("Failed to fetch step count: \(error)")
        }
        
        do {
            if let sleepData = try await fetchSleepData(for: date) {
                result.sleepHours = sleepData.hours
                result.sleepQuality = sleepData.quality
            }
        } catch {
            print("Failed to fetch sleep data: \(error)")
        }
        
        do {
            result.exerciseMinutes = try await fetchExerciseMinutes(for: date)
        } catch {
            print("Failed to fetch exercise minutes: \(error)")
        }
        
        do {
            result.restingHeartRate = try await fetchRestingHeartRate(for: date)
        } catch {
            print("Failed to fetch resting heart rate: \(error)")
        }
        
        do {
            result.hrvAverage = try await fetchHRV(for: date)
        } catch {
            print("Failed to fetch HRV: \(error)")
        }
        
        return result
    }
    
    // MARK: - Private
    
    private init() {}
}

// MARK: - Supporting Types

struct HealthDataResult {
    var stepCount: Int?
    var sleepHours: Double?
    var sleepQuality: SleepQuality?
    var exerciseMinutes: Int?
    var restingHeartRate: Double?
    var hrvAverage: Double?
    
    var collectedSignals: [SignalType] {
        var signals: [SignalType] = []
        if stepCount != nil { signals.append(.steps) }
        if sleepHours != nil { signals.append(.sleep) }
        if exerciseMinutes != nil { signals.append(.exercise) }
        if restingHeartRate != nil { signals.append(.heartRate) }
        if hrvAverage != nil { signals.append(.hrv) }
        return signals
    }
}

enum HealthKitError: Error, LocalizedError {
    case notAvailable
    case notAuthorized
    case queryFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device"
        case .notAuthorized:
            return "Health data access not authorized"
        case .queryFailed(let message):
            return "Health query failed: \(message)"
        }
    }
}
