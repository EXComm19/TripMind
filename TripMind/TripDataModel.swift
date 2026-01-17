//
//  TripDataModel.swift
//  TripMind
//
//  Created by EXC19 on 2026/1/16.
//

import Foundation

// MARK: - Enums
enum EventType: String, Codable, CaseIterable, Identifiable {
    case flight = "FLIGHT"
    case hotel = "HOTEL"
    case train = "TRAIN"
    case car = "CAR"
    case other = "OTHER"
    case transport = "TRANSPORT"
    case activity = "ACTIVITY"
    case dining = "DINING"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .flight: return "Flight"
        case .hotel: return "Hotel"
        case .train: return "Train"
        case .car: return "Car Rental"
        case .other: return "Other"
        case .transport: return "Transport"
        case .activity: return "Activity"
        case .dining: return "Dining"
        }
    }
    
    var symbolName: String {
        switch self {
        case .flight: return "airplane"
        case .hotel: return "bed.double"
        case .train: return "train.side.front.car"
        case .car: return "car"
        case .other: return "questionmark.circle"
        case .transport: return "figure.walk"
        case .activity: return "figure.run.circle"
        case .dining: return "fork.knife"
        }
    }
}

// MARK: - Basic Structures
struct GeoCoordinates: Codable, Hashable {
    var lat: Double
    var lng: Double
}

struct BookingSource: Codable, Hashable {
    var name: String
    var domain: String?
    var isOTA: Bool?
}

struct TravelFare: Codable, Hashable {
    var currency: String
    var amount: Double
}

struct Attachment: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var type: String
    var data: String
    var size: Int
}

struct WeatherInfo: Codable, Hashable {
    var code: Int
    var tempMax: Double?
    var tempMin: Double?
    var precipitationProbability: Double?
}

// ✅ NEW: Baggage Data Models
enum BaggageType: String, Codable, CaseIterable, Identifiable {
    case carryOn = "Carry-on"
    case checked = "Checked"
    var id: String { rawValue }
}

struct BaggageItem: Codable, Hashable, Identifiable {
    var id: String = UUID().uuidString
    var type: BaggageType
    var weightKg: Double?
    
    // LCC Mode Constraints
    var isLCCMode: Bool = false
    var lengthCm: Double?
    var widthCm: Double?
    var heightCm: Double?
}

// MARK: - Specific Data Schemas

struct FlightData: Codable, Hashable {
    var airline: String
    var brandDomain: String?
    var airlineCode: String?
    var flightNumber: String
    var confirmationCode: String
    var passenger: String?
    var travelClass: String?
    
    var departureCity: String?
    var arrivalCity: String?
    
    var departureAirport: String
    var departureCountry: String?
    var departureCountryCode: String?
    var departureTerminal: String?
    var departureGate: String?
    var checkInDesk: String?
    var seat: String?
    var aircraft: String?
    var aircraftRegistration: String?
    var departureTime: Date
    var arrivalAirport: String
    var arrivalCountry: String?
    var arrivalCountryCode: String?
    var arrivalTerminal: String?
    var arrivalTime: Date
    var etkt: String?
    var fare: TravelFare?
    
    // ✅ NEW: Baggage List
    var baggage: [BaggageItem]?
}

struct TrainData: Codable, Hashable {
    var serviceProvider: String?
    var trainNumber: String?
    var passenger: String?
    var travelClass: String?
    var departureStation: String
    var departureCountry: String?
    var departureCountryCode: String?
    var departureTime: Date
    var departureGate: String?
    var seat: String?
    var arrivalStation: String
    var arrivalCountry: String?
    var arrivalCountryCode: String?
    var arrivalTime: Date
    var fare: TravelFare?
}

struct CarData: Codable, Hashable {
    var origin: String
    var departureCountry: String?
    var departureCountryCode: String?
    var destination: String?
    var arrivalCountry: String?
    var arrivalCountryCode: String?
    var pickupTime: Date
    var driver: String?
    var passenger: String?
    var carPlate: String?
    var carColor: String?
    var carBrand: String?
    var fare: TravelFare?
}

struct HotelData: Codable, Hashable {
    var hotelName: String
    var brandDomain: String?
    var address: String
    var checkInTime: Date?
    var checkOutTime: Date?
    var bookingNumber: String?
    var confirmationNumber: String?
    var guestName: String?
    var roomType: String?
    var numberOfNights: String
    var fare: TravelFare?
    var isBreakfastIncluded: Bool?
    var extraIncluded: String?
}

