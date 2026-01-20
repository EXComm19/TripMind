//
//  TrainEditForm.swift
//  TripMind
//
//  Created by EXC19 on 2026/1/18.
//

import SwiftUI

struct TrainEditForm: View {
    @Binding var trainData: TrainData
    // Removed the separate bookingSource binding to avoid "Source of Truth" conflicts.
    // We can access it directly through trainData.bookingSource
    
    @State private var trainOpText: String = ""
    @State private var OpDomainText: String = ""
    @State private var trainNumText: String = ""
    @State private var passengerText: String = ""
    @State private var classText: String = ""
    @State private var seatText: String = ""
    @State private var gateText: String = ""
    
    // Booking Source
    @State private var bookingSourceName: String = ""
    @State private var bookingSourceDomain: String = ""
    
    // Fare
    @State private var fareCurrencyText: String = ""
    @State private var fareAmount: Double?

    var body: some View {
        Form {
            Section("Train Details") {
                TextField("Service Provider (e.g. Amtrak)", text: $trainOpText)
                    .onChange(of: trainOpText) { _, newValue in trainData.trainOperator = newValue.isEmpty ? nil : newValue }
               
                TextField("Train Number", text: $trainNumText)
                    .onChange(of: trainNumText) { _, newValue in trainData.trainNumber = newValue.isEmpty ? nil : newValue }
               
                TextField("Passenger", text: $passengerText)
                    .onChange(of: passengerText) { _, newValue in trainData.passenger = newValue.isEmpty ? nil : newValue }
               
                TextField("Class", text: $classText)
                    .onChange(of: classText) { _, newValue in trainData.travelClass = newValue.isEmpty ? nil : newValue }
            }
           
            Section("Journey") {
                VStack(alignment: .leading) {
                    Text("Departure Station").font(.caption).foregroundColor(.secondary)
                    TextField("Station Name", text: $trainData.departureStation)
                    DatePicker("Time", selection: $trainData.departureTime)
                }
               
                VStack(alignment: .leading) {
                    Text("Arrival Station").font(.caption).foregroundColor(.secondary)
                    TextField("Station Name", text: $trainData.arrivalStation)
                    DatePicker("Time", selection: $trainData.arrivalTime)
                }
            }
           
            Section("Seat & Gate") {
                TextField("Car/Seat", text: $seatText)
                    .onChange(of: seatText) { _, newValue in trainData.seat = newValue.isEmpty ? nil : newValue }
               
                TextField("Platform/Gate", text: $gateText)
                    .onChange(of: gateText) { _, newValue in trainData.departureGate = newValue.isEmpty ? nil : newValue }
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
                TextField("Operator Domain", text: $OpDomainText)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .onChange(of: OpDomainText) { _, newValue in
                        trainData.brandDomain = newValue.isEmpty ? nil : newValue
                    }
                
                TextField("Source Name", text: $bookingSourceName)
                    .onChange(of: bookingSourceName) { _, newValue in
                        trainData.bookingSource?.name = newValue.isEmpty ? nil : newValue
                    }
                
                TextField("Source Domain", text: $bookingSourceDomain)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .onChange(of: bookingSourceDomain) { _, newValue in
                        trainData.bookingSource?.domain = newValue.isEmpty ? nil : newValue
                    }
            }
        }
        .onAppear { initializeState() }
    }
    
    private func initializeState() {
        trainOpText = trainData.trainOperator ?? ""
        trainNumText = trainData.trainNumber ?? ""
        passengerText = trainData.passenger ?? ""
        classText = trainData.travelClass ?? ""
        seatText = trainData.seat ?? ""
        gateText = trainData.departureGate ?? ""
        
        // Load directly from trainData to ensure consistency
        bookingSourceName = trainData.bookingSource?.name ?? ""
        bookingSourceDomain = trainData.bookingSource?.domain ?? ""
        OpDomainText = trainData.brandDomain ?? "" // Ensure this loads too
        
        fareCurrencyText = trainData.fare?.currency ?? ""
        fareAmount = trainData.fare?.amount
    }
    
    private func updateFare() {
        if fareCurrencyText.isEmpty && fareAmount == nil {
            trainData.fare = nil
        } else {
            // Default currency to current locale if empty, or keep user input
            let currency = fareCurrencyText.isEmpty ? Locale.current.currency?.identifier ?? "USD" : fareCurrencyText
            trainData.fare = TravelFare(currency: currency, amount: fareAmount ?? 0.0)
        }
    }
    
    // MARK: - Safe Booking Source Update
    private func updateBookingSource(name: String, domain: String) {
        // 1. If both are empty, remove the object entirely to keep data clean
        if name.isEmpty && domain.isEmpty {
            trainData.bookingSource = nil
            return
        }
        
        // 2. If the object is currently nil, CREATE it first
        if trainData.bookingSource == nil {
            trainData.bookingSource = BookingSource(name: nil, domain: nil, isOTA: nil)
        }
        
        // 3. Now it is safe to assign values
        trainData.bookingSource?.name = name.isEmpty ? nil : name
        trainData.bookingSource?.domain = domain.isEmpty ? nil : domain
    }
}
