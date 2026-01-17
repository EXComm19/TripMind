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
        case .debuggingModeActive: return "Decoding paused for debugging. Check console for raw Gemini response." // ADDED
        }
    }
}

class GeminiAPIClient {
    private let textModel: GenerativeModel
    private let visionModel: GenerativeModel // Use gemini-pro-vision for image/PDF inputs
    
    private let firebaseAI: FirebaseAI // Keep the FirebaseAI instance

    init() {
        self.firebaseAI = FirebaseAI.firebaseAI(backend: .googleAI())
        
        // Ensure consistent model names if both are intended to be multi-modal capable "flash" models
        self.textModel = firebaseAI.generativeModel(modelName: "gemini-2.5-flash") // Reverted to 1.5-flash for broader access
        self.visionModel = firebaseAI.generativeModel(modelName: "gemini-2.5-flash") // Using same model for multimodal
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
            let name: String
            let domain: String?
            let isOTA: Bool?
        }

        struct TravelFare: Codable, Hashable {
            let currency: String
            let amount: Double
        }
        
        struct FlightData: Codable, Hashable {
            let airline: String
            let brandDomain: String?
            let airlineCode: String?
            let flightNumber: String
            let confirmationCode: String
            let passenger: String?
            let travelClass: String?
            let departureAirport: String // IATA e.g. "KIX"
            let departureCountry: String?
            let departureCountryCode: String?
            let departureTerminal: String?
            let departureCity: String? // e.g. "Osaka"
            let arrivalCity: String?   // e.g. "Guangzhou"
            let departureGate: String?
            let checkInDesk: String?
            let seat: String?
            let aircraft: String?
            let aircraftRegistration: String?
            let departureTime: Date // ISO 8601 format string
            let arrivalAirport: String // IATA e.g. "CAN"
            let arrivalCountry: String?
            let arrivalCountryCode: String?
            let arrivalTerminal: String?
            let arrivalTime: Date // ISO 8601 format string
            let etkt: String?
            let fare: TravelFare?
        }

        struct TrainData: Codable, Hashable {
            let serviceProvider: String?
            let trainNumber: String?
            let passenger: String?
            let travelClass: String?
            let departureStation: String
            let departureCountry: String?
            let departureCountryCode: String?
            let departureTime: Date // ISO
            let departureGate: String?
            let seat: String?
            let arrivalStation: String
            let arrivalCountry: String?
            let arrivalCountryCode: String?
            let arrivalTime: Date // ISO
            let fare: TravelFare?
        }

        struct CarData: Codable, Hashable {
            let origin: String
            let departureCountry: String?
            let departureCountryCode: String?
            let destination: String?
            let arrivalCountry: String?
            let arrivalCountryCode: String?
            let pickupTime: Date // ISO
            let driver: String?
            let passenger: String?
            let carPlate: String?
            let carColor: String?
            let carBrand: String?
            let fare: TravelFare?
        }

        struct HotelData: Codable, Hashable {
            let hotelName: String
            let brandDomain: String?
            let address: String
            let checkInTime: Date? // ISO
            let checkOutTime: Date? // ISO
            let bookingNumber: String?
            let confirmationNumber: String?
            let guestName: String?
            let roomType: String?
            let numberOfNights: String // Store as string to allow "3 nights" or just "3"
            let fare: TravelFare?
            let isBreakfastIncluded: Bool?
            let extraIncluded: String?
        }

        struct OtherData: Codable, Hashable {
            let title: String
            let description: String?
            let location: String?
            let time: String? // Keeping as String as it's not strictly ISO and can be flexible
            let fare: TravelFare?
            // extraFields: [String: AnyCodable]? - Note: Gemini might not perfectly map arbitrary 'any' fields.
            // Focus on core fields first, or simplify OtherData for Gemini.
        }

        enum ItineraryEventDataType: Codable, Hashable {
            case flight(FlightData)
            case train(TrainData)
            case car(CarData)
            case hotel(HotelData)
            case other(OtherData)
        }

        struct TravelEvent: Codable, Identifiable, Hashable {
            let id: String // UUID().uuidString
            let type: EventType
            let startTime: Date // ISO
            let endTime: Date? // ISO
            let geoCoordinates: GeoCoordinates?
            let destinationGeoCoordinates: GeoCoordinates? 
            let detectedLanguage: String?
            let bookingSource: BookingSource?
            let data: ItineraryEventDataType
            // translations and attachments will not be generated by Gemini here.
            let attachments: [Attachment]?
            let weather: WeatherInfo?
        }
        
