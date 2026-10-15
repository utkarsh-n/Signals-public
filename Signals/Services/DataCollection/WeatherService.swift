//
//  WeatherService.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import Foundation
import WeatherKit
import CoreLocation

/// Service for fetching daily weather data
@MainActor
final class WeatherService {
    static let shared = WeatherService()
    
    private let weatherService = WeatherKit.WeatherService.shared
    
    // Cache weather data to avoid excessive API calls
    private var weatherCache: [String: CachedWeather] = [:]
    
    // MARK: - Data Collection
    
    /// Fetch weather for a location on a specific date
    func fetchWeather(for location: CLLocation, date: Date) async throws -> WeatherDataResult? {
        let cacheKey = makeCacheKey(location: location, date: date)
        
        // Check cache first
        if let cached = weatherCache[cacheKey], !cached.isExpired {
            return cached.data
        }
        
        // Determine if we need current weather or historical
        let isToday = Calendar.current.isDateInToday(date)
        let isPast = date < Date()
        
        if isToday {
            return try await fetchCurrentWeather(for: location)
        } else if isPast {
            // WeatherKit can fetch historical data for recent dates
            return try await fetchHistoricalWeather(for: location, date: date)
        } else {
            // Future dates - use forecast
            return try await fetchForecastWeather(for: location, date: date)
        }
    }
    
    /// Fetch current weather
    private func fetchCurrentWeather(for location: CLLocation) async throws -> WeatherDataResult {
        let weather = try await weatherService.weather(for: location)
        
        let condition = mapCondition(weather.currentWeather.condition)
        let result = WeatherDataResult(
            condition: condition,
            temperatureHigh: weather.dailyForecast.first?.highTemperature.value,
            temperatureLow: weather.dailyForecast.first?.lowTemperature.value,
            humidity: weather.currentWeather.humidity,
            uvIndex: weather.currentWeather.uvIndex.value
        )
        
        // Cache the result
        let cacheKey = makeCacheKey(location: location, date: Date())
        weatherCache[cacheKey] = CachedWeather(data: result, fetchedAt: Date())
        
        return result
    }
    
    /// Fetch historical weather
    private func fetchHistoricalWeather(for location: CLLocation, date: Date) async throws -> WeatherDataResult {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = startOfDay.addingTimeInterval(86400)
        
        let weather = try await weatherService.weather(
            for: location,
            including: .daily(startDate: startOfDay, endDate: endOfDay)
        )
        
        guard let dayWeather = weather.first else {
            throw WeatherError.dataNotAvailable
        }
        
        let condition = mapCondition(dayWeather.condition)
        let result = WeatherDataResult(
            condition: condition,
            temperatureHigh: dayWeather.highTemperature.value,
            temperatureLow: dayWeather.lowTemperature.value,
            humidity: nil,
            uvIndex: dayWeather.uvIndex.value
        )
        
        // Cache the result
        let cacheKey = makeCacheKey(location: location, date: date)
        weatherCache[cacheKey] = CachedWeather(data: result, fetchedAt: Date())
        
        return result
    }
    
    /// Fetch forecast weather
    private func fetchForecastWeather(for location: CLLocation, date: Date) async throws -> WeatherDataResult {
        let weather = try await weatherService.weather(for: location)
        
        // Find the forecast for the requested date
        let targetDay = Calendar.current.startOfDay(for: date)
        
        guard let dayForecast = weather.dailyForecast.first(where: {
            Calendar.current.isDate($0.date, inSameDayAs: targetDay)
        }) else {
            throw WeatherError.dataNotAvailable
        }
        
        let condition = mapCondition(dayForecast.condition)
        return WeatherDataResult(
            condition: condition,
            temperatureHigh: dayForecast.highTemperature.value,
            temperatureLow: dayForecast.lowTemperature.value,
            humidity: nil,
            uvIndex: dayForecast.uvIndex.value
        )
    }
    
    /// Fetch weather using a city-level location (for privacy)
    func fetchWeatherForGeneralLocation(latitude: Double, longitude: Double, date: Date) async throws -> WeatherDataResult? {
        // Round coordinates to reduce precision (city-level)
        let roundedLat = (latitude * 10).rounded() / 10
        let roundedLon = (longitude * 10).rounded() / 10
        
        let location = CLLocation(latitude: roundedLat, longitude: roundedLon)
        return try await fetchWeather(for: location, date: date)
    }
    
    // MARK: - Condition Mapping
    
    private func mapCondition(_ condition: WeatherKit.WeatherCondition) -> WeatherCondition {
        switch condition {
        case .clear, .mostlyClear, .hot:
            return .clear
        case .cloudy, .mostlyCloudy, .partlyCloudy, .foggy, .haze, .smoky:
            return .cloudy
        case .rain, .heavyRain, .drizzle, .freezingRain, .freezingDrizzle, .sunShowers:
            return .rainy
        case .snow, .heavySnow, .flurries, .sunFlurries, .sleet, .blizzard, .blowingSnow, .wintryMix:
            return .snowy
        case .thunderstorms, .isolatedThunderstorms, .scatteredThunderstorms, .strongStorms, .tropicalStorm, .hurricane:
            return .stormy
        default:
            return .cloudy
        }
    }
    
    // MARK: - Cache Management
    
    private func makeCacheKey(location: CLLocation, date: Date) -> String {
        let dateString = ISO8601DateFormatter().string(from: Calendar.current.startOfDay(for: date))
        let latRounded = (location.coordinate.latitude * 10).rounded() / 10
        let lonRounded = (location.coordinate.longitude * 10).rounded() / 10
        return "\(latRounded),\(lonRounded)_\(dateString)"
    }
    
    func clearCache() {
        weatherCache.removeAll()
    }
    
    // MARK: - Private
    
    private init() {}
}

// MARK: - Supporting Types

struct WeatherDataResult {
    var condition: WeatherCondition
    var temperatureHigh: Double?  // Celsius
    var temperatureLow: Double?   // Celsius
    var humidity: Double?         // 0-1
    var uvIndex: Int?
    
    var collectedSignals: [SignalType] {
        [.weather]
    }
    
    var temperatureRange: String? {
        guard let high = temperatureHigh, let low = temperatureLow else {
            return nil
        }
        let highF = celsiusToFahrenheit(high)
        let lowF = celsiusToFahrenheit(low)
        return "\(Int(lowF))° - \(Int(highF))°F"
    }
    
    private func celsiusToFahrenheit(_ celsius: Double) -> Double {
        celsius * 9/5 + 32
    }
}

struct CachedWeather {
    let data: WeatherDataResult
    let fetchedAt: Date
    
    var isExpired: Bool {
        // Cache expires after 1 hour
        Date().timeIntervalSince(fetchedAt) > 3600
    }
}

enum WeatherError: Error, LocalizedError {
    case locationRequired
    case dataNotAvailable
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .locationRequired:
            return "Location is required to fetch weather"
        case .dataNotAvailable:
            return "Weather data not available for this date"
        case .apiError(let message):
            return "Weather API error: \(message)"
        }
    }
}
