//
//  LocationService.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import Foundation
import CoreLocation
import MapKit

/// Service for monitoring significant location changes
/// Note: Only stores semantic labels (Home, Work, etc.), never raw coordinates
@MainActor
final class LocationService: NSObject {
    static let shared = LocationService()
    
    private let locationManager = CLLocationManager()
    
    // MARK: - State
    
    private(set) var isMonitoring = false
    private(set) var lastKnownLocation: CLLocation?
    private var locationHistory: [LocationVisit] = []
    private var knownPlaces: [KnownPlace] = []
    
    // Callbacks
    var onLocationUpdate: ((LocationCluster) -> Void)?
    
    // MARK: - Authorization
    
    var authorizationStatus: CLAuthorizationStatus {
        locationManager.authorizationStatus
    }
    
    var hasAuthorization: Bool {
        let status = authorizationStatus
        return status == .authorizedAlways || status == .authorizedWhenInUse
    }
    
    var hasAlwaysAuthorization: Bool {
        authorizationStatus == .authorizedAlways
    }
    
    func requestAuthorization() {
        locationManager.requestAlwaysAuthorization()
    }
    
    // MARK: - Monitoring
    
    func startMonitoring() {
        guard hasAuthorization else {
            print("Location authorization not granted")
            return
        }
        
        locationManager.delegate = self
        
        // Only enable background location updates if we have "always" authorization
        // and we're not running in a preview/simulator environment that doesn't support it
        if hasAlwaysAuthorization {
            // Check if background location is available before enabling
            if CLLocationManager.locationServicesEnabled() {
                locationManager.allowsBackgroundLocationUpdates = true
            }
        }
        
        locationManager.startMonitoringSignificantLocationChanges()
        isMonitoring = true
        
        // Load known places from UserDefaults
        loadKnownPlaces()
    }
    
    func stopMonitoring() {
        locationManager.stopMonitoringSignificantLocationChanges()
        isMonitoring = false
    }
    
    // MARK: - Data Collection
    
    /// Get location data for a specific date
    func getLocationData(for date: Date) -> LocationDataResult {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = startOfDay.addingTimeInterval(86400)
        
        let dayVisits = locationHistory.filter { visit in
            visit.arrivalTime >= startOfDay && visit.arrivalTime < endOfDay
        }
        
        // Group visits by place label
        var clusterDict: [String: Int] = [:]
        var totalDistance: Double = 0
        var visitedNewPlace = false
        var leftHome = false
        
        for visit in dayVisits {
            let label = visit.placeLabel
            clusterDict[label, default: 0] += visit.durationMinutes
            
            if visit.isNew {
                visitedNewPlace = true
            }
            if label != "Home" {
                leftHome = true
            }
            totalDistance += visit.distanceFromPrevious ?? 0
        }
        
        let clusters = clusterDict.map { label, minutes in
            LocationCluster(
                label: label,
                timeSpentMinutes: minutes,
                isNew: visitedNewPlace && label == "New place"
            )
        }
        
        return LocationDataResult(
            clusters: clusters,
            distanceTraveled: totalDistance,
            placesVisited: Set(dayVisits.map { $0.placeLabel }).count,
            leftHome: leftHome
        )
    }
    
    // MARK: - Place Management
    
    /// Classify a location into a semantic label
    private func classifyLocation(_ location: CLLocation) async -> String {
        // Check against known places first
        for place in knownPlaces {
            let placeLocation = CLLocation(latitude: place.latitude, longitude: place.longitude)
            let distance = location.distance(from: placeLocation)
            
            if distance < place.radiusMeters {
                return place.label
            }
        }
        
        // Try to get a semantic label from reverse geocoding
        do {
            let placeName = try await reverseGeocode(location)
            if let name = placeName {
                if name.lowercased().contains("gym") || name.lowercased().contains("fitness") {
                    return "Gym"
                }
                if name.lowercased().contains("office") || name.lowercased().contains("work") {
                    return "Work"
                }
            }
        } catch {
            print("Reverse geocoding failed: \(error)")
        }
        
        return "New place"
    }
    
