//
//  EventCardView.swift
//  TripMind
//
//  Created by EXC19 on 2026/1/18.
//

import SwiftUI

struct EventCardView: View {
    let event: TravelEvent
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a" // 12-hour format
        return formatter
    }()
    
    // Formatter for the Hotel Card Grid
    private let hotelDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d" // No Year
        return formatter
    }()
    
    var body: some View {
        // Main Card Container
        HStack(spacing: 0) {
            
            // COLORED LEFT EDGE
            Rectangle()
                .fill(eventTypeColor)
                .frame(width: 6)
            
            // CONTENT CONTAINER
            VStack(alignment: .leading, spacing: 12) {
                
                if isFlightEvent {
                    contentView
                } else if isCarEvent {
                    contentView
                } else if isTrainEvent {
                    contentView
                } else if isHotelEvent {
                    contentView
                } else {
                    // Generic Header for others
                    HStack(alignment: .center, spacing: 12) {
                        BrandLogoView(
                            brandDomain: getBrandDomain(),
                            fallbackIcon: event.type.symbolName,
                            size: 16
                        )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(displayTitle)
                                    .font(.system(size: 16, weight: .semibold))
                                    .lineLimit(1)
                                    .foregroundColor(.primary)
                                Spacer()
                                // Hide redundant time for hotels
                                if !isHotelEvent {
                                    Text(timeFormatter.string(from: event.startTime))
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.primary)
                                }
                            }
                            
                            // Don't show address for Hotels (handled in grid)
                            if !isHotelEvent {
                                Text(event.displayLocation)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    
                    Divider().overlay(Color.white.opacity(0.3))
                    contentView.padding(.top, 4)
                }
            }
            .padding(16)
        }
        .background(Color.cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    var contentView: some View {
        switch event.data {
        case .flight(let flight):
            FlightCardContent(flight: flight, timeFormatter: timeFormatter)
        case .hotel(let hotel):
            HotelCardContent(hotel: hotel, timeFormatter: timeFormatter, dateFormatter: hotelDateFormatter)
        case .car(let car):
            CarCardContent(
                car: car,
                bookingSource: car.bookingSource,
                startTime: event.startTime,
                timeFormatter: timeFormatter
            )
        case .train(let train):
            TrainCardContent(train: train, timeFormatter: timeFormatter)
        default:
            EmptyView()
        }
    }
    
    var displayTitle: String {
        switch event.data {
        case .flight(let f): return "\(f.airlineCode ?? "") \(f.flightNumber)"
        case .hotel(let h): return h.hotelName
        case .car(let c): return c.carBrand ?? "Ride"
        case .train(let t): return "\(t.trainOperator ?? "") \(t.trainNumber)"
        default: return event.displayTitle
        }
    }
    
    var isCarEvent: Bool { if case .car = event.data { return true } else { return false } }
    var isFlightEvent: Bool { if case .flight = event.data { return true } else { return false } }
    var isTrainEvent: Bool { if case .train = event.data { return true } else { return false } }
    var isHotelEvent: Bool { if case .hotel = event.data { return true } else { return false } }
    
    var eventTypeColor: Color {
        switch event.type {
        case .flight: return .blue
        case .hotel: return .purple
        case .train: return .orange
        case .car: return .green
        default: return .gray
        }
    }
    
    func getBrandDomain() -> String? {
        switch event.data {
        case .flight(let f): return f.brandDomain
        case .hotel(let h): return h.brandDomain
        case .car(let c): return c.brandDomain
        case .train(let t): return t.brandDomain
        default: return nil
        }
    }
}

// MARK: - Subviews

struct FlightCardContent: View {
    let flight: FlightData
    let timeFormatter: DateFormatter
    
    var body: some View {
        VStack(spacing: 8) {
            // Header: Airline & Flight Number
            HStack(spacing: 8) {
                BrandLogoView(brandDomain: flight.brandDomain, fallbackIcon: "airplane", size: 16)
                Text("\(flight.airline) · \(flight.airlineCode ?? "") \(flight.flightNumber)")
                    .font(.system(size: 16, weight: .regular))
                Spacer()
            }
            .padding(.bottom, 4)
            
            Divider().overlay(Color.white.opacity(0.3))
            
            // Main Flight Info
            HStack(alignment: .top) {
                // DEPARTURE
                VStack(alignment: .leading, spacing: 2) {
                    Text(timeFormatter.string(from: flight.departureTime))
                        .font(.title3).bold().foregroundColor(.primary)
                    Text(flight.departureCity ?? flight.departureAirport)
                        .font(.headline).fontWeight(.bold).foregroundColor(.primary)
                    
                    // Optimized Terminal Display: Only show "· T1" if terminal exists
                    Text(shouldShowTerminal(flight.departureTerminal)
                         ? "\(flight.departureAirport) · \(formatTerminal(flight.departureTerminal))"
                         : flight.departureAirport)
                        .font(.subheadline).fontWeight(.regular).foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Duration & Graphic
                VStack(spacing: 4) {
                    if let duration = calculateDuration() {
                        Text(duration).font(.caption).foregroundColor(.secondary)
                    }
                    HStack(spacing: 0) {
                        Rectangle().fill(Color.gray).frame(height: 3)
                        Image(systemName: "airplane")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 4)
                        Rectangle().fill(Color.gray).frame(height: 3)
                    }
                    .frame(width: 140)
                }
                .padding(.top, 8)
                
                Spacer()
                
                // ARRIVAL
                VStack(alignment: .trailing, spacing: 2) {
                    Text(timeFormatter.string(from: flight.arrivalTime))
                        .font(.title3).bold().foregroundColor(.primary)
                    Text(flight.arrivalCity ?? flight.arrivalAirport)
                        .font(.headline).fontWeight(.bold).foregroundColor(.primary)
                    
                    // Optimized Terminal Display: Only show "· T1" if terminal exists
                    Text(shouldShowTerminal(flight.arrivalTerminal)
                         ? "\(flight.arrivalAirport) · \(formatTerminal(flight.arrivalTerminal))"
                         : flight.arrivalAirport)
                        .font(.subheadline).fontWeight(.regular).foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
            
            // Footer: Gate & Check-in
            if flight.departureGate != nil || flight.checkInCounter != nil {
                Divider().overlay(Color.white.opacity(0.3))
                HStack {
                    if let gate = flight.departureGate {
                        HStack(spacing: 6) {
                            Image(systemName: "airplane.departure")
                                .font(.callout).foregroundColor(.secondary)
                            Text("Gate:").font(.callout).foregroundColor(.secondary)
                            Text(gate).font(.callout).bold().foregroundColor(.primary)
                        }
                    }
                    Spacer()
                    if let counter = flight.checkInCounter {
                        HStack(spacing: 6) {
                            Image(systemName: "person.crop.rectangle")
                                .font(.callout).foregroundColor(.secondary)
                            Text("Check-in:").font(.callout).foregroundColor(.secondary)
                            Text(counter).font(.callout).bold().foregroundColor(.primary)
                        }
                    }
                }
                .padding(.top, 2)
            }
        }
    }
    
    // Helper to check if we should display the terminal
    func shouldShowTerminal(_ term: String?) -> Bool {
        return term != nil && !term!.isEmpty
    }
    
    // Existing formatting function (Unchanged)
    func formatTerminal(_ term: String?) -> String {
        guard let term = term, !term.isEmpty else { return "T?" }
        if term.uppercased().hasPrefix("T") || term.lowercased().contains("terminal") { return term }
        return "T\(term)"
    }
    
    func calculateDuration() -> String? {
        let diff = flight.arrivalTime.timeIntervalSince(flight.departureTime)
        if diff > 0 {
            let h = Int(diff) / 3600
            let m = Int(diff) % 3600 / 60
            return "\(h)h \(m)m"
        }
        return nil
    }
}

// ✅ UPDATED HOTEL CARD CONTENT
struct HotelCardContent: View {
    let hotel: HotelData
    let timeFormatter: DateFormatter
    let dateFormatter: DateFormatter
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            // ROW 1: HEADER (Logo + Name)
            HStack(alignment: .center, spacing: 12) {
                BrandLogoView(
                    brandDomain: hotel.brandDomain,
                    fallbackIcon: "bed.double",
                    size: 32 // Slightly larger for hotel brand
                )
                
                Text(hotel.hotelName)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            
            // ROW 2: TIMELINE (Check-in -> Nights -> Check-out)
            HStack(alignment: .center) {
                // Check-in
                VStack(alignment: .leading, spacing: 4) {
                    Text("CHECK-IN")
                        .font(.caption2).fontWeight(.bold).foregroundColor(.secondary)
                    if let checkIn = hotel.checkInTime {
                        Text(dateFormatter.string(from: checkIn).uppercased())
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.primary)
                        Text(timeFormatter.string(from: checkIn))
                            .font(.caption).foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Duration Graphic
                VStack(spacing: 4) {
                    Text(getNightsString())
                        .font(.caption).fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 0) {
                        Circle().fill(Color.white).frame(width: 6, height: 6)
                        Rectangle().fill(Color.white.opacity(0.3)).frame(height: 2)
                        Image(systemName: "moon.stars.fill")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                        Rectangle().fill(Color.white.opacity(0.3)).frame(height: 2)
                        Circle().fill(Color.white).frame(width: 6, height: 6)
                    }
                    .frame(width: 100)
                }
                
                Spacer()
                
                // Check-out
                VStack(alignment: .trailing, spacing: 4) {
                    Text("CHECK-OUT")
                        .font(.caption2).fontWeight(.bold).foregroundColor(.secondary)
                    if let checkOut = hotel.checkOutTime {
                        Text(dateFormatter.string(from: checkOut).uppercased())
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.primary)
                        Text(timeFormatter.string(from: checkOut))
                            .font(.caption).foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 4)
            
            // ROW 3: TAGS (Room Type, Breakfast, etc.)
            FlowLayout(spacing: 8) {
                if let room = hotel.roomType, !room.isEmpty {
                    TagView(icon: "bed.double.fill", text: room, color: .blue)
                }
                
                if let breakfast = hotel.isBreakfastIncluded, breakfast {
                    TagView(icon: "cup.and.saucer.fill", text: "Breakfast Included", color: .orange)
                }
                
                if let extras = hotel.extraIncluded, !extras.isEmpty {
                    TagView(icon: "star.fill", text: "Extras", color: .purple)
                }
            }
        }
        .padding(.top, 4)
    }
    
    func getNightsString() -> String {
        if !hotel.numberOfNights.isEmpty {
            return "\(hotel.numberOfNights) NIGHTS"
        } else if let checkIn = hotel.checkInTime, let checkOut = hotel.checkOutTime {
            let nights = Calendar.current.dateComponents([.day], from: checkIn, to: checkOut).day ?? 0
            return "\(nights) NIGHTS"
        }
        return ""
    }
}

// Helper Views for Tags
struct TagView: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(color.opacity(0.1))
        .foregroundColor(color)
        .clipShape(Capsule())
    }
}

// Simple FlowLayout implementation (if iOS 16+ use Layout, else HStack wrapper)
// Since target is iOS 16+, we can use a wrapped HStack equivalent or just standard wrapping.
// For simplicity in this snippet, using a scrollable HStack if flow is complex,
// but let's stick to a wrapped layout logic or just an HStack if items are few.
// UPDATED: Using a simple HStack for now as usually only 2-3 tags.
struct FlowLayout: View {
    let spacing: CGFloat
    let content: () -> any View
    
    init(spacing: CGFloat = 8, @ViewBuilder content: @escaping () -> any View) {
        self.spacing = spacing
        self.content = content
    }
    
    var body: some View {
         // Fallback to simple HStack for now to ensure compilation,
         // as true FlowLayout requires more code.
         ScrollView(.horizontal, showsIndicators: false) {
             HStack(spacing: spacing) {
                 AnyView(content())
             }
         }
    }
}

struct CarCardContent: View {
    let car: CarData
    let bookingSource: BookingSource?
    let startTime: Date
    let timeFormatter: DateFormatter
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // 1. HEADER: Provider + Logo + Time
            HStack(alignment: .center, spacing: 10) {
                BrandLogoView(
                    brandDomain: car.brandDomain,
                    fallbackIcon: "car",
                    size: 16
                )
                
                let provider = car.serviceProvider?.uppercased() ?? "CAR SERVICE"
                let service = car.serviceType ?? ""
                let titleText = service.isEmpty ? provider : "\(provider) · \(service)"
                
                Text(titleText)
                    .font(.system(size: 16))
                    .fontWeight(.regular)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Spacer()
                
                Text(timeFormatter.string(from: startTime))
                    .font(.system(size: 16)).bold()
                    .foregroundColor(.primary)
            }
            .padding(.bottom, 0)
            
            Divider().overlay(Color.white.opacity(0.3))
            
            // 2. MAIN ROW: Route | Car Image
            HStack(alignment: .center, spacing: 16) {
                
                VStack(alignment: .leading, spacing: 0) {
                    RoutePointView(dotColor: .green, text: car.origin)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2)
                        .frame(height: 16)
                        .padding(.leading, 3)
                    
                    RoutePointView(dotColor: .red, text: car.destination ?? "Unknown")
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    Image(CarAssetManager.getCarImage(for: car.carBrand ?? "", serviceType: car.serviceType))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120)
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(car.carPlate ?? "NO PLATE")
                            .font(.title3).bold()
                            .foregroundColor(.primary)
                    }
                }
            }
            
            Divider().overlay(Color.white.opacity(0.3))
            
            // 3. FOOTER
            HStack {
                if let driver = car.driver {
                    HStack(spacing: 6) {
                        Image(systemName: "person.fill").font(.callout).foregroundColor(.secondary)
                        Text(driver).font(.callout).fontWeight(.semibold).foregroundColor(.primary)
                    }
                }
                Spacer()
                if let brand = car.carBrand {
                    HStack(spacing: 6) {
                        Image(systemName: "car.fill").font(.callout).foregroundColor(.secondary)
                        let colorText = car.carColor != nil ? " · \(car.carColor!)" : ""
                        Text("\(brand)\(colorText)").font(.callout).fontWeight(.semibold).foregroundColor(.primary)
                    }
                }
            }
            .padding(.top, 2)
        }
    }

    struct CarAssetManager {
        // Define your mapping: Image Name -> Array of Keywords
        private static let carMapping: [String: [String]] = [
            "gac_aionS": ["aion s", "埃安S"],
            "hongqi_eqm5": ["eqm5", "e-qm5"],
            "byd_qin": ["qin EV", "秦EV"],
            "byd_qinPlus": ["qin Plus EV", "秦Plus"],
            "buick_gl8": ["gl8"],
            "byd_han": ["han", "汉"],
            "voyah_dreamer": ["dreamer", "梦想家"],
            "gac_aionY": ["aion Y", "埃安Y"],
            "benz_eclass": ["E级","E300L","E260L", "E300", "E260"]
        ]
        
        /// Searches for a car image based on a raw model string
        static func getCarImage(for modelString: String, serviceType: String? = nil) -> String {
            let normalizedInput = modelString.lowercased()
            
            // Loop through mapping to find a keyword match
            for (imageName, keywords) in carMapping {
                for keyword in keywords {
                    if normalizedInput.contains(keyword.lowercased()) {
                        return "carImage/\(imageName)"
                    }
                }
            }
            
            // Backup logic based on Service Type
            if let service = serviceType?.lowercased() {
                if service.contains("六座专车") || service.contains("商务车") || service.contains("商务") || service.contains("六座") || service.contains("mpv") || service.contains("商务mpv") || service.contains("six-seater") || service.contains("six-seater mpv") || service.contains("business") {
                    return "carImage/voyah_dreamer"
                } else if service.contains("专车") || service.contains("premier") || service.contains("舒适型") || service.contains("comfort") || service.contains("轻享") {
                    return "carImage/byd_han"
                } else if service.contains("豪华") || service.contains("luxe") || service.contains("luxury") || service.contains("lux") {
                    return "carImage/benz_eclass"
                }
            }
            
            // Backup image if no match is found
            return "carImage/byd_qinPlus"
        }
    }
}

