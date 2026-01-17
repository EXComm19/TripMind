//
//  TrainEditForm.swift
//  TripMind
//
//  Created by EXC19 on 2026/1/18.
//

import SwiftUI

struct TrainEditForm: View {
    @Binding var trainData: TrainData
    @Binding var bookingSource: BookingSource?
    
    @State private var providerText: String = ""
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
                TextField("Service Provider (e.g. Amtrak)", text: $providerText)
                    .onChange(of: providerText) { _, newValue in trainData.serviceProvider = newValue.isEmpty ? nil : newValue }
                
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
        providerText = trainData.serviceProvider ?? ""
        trainNumText = trainData.trainNumber ?? ""
        passengerText = trainData.passenger ?? ""
        classText = trainData.travelClass ?? ""
        seatText = trainData.seat ?? ""
        gateText = trainData.departureGate ?? ""
        
        bookingSourceName = bookingSource?.name ?? ""
        bookingSourceDomain = bookingSource?.domain ?? ""
        
        fareCurrencyText = trainData.fare?.currency ?? ""
        fareAmount = trainData.fare?.amount
    }
    
    private func updateFare() {
        if fareCurrencyText.isEmpty && fareAmount == nil {
            trainData.fare = nil
        } else {
            trainData.fare = TravelFare(currency: fareCurrencyText, amount: fareAmount ?? 0.0)
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
