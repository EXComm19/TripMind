import Foundation
// Removed: import FirebaseFirestoreSwift // Not available, as per user's feedback

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
    
    // For display purposes, convert to a more readable string
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
    
    // For SF Symbol icon display
    var symbolName: String {
        switch self {
        case .flight: return "airplane"
        case .hotel: return "bed.double"
        case .train: return "train.side.front.car"
        case .car: return "car"
        case .other: return "questionmark.circle"
        case .transport: return "figure.walk" // Generic transport
        case .activity: return "figure.run.circle"
        case .dining: return "fork.knife"
        }
    }
}

// MARK: - Basic Structures

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
    let currency: String // ISO 4217 3-letter code (e.g., "USD", "CNY")
    let amount: Double // 2 decimal places
}

struct Attachment: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let type: String
    let data: String // Base64 string
    let size: Int
}

struct WeatherInfo: Codable, Hashable {
    let code: Int // WMO Weather code
    let tempMax: Double?
    let tempMin: Double?
    let precipitationProbability: Double?
}

// MARK: - Specific Data Schemas

// Custom Codable for dynamic keys in `OtherData`
struct AnyCodable: Codable, Hashable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable cannot decode unsupported type")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let string = value as? String {
            try container.encode(string)
        } else if let int = value as? Int {
            try container.encode(int)
        } else if let double = value as? Double {
            try container.encode(double)
        } else if let bool = value as? Bool {
            try container.encode(bool)
        } else if let dict = value as? [String: AnyCodable] {
            try container.encode(dict)
        } else if let array = value as? [AnyCodable] {
            try container.encode(array)
        } else {
            let description = "AnyCodable cannot encode unsupported type: \(type(of: value))"
            throw EncodingError.invalidValue(value, .init(codingPath: encoder.codingPath, debugDescription: description))
        }
    }
    
    static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        // Implement a more robust equality check for Any
        // For simplicity, we'll rely on string representation if possible.
        // For real-world use, a deeper comparison of the 'value' property might be needed.
        // Currently, it compares the underlying values directly if they are Codable-compatible.
        // For dictionaries/arrays, a recursive comparison would be ideal.
        // For now, let's keep it basic to allow compilation.
        return String(describing: lhs.value) == String(describing: rhs.value)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(String(describing: value))
    }
}


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
    let departureGate: String?
    let checkInDesk: String?
    let seat: String?
    let aircraft: String?
    let aircraftRegistration: String?
    let departureTime: Date // ISO
    let arrivalAirport: String
    let arrivalCountry: String?
    let arrivalCountryCode: String?
    let arrivalTerminal: String?
    let arrivalTime: Date // ISO
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
    let destination: String
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
    let extraFields: [String: AnyCodable]?
    
    // Explicit memberwise initializer
    public init(title: String, description: String? = nil, location: String? = nil, time: String? = nil, fare: TravelFare? = nil, extraFields: [String: AnyCodable]? = nil) {
        self.title = title
        self.description = description
        self.location = location
        self.time = time
        self.fare = fare
        self.extraFields = extraFields
    }
    
    enum StaticCodingKeys: String, CodingKey {
        case title
        case description
        case location
        case time
        case fare
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StaticCodingKeys.self)
        self.title = try container.decode(String.self, forKey: .title)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.location = try container.decodeIfPresent(String.self, forKey: .location)
        self.time = try container.decodeIfPresent(String.self, forKey: .time)
        self.fare = try container.decodeIfPresent(TravelFare.self, forKey: .fare)
        
        var extraFieldsDict: [String: AnyCodable] = [:]
        let allKeys = try decoder.container(keyedBy: AnyCodingKey.self)
        for key in allKeys.allKeys {
            // Check if the key is one of our predefined static keys
            if StaticCodingKeys(rawValue: key.stringValue) == nil {
                // If not, decode it as an extra field
                let nestedDecoder = try allKeys.superDecoder(forKey: key)
                let anyCodable = try AnyCodable(from: nestedDecoder)
                extraFieldsDict[key.stringValue] = anyCodable
            }
        }
        self.extraFields = extraFieldsDict.isEmpty ? nil : extraFieldsDict
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StaticCodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(location, forKey: .location)
        try container.encodeIfPresent(time, forKey: .time)
        try container.encodeIfPresent(fare, forKey: .fare)
        
        if let extraFields = extraFields {
            var dynamicContainer = encoder.container(keyedBy: AnyCodingKey.self)
            for (key, value) in extraFields {
                try dynamicContainer.encode(value, forKey: AnyCodingKey(key))
            }
        }
    }
    
    struct AnyCodingKey: CodingKey {
        var stringValue: String
        var intValue: Int?
        
        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) {
            self.stringValue = "\(intValue)"
            self.intValue = intValue
        }
        init(_ string: String) { self.stringValue = string }
    }
}


