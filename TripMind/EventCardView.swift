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
    
    // Helper for Hotel dates in the card content
    private let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            
            // Timeline Column
            VStack(spacing: 0) {
                // Rounded Square Icon
                RoundedRectangle(cornerRadius: 3)
                    .fill(eventTypeColor)
                    .frame(width: 12, height: 12)
                    .background(RoundedRectangle(cornerRadius: 3).stroke(Color(UIColor.systemGroupedBackground), lineWidth: 4))
                    .padding(.top, 28)
                
                Rectangle()
                    .fill(Color.timelineLine)
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }
            .frame(width: 20)
            
            // Content Column
            VStack(alignment: .leading, spacing: 0) {
                
                // Card Box
                VStack(alignment: .leading, spacing: 12) {
                    
                    if isFlightEvent {
                        // Custom Full Card Layout for Flights
                        contentView
                        
                    } else {
                        // Generic Header for others
                        HStack(alignment: .center, spacing: 12) {
                            BrandLogoView(
                                brandDomain: getBrandDomain(),
                                fallbackIcon: event.type.symbolName
                            )
                            
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(displayTitle)
                                        .font(.system(size: 16, weight: .semibold))
                                        .lineLimit(1)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text(timeFormatter.string(from: event.startTime))
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.primary)
                                }
                                
                                if !isCarEvent {
                                    Text(event.displayLocation)
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                        
                        Divider().overlay(Color.gray.opacity(0.6)) // Brighter Divider
                        contentView.padding(.top, 4)
                    }
                }
                .padding(16)
                .background(Color.cardBackground)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
                
                Spacer().frame(height: 12)
            }
        }
    }
    
    @ViewBuilder
    var contentView: some View {
        switch event.data {
        case .flight(let flight):
            FlightCardContent(flight: flight, timeFormatter: timeFormatter)
        case .hotel(let hotel):
            HotelCardContent(hotel: hotel, timeFormatter: timeFormatter, dateFormatter: shortDateFormatter)
        case .car(let car):
            CarCardContent(car: car)
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
            
            // 1. TOP HEADER
            HStack(spacing: 8) {
                BrandLogoView(
                    brandDomain: flight.brandDomain,
                    fallbackIcon: "airplane",
                    size: 16
                )
                
                Text("\(flight.airline) • \(flight.airlineCode ?? "") \(flight.flightNumber)")
                    .font(.subheadline)
                    .fontWeight(.regular)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding(.bottom, 0)
            
            // Brighter Divider
            Divider().overlay(Color.gray.opacity(0.5))
            
            // 2. MAIN JOURNEY ROW
            HStack(alignment: .top) {
                
                // DEPARTURE
                VStack(alignment: .leading, spacing: 2) {
                    Text(timeFormatter.string(from: flight.departureTime))
                        .font(.title3).bold()
                        .foregroundColor(.primary)
                    
                    Text(flight.departureCity ?? flight.departureAirport)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("\(flight.departureAirport) • \(formatTerminal(flight.departureTerminal))")
                        .font(.subheadline)
                        .fontWeight(.regular)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // CONNECTOR
                VStack(spacing: 4) {
                    if let duration = calculateDuration() {
                        Text(duration)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // ✅ ELONGATED & BOLD LINE
                    HStack(spacing: 0) {
                        Rectangle().fill(Color.gray.opacity(0.6)).frame(height: 2) // Bold
                        Image(systemName: "airplane")
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 4)
                        Rectangle().fill(Color.gray.opacity(0.6)).frame(height: 2) // Bold
                    }
                    .frame(width: 100) // Elongated (was 60)
                }
                .padding(.top, 8)
                
                Spacer()
                
                // ARRIVAL
                VStack(alignment: .trailing, spacing: 2) {
                    Text(timeFormatter.string(from: flight.arrivalTime))
                        .font(.title3).bold()
                        .foregroundColor(.primary)
                    
                    Text(flight.arrivalCity ?? flight.arrivalAirport)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("\(flight.arrivalAirport) • \(formatTerminal(flight.arrivalTerminal))")
                        .font(.subheadline)
                        .fontWeight(.regular)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
            
            // 3. FOOTER
            if flight.departureGate != nil || flight.checkInCounter != nil {
                // Brighter Divider
                Divider().overlay(Color.gray.opacity(0.5))
                
                HStack {
                    if let gate = flight.departureGate {
                        HStack(spacing: 6) {
                            // ✅ ICON: Departing Flight
                            Image(systemName: "airplane.departure")
                                .font(.callout)
                                .foregroundColor(.secondary)
                            
                            Text("Gate:")
                                .font(.callout)
                                .foregroundColor(.secondary)
                            
                            Text(gate)
                                .font(.callout).bold()
                                .foregroundColor(.primary)
                        }
                    }
                    
                    Spacer()
                    
                    if let counter = flight.checkInCounter {
                        HStack(spacing: 6) {
                            // ✅ ICON: Service Desk Person
                            Image(systemName: "person.crop.rectangle")
                                .font(.callout)
                                .foregroundColor(.secondary)
                            
                            Text("Check-in:")
                                .font(.callout)
                                .foregroundColor(.secondary)
                            
                            Text(counter)
                                .font(.callout).bold()
                                .foregroundColor(.primary)
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

struct HotelCardContent: View {
    let hotel: HotelData
    let timeFormatter: DateFormatter
    let dateFormatter: DateFormatter
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                if let checkIn = hotel.checkInTime {
                    Text(dateFormatter.string(from: checkIn))
                        .font(.subheadline).fontWeight(.medium)
                }
                HStack(spacing: 2) {
                    if !hotel.numberOfNights.isEmpty {
                        Text(hotel.numberOfNights)
                    } else if let checkIn = hotel.checkInTime, let checkOut = hotel.checkOutTime {
                        let nights = Calendar.current.dateComponents([.day], from: checkIn, to: checkOut).day ?? 0
                        Text("\(nights) night\(nights == 1 ? "" : "s")")
                    }
                }
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().stroke(Color.secondary.opacity(0.5), lineWidth: 1))
                .foregroundColor(.secondary)
                
                if let checkOut = hotel.checkOutTime {
                    Text(dateFormatter.string(from: checkOut))
                        .font(.subheadline).fontWeight(.medium)
                }
            }
            HStack {
                if let checkIn = hotel.checkInTime {
                    Text("Check-in \(timeFormatter.string(from: checkIn))")
                }
                Text("---").foregroundColor(.secondary.opacity(0.5))
                if let checkOut = hotel.checkOutTime {
                    Text("Check-out \(timeFormatter.string(from: checkOut))")
                }
            }
            .font(.caption).foregroundColor(.secondary)
            
            if let room = hotel.roomType, !room.isEmpty {
                Text(room).font(.caption).foregroundColor(.secondary.opacity(0.8))
            }
        }
    }
}

struct CarCardContent: View {
    let car: CarData
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "circle.fill").font(.system(size: 8))
                    .foregroundColor(.green.opacity(0.6))
                    .padding(.top, 4)
                Text(car.origin).font(.subheadline).foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "circle.fill").font(.system(size: 8))
                    .foregroundColor(.red.opacity(0.6))
                    .padding(.top, 4)
                Text(car.destination ?? "Unknown Destination").font(.subheadline).foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Divider().background(Color.gray.opacity(0.3))
            HStack {
                Text(car.carPlate ?? "No Plate")
                    .font(.caption).bold()
                    .padding(4)
                    .background(Color(UIColor.tertiarySystemFill))
                    .cornerRadius(4)
                Spacer()
                if let brand = car.carBrand {
                    Text(brand).font(.caption).foregroundColor(.secondary)
                }
                if let driver = car.driver {
                    Text("• \(driver)").font(.caption).foregroundColor(.secondary)
                }
            }
        }
        .foregroundColor(.primary)
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
