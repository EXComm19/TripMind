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
    
    @State private var destinationText: String = ""
    @State private var driverText: String = ""
    @State private var passengerText: String = ""
    @State private var carPlateText: String = ""
    @State private var carColorText: String = ""
    @State private var carBrandText: String = ""
    
    // Booking Source
    @State private var bookingSourceName: String = ""
    @State private var bookingSourceDomain: String = ""
    
    // Fare
    @State private var fareCurrencyText: String = ""
    @State private var fareAmount: Double?

    var body: some View {
        Form {
            Section("Ride Details") {
                TextField("Pickup Location", text: $carData.origin)
                DatePicker("Pickup Time", selection: $carData.pickupTime)
                
                TextField("Destination (Optional)", text: $destinationText)
                    .onChange(of: destinationText) { _, newValue in carData.destination = newValue.isEmpty ? nil : newValue }
            }
            
            Section("Vehicle Info") {
                TextField("Brand (e.g. Tesla)", text: $carBrandText)
                    .onChange(of: carBrandText) { _, newValue in carData.carBrand = newValue.isEmpty ? nil : newValue }
                
                TextField("License Plate", text: $carPlateText)
                    .onChange(of: carPlateText) { _, newValue in carData.carPlate = newValue.isEmpty ? nil : newValue }
                
                TextField("Color", text: $carColorText)
                    .onChange(of: carColorText) { _, newValue in carData.carColor = newValue.isEmpty ? nil : newValue }
            }
            
            Section("People") {
                TextField("Driver Name", text: $driverText)
                    .onChange(of: driverText) { _, newValue in carData.driver = newValue.isEmpty ? nil : newValue }
                
                TextField("Passenger Name", text: $passengerText)
                    .onChange(of: passengerText) { _, newValue in carData.passenger = newValue.isEmpty ? nil : newValue }
            }
            
            Section("Fare") {
                HStack {
                    TextField("Currency", text: $fareCurrencyText)
                        .frame(width: 80)
                        .onChange(of: fareCurrencyText) { _, _ in updateFare() }
                    
                    TextField("Amount", value: $fareAmount, format: .number)
                        .keyboardType(.decimalPad)
                        .onChange(of: fareAmount) { _, _ in updateFare() }
                }
            }
            
            Section("System Data") {
                TextField("Source Name", text: $bookingSourceName)
                    .onChange(of: bookingSourceName) { _, _ in updateBookingSource() }
                TextField("Source Domain", text: $bookingSourceDomain)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .onChange(of: bookingSourceDomain) { _, _ in updateBookingSource() }
            }
        }
        .onAppear { initializeState() }
    }
    
    private func initializeState() {
        destinationText = carData.destination ?? ""
        driverText = carData.driver ?? ""
        passengerText = carData.passenger ?? ""
        carPlateText = carData.carPlate ?? ""
        carColorText = carData.carColor ?? ""
        carBrandText = carData.carBrand ?? ""
        
        bookingSourceName = bookingSource?.name ?? ""
        bookingSourceDomain = bookingSource?.domain ?? ""
        
        fareCurrencyText = carData.fare?.currency ?? ""
        fareAmount = carData.fare?.amount
    }
    
    private func updateFare() {
        if fareCurrencyText.isEmpty && fareAmount == nil {
            carData.fare = nil
        } else {
            carData.fare = TravelFare(currency: fareCurrencyText, amount: fareAmount ?? 0.0)
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