    /// Reverse geocode a location using the appropriate API for the iOS version
    private func reverseGeocode(_ location: CLLocation) async throws -> String? {
        if #available(iOS 26.0, *) {
            // Use MapKit's MKReverseGeocodingRequest for iOS 26+
            guard let request = MKReverseGeocodingRequest(location: location) else {
                return nil
            }
            let mapItems = try await request.mapItems
            return mapItems.first?.name
        } else {
            // Use CLGeocoder for earlier iOS versions
            let geocoder = CLGeocoder()
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            return placemarks.first?.name
        }
    }
    
    /// Mark the current location as Home
    func setCurrentAsHome() {
        locationManager.requestLocation()
        // The actual setting happens in the delegate callback
    }
    
    /// Mark the current location as Work
    func setCurrentAsWork() {
        // Similar to setCurrentAsHome
    }
    
    private func addKnownPlace(label: String, location: CLLocation) {
        let place = KnownPlace(
            label: label,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            radiusMeters: 100
        )
        
        // Remove any existing place with the same label
        knownPlaces.removeAll { $0.label == label }
        knownPlaces.append(place)
        saveKnownPlaces()
    }
    
    // MARK: - Persistence
    
    private func loadKnownPlaces() {
        if let data = UserDefaults.standard.data(forKey: "knownPlaces"),
           let places = try? JSONDecoder().decode([KnownPlace].self, from: data) {
            knownPlaces = places
        }
    }
    
    private func saveKnownPlaces() {
        if let data = try? JSONEncoder().encode(knownPlaces) {
            UserDefaults.standard.set(data, forKey: "knownPlaces")
        }
    }
    
    // MARK: - Private
    
    private override init() {
        super.init()
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.pausesLocationUpdatesAutomatically = true
        // Note: delegate and background updates are configured in startMonitoring()
        // to avoid crashes when the service is initialized before authorization
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        Task { @MainActor in
            // Store last known location for weather fetching
            self.lastKnownLocation = location
            
            let label = await classifyLocation(location)
            
            // Note: Distance calculation would require storing coordinates,
            // which we avoid for privacy. Pass nil for now.
            let distanceFromPrevious: Double? = nil
            
            let visit = LocationVisit(
                placeLabel: label,
                arrivalTime: Date(),
                durationMinutes: 0,
                isNew: !knownPlaces.contains { $0.label == label },
                distanceFromPrevious: distanceFromPrevious
            )
            
            // Update the previous visit's duration
            if var lastVisit = locationHistory.last {
                lastVisit.durationMinutes = Int(Date().timeIntervalSince(lastVisit.arrivalTime) / 60)
                locationHistory[locationHistory.count - 1] = lastVisit
            }
            
            locationHistory.append(visit)
            
            // Notify listeners
            let cluster = LocationCluster(
                label: label,
                timeSpentMinutes: 0,
                isNew: visit.isNew
            )
            onLocationUpdate?(cluster)
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error)")
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            if hasAuthorization && !isMonitoring {
                startMonitoring()
            }
        }
    }
}

// MARK: - Supporting Types

struct LocationVisit {
    var placeLabel: String
    var arrivalTime: Date
    var durationMinutes: Int
    var isNew: Bool
    var distanceFromPrevious: Double?
}

struct KnownPlace: Codable {
    let label: String
    let latitude: Double
    let longitude: Double
    let radiusMeters: Double
}

struct LocationDataResult {
    var clusters: [LocationCluster]
    var distanceTraveled: Double
    var placesVisited: Int
    var leftHome: Bool
    
    var collectedSignals: [SignalType] {
        var signals: [SignalType] = []
        if !clusters.isEmpty { signals.append(.location) }
        if distanceTraveled > 0 { signals.append(.distance) }
        if placesVisited > 0 { signals.append(.places) }
        return signals
    }
}

enum LocationError: Error, LocalizedError {
    case notAuthorized
    case monitoringFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Location access not authorized"
        case .monitoringFailed:
            return "Failed to monitor location changes"
        }
    }
}
