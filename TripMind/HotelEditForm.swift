//
//  HotelEditForm.swift
//  TripMind
//
//  Created by EXC19 on 2026/1/18.
//

import SwiftUI

struct HotelEditForm: View {
    @Binding var hotelData: HotelData
    
    // Local states for optionals
    @State private var bookingNumberText: String = ""
    @State private var confirmationNumberText: String = ""
    @State private var guestNameText: String = ""
    @State private var roomTypeText: String = ""
    @State private var brandDomainText: String = ""
    @State private var extraIncludedText: String = ""
    
    // Booking Source
    @State private var bookingSourceName: String = ""
    @State private var bookingSourceDomain: String = ""
    
    // Fare
    @State private var fareCurrencyText: String = ""
    @State private var fareAmount: Double?
    
    // Breakfast (Tristate logic: true, false, or nil)
    @State private var hasBreakfast: Bool = false
    
    var body: some View {
        Form {
            Section("Hotel Details") {
                TextField("Hotel Name", text: $hotelData.hotelName)
                TextField("Address", text: $hotelData.address)
                
                TextField("Booking Number", text: $bookingNumberText)
                    .onChange(of: bookingNumberText) { _, newValue in hotelData.bookingNumber = newValue.isEmpty ? nil : newValue }
                
                TextField("Confirmation Number", text: $confirmationNumberText)
                    .onChange(of: confirmationNumberText) { _, newValue in hotelData.confirmationNumber = newValue.isEmpty ? nil : newValue }
            }
            
            Section("Stay Details") {
                // Safely handle optional dates
                if let checkIn = hotelData.checkInTime {
                    DatePicker("Check-in", selection: Binding(
                        get: { checkIn },
                        set: { hotelData.checkInTime = $0 }
                    ))
                } else {
                    Button("Add Check-in Time") { hotelData.checkInTime = Date() }
                }
                
                if let checkOut = hotelData.checkOutTime {
                    DatePicker("Check-out", selection: Binding(
                        get: { checkOut },
                        set: { hotelData.checkOutTime = $0 }
                    ))
                } else {
                    Button("Add Check-out Time") { hotelData.checkOutTime = Date() }
                }
                
                TextField("Nights (e.g. '3 nights')", text: $hotelData.numberOfNights)
            }
            
            Section("Room & Guest") {
                TextField("Guest Name", text: $guestNameText)
                    .onChange(of: guestNameText) { _, newValue in hotelData.guestName = newValue.isEmpty ? nil : newValue }
                
                TextField("Room Type", text: $roomTypeText)
                    .onChange(of: roomTypeText) { _, newValue in hotelData.roomType = newValue.isEmpty ? nil : newValue }
                
                Toggle("Breakfast Included", isOn: $hasBreakfast)
                    .onChange(of: hasBreakfast) { _, newValue in hotelData.isBreakfastIncluded = newValue }
                
                TextField("Extras (e.g. Spa, Parking)", text: $extraIncludedText)
                    .onChange(of: extraIncludedText) { _, newValue in hotelData.extraIncluded = newValue.isEmpty ? nil : newValue }
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
            
            Section(header: Text("System Data")) {
                TextField("Brand Domain", text: $brandDomainText)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .onChange(of: brandDomainText) { _, newValue in hotelData.brandDomain = newValue.isEmpty ? nil : newValue }
                
                TextField("Source Name", text: $bookingSourceName)
                                    .onChange(of: bookingSourceName) { _, val in
                                        updateBookingSource(name: val, domain: bookingSourceDomain)
                                    }
                                
                                TextField("Source Domain", text: $bookingSourceDomain)
                                    .keyboardType(.URL)
                                    .autocapitalization(.none)
                                    .onChange(of: bookingSourceDomain) { _, val in
                                        updateBookingSource(name: bookingSourceName, domain: val)
                                    }
            }
        }
        .onAppear { initializeState() }
    }
    
    private func initializeState() {
        bookingNumberText = hotelData.bookingNumber ?? ""
        confirmationNumberText = hotelData.confirmationNumber ?? ""
        guestNameText = hotelData.guestName ?? ""
        roomTypeText = hotelData.roomType ?? ""
        brandDomainText = hotelData.brandDomain ?? ""
        extraIncludedText = hotelData.extraIncluded ?? ""
        hasBreakfast = hotelData.isBreakfastIncluded ?? false
        
        bookingSourceName = hotelData.bookingSource?.name ?? ""
        bookingSourceDomain = hotelData.bookingSource?.domain ?? ""
        
        fareCurrencyText = hotelData.fare?.currency ?? ""
        fareAmount = hotelData.fare?.amount
    }
    
    private func updateFare() {
        if fareCurrencyText.isEmpty && fareAmount == nil {
            hotelData.fare = nil
        } else {
            hotelData.fare = TravelFare(currency: fareCurrencyText, amount: fareAmount ?? 0.0)
        }
    }
    
    private func updateBookingSource(name: String, domain: String) {
            if name.isEmpty && domain.isEmpty {
                hotelData.bookingSource = nil
                return
            }
            if hotelData.bookingSource == nil {
                hotelData.bookingSource = BookingSource(name: nil, domain: nil, isOTA: nil)
            }
            hotelData.bookingSource?.name = name.isEmpty ? nil : name
            hotelData.bookingSource?.domain = domain.isEmpty ? nil : domain
        }
}