struct OtherData: Codable, Hashable {
    var title: String
    var description: String?
    var location: String?
    var time: String?
    var fare: TravelFare?
}

// MARK: - Union Type
enum ItineraryEventDataType: Codable, Hashable {
    case flight(FlightData)
    case train(TrainData)
    case car(CarData)
    case hotel(HotelData)
    case other(OtherData)
    
    enum CodingKeys: String, CodingKey {
        case flight, train, car, hotel, other
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if container.contains(.flight) {
            self = .flight(try container.decode(FlightData.self, forKey: .flight))
        } else if container.contains(.train) {
            self = .train(try container.decode(TrainData.self, forKey: .train))
        } else if container.contains(.car) {
            self = .car(try container.decode(CarData.self, forKey: .car))
        } else if container.contains(.hotel) {
            self = .hotel(try container.decode(HotelData.self, forKey: .hotel))
        } else if container.contains(.other) {
            self = .other(try container.decode(OtherData.self, forKey: .other))
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: container.codingPath, debugDescription: "Invalid event type")
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .flight(let d): try container.encode(d, forKey: .flight)
        case .train(let d): try container.encode(d, forKey: .train)
        case .car(let d): try container.encode(d, forKey: .car)
        case .hotel(let d): try container.encode(d, forKey: .hotel)
        case .other(let d): try container.encode(d, forKey: .other)
        }
    }
    
    var eventType: EventType {
        switch self {
        case .flight: return .flight
        case .train: return .train
        case .car: return .car
        case .hotel: return .hotel
        case .other: return .other
        }
    }
}

struct TranslatedContent: Codable, Hashable {
    var data: ItineraryEventDataType
    var labels: [String: String]
}

// MARK: - Main Travel Event
struct TravelEvent: Codable, Identifiable, Hashable {
    var id: String
    var type: EventType
    
    var startTime: Date
    var endTime: Date?
    
    var geoCoordinates: GeoCoordinates?
    var destinationGeoCoordinates: GeoCoordinates?
    var detectedLanguage: String?
    var bookingSource: BookingSource?
    
    var data: ItineraryEventDataType
    var translations: [String: TranslatedContent]?
    var attachments: [Attachment]?
    var weather: WeatherInfo?
    
    init(id: String = UUID().uuidString, type: EventType, startTime: Date, endTime: Date? = nil, geoCoordinates: GeoCoordinates? = nil, destinationGeoCoordinates: GeoCoordinates? = nil, detectedLanguage: String? = nil, bookingSource: BookingSource? = nil, data: ItineraryEventDataType, translations: [String: TranslatedContent]? = nil, attachments: [Attachment]? = nil, weather: WeatherInfo? = nil) {
        self.id = id
        self.type = type
        self.startTime = startTime
        self.endTime = endTime
        self.geoCoordinates = geoCoordinates
        self.destinationGeoCoordinates = destinationGeoCoordinates
        self.detectedLanguage = detectedLanguage
        self.bookingSource = bookingSource
        self.data = data
        self.translations = translations
        self.attachments = attachments
        self.weather = weather
    }
    
    var displayTitle: String {
        switch data {
        case .flight(let f): return f.airlineCode != nil ? "\(f.airlineCode!)\(f.flightNumber)" : "\(f.airline) \(f.flightNumber)"
        case .hotel(let h): return h.hotelName
        case .train(let t): return "\(t.serviceProvider ?? "Train") \(t.trainNumber ?? "")"
        case .car(let c): return c.carBrand ?? "Ride"
        case .other(let o): return o.title
        }
    }
    
    var displayLocation: String {
        switch data {
        case .flight(let f):
            let start = f.departureCity ?? f.departureAirport
            let end = f.arrivalCity ?? f.arrivalAirport
            return "\(start) to \(end)"
        case .hotel(let h): return h.address
        case .train(let t): return "\(t.departureStation) to \(t.arrivalStation)"
        case .car(let c):
            if let dest = c.destination { return "\(c.origin) to \(dest)" }
            return c.origin
        case .other(let o): return o.location ?? ""
        }
    }
}

// MARK: - Trip
struct Trip: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var startDate: Date?
    var endDate: Date?
    var events: [TravelEvent]
    
    init(id: String = UUID().uuidString, name: String, startDate: Date? = nil, endDate: Date? = nil, events: [TravelEvent] = []) {
        self.id = id
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.events = events
    }
}
