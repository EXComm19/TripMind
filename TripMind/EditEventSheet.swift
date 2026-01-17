//
//  EditEventSheet.swift
//  TripMind
//
//  Created by EXC19 on 2026/1/18.
//

import SwiftUI

struct EditEventSheet: View {
    @Environment(\.dismiss) var dismiss
    
    @State var event: TravelEvent
    var onSave: (TravelEvent) -> Void
    
    var body: some View {
        NavigationView {
            Group {
                switch event.data {
                case .flight(let flightData):
                    FlightEditForm(
                        flightData: Binding(
                            get: { flightData },
                            set: { newData in event.data = .flight(newData) }
                        ),
                        bookingSource: $event.bookingSource
                    )
                case .hotel(let hotelData):
                    HotelEditForm(
                        hotelData: Binding(
                            get: { hotelData },
                            set: { newData in event.data = .hotel(newData) }
                        ),
                        bookingSource: $event.bookingSource
                    )
                case .train(let trainData):
                    TrainEditForm(
                        trainData: Binding(
                            get: { trainData },
                            set: { newData in event.data = .train(newData) }
                        ),
                        bookingSource: $event.bookingSource
                    )
                case .car(let carData):
                    CarEditForm(
                        carData: Binding(
                            get: { carData },
                            set: { newData in event.data = .car(newData) }
                        ),
                        bookingSource: $event.bookingSource
                    )
                case .other(let otherData):
                    OtherEditForm(
                        otherData: Binding(
                            get: { otherData },
                            set: { newData in event.data = .other(newData) }
                        ),
                        bookingSource: $event.bookingSource
                    )
                }
            }
            .navigationTitle("Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        syncTimes() // ✅ FIX: Update root times before saving
                        onSave(event)
                        dismiss()
                    }
                }
            }
        }
    }
    
    // ✅ Helper to keep root TravelEvent times in sync with edited Data
    private func syncTimes() {
        switch event.data {
        case .flight(let f):
            event.startTime = f.departureTime
            event.endTime = f.arrivalTime
        case .train(let t):
            event.startTime = t.departureTime
            event.endTime = t.arrivalTime
        case .car(let c):
            event.startTime = c.pickupTime
            // Car might not have end time, preserve existing if not set?
            // Usually car endTime is nil unless it's a rental duration.
        case .hotel(let h):
            if let start = h.checkInTime { event.startTime = start }
            if let end = h.checkOutTime { event.endTime = end }
        default:
            break
        }
    }
}
