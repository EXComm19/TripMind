//
//  TripListView.swift
//  TripMind
//
//  Created by EXC19 on 2026/1/16.
//

import SwiftUI
import MapKit
import UniformTypeIdentifiers

// MARK: - Export Wrapper
struct TripDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var trip: Trip
    init(trip: Trip) { self.trip = trip }
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else { throw CocoaError(.fileReadCorruptFile) }
        self.trip = try JSONDecoder().decode(Trip.self, from: data)
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(trip)
        return FileWrapper(regularFileWithContents: data)
    }
}

struct TripListView: View {
    @EnvironmentObject var tripStore: TripStore
    @State private var showingAddTripSheet = false
    @State private var newTripName = ""
    
    // Map State
    @State private var position: MapCameraPosition = .automatic
    @State private var isGlobeMode = true
    
    // Import/Export State
    @State private var isImporting = false
    @State private var isExporting = false
    @State private var tripToExport: TripDocument?
    @State private var importError: String?
    
    // Edit State
    @State private var tripToEdit: Trip?
    @State private var editTripName: String = ""
    
    // Search State
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    
    // Drag State
    @State private var sheetHeight: CGFloat = 380
    @State private var dragOffset: CGFloat = 0
    
    var filteredTrips: [Trip] {
        if searchText.isEmpty {
            return tripStore.trips
        } else {
            return tripStore.trips.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                // ✅ UPDATED: Default Safe Area Top to 60 (pushes controls down)
                let safeAreaTop = max(geometry.safeAreaInsets.top, 60)
                let screenHeight = geometry.size.height
                
                ZStack(alignment: .top) {
                    
                    // MARK: - Layer 1: Full Screen Map
                    Map(position: $position) {
                        ForEach(tripStore.trips) { trip in
                            ForEach(trip.events) { event in
                                if isJourney(event.type),
                                   let start = event.geoCoordinates,
                                   let end = event.destinationGeoCoordinates {
                                    
                                    MapPolyline(coordinates: [
                                        CLLocationCoordinate2D(latitude: start.lat, longitude: start.lng),
                                        CLLocationCoordinate2D(latitude: end.lat, longitude: end.lng)
                                    ])
                                    .stroke(eventTypeColor(event.type), lineWidth: 3)
                                    .mapOverlayLevel(level: .aboveLabels)
                                    
                                    MapCircle(center: CLLocationCoordinate2D(latitude: start.lat, longitude: start.lng), radius: 5000)
                                        .foregroundStyle(eventTypeColor(event.type).opacity(0.6))
                                    MapCircle(center: CLLocationCoordinate2D(latitude: end.lat, longitude: end.lng), radius: 5000)
                                        .foregroundStyle(eventTypeColor(event.type))
                                } else if !isJourney(event.type), let geo = event.geoCoordinates {
                                    Marker(event.displayTitle, systemImage: event.type.symbolName, coordinate: CLLocationCoordinate2D(latitude: geo.lat, longitude: geo.lng))
                                        .tint(eventTypeColor(event.type))
                                }
                            }
                        }
                    }
                    .mapStyle(isGlobeMode ? .hybrid(elevation: .realistic) : .standard)
                    .ignoresSafeArea()
                    .onTapGesture { isSearchFocused = false }
                    
                    // MARK: - Layer 2: Top Floating Controls
                    VStack {
                        HStack {
                            Button { withAnimation { isGlobeMode.toggle() } } label: {
                                Image(systemName: isGlobeMode ? "map.fill" : "globe.americas.fill")
                                    .font(.title3)
                                    .foregroundColor(.primary)
                                    .padding(12)
                                    .background(.thinMaterial)
                                    .clipShape(Circle())
                                    .shadow(radius: 4)
                            }
                            Spacer()
                            Menu {
                                Button { isImporting = true } label: { Label("Import JSON File", systemImage: "arrow.down.doc") }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "square.and.arrow.down")
                                    Text("Import").fontWeight(.medium)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(.thinMaterial)
                                .clipShape(Capsule())
                                .shadow(radius: 4)
                                .foregroundColor(.primary)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, safeAreaTop + 10)
                        
                        if let error = importError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.red.opacity(0.8))
                                .cornerRadius(8)
                        }
                        Spacer()
                    }
                    .allowsHitTesting(!isSearchFocused)
                    
                    // MARK: - Layer 3: Floating Bottom Sheet
                    VStack {
                        Spacer()
                        
                        VStack(spacing: 0) {
                            
                            // --- HEADER ---
                            VStack(spacing: 0) {
                                Capsule()
                                    .frame(width: 40, height: 5)
                                    .foregroundColor(.secondary.opacity(0.4))
                                    .padding(.top, 12)
                                    .padding(.bottom, 12)
                                
                                // Title Row
                                HStack {
                                    Text("My Trips")
                                        .font(.system(size: 28, weight: .bold))
                                    Spacer()
                                    Button { showingAddTripSheet = true } label: {
                                        Image(systemName: "plus")
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundColor(.white)
                                            .frame(width: 36, height: 36)
                                            .background(Color.blue)
                                            .clipShape(Circle())
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 12)
                                
                                // Search Bar
                                HStack(spacing: 10) {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundColor(.secondary)
                                    TextField("Search my trips...", text: $searchText)
                                        .textFieldStyle(.plain)
                                        .focused($isSearchFocused)
                                    
                                    if !searchText.isEmpty {
                                        Button { searchText = "" } label: {
                                            Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                                        }
                                    }
                                }
                                .padding(12)
                                .background(Color(UIColor.tertiarySystemFill))
                                .cornerRadius(12)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 10)
                            }
                            .background(Color.clear)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(coordinateSpace: .global)
                                    .onChanged { value in
                                        dragOffset = -value.translation.height
                                    }
                                    .onEnded { value in
                                        let verticalMove = -value.translation.height
                                        let velocity = -value.predictedEndTranslation.height
                                        
                                        let minHeight = screenHeight / 3.0
                                        let midHeight = screenHeight * 0.60
                                        let maxHeight = screenHeight - safeAreaTop - 8
                                        
                                        let snapPoints = [minHeight, midHeight, maxHeight]
                                        let currentSnapIndex = snapPoints.firstIndex(where: { abs($0 - sheetHeight) < 20 }) ?? 1
                                        var targetHeight = sheetHeight
                                        
                                        if verticalMove > 50 || velocity > 200 {
                                            targetHeight = (currentSnapIndex < 2) ? snapPoints[currentSnapIndex + 1] : maxHeight
                                        } else if verticalMove < -50 || velocity < -200 {
                                            targetHeight = (currentSnapIndex > 0) ? snapPoints[currentSnapIndex - 1] : minHeight
                                        } else {
                                            let visualHeight = sheetHeight + verticalMove
                                            targetHeight = snapPoints.min(by: { abs($0 - visualHeight) < abs($1 - visualHeight) }) ?? midHeight
                                        }
                                        
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                            sheetHeight = targetHeight
                                            dragOffset = 0
                                        }
                                    }
                            )
                            
                            // --- LIST CONTENT ---
                            List {
                                ForEach(filteredTrips) { trip in
                                    ZStack {
                                        NavigationLink(destination: TripDetailView(trip: trip)) { EmptyView() }.opacity(0)
                                        TripListRow(trip: trip)
                                    }
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                                    .swipeActions(edge: .leading) {
                                        Button {
                                            tripToExport = TripDocument(trip: trip)
                                            isExporting = true
                                        } label: { Label("Export", systemImage: "square.and.arrow.up") }
                                        .tint(.blue)
                                        
                                        Button {
                                            tripToEdit = trip
                                            editTripName = trip.name
                                        } label: { Label("Edit", systemImage: "pencil") }
                                        .tint(.orange)
                                    }
                                    .contextMenu {
                                        Button {
                                            tripToExport = TripDocument(trip: trip)
                                            isExporting = true
                                        } label: { Label("Export JSON", systemImage: "square.and.arrow.up") }
                                        
                                        Button {
                                            tripToEdit = trip
                                            editTripName = trip.name
                                        } label: { Label("Edit", systemImage: "pencil") }
                                        
                                        Button(role: .destructive) {
                                            Task { try? await tripStore.deleteTrip(id: trip.id) }
                                        } label: { Label("Delete", systemImage: "trash") }
                                    }
                                }
                                .onDelete(perform: deleteTrip)
                            }
                            .listStyle(.plain)
                            .scrollContentBackground(.hidden)
                        }
                        .frame(height: max(120, sheetHeight + dragOffset))
                        
