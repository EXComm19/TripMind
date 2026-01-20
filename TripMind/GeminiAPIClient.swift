//
//  GeminiAPIClient.swift
//  TripMind
//
//  Created by EXC19 on 2026/1/16.
//

import Foundation
import FirebaseAILogic // Import the FirebaseAILogic SDK
import UIKit // Still needed for UIImage conversion to Data

enum GeminiAPIError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case apiError(String)
    case invalidResponse
    case decodingError(Error)
    case invalidInput
    case firebaseError(Error)
    case debuggingModeActive // ADDED: New error case for debugging
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "An internal URL for Gemini API was invalid."
        case .networkError(let error): return "Network error: \(error.localizedDescription)"
        case .apiError(let message): return "Gemini API Error: \(message)"
        case .invalidResponse: return "Received an invalid response from the Gemini API."
        case .decodingError(let error): return "Failed to decode Gemini's response: \(error.localizedDescription)"
        case .invalidInput: return "Invalid input provided to Gemini API."
        case .firebaseError(let error): return "Firebase AI Logic Error: \(error.localizedDescription)"
        case .debuggingModeActive: return "Decoding paused for debugging. Check console for raw Gemini response."
        }
    }
}

class GeminiAPIClient {
    private let textModel: GenerativeModel
    private let visionModel: GenerativeModel
    
    private let firebaseAI: FirebaseAI

    init() {
        self.firebaseAI = FirebaseAI.firebaseAI(backend: .googleAI())
        
        // Using "flash" model for speed and efficiency
        self.textModel = firebaseAI.generativeModel(modelName: "gemini-2.5-flash")
        self.visionModel = firebaseAI.generativeModel(modelName: "gemini-2.5-flash")
    }
    
    private func generatePrompt(for content: String) -> String {
            return """
            You are an intelligent itinerary parsing assistant. Your task is to extract travel event information from the provided text or image content and return it as a JSON array of structured objects.
            
            The JSON output should strictly adhere to the following Swift Codable structs.
            
            --- Swift Data Model ---
            
            enum EventType: String, Codable, CaseIterable, Identifiable {
                case flight = "FLIGHT"
                case hotel = "HOTEL"
                case train = "TRAIN"
                case car = "CAR"
                case other = "OTHER"
                case transport = "TRANSPORT"
                case activity = "ACTIVITY"
                case dining = "DINING"
            }

            struct GeoCoordinates: Codable, Hashable {
                let lat: Double
                let lng: Double
            }

            struct BookingSource: Codable, Hashable {
                let name: String?
                let domain: String?
                let isOTA: Bool?
            }

            struct TravelFare: Codable, Hashable {
                let currency: String
                let amount: Double
            }
            
            // MARK: - Specific Data Schemas
            
            struct FlightData: Codable, Hashable {
                let airline: String
                let brandDomain: String?
                let airlineCode: String?
                let flightNumber: String
                let confirmationCode: String
                let passenger: String?
                let travelClass: String?
                let departureAirport: String
                let departureCountry: String?
                let departureCountryCode: String?
                let departureTerminal: String?
                let departureCity: String?
                let arrivalCity: String?
                let departureGate: String?
                let checkInCounter: String?
                let seat: String?
                let aircraft: String?
                let aircraftRegistration: String?
                let departureTime: Date // ISO with Offset
                let arrivalAirport: String
                let arrivalCountry: String?
                let arrivalCountryCode: String?
                let arrivalTerminal: String?
                let arrivalTime: Date // ISO with Offset
                let etkt: String?
                let fare: TravelFare?
                let bookingSource: BookingSource?
            }

            struct TrainData: Codable, Hashable {
                let serviceProvider: String? // Operator Name
                let brandDomain: String?     // Operator Domain
                let trainNumber: String?
                let passenger: String?
                let travelClass: String?
                let departureStation: String
                let departureCountry: String?
                let departureCountryCode: String?
                let departureTime: Date // ISO with Offset
                let departureGate: String?
                let seat: String?
                let arrivalStation: String
                let arrivalCountry: String?
                let arrivalCountryCode: String?
                let arrivalTime: Date // ISO with Offset
                let fare: TravelFare?
                let bookingSource: BookingSource?
            }

            struct CarData: Codable, Hashable {
                let serviceProvider: String?
                let brandDomain: String?
                let origin: String
                let departureCountry: String?
                let departureCountryCode: String?
                let destination: String?
                let arrivalCountry: String?
                let arrivalCountryCode: String?
                let pickupTime: Date // ISO with Offset
                let driver: String?
                let passenger: String?
                let carPlate: String?
                let carColor: String?
                let carBrand: String?
                let serviceType: String?
                let fare: TravelFare?
                let bookingSource: BookingSource?
            }

            struct HotelData: Codable, Hashable {
                let hotelName: String
                let brandDomain: String?
                let address: String
                let checkInTime: Date? // ISO with Offset
                let checkOutTime: Date? // ISO with Offset
                let bookingNumber: String?
                let confirmationNumber: String?
                let guestName: String?
                let roomType: String?
                let numberOfNights: String
                let fare: TravelFare?
                let isBreakfastIncluded: Bool?
                let extraIncluded: String?
                let bookingSource: BookingSource?
            }

            struct OtherData: Codable, Hashable {
                let title: String
                let description: String?
                let location: String?
                let time: String? 
                let fare: TravelFare?
                let bookingSource: BookingSource?
            }

            enum ItineraryEventDataType: Codable, Hashable {
                case flight(FlightData)
                case train(TrainData)
                case car(CarData)
                case hotel(HotelData)
                case other(OtherData)
            }

            struct TravelEvent: Codable, Identifiable, Hashable {
                let id: String
                let type: EventType
                let startTime: Date
                let endTime: Date?
                let geoCoordinates: GeoCoordinates?
                let destinationGeoCoordinates: GeoCoordinates? 
                let detectedLanguage: String?
                // bookingSource is inside the specific data structs now
                let data: ItineraryEventDataType
            }
            
            --- Important Notes ---
            1. **CRITICAL - DATES & TIMEZONES:**
               - Do NOT default to "Z" (UTC) unless the time is explicitly stated as UTC.
               - Infer the correct **Timezone Offset** based on the location (e.g., Tokyo is +09:00, New York is -05:00).
               - Return dates in ISO 8601 format with the correct offset.
               - Example (Tokyo 2:30 PM): "2026-01-20T14:30:00+09:00" (CORRECT) vs "2026-01-20T14:30:00Z" (WRONG).
            2. Set `id` as a new UUID string.
            3. Infer `type` from the event data.
            4. For Trains, separate `serviceProvider` (operator) from `bookingSource` (agency).
            5. Return JSON array only.
            
            Please parse the following content into a JSON array of `TravelEvent` objects:
            
            Content:
            \(content)
            """
        }
    