// MARK: - Union Type for Polymorphic Data

enum ItineraryEventDataType: Codable, Hashable {
    case flight(FlightData)
    case train(TrainData)
    case car(CarData)
    case hotel(HotelData)
    case other(OtherData)
    
    // 1. Define the keys we expect inside the "data" object
    enum CodingKeys: String, CodingKey {
        case flight, train, car, hotel, other
    }

    // 2. Manual Decoder that handles the nesting
    init(from decoder: Decoder) throws {
        // Use a KEYED container, not a single value container
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if container.contains(.flight) {
            let value = try container.decode(FlightData.self, forKey: .flight)
            self = .flight(value)
        } else if container.contains(.train) {
            let value = try container.decode(TrainData.self, forKey: .train)
            self = .train(value)
        } else if container.contains(.car) {
            let value = try container.decode(CarData.self, forKey: .car)
            self = .car(value)
        } else if container.contains(.hotel) {
            let value = try container.decode(HotelData.self, forKey: .hotel)
            self = .hotel(value)
        } else if container.contains(.other) {
            let value = try container.decode(OtherData.self, forKey: .other)
            self = .other(value)
        } else {
            // This catches the exact error you are seeing
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Cannot decode ItineraryEventDataType: Valid key not found (expected flight, train, car, hotel, or other)"
                )
            )
        }
    }
    
    // 3. Manual Encoder (Required to match the nesting)
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .flight(let data): try container.encode(data, forKey: .flight)
        case .train(let data): try container.encode(data, forKey: .train)
        case .car(let data): try container.encode(data, forKey: .car)
        case .hotel(let data): try container.encode(data, forKey: .hotel)
        case .other(let data): try container.encode(data, forKey: .other)
        }
    }
    
    // Helper to keep your existing logic working
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
    let data: ItineraryEventDataType
    let labels: [String: String] // Record<string, string>
}

// MARK: - Main Travel Event

struct TravelEvent: Codable, Identifiable, Hashable {
    let id: String // Keep as String for consistent UUID().uuidString and Firestore storage
    let type: EventType
    
    let startTime: Date // ISO
    let endTime: Date? // ISO
    
    let geoCoordinates: GeoCoordinates? // Origin
    let destinationGeoCoordinates: GeoCoordinates? // Destination (for paths)

    let detectedLanguage: String? // e.g., 'zh', 'en', 'ja'
    let bookingSource: BookingSource? // The agency/site where it was booked
    
    let data: ItineraryEventDataType
    
    let translations: [String: TranslatedContent]?

    let attachments: [Attachment]?
    let weather: WeatherInfo?
    