                        // ✅ IOS 26 LIQUID GLASS EFFECT
                        .background(LiquidGlassView())
                        
                        .clipShape(
                            UnevenRoundedRectangle(
                                topLeadingRadius: 40,
                                bottomLeadingRadius: 59,
                                bottomTrailingRadius: 59,
                                topTrailingRadius: 40
                            )
                        )
                        .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 5)
                        .padding(.horizontal, 8)
                        .padding(.bottom, 8)
                    }
                }
            }
            .ignoresSafeArea()
            
            // Handlers
            .fileImporter(isPresented: $isImporting, allowedContentTypes: [.json]) { result in
                switch result {
                case .success(let url): importTrip(from: url)
                case .failure(let error): importError = "Import failed: \(error.localizedDescription)"
                }
            }
            .fileExporter(isPresented: $isExporting, document: tripToExport, contentType: .json, defaultFilename: "Trip_Export") { _ in }
            .sheet(isPresented: $showingAddTripSheet) {
                NavigationStack {
                    Form { TextField("Trip Name", text: $newTripName) }
                    .navigationTitle("New Trip")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingAddTripSheet = false } }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Create") { addNewTrip(); showingAddTripSheet = false }
                            .disabled(newTripName.isEmpty)
                        }
                    }
                }
                .presentationDetents([.height(200)])

            }
            .sheet(item: $tripToEdit) { trip in
                NavigationStack {
                    Form {
                        TextField("Trip Name", text: $editTripName)
                    }
                    .navigationTitle("Edit Trip")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) { Button("Cancel") { tripToEdit = nil } }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                var updatedTrip = trip
                                updatedTrip.name = editTripName
                                Task { try? await tripStore.updateTrip(updatedTrip) }
                                tripToEdit = nil
                            }
                            .disabled(editTripName.isEmpty)
                        }
                    }
                }
                .presentationDetents([.height(200)])
            }
        }
    }
    
    // MARK: - Logic
    
    private func isJourney(_ type: EventType) -> Bool {
        return type == .flight || type == .train || type == .car || type == .transport
    }
    
    private func addNewTrip() {
        let newTrip = Trip(name: newTripName)
        Task { try? await tripStore.addTrip(newTrip) }
        newTripName = ""
    }
    
    private func deleteTrip(at offsets: IndexSet) {
        offsets.forEach { index in
            if index < filteredTrips.count {
                let trip = filteredTrips[index]
                Task { try? await tripStore.deleteTrip(id: trip.id) }
            }
        }
    }
    
    private func importTrip(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        do {
            let data = try Data(contentsOf: url)
            var trip = try JSONDecoder().decode(Trip.self, from: data)
            trip.id = UUID().uuidString
            let finalTrip = trip
            Task { try await tripStore.addTrip(finalTrip) }
        } catch {
            importError = "Error: \(error.localizedDescription)"
        }
    }
    
    private func eventTypeColor(_ type: EventType) -> Color {
        switch type {
        case .flight: return .blue
        case .train: return .orange
        case .car: return .green
        case .hotel: return .purple
        default: return .gray
        }
    }
}

