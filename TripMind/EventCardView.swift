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
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter
    }()
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            
            // Timeline Column
            VStack(spacing: 0) {
                Circle()
                    .fill(eventTypeColor)
                    .frame(width: 12, height: 12)
                    .background(Circle().stroke(Color(UIColor.systemGroupedBackground), lineWidth: 4))
                    .padding(.top, 4)
                
                Rectangle()
                    .fill(Color.timelineLine)
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }
            .frame(width: 20)
            
            // Content Column
            VStack(alignment: .leading, spacing: 8) {
                
                // Date Header
                Text(dateFormatter.string(from: event.startTime).uppercased())
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.secondary)
                
                // Card Box
                VStack(alignment: .leading, spacing: 12) {
                    
                    // Header: Logo + Title + Time
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
                                Spacer()
                                // Time inside card
                                Text(timeFormatter.string(from: event.startTime))
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.primary)
                            }
                            
                            // Subtitle: Hide for Car (since it's in body), Show for others
                            if !isCarEvent {
                                Text(event.displayLocation)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    
                    Divider().opacity(0.5)
                    
                    // Specific Content
                    contentView.padding(.top, 4)
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
            HotelCardContent(hotel: hotel, timeFormatter: timeFormatter)
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
        case .flight(let f): return f.airlineCode != nil ? "\(f.airlineCode!)\(f.flightNumber)" : f.flightNumber
        case .car(let c): return c.carBrand ?? "Ride"
        default: return event.displayTitle
        }
    }
    
    var isCarEvent: Bool {
        if case .car = event.data { return true }
        return false
    }
    
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
        HStack(alignment: .center) {
            VStack(alignment: .leading) {
                HStack(spacing: 4) {
                    Text(flight.departureAirport).font(.system(size: 20, weight: .bold))
                    if let term = flight.departureTerminal {
                        // ✅ FIX: Check prefix before adding T
                        Text(formatTerminal(term)).font(.system(size: 20, weight: .bold)).foregroundColor(.secondary)
                    }
                }
                Text(timeFormatter.string(from: flight.departureTime)).font(.subheadline).foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "airplane").foregroundColor(.gray.opacity(0.5))
            Spacer()
            VStack(alignment: .trailing) {
                HStack(spacing: 4) {
                    Text(flight.arrivalAirport).font(.system(size: 20, weight: .bold))
                    if let term = flight.arrivalTerminal {
                        // ✅ FIX: Check prefix before adding T
                        Text(formatTerminal(term)).font(.system(size: 20, weight: .bold)).foregroundColor(.secondary)
                    }
                }
                Text(timeFormatter.string(from: flight.arrivalTime)).font(.subheadline).foregroundColor(.secondary)
            }
        }
    }
    
    // Helper to format terminal string
    func formatTerminal(_ term: String) -> String {
        if term.uppercased().hasPrefix("T") || term.lowercased().contains("terminal") {
            return term
        }
        return "T\(term)"
    }
}

// ✅ UPDATED CAR CARD CONTENT (Vertical Layout)
struct CarCardContent: View {
    let car: CarData
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Origin (Line 1)
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "circle.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.green)
                    .padding(.top, 4)
                Text(car.origin)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Destination (Line 2)
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "circle.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.red)
                    .padding(.top, 4)
                Text(car.destination ?? "Unknown Destination")
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Divider()
            
            // Footer (Plate)
            HStack {
                Text(car.carPlate ?? "No Plate")
                    .font(.caption).bold()
                    .padding(4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(4)
                
                Spacer()
                if let driver = car.driver {
                    Text(driver).font(.caption).foregroundColor(.secondary)
                }
            }
        }
    }
}

struct HotelCardContent: View {
    let hotel: HotelData
    let timeFormatter: DateFormatter
    var body: some View {
        HStack(spacing: 16) {
            if let checkIn = hotel.checkInTime {
                VStack(alignment: .leading) {
                    Text("Check-in").font(.caption2).foregroundColor(.secondary)
                    Text(timeFormatter.string(from: checkIn)).font(.subheadline).bold()
                }
            }
            if let checkOut = hotel.checkOutTime {
                VStack(alignment: .leading) {
                    Text("Check-out").font(.caption2).foregroundColor(.secondary)
                    Text(timeFormatter.string(from: checkOut)).font(.subheadline).bold()
                }
            }
            Spacer()
            if !hotel.numberOfNights.isEmpty {
                Text(hotel.numberOfNights)
                    .font(.caption).bold()
                    .padding(6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
            }
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
    }
}
