//
//  GeocodingService.swift
//  TripMind
//
//  Created by EXC19 on 2026/1/18.
//

import Foundation
import MapKit

class GeocodingService {
    static let shared = GeocodingService()
    
    // Process a list of events sequentially to avoid rate limiting
    func geocodeEvents(_ events: [TravelEvent]) async -> [TravelEvent] {
        var updatedEvents = [TravelEvent]()
        
        for event in events {
            var newEvent = event
            
            // 1. Geocode Start Location
            if newEvent.geoCoordinates == nil {
                if let query = getStartLocationQuery(for: event) {
                    if let coords = await searchLocation(query) {
                        newEvent.geoCoordinates = GeoCoordinates(lat: coords.latitude, lng: coords.longitude)
                    }
                }
            }
            
            // 2. Geocode Destination
            if newEvent.destinationGeoCoordinates == nil {
                if let query = getEndLocationQuery(for: event) {
                    if let coords = await searchLocation(query) {
                        newEvent.destinationGeoCoordinates = GeoCoordinates(lat: coords.latitude, lng: coords.longitude)
                    }
                }
            }
            
            updatedEvents.append(newEvent)
        }
        return updatedEvents
    }
    
    // Helper: Determine what string to search for based on event type
    private func getStartLocationQuery(for event: TravelEvent) -> String? {
        switch event.data {
        case .flight(let f):
            return f.departureCity ?? "\(f.departureAirport) Airport"
        case .hotel(let h):
            return h.address.isEmpty ? h.hotelName : h.address
        case .car(let c):
            return c.origin
        case .train(let t):
            return "\(t.departureStation) Train Station"
        case .other(let o):
            return o.location
        }
    }
    
    private func getEndLocationQuery(for event: TravelEvent) -> String? {
        switch event.data {
        case .flight(let f):
            return f.arrivalCity ?? "\(f.arrivalAirport) Airport"
        case .train(let t):
            return "\(t.arrivalStation) Train Station"
        case .car(let c):
            return c.destination
        default:
            return nil
        }
    }
    
    // MapKit Search Logic
    private func searchLocation(_ query: String) async -> CLLocationCoordinate2D? {
        guard !query.isEmpty else { return nil }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = .pointOfInterest
        
        let search = MKLocalSearch(request: request)
        
        do {
            print("📍 MapKit Searching: \(query)...")
            let response = try await search.start()
            
            if let item = response.mapItems.first {
                // ✅ FIX: Removed '?' because 'location' is non-optional
                return item.location.coordinate
            }
            return nil
        } catch {
            print("⚠️ MapKit Search failed for '\(query)': \(error.localizedDescription)")
            return nil
        }
    }
}
