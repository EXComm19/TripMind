//
//  FlightEditForm.swift
//  TripMind
//
//  Created by EXC19 on 2026/1/18.
//

import SwiftUI

struct FlightEditForm: View {
    @Binding var flightData: FlightData
    @Binding var bookingSource: BookingSource?
    
    // Helper states for optional fields
    @State private var airlineCodeText: String = ""
    @State private var brandDomainText: String = ""
    @State private var aircraftRegText: String = ""
    @State private var depCountryCodeText: String = ""
    @State private var arrCountryCodeText: String = ""
    @State private var bookingSourceName: String = ""
    @State private var bookingSourceDomain: String = ""
    
    @State private var depCityText: String = ""
    @State private var arrCityText: String = ""
    
    @State private var fareCurrencyText: String = ""
    @State private var fareAmount: Double?
    
    var body: some View {
        Form {
            Section("Flight Information") {
                TextField("Airline Name", text: $flightData.airline)
                TextField("Flight Number", text: $flightData.flightNumber)
                TextField("Confirmation Code (PNR)", text: $flightData.confirmationCode)
            }
            
            Section("Passenger Details") {
                TextField("Passenger Name", text: Binding(
                    get: { flightData.passenger ?? "" },
                    set: { flightData.passenger = $0.isEmpty ? nil : $0 }
                ))
                TextField("Travel Class", text: Binding(
                    get: { flightData.travelClass ?? "" },
                    set: { flightData.travelClass = $0.isEmpty ? nil : $0 }
                ))
                TextField("Seat Assignment", text: Binding(
                    get: { flightData.seat ?? "" },
                    set: { flightData.seat = $0.isEmpty ? nil : $0 }
                ))
            }
            
            // MARK: - Baggage Management (Fixed)
            Section("Baggage") {
                // Safely access the array. Use 'indices' to create safe bindings.
                if let bags = flightData.baggage, !bags.isEmpty {
                    ForEach(bags.indices, id: \.self) { index in
                        // Ensure index is valid before rendering content
                        if index < (flightData.baggage?.count ?? 0) {
                            let bag = bags[index]
                            
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Bag \(index + 1)").font(.headline)
                                    Spacer()
                                    Button(role: .destructive) {
                                        deleteBag(at: index)
                                    } label: {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                }
                                
                                Picker("Type", selection: Binding(
                                    get: { flightData.baggage?[index].type ?? .checked },
                                    set: { flightData.baggage?[index].type = $0 }
                                )) {
                                    ForEach(BaggageType.allCases) { type in
                                        Text(type.rawValue).tag(type)
                                    }
                                }
                                .pickerStyle(.segmented)
                                
                                HStack {
                                    Text("Weight (kg)")
                                    Spacer()
                                    TextField("kg", value: Binding(
                                        get: { flightData.baggage?[index].weightKg },
                                        set: { flightData.baggage?[index].weightKg = $0 }
                                    ), format: .number)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 80)
                                }
                                
                                Toggle("LCC Mode (Size Constraints)", isOn: Binding(
                                    get: { flightData.baggage?[index].isLCCMode ?? false },
                                    set: { flightData.baggage?[index].isLCCMode = $0 }
                                ))
                                
                                if bag.isLCCMode {
                                    HStack(spacing: 12) {
                                        TextField("L", value: Binding(
                                            get: { flightData.baggage?[index].lengthCm },
                                            set: { flightData.baggage?[index].lengthCm = $0 }
                                        ), format: .number).keyboardType(.decimalPad)
                                        Text("x")
                                        TextField("W", value: Binding(
                                            get: { flightData.baggage?[index].widthCm },
                                            set: { flightData.baggage?[index].widthCm = $0 }
                                        ), format: .number).keyboardType(.decimalPad)
                                        Text("x")
                                        TextField("H", value: Binding(
                                            get: { flightData.baggage?[index].heightCm },
                                            set: { flightData.baggage?[index].heightCm = $0 }
                                        ), format: .number).keyboardType(.decimalPad)
                                        Text("cm")
                                    }
                                    .font(.caption)
                                    .textFieldStyle(.roundedBorder)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                } else {
                    Text("No baggage added")
                        .foregroundColor(.secondary)
                }
                
                Button("Add Bag") {
                    addBag()
                }
            }
            
            Section("Departure") {
                HStack {
                    Text("Airport Code")
                    Spacer()
                    TextField("SIN", text: $flightData.departureAirport).multilineTextAlignment(.trailing)
                }
                DatePicker("Time", selection: $flightData.departureTime)
                
                HStack {
                    TextField("Terminal", text: Binding(
                        get: { flightData.departureTerminal ?? "" },
                        set: { flightData.departureTerminal = $0.isEmpty ? nil : $0 }
                    ))
                    Divider()
                    TextField("Gate", text: Binding(
                        get: { flightData.departureGate ?? "" },
                        set: { flightData.departureGate = $0.isEmpty ? nil : $0 }
                    ))
                }
            }
            
            Section("Arrival") {
                HStack {
                    Text("Airport Code")
                    Spacer()
                    TextField("MEL", text: $flightData.arrivalAirport).multilineTextAlignment(.trailing)
                }
                DatePicker("Time", selection: $flightData.arrivalTime)
                
                TextField("Terminal", text: Binding(
                    get: { flightData.arrivalTerminal ?? "" },
                    set: { flightData.arrivalTerminal = $0.isEmpty ? nil : $0 }
                ))
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
            
            // MARK: - Admin / Technical Data
            Section(header: Text("System & Admin Data"), footer: Text("City names are displayed on the event card.")) {
                
                Group {
                    HStack {
                        Text("Dep City Name")
                        Spacer()
                        TextField("e.g. Osaka", text: $depCityText)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: depCityText) { _, newValue in
                                flightData.departureCity = newValue.isEmpty ? nil : newValue
                            }
                    }
                    
                    HStack {
                        Text("Arr City Name")
                        Spacer()
                        TextField("e.g. Guangzhou", text: $arrCityText)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: arrCityText) { _, newValue in
                                flightData.arrivalCity = newValue.isEmpty ? nil : newValue
                            }
                    }
                }
                
                Group {
                    HStack {
                        Text("Airline IATA")
                        Spacer()
                        TextField("e.g. SQ", text: $airlineCodeText)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: airlineCodeText) { _, val in flightData.airlineCode = val.isEmpty ? nil : val }
                    }
                    HStack {
                        Text("Brand Domain")
                        Spacer()
                        TextField("e.g. singaporeair.com", text: $brandDomainText)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .onChange(of: brandDomainText) { _, val in flightData.brandDomain = val.isEmpty ? nil : val }
                    }
                }
                
                Group {
                    HStack {
                        Text("Source Name")
                        Spacer()
                        TextField("e.g. Trip.com", text: $bookingSourceName)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: bookingSourceName) { _, _ in updateBookingSource() }
                    }
                    HStack {
                        Text("Source Domain")
                        Spacer()
                        TextField("e.g. trip.com", text: $bookingSourceDomain)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .onChange(of: bookingSourceDomain) { _, _ in updateBookingSource() }
                    }
                }
            }
        }
        .onAppear { initializeLocalState() }
    }
    
    // MARK: - Logic Helpers
    
    private func addBag() {
        withAnimation {
            // Atomic update to avoid binding race conditions
            var currentBags = flightData.baggage ?? []
            let newBag = BaggageItem(type: .checked, weightKg: 20, isLCCMode: false)
            currentBags.append(newBag)
            flightData.baggage = currentBags
        }
    }
    
    private func deleteBag(at index: Int) {
        withAnimation {
            var currentBags = flightData.baggage ?? []
            if currentBags.indices.contains(index) {
                currentBags.remove(at: index)
                flightData.baggage = currentBags.isEmpty ? nil : currentBags
            }
        }
    }
    
    private func initializeLocalState() {
        airlineCodeText = flightData.airlineCode ?? ""
        brandDomainText = flightData.brandDomain ?? ""
        aircraftRegText = flightData.aircraftRegistration ?? ""
        depCountryCodeText = flightData.departureCountryCode ?? ""
        arrCountryCodeText = flightData.arrivalCountryCode ?? ""
        
        depCityText = flightData.departureCity ?? ""
        arrCityText = flightData.arrivalCity ?? ""
        
        bookingSourceName = bookingSource?.name ?? ""
        bookingSourceDomain = bookingSource?.domain ?? ""
        fareCurrencyText = flightData.fare?.currency ?? ""
        fareAmount = flightData.fare?.amount
    }
    
    private func updateFare() {
        if fareCurrencyText.isEmpty && fareAmount == nil { flightData.fare = nil }
        else { flightData.fare = TravelFare(currency: fareCurrencyText, amount: fareAmount ?? 0.0) }
    }
    
    private func updateBookingSource() {
        if bookingSourceName.isEmpty && bookingSourceDomain.isEmpty { bookingSource = nil }
        else { bookingSource = BookingSource(name: bookingSourceName, domain: bookingSourceDomain, isOTA: bookingSource?.isOTA) }
    }
}
