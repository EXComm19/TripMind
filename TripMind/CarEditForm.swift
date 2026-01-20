//
//  CarEditForm.swift
//  TripMind
//
//  Created by EXC19 on 2026/1/18.
//

import SwiftUI

struct CarEditForm: View {
    @Binding var carData: CarData
    
    // Local state for optional fields
    @State private var pickupTime: Date = Date()
    @State private var bookingSourceName: String = ""
    @State private var bookingSourceDomain: String = ""
    
    var body: some View {
        Form {
            Section("Service Details") {
                
                TextField("Service Provider", text: Binding(
                    get: { carData.serviceProvider ?? "" },
                    set: { carData.serviceProvider = $0.isEmpty ? nil : $0 }
                ))
                
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
            
            Section("System Data") {
                TextField("Service Provider Domain", text: Binding(
                    get: { carData.brandDomain ?? "" },
                    set: { carData.brandDomain = $0.isEmpty ? nil : $0 }
                ))
                TextField("Source Name", text: $bookingSourceName)
                    .onChange(of: bookingSourceName) { _, newValue in
                        carData.bookingSource?.name = newValue.isEmpty ? nil : newValue
                    }
                
                TextField("Source Domain", text: $bookingSourceDomain)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .onChange(of: bookingSourceDomain) { _, newValue in
                        carData.bookingSource?.domain = newValue.isEmpty ? nil : newValue
                    }
            }
        }
        .onAppear {
            bookingSourceName = carData.bookingSource?.name ?? ""
            bookingSourceDomain = carData.bookingSource?.domain ?? ""
        }
    }
    
    private func updateBookingSource(name: String, domain: String) {
            if name.isEmpty && domain.isEmpty {
                carData.bookingSource = nil
                return
            }
            if carData.bookingSource == nil {
                carData.bookingSource = BookingSource(name: nil, domain: nil, isOTA: nil)
            }
            carData.bookingSource?.name = name.isEmpty ? nil : name
            carData.bookingSource?.domain = domain.isEmpty ? nil : domain
        }
}
