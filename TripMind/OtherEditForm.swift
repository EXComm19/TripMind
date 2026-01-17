//
//  OtherEditForm.swift
//  TripMind
//
//  Created by EXC19 on 2026/1/18.
//

import SwiftUI

struct OtherEditForm: View {
    @Binding var otherData: OtherData
    @Binding var bookingSource: BookingSource?
    
    @State private var descText: String = ""
    @State private var locationText: String = ""
    @State private var timeText: String = ""
    
    // Booking Source
    @State private var bookingSourceName: String = ""
    @State private var bookingSourceDomain: String = ""
    
    // Fare
    @State private var fareCurrencyText: String = ""
    @State private var fareAmount: Double?

    var body: some View {
        Form {
            Section("Event Details") {
                TextField("Title", text: $otherData.title)
                
                TextField("Description", text: $descText, axis: .vertical)
                    .lineLimit(3...6)
                    .onChange(of: descText) { _, newValue in otherData.description = newValue.isEmpty ? nil : newValue }
                
                TextField("Location", text: $locationText)
                    .onChange(of: locationText) { _, newValue in otherData.location = newValue.isEmpty ? nil : newValue }
                
                TextField("Time (e.g. '14:00' or 'Afternoon')", text: $timeText)
                    .onChange(of: timeText) { _, newValue in otherData.time = newValue.isEmpty ? nil : newValue }
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
        descText = otherData.description ?? ""
        locationText = otherData.location ?? ""
        timeText = otherData.time ?? ""
        
        bookingSourceName = bookingSource?.name ?? ""
        bookingSourceDomain = bookingSource?.domain ?? ""
        
        fareCurrencyText = otherData.fare?.currency ?? ""
        fareAmount = otherData.fare?.amount
    }
    
    private func updateFare() {
        if fareCurrencyText.isEmpty && fareAmount == nil {
            otherData.fare = nil
        } else {
            otherData.fare = TravelFare(currency: fareCurrencyText, amount: fareAmount ?? 0.0)
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
