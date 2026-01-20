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
    var onDelete: () -> Void
    var onSave: (TravelEvent) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Group {
                    switch event.data {
                    case .flight(let flightData):
                        FlightEditForm(
                            flightData: Binding(
                                get: { flightData },
                                set: { newData in event.data = .flight(newData) }
                            )
                        )
                    case .hotel(let hotelData):
                        HotelEditForm(
                            hotelData: Binding(
                                get: { hotelData },
                                set: { newData in event.data = .hotel(newData) }
                            )
                        )
                    case .train(let trainData):
                        TrainEditForm(
                            trainData: Binding(
                                get: { trainData },
                                set: { newData in event.data = .train(newData) }
                            )
                        )
                    case .car(let carData):
                        CarEditForm(
                            carData: Binding(
                                get: { carData },
                                set: { newData in event.data = .car(newData) }
                            )
                        )
                    case .other(let otherData):
                        OtherEditForm(
                            otherData: Binding(
                                get: { otherData },
                                set: { newData in event.data = .other(newData) }
                            )
                        )
                    }
                }
            }
            .navigationTitle("Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        syncTimes()
                        onSave(event)
                        dismiss()
                    }
                }
            }
        }
    }
    
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
        case .hotel(let h):
            if let start = h.checkInTime { event.startTime = start }
            if let end = h.checkOutTime { event.endTime = end }
        default: break
        }
    }
}