        --- Important Notes ---
        1. All dates should be in ISO 8601 format (e.g., "YYYY-MM-DDTHH:mm:ssZ").
        2. Set `id` as a new UUID string (e.g., UUID().uuidString).
        3. Infer `type` from the event data.
        4. Populate `startTime` and `endTime` from the specific event data (e.g., flight.departureTime, flight.arrivalTime).
        5. Omit fields not found in the source content. Provide `nil` for optional fields if data is not available.
        6. Return an empty array `[]` if no travel events are detected.
        7. Only return the JSON array. Do not include any other text or formatting outside the JSON.
        8. The `data` field in `TravelEvent` should wrap the specific data (e.g., `{"flight": {...}}`).
        9. Do not use Markdown formatting (like ```json). Just return the raw JSON array string starting with [ and ending with ].
        
        Please parse the following content into a JSON array of `TravelEvent` objects:
        
        Content:
        \(content)
        """
    }
    
    // MODIFIED: Decoding is paused for debugging
    // ✅ CRASH-PROOF EXTRACTOR
        private func extractEventsFromResponse(response: GenerateContentResponse) throws -> [TravelEvent] {
            guard let textPart = response.text else {
                print("DEBUG: Gemini response.text is nil.")
                throw GeminiAPIError.invalidResponse
            }
            
            print("🔍 RAW GEMINI RESPONSE: \(textPart)")

            // 1. SAFE CLEANUP (No Dangerous Slicing)
            // We clean the string by replacing known Markdown patterns.
            // This avoids the "String index is out of bounds" crash entirely.
            var jsonString = textPart
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 2. Locate the Array Brackets Safely
            // Only slice if we find a valid opening '[' and closing ']'
            if let firstBracket = jsonString.firstIndex(of: "["),
               let lastBracket = jsonString.lastIndex(of: "]"),
               firstBracket < lastBracket {
                // Safe Swift slicing
                jsonString = String(jsonString[firstBracket...lastBracket])
            }
            
            print("✅ CLEANED JSON: \(jsonString)")
            
            guard let jsonData = jsonString.data(using: .utf8) else {
                throw GeminiAPIError.decodingError(NSError(domain: "DataError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert cleaned JSON string to Data"]))
            }
            
            // 3. ROBUST DECODER
            let decoder = JSONDecoder()
            
            // Custom Date Strategy to handle "2024-07-17T10:15:00+08:00" AND "2024-07-17"
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .iso8601)
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            
            decoder.dateDecodingStrategy = .custom { decoder -> Date in
                let container = try decoder.singleValueContainer()
                let dateStr = try container.decode(String.self)
                
                // Format 1: Full ISO with Timezone (e.g. from your logs)
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                if let date = formatter.date(from: dateStr) { return date }
                
                // Format 2: ISO with milliseconds
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                if let date = formatter.date(from: dateStr) { return date }
                
                // Format 3: Simple Date (Fallback)
                formatter.dateFormat = "yyyy-MM-dd"
                if let date = formatter.date(from: dateStr) { return date }
                
                print("⚠️ Date decoding failed for: \(dateStr)")
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format")
            }

            // 4. Decode & Return
            do {
                return try decoder.decode([TravelEvent].self, from: jsonData)
            } catch let DecodingError.dataCorrupted(context) {
                print("❌ Decoding Error (Data Corrupted): \(context.debugDescription)")
                throw GeminiAPIError.decodingError(DecodingError.dataCorrupted(context))
            } catch let DecodingError.keyNotFound(key, context) {
                print("❌ Decoding Error (Missing Key): '\(key.stringValue)'")
                throw GeminiAPIError.decodingError(DecodingError.keyNotFound(key, context))
            } catch let DecodingError.typeMismatch(type, context) {
                print("❌ Decoding Error (Type Mismatch): Expected \(type) but found something else at \(context.codingPath)")
                throw GeminiAPIError.decodingError(DecodingError.typeMismatch(type, context))
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
        } catch let error { // Capture generic error here
            print("DEBUG: Error in parseText: \(error)")
            if let nsError = error as? NSError {
                print("DEBUG: NSError domain: \(nsError.domain), code: \(nsError.code), userInfo: \(nsError.userInfo)")
                if nsError.domain == "com.firebase.generativeai" {
                    throw GeminiAPIError.firebaseError(nsError)
                }
            }
            throw GeminiAPIError.networkError(error)
        }
    }
    
    func parseImage(_ image: UIImage) async throws -> [TravelEvent] {
        // Simplified prompt for multimodal input, just using the core instruction part
        let basePrompt = generatePrompt(for: "")
        let fullPrompt = "This is an image of a travel itinerary. \(basePrompt)"
        
        do {
            let response = try await visionModel.generateContent(image, fullPrompt)
            return try extractEventsFromResponse(response: response)
        } catch let error { // Capture generic error here
            print("DEBUG: Error in parseImage: \(error)")
            if let nsError = error as? NSError {
                print("DEBUG: NSError domain: \(nsError.domain), code: \(nsError.code), userInfo: \(nsError.userInfo)")
                if nsError.domain == "com.firebase.generativeai" {
                    throw GeminiAPIError.firebaseError(nsError)
                }
            }
            throw GeminiAPIError.networkError(error)
        }
    }

    func parsePDF(_ pdfData: Data) async throws -> [TravelEvent] {
        // Simplified prompt for multimodal input, just using the core instruction part
        let basePrompt = generatePrompt(for: "")
        let fullPrompt = "This is a PDF document of a travel itinerary. \(basePrompt)"
        
        do {
            let pdfPart = InlineDataPart(data: pdfData, mimeType: "application/pdf")
            let response = try await visionModel.generateContent(pdfPart, fullPrompt)
            return try extractEventsFromResponse(response: response)
        } catch let error { // Capture generic error here
            print("DEBUG: Error in parsePDF: \(error)")
            let nsError = error as NSError
                print("DEBUG: NSError domain: \(nsError.domain), code: \(nsError.code), userInfo: \(nsError.userInfo)")
                if nsError.domain == "com.firebase.generativeai" {
                    throw GeminiAPIError.firebaseError(nsError)
                
            }
            throw GeminiAPIError.networkError(error)
        }
    }
}
