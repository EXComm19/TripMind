//
//  TripListView.swift
//  TripMind
//
//  Created by EXC19 on 2026/1/16.
//

import SwiftUI

struct TripListView: View {
    // Use @EnvironmentObject to access the TripStore provided by TripMindApp
    @EnvironmentObject var tripStore: TripStore
    
    @State private var showingAddTripSheet = false
    @State private var newTripName = ""
    @State private var showDeleteConfirmation = false
    @State private var tripToDelete: Trip?
    
    var body: some View {
        List {
            if tripStore.trips.isEmpty {
                Text("No trips added yet. Tap '+' to create your first trip!")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ForEach(tripStore.trips) { trip in // Use the tripStore.trips array
                    // Pass the actual trip object to TripDetailView.
                    // When the trip in TripDetailView is modified, it updates its local state,
                    // then calls tripStore.updateTrip(self.trip), which then triggers the listener
                    // in TripStore to update all trips, including the one in TripDetailView via .onReceive.
                    NavigationLink(destination: TripDetailView(trip: trip)) {
                        TripRow(trip: trip)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            tripToDelete = trip
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .navigationTitle("My Trips")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                // EditButton functionality will be handled by swipe actions or can be customized
                // For now, removing EditButton as swipe actions provide a better UX
                EmptyView() // Remove default EditButton if not needed
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddTripSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddTripSheet) {
            AddTripSheet(isPresented: $showingAddTripSheet, newTripName: $newTripName) {
                // Action to add the new trip
                Task {
                    await addTrip()
                }
            }
        }
        .alert("Delete Trip", isPresented: $showDeleteConfirmation, presenting: tripToDelete) { trip in
            Button("Delete", role: .destructive) {
                Task {
                    await deleteTrip(trip: trip)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: { trip in
            Text("Are you sure you want to delete '\(trip.name)'? This action cannot be undone.")
        }
    }
    
    private func addTrip() async {
        guard !newTripName.isEmpty else { return }
        // The Trip initializer will generate a UUID string for `id` by default
        let newTrip = Trip(name: newTripName)
        do {
            try await tripStore.addTrip(newTrip)
            newTripName = "" // Reset for next time
        } catch {
            print("Failed to add trip: \(error.localizedDescription)")
            // TODO: Show user an alert or error message
        }
    }
    
    private func deleteTrip(trip: Trip) async {
        // `trip.id` is now directly the Firestore document ID (String)
        do {
            try await tripStore.deleteTrip(id: trip.id) // Pass String ID
        } catch {
            print("Failed to delete trip: \(error.localizedDescription)")
            // TODO: Show user an alert or error message
        }
    }
}

// MARK: - Helper Views for TripListView

struct TripRow: View {
    let trip: Trip
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(trip.name)
                    .font(.headline)
                if let startDate = trip.startDate, let endDate = trip.endDate {
                    Text("\(startDate.formatted(date: .abbreviated, time: .omitted)) - \(endDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                } else {
                    Text("No dates set")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            Spacer()
            // Optional: Show count of events
            Text("\(trip.events.count) events")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct AddTripSheet: View {
    @Binding var isPresented: Bool
    @Binding var newTripName: String
    var onAdd: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Trip Name", text: $newTripName)
            }
            .navigationTitle("New Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                        newTripName = "" // Clear input on cancel
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        onAdd()
                        isPresented = false
                    }
                    .disabled(newTripName.isEmpty)
                }
            }
        }
    }
}


#Preview {
    // For Preview, provide a mock TripStore
    NavigationView {
        TripListView()
            .environmentObject(TripStore()) // Provide a mock or actual TripStore for preview
    }
}