struct RoutePointView: View {
    let dotColor: Color
    let text: String
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Circle().fill(dotColor).frame(width: 8, height: 8)
            Text(text).font(.subheadline).fontWeight(.medium).foregroundColor(.primary).fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct TrainCardContent: View {
    let train: TrainData
    let timeFormatter: DateFormatter
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                BrandLogoView(brandDomain: train.brandDomain, fallbackIcon: "train.side.front.car", size: 16)
                Text("\(train.trainOperator ?? "Train") · \(train.trainNumber ?? "")")
                    .font(.system(size: 16, weight: .regular))
                Spacer()
            }
            .padding(.bottom, 4)
            Divider().overlay(Color.white.opacity(0.3))
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(timeFormatter.string(from: train.departureTime)).font(.title3).bold().foregroundColor(.primary)
                    Text(train.departureStation).font(.headline).fontWeight(.bold).foregroundColor(.primary)
                }
                Spacer()
                VStack(spacing: 4) {
                    if let duration = calculateDuration() { Text(duration).font(.caption).foregroundColor(.secondary) }
                    HStack(spacing: 0) {
                        Rectangle().fill(Color.gray).frame(height: 3)
                        Image(systemName: "train.side.front.car").font(.system(size: 14, weight: .bold)).foregroundColor(.primary).padding(.horizontal, 4)
                        Rectangle().fill(Color.gray).frame(height: 3)
                    }
                    .frame(width: 140)
                }
                .padding(.top, 8)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(timeFormatter.string(from: train.arrivalTime)).font(.title3).bold().foregroundColor(.primary)
                    Text(train.arrivalStation).font(.headline).fontWeight(.bold).foregroundColor(.primary)
                }
            }
            .padding(.vertical, 4)
            if train.seat != nil || train.travelClass != nil {
                Divider().overlay(Color.white.opacity(0.3))
                HStack {
                    if let seat = train.seat {
                        HStack(spacing: 6) {
                            Image(systemName: "airplaneseat").font(.callout).foregroundColor(.secondary)
                            Text(seat).font(.callout).bold().foregroundColor(.primary)
                        }
                    }
                    Spacer()
                    if let tclass = train.travelClass {
                        HStack(spacing: 6) {
                            Image(systemName: "star.circle").font(.callout).foregroundColor(.secondary)
                            Text(tclass).font(.callout).bold().foregroundColor(.primary)
                        }
                    }
                }
                .padding(.top, 2)
            }
            
        }
        
    }
    func calculateDuration() -> String? {
        let diff = train.arrivalTime.timeIntervalSince(train.departureTime)
        if diff > 0 {
            let h = Int(diff) / 3600
            let m = Int(diff) % 3600 / 60
            return "\(h)h \(m)m"
        }
        return nil
    }
}
