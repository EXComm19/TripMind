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
                } else {
                    // Generic Header for others (Hotel, Train)
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
                bookingSource: event.bookingSource,
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
        default: return event.displayTitle
        }
    }
    
    var isCarEvent: Bool { if case .car = event.data { return true } else { return false } }
    var isFlightEvent: Bool { if case .flight = event.data { return true } else { return false } }
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
            HStack(spacing: 8) {
                BrandLogoView(brandDomain: flight.brandDomain, fallbackIcon: "airplane", size: 16)
                Text("\(flight.airline) • \(flight.airlineCode ?? "") \(flight.flightNumber)")
                    .font(.subheadline).fontWeight(.regular).foregroundColor(.secondary)
                Spacer()
            }
            .padding(.bottom, 0)
            Divider().overlay(Color.white.opacity(0.3))
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(timeFormatter.string(from: flight.departureTime)).font(.title3).bold().foregroundColor(.primary)
                    Text(flight.departureCity ?? flight.departureAirport).font(.subheadline).fontWeight(.bold).foregroundColor(.primary)
                    Text("\(flight.departureAirport) • \(formatTerminal(flight.departureTerminal))").font(.subheadline).fontWeight(.regular).foregroundColor(.secondary)
                }
                Spacer()
                VStack(spacing: 4) {
                    if let duration = calculateDuration() { Text(duration).font(.caption).foregroundColor(.secondary) }
                    HStack(spacing: 0) {
                        Rectangle().fill(Color.gray).frame(height: 3)
                        Image(systemName: "airplane").font(.system(size: 14, weight: .bold)).foregroundColor(.primary).padding(.horizontal, 4)
                        Rectangle().fill(Color.gray).frame(height: 3)
                    }
                    .frame(width: 140)
                }
                .padding(.top, 8)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(timeFormatter.string(from: flight.arrivalTime)).font(.title3).bold().foregroundColor(.primary)
                    Text(flight.arrivalCity ?? flight.arrivalAirport).font(.subheadline).fontWeight(.bold).foregroundColor(.primary)
                    Text("\(flight.arrivalAirport) • \(formatTerminal(flight.arrivalTerminal))").font(.subheadline).fontWeight(.regular).foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
            if flight.departureGate != nil || flight.checkInCounter != nil {
                Divider().overlay(Color.white.opacity(0.3))
                HStack {
                    if let gate = flight.departureGate {
                        HStack(spacing: 6) {
                            Image(systemName: "airplane.departure").font(.callout).foregroundColor(.secondary)
                            Text("Gate:").font(.callout).foregroundColor(.secondary)
                            Text(gate).font(.callout).bold().foregroundColor(.primary)
                        }
                    }
                    Spacer()
                    if let counter = flight.checkInCounter {
                        HStack(spacing: 6) {
                            Image(systemName: "person.crop.rectangle").font(.callout).foregroundColor(.secondary)
                            Text("Check-in:").font(.callout).foregroundColor(.secondary)
                            Text(counter).font(.callout).bold().foregroundColor(.primary)
                        }
                    }
                }
                .padding(.top, 2)
            }
        }
    }
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
        HStack(alignment: .top, spacing: 0) {
            
            // COL 1: CHECK-IN
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                    Text("CHECK-IN")
                        .font(.caption2).fontWeight(.bold)
                }
                .foregroundColor(.secondary)
                
                if let checkIn = hotel.checkInTime {
                    // ✅ Date: Decreased to .headline (was .title3)
                    Text(dateFormatter.string(from: checkIn).uppercased())
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(timeFormatter.string(from: checkIn))
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            }
            .frame(width: 90, alignment: .leading)
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 1)
                .padding(.horizontal, 10)
            
            // COL 2: CHECK-OUT
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                    Text("CHECK-OUT")
                        .font(.caption2).fontWeight(.bold)
                }
                .foregroundColor(.secondary)
                
                if let checkOut = hotel.checkOutTime {
                    // ✅ Date: Decreased to .headline
                    Text(dateFormatter.string(from: checkOut).uppercased())
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(timeFormatter.string(from: checkOut))
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            }
            .frame(width: 90, alignment: .leading)
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 1)
                .padding(.horizontal, 10)
            
            // COL 3: DETAILS
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "moon.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("DURATION")
                            .font(.caption2).fontWeight(.bold).foregroundColor(.secondary)
                        Text(getNightsString())
                            .font(.subheadline).fontWeight(.bold).foregroundColor(.primary)
                    }
                }
                
                if let room = hotel.roomType, !room.isEmpty {
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "bed.double.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("ROOM TYPE")
                                .font(.caption2).fontWeight(.bold).foregroundColor(.secondary)
                            Text(room.uppercased())
                                .font(.caption).fontWeight(.bold)
                                .foregroundColor(.primary)
                                .lineLimit(2)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.top, 4)
    }
    
    func getNightsString() -> String {
        if !hotel.numberOfNights.isEmpty {
            return hotel.numberOfNights.uppercased()
        } else if let checkIn = hotel.checkInTime, let checkOut = hotel.checkOutTime {
            let nights = Calendar.current.dateComponents([.day], from: checkIn, to: checkOut).day ?? 0
            return "\(nights) NIGHTS"
        }
        return ""
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
                    brandDomain: bookingSource?.domain,
                    fallbackIcon: "car",
                    size: 16
                )
                
                let provider = bookingSource?.name.uppercased() ?? "CAR SERVICE"
                let service = car.serviceType ?? ""
                let titleText = service.isEmpty ? provider : "\(provider) · \(service)"
                
                Text(titleText)
                    .font(.subheadline)
                    .fontWeight(.regular)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Spacer()
                
                Text(timeFormatter.string(from: startTime))
                    .font(.title3).bold()
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
                    Image("Car")
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
        HStack {
            VStack(alignment: .leading) {
                Text(train.departureStation).font(.headline)
                Text(timeFormatter.string(from: train.departureTime)).font(.subheadline).foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "arrow.right").font(.caption).foregroundColor(.secondary)
            Spacer()
            VStack(alignment: .trailing) {
                Text(train.arrivalStation).font(.headline)
                Text(timeFormatter.string(from: train.arrivalTime)).font(.subheadline).foregroundColor(.secondary)
            } 
        }
        .foregroundColor(.primary)
    }
}
