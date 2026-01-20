//
//  TripStore.swift
//  TripMind
//
//  Created by EXC19 on 2026/1/16.
//

import Foundation
import Combine // ADDED: Explicitly import Combine for ObservableObject conformance

class TripStore: ObservableObject {
    @Published var trips: [Trip] = [] {
        // Automatically save trips whenever the array changes
        didSet {
            saveTrips()
        }
    }
    
    // File URL for storing trips data locally
    private var tripsFileURL: URL {
        // Use the application's Documents directory for storing data
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("trips.json")
    }
    
    // JSON Encoder and Decoder for Codable objects
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601 // Ensure ISO 8601 for dates
        encoder.outputFormatting = .prettyPrinted // For readability of saved JSON (can be removed in prod)
        return encoder
    }()
    
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601 // Ensure ISO 8601 for dates
        return decoder
    }()
    
    init() {
        loadTrips() // Load trips when the store is initialized
    }
    
    // MARK: - Local Persistence Methods
    
    private func loadTrips() {
        guard FileManager.default.fileExists(atPath: tripsFileURL.path) else {
            print("No local trips file found.")
            return
        }
        
        do {
            let data = try Data(contentsOf: tripsFileURL)
            let decodedTrips = try decoder.decode([Trip].self, from: data)
            DispatchQueue.main.async {
                // Ensure events are sorted after loading
                self.trips = decodedTrips.map { trip in
                    var mutableTrip = trip
                    mutableTrip.events.sort { $0.startTime < $1.startTime }
                    return mutableTrip
                }
                print("Trips loaded successfully from local storage.")
            }
        } catch {
            print("Error loading trips from local storage: \(error.localizedDescription)")
            // Optionally, try to recover or start with an/ empty list
            self.trips = []
        }
    }
    
    private func saveTrips() {
        do {
            let data = try encoder.encode(self.trips)
            try data.write(to: tripsFileURL, options: [.atomicWrite])
            print("Trips saved successfully to local storage.")
        } catch {
            print("Error saving trips to local storage: \(error.localizedDescription)")
        }
    }
    
    // MARK: - CRUD Operations (now operate on local array and trigger save)
    
    func addTrip(_ trip: Trip) async throws {
        // For local storage, we can directly append and the didSet observer will save.
        // If 'id' is empty string, assign a new one, as it's required for Identifiable.
        var newTrip = trip
        if newTrip.id.isEmpty {
            newTrip.id = UUID().uuidString
        }
        newTrip.updateDatesFromEvents() // Auto-update dates
        self.trips.append(newTrip)
        // didSet will call saveTrips()
        print("Added trip: \(newTrip.name)")
    }
    
    func updateTrip(_ trip: Trip) async throws {
        // Find the index of the trip to update
        if let index = trips.firstIndex(where: { $0.id == trip.id }) {
            // Replace the existing trip with the updated one
            var updatedTrip = trip
            updatedTrip.updateDatesFromEvents() // Auto-update dates
            self.trips[index] = updatedTrip
            // didSet will call saveTrips()
            print("Updated trip: \(trip.name)")
        } else {
            throw TripStoreError.tripNotFound // Custom error
        }
    }
    
    func deleteTrip(id: String) async throws {
        self.trips.removeAll { $0.id == id }
        // didSet will call saveTrips()
        print("Deleted trip with ID: \(id)")
    }
    
    // MARK: - Error Handling
    enum TripStoreError: Error, LocalizedError {
        case tripNotFound
        case encodingError(Error) // Keeping this, though save/load handles it
        case decodingError(Error) // Keeping this, though save/load handles it
        
        var errorDescription: String? {
            switch self {
            case .tripNotFound: return "The specified trip was not found."
            case .encodingError(let error): return "Failed to encode data for local storage: \(error.localizedDescription)"
            case .decodingError(let error): return "Failed to decode data from local storage: \(error.localizedDescription)"
            }
        }
    }
}