    // Explicit memberwise initializer
    public init(id: String = UUID().uuidString, type: EventType, startTime: Date, endTime: Date? = nil, geoCoordinates: GeoCoordinates? = nil, destinationGeoCoordinates: GeoCoordinates? = nil, detectedLanguage: String? = nil, bookingSource: BookingSource? = nil, data: ItineraryEventDataType, translations: [String: TranslatedContent]? = nil, attachments: [Attachment]? = nil, weather: WeatherInfo? = nil) {
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
    
    // Define CodingKeys explicitly for TravelEvent
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case startTime
        case endTime
        case geoCoordinates
        case destinationGeoCoordinates
        case detectedLanguage
        case bookingSource
        case data
        case translations
        case attachments
        case weather
    }
    
    // Custom initializer for decoding Dates
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.type = try container.decode(EventType.self, forKey: .type)
        self.startTime = try container.decode(Date.self, forKey: .startTime)
        self.endTime = try container.decodeIfPresent(Date.self, forKey: .endTime)
        self.geoCoordinates = try container.decodeIfPresent(GeoCoordinates.self, forKey: .geoCoordinates)
        self.destinationGeoCoordinates = try container.decodeIfPresent(GeoCoordinates.self, forKey: .destinationGeoCoordinates)
        self.detectedLanguage = try container.decodeIfPresent(String.self, forKey: .detectedLanguage)
        self.bookingSource = try container.decodeIfPresent(BookingSource.self, forKey: .bookingSource)
        self.data = try container.decode(ItineraryEventDataType.self, forKey: .data)
        self.translations = try container.decodeIfPresent([String: TranslatedContent].self, forKey: .translations)
        self.attachments = try container.decodeIfPresent([Attachment].self, forKey: .attachments)
        self.weather = try container.decodeIfPresent(WeatherInfo.self, forKey: .weather)
    }
    
    // Custom encoder for Dates
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(startTime, forKey: .startTime)
        try container.encodeIfPresent(endTime, forKey: .endTime)
        try container.encodeIfPresent(geoCoordinates, forKey: .geoCoordinates)
        try container.encodeIfPresent(destinationGeoCoordinates, forKey: .destinationGeoCoordinates)
        try container.encodeIfPresent(detectedLanguage, forKey: .detectedLanguage)
        try container.encodeIfPresent(bookingSource, forKey: .bookingSource)
        try container.encode(data, forKey: .data)
        try container.encodeIfPresent(translations, forKey: .translations)
        try container.encodeIfPresent(attachments, forKey: .attachments)
        try container.encodeIfPresent(weather, forKey: .weather)
    }
    
    // Helper to get a display title
    var displayTitle: String {
        switch data {
        case .flight(let flight):
            return "\(flight.airline) Flight \(flight.flightNumber)"
        case .hotel(let hotel):
            return hotel.hotelName
        case .train(let train):
            return "\(train.serviceProvider ?? "Train") \(train.trainNumber ?? "")"
        case .car(let car):
            return "\(car.carBrand ?? "Car Rental")"
        case .other(let other):
            return other.title
        }
    }
    
    // Helper to get a display location
    var displayLocation: String {
        switch data {
        case .flight(let flight):
            return "\(flight.departureAirport) to \(flight.arrivalAirport)"
        case .hotel(let hotel):
            return hotel.address
        case .train(let train):
            return "\(train.departureStation) to \(train.arrivalStation)"
        case .car(let car):
            return "\(car.origin) to \(car.destination)"
        case .other(let other):
            return other.location ?? "Unknown Location"
        }
    }
}

// MARK: - Trip Structure for organizing events

struct Trip: Identifiable, Codable, Hashable {
    var id: String // Explicitly use String for ID to store Firestore document ID
    var name: String
    var startDate: Date?
    var endDate: Date?
    var events: [TravelEvent] // All events associated with this trip
    
    // Custom initializer to handle `id` from Firestore or a new client-generated one
    init(id: String = UUID().uuidString, name: String, startDate: Date? = nil, endDate: Date? = nil, events: [TravelEvent] = []) {
        self.id = id
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.events = events
    }
    
    // The `uid` computed property is no longer needed as `id` is now a non-optional String
    // We can rely directly on `id` for `Identifiable` conformance.
}

