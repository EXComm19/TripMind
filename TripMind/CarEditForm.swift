//
//  CarEditForm.swift
//  TripMind
//
//  Created by EXC19 on 2026/1/18.
//

import SwiftUI

struct CarEditForm: View {
    @Binding var carData: CarData
    @Binding var bookingSource: BookingSource?
    
    // Local state for optional fields
    @State private var pickupTime: Date = Date()
    @State private var bookingSourceName: String = ""
    @State private var bookingSourceDomain: String = ""
    
    var body: some View {
        Form {
            Section("Service Provider") {
                TextField("Provider Name (e.g. DragonPass)", text: $bookingSourceName)
                    .onChange(of: bookingSourceName) { _, _ in updateBookingSource() }
                
                TextField("Domain (e.g. dragonpass.com)", text: $bookingSourceDomain)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .onChange(of: bookingSourceDomain) { _, _ in updateBookingSource() }
            }
            
            Section("Service Details") {
                // ✅ ADDED: Service Type
                TextField("Service Type (e.g. Airport Pickup)", text: Binding(
                    get: { carData.serviceType ?? "" },
                    set: { carData.serviceType = $0.isEmpty ? nil : $0 }
                ))
                
                DatePicker("Pickup Time", selection: $carData.pickupTime)
            }
            
            Section("Route") {
                TextField("Origin", text: $carData.origin)
                TextField("Destination", text: Binding(
                    get: { carData.destination ?? "" },
                    set: { carData.destination = $0.isEmpty ? nil : $0 }
                ))
            }
            
            Section("Vehicle Information") {
                TextField("Plate Number", text: Binding(
                    get: { carData.carPlate ?? "" },
                    set: { carData.carPlate = $0.isEmpty ? nil : $0 }
                ))
                
                TextField("Car Brand/Model", text: Binding(
                    get: { carData.carBrand ?? "" },
                    set: { carData.carBrand = $0.isEmpty ? nil : $0 }
                ))
                
                TextField("Car Color", text: Binding(
                    get: { carData.carColor ?? "" },
                    set: { carData.carColor = $0.isEmpty ? nil : $0 }
                ))
            }
            
            Section("Driver Info") {
                TextField("Driver Name", text: Binding(
                    get: { carData.driver ?? "" },
                    set: { carData.driver = $0.isEmpty ? nil : $0 }
                ))
            }
        }
        .onAppear {
            bookingSourceName = bookingSource?.name ?? ""
            bookingSourceDomain = bookingSource?.domain ?? ""
        }
    }
    
    private func updateBookingSource() {
        if bookingSourceName.isEmpty && bookingSourceDomain.isEmpty {
            bookingSource = nil
        } else {
            bookingSource = BookingSource(name: bookingSourceName, domain: bookingSourceDomain, isOTA: bookingSource?.isOTA)
        }
    }
}
