//
//  EventCardView.swift
//  TripMind
//
//  Created by EXC19 on 2026/1/16.
//

import SwiftUI

struct EventCardView: View {
    let event: TravelEvent
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            // Timeline indicator
            VStack {
                Circle()
                    .fill(colorForEventType(event.type))
                    .frame(width: 15, height: 15)
                Rectangle()
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 2, height: 60) // Adjust height as needed
            }
            
            // Event Card Content
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: event.type.symbolName)
                        .font(.headline)
                        .foregroundColor(colorForEventType(event.type))
                    Text(event.displayTitle)
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                Text(event.displayLocation)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text(timeFormatter.string(from: event.startTime))
                    if let endTime = event.endTime {
                        Text(" - \(timeFormatter.string(from: endTime))")
                    }
                }
                .font(.caption)
                .foregroundColor(.gray)
                
                // Add more specific details based on event.data type
                detailsSection(for: event.data)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(colorForEventType(event.type).opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(colorForEventType(event.type), lineWidth: 1)
            )
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func detailsSection(for dataType: ItineraryEventDataType) -> some View {
        switch dataType {
        case .flight(let flight):
            VStack(alignment: .leading) {
                Text("Flight No: \(flight.flightNumber)")
                Text("From: \(flight.departureAirport) (\(flight.departureTerminal ?? ""))")
                Text("To: \(flight.arrivalAirport) (\(flight.arrivalTerminal ?? ""))")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        case .hotel(let hotel):
            VStack(alignment: .leading) {
                Text("Nights: \(hotel.numberOfNights)")
                if let checkIn = hotel.checkInTime, let checkOut = hotel.checkOutTime {
                    Text("Check-in: \(timeFormatter.string(from: checkIn))")
                    Text("Check-out: \(timeFormatter.string(from: checkOut))")
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
        case .train(let train):
            VStack(alignment: .leading) {
                Text("Train No: \(train.trainNumber ?? "N/A")")
                Text("From: \(train.departureStation)")
                Text("To: \(train.arrivalStation)")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        case .car(let car):
            VStack(alignment: .leading) {
                Text("Pickup: \(car.origin)")
                Text("Dropoff: \(car.destination)")
                Text("Car: \(car.carBrand ?? "N/A") (\(car.carPlate ?? "N/A"))")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        case .other(let other):
            if let description = other.description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            // You could add more display for extraFields if needed
        }
    }
    
    private func colorForEventType(_ type: EventType) -> Color {
        switch type {
        case .flight: return .blue
        case .hotel: return .green
        case .train: return .orange
        case .car: return .purple
        case .dining: return .red
        case .activity: return .yellow
        case .transport: return .teal
        case .other: return .gray
        }
    }
}

#Preview {
    // Sample Flight Event
    let flightEvent = TravelEvent(
        id: UUID().uuidString,
        type: .flight,
        startTime: Date().addingTimeInterval(3600*2),
        endTime: Date().addingTimeInterval(3600*5),
        data: .flight(FlightData(
            airline: "AirSwift",
            brandDomain: nil,
            airlineCode: nil,
            flightNumber: "AS123",
            confirmationCode: "ABCDEF",
            passenger: nil,
            travelClass: nil,
            departureAirport: "JFK",
            departureCountry: nil,
            departureCountryCode: nil,
            departureTerminal: "4",
            departureGate: nil,
            checkInDesk: nil,
            seat: nil,
            aircraft: nil,
            aircraftRegistration: nil,
            departureTime: Date().addingTimeInterval(3600*2),
            arrivalAirport: "LAX",
            arrivalCountry: nil,
            arrivalCountryCode: nil,
            arrivalTerminal: nil,
            arrivalTime: Date().addingTimeInterval(3600*5),
            etkt: nil,
            fare: nil
        ))
    )
    
    // Sample Hotel Event
    let hotelEvent = TravelEvent(
        id: UUID().uuidString,
        type: .hotel,
        startTime: Date().addingTimeInterval(3600*6),
        endTime: Date().addingTimeInterval(3600*6 + 86400*2),
        data: .hotel(HotelData(
            hotelName: "Grand Hyatt",
            brandDomain: nil,
            address: "123 Main St, Anytown",
            checkInTime: Date().addingTimeInterval(3600*6),
            checkOutTime: Date().addingTimeInterval(3600*6 + 86400*2),
            bookingNumber: nil,
            confirmationNumber: nil,
            guestName: nil,
            roomType: nil,
            numberOfNights: "2 nights",
            fare: nil,
            isBreakfastIncluded: nil,
            extraIncluded: nil
        ))
    )

    // Fix: Remove explicit `return` in ViewBuilder
    VStack(spacing: 20) {
        EventCardView(event: flightEvent)
        EventCardView(event: hotelEvent)
    }
}