        private func extractEventsFromResponse(response: GenerateContentResponse) throws -> [TravelEvent] {
            guard let textPart = response.text else {
                print("DEBUG: Gemini response.text is nil.")
                throw GeminiAPIError.invalidResponse
            }
            
            print("🔍 RAW GEMINI RESPONSE: \(textPart)")

            // 1. SAFE CLEANUP
            var jsonString = textPart
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            if let firstBracket = jsonString.firstIndex(of: "["),
               let lastBracket = jsonString.lastIndex(of: "]"),
               firstBracket < lastBracket {
                jsonString = String(jsonString[firstBracket...lastBracket])
            }
            
            guard let jsonData = jsonString.data(using: .utf8) else {
                throw GeminiAPIError.decodingError(NSError(domain: "DataError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert cleaned JSON string to Data"]))
            }
            
            // 2. ROBUST DATE DECODING
            let decoder = JSONDecoder()
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .iso8601)
            formatter.locale = Locale(identifier: "en_US_POSIX")
            // Note: We do NOT set timeZone here. We let the offset in the string dictate the time.
            
            decoder.dateDecodingStrategy = .custom { decoder -> Date in
                let container = try decoder.singleValueContainer()
                let dateStr = try container.decode(String.self)
                
                // Format 1: ISO with Timezone Offset (e.g. 2026-01-20T14:30:00+09:00) - PREFERRED
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
                if let date = formatter.date(from: dateStr) { return date }
                
                // Format 2: ISO with 'Z' (e.g. 2026-01-20T14:30:00Z)
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                if let date = formatter.date(from: dateStr) { return date }
                
                // Format 3: ISO with milliseconds
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                if let date = formatter.date(from: dateStr) { return date }
                
                // Format 4: ISO Local Time (No Offset) -> Treat as UTC to avoid crash, but warn
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                if let date = formatter.date(from: dateStr) { return date }
                
                // Format 5: Simple Date
                formatter.dateFormat = "yyyy-MM-dd"
                if let date = formatter.date(from: dateStr) { return date }
                
                print("⚠️ Date parsing failed for: \(dateStr)")
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format: \(dateStr)")
            }

            do {
                return try decoder.decode([TravelEvent].self, from: jsonData)
            } catch {
                print("❌ Generic Decoding Error: \(error)")
                throw GeminiAPIError.decodingError(error)
            }
        }
    
    // MARK: - Public Parsing Methods
    
    func parseText(_ text: String) async throws -> [TravelEvent] {
        let promptText = generatePrompt(for: text)
        do {
            let response = try await textModel.generateContent(promptText)
            return try extractEventsFromResponse(response: response)
        } catch let error {
            if let nsError = error as? NSError, nsError.domain == "com.firebase.generativeai" {
                throw GeminiAPIError.firebaseError(nsError)
            }
            throw GeminiAPIError.networkError(error)
        }
    }
    
    func parseImage(_ image: UIImage) async throws -> [TravelEvent] {
        let basePrompt = generatePrompt(for: "")
        let fullPrompt = "This is an image of a travel itinerary. \(basePrompt)"
        do {
            let response = try await visionModel.generateContent(image, fullPrompt)
            return try extractEventsFromResponse(response: response)
        } catch let error {
            throw GeminiAPIError.networkError(error)
        }
    }

    func parsePDF(_ pdfData: Data) async throws -> [TravelEvent] {
        let basePrompt = generatePrompt(for: "")
        let fullPrompt = "This is a PDF document of a travel itinerary. \(basePrompt)"
        do {
            let pdfPart = InlineDataPart(data: pdfData, mimeType: "application/pdf")
            let response = try await visionModel.generateContent(pdfPart, fullPrompt)
            return try extractEventsFromResponse(response: response)
        } catch let error {
            throw GeminiAPIError.networkError(error)
        }
    }
}
