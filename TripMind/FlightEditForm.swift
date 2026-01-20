//
//  FlightEditForm.swift
//  TripMind
//
//  Created by EXC19 on 2026/1/18.
//

import SwiftUI

struct FlightEditForm: View {
    @Binding var flightData: FlightData
    
    @State private var airlineCodeText: String = ""
    @State private var brandDomainText: String = ""
    @State private var depCityText: String = ""
    @State private var arrCityText: String = ""
    
    @State private var bookingSourceName: String = ""
    @State private var bookingSourceDomain: String = ""
    
    @State private var fareCurrencyText: String = ""
    @State private var fareAmount: Double?
    
    
    var body: some View {
        Form {
            Section("Flight Information") {
                TextField("Airline Name", text: $flightData.airline)
                TextField("Flight Number", text: $flightData.flightNumber)
                TextField("Confirmation Code", text: $flightData.confirmationCode)
            }
            
            Section("Passenger") {
                TextField("Name", text: Binding(
                    get: { flightData.passenger ?? "" },
                    set: { flightData.passenger = $0.isEmpty ? nil : $0 }
                ))
                TextField("Seat", text: Binding(
                    get: { flightData.seat ?? "" },
                    set: { flightData.seat = $0.isEmpty ? nil : $0 }
                ))
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
                // ✅ UPDATED: Edit Check-in Counter
                TextField("Check-in Counter", text: Binding(
                    get: { flightData.checkInCounter ?? "" },
                    set: { flightData.checkInCounter = $0.isEmpty ? nil : $0 }
                ))
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
            
            Section(header: Text("City & System Data")) {
                TextField("Dep City", text: $depCityText)
                    .onChange(of: depCityText) { _, val in flightData.departureCity = val.isEmpty ? nil : val }
                
                TextField("Arr City", text: $arrCityText)
                    .onChange(of: arrCityText) { _, val in flightData.arrivalCity = val.isEmpty ? nil : val }
                
                TextField("Airline Code (IATA)", text: $airlineCodeText)
                    .onChange(of: airlineCodeText) { _, val in flightData.airlineCode = val.isEmpty ? nil : val }
                
                TextField("Brand Domain", text: $brandDomainText)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .onChange(of: brandDomainText) { _, val in flightData.brandDomain = val.isEmpty ? nil : val }
                TextField("Source Name", text: $bookingSourceName)
                    .onChange(of: bookingSourceName) { _, val in flightData.bookingSource?.name = val.isEmpty ? nil : val }
                TextField("Source Domain", text: $bookingSourceDomain)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .onChange(of: bookingSourceDomain) { _, val in flightData.bookingSource?.domain = val.isEmpty ? nil : val }
            }
        }
        .onAppear { initializeLocalState() }
    }
    
    private func initializeLocalState() {
        airlineCodeText = flightData.airlineCode ?? ""
        brandDomainText = flightData.brandDomain ?? ""
        depCityText = flightData.departureCity ?? ""
        arrCityText = flightData.arrivalCity ?? ""
        bookingSourceName = flightData.bookingSource?.name ?? ""
        bookingSourceDomain = flightData.bookingSource?.domain ?? ""
    }
}