// MARK: - Liquid Glass Effect
// Updated to be more "Liquid" with a brighter top reflection
struct LiquidGlassView: View {
    var body: some View {
        ZStack {
            // 1. Ultra Thin Material Base
            Rectangle()
                .fill(.ultraThinMaterial)
            
            // 2. Liquid Gradient Overlay
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.3),  // Brighter top highlight
                    Color.white.opacity(0.1),
                    Color.white.opacity(0.0),
                    Color.white.opacity(0.05)  // Subtle bottom edge
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blendMode(.overlay)
            
            // 3. Subtle Border for glass edge
            RoundedRectangle(cornerRadius: 0) // Radius handled by parent clipShape
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.4), .clear, .white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }
}

// MARK: - List Row
struct TripListRow: View {
    let trip: Trip
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(trip.name).font(.headline).foregroundColor(.primary)
                if let start = trip.startDate, let end = trip.endDate {
                    Text("\(start.formatted(date: .abbreviated, time: .omitted)) - \(end.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption).foregroundColor(.secondary)
                } else {
                    Text("No dates set").font(.caption).foregroundColor(.secondary.opacity(0.7))
                }
            }
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "mappin.and.ellipse").font(.caption2)
                Text("\(trip.events.count)").font(.caption).fontWeight(.bold)
            }
            .padding(.vertical, 6).padding(.horizontal, 10)
            .background(Color.gray.opacity(0.15)).cornerRadius(8)
            .foregroundColor(.secondary)
        }
        .padding(16)
        .background(
            LiquidGlassView().opacity(0.6)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        )
    }
}
