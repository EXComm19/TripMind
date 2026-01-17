//
//  TripDetailView.swift
//  TripMind
//
//  Created by EXC19 on 2026/1/18.
//

import SwiftUI
import MapKit

// MARK: - Main View
struct TripDetailView: View {
    let trip: Trip
    @State private var mapCameraPosition: MapCameraPosition = .automatic
    
    // Processed timeline data
    private var timelineDays: [TripTimelineProvider.DaySchedule] {
        TripTimelineProvider.processTimeline(events: trip.events)
    }
    
    // Processed map routes with curves
    private var routedPolylines: [MapCurveProvider.RoutedPolyline] {
        MapCurveProvider.generateCurves(for: trip.events)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // MARK: Header Map
                Map(position: $mapCameraPosition) {
                    // Draw curved route lines
                    ForEach(routedPolylines) { route in
                        MapPolyline(coordinates: route.coordinates)
                            .stroke(route.color, lineWidth: 3)
                    }
                    
                    // Draw markers
                    ForEach(trip.events.compactMap { $0.geoCoordinates != nil ? $0 : nil }) { event in
                        let coord = CLLocationCoordinate2D(latitude: event.geoCoordinates!.lat, longitude: event.geoCoordinates!.lng)
                        Marker(event.displayTitle, systemImage: event.type.symbolName, coordinate: coord)
                            .tint(eventTypeColor(event.type))
                    }
                }
                .frame(height: 300)
                .mapStyle(.standard(elevation: .realistic))
                
                // MARK: Timeline Content
                LazyVStack(spacing: 25, pinnedViews: []) {
                    ForEach(timelineDays) { daySchedule in
                        VStack(alignment: .leading, spacing: 15) {
                            // --- Main Date Header per Day ---
                            Text(daySchedule.date.formatted(date: .complete, time: .omitted))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                                .padding(.horizontal)
                                .padding(.top, 10)
                            
                            // --- Timeline Items for this Day ---
                            VStack(spacing: 0) {
                                ForEach(daySchedule.items) { item in
                                    switch item.content {
                                    case .event(let event):
                                        EventRowView(event: event, showDateHeader: false)
                                            .padding(.bottom, 4) // Small gap between cards
                                        
                                    case .connection(let duration, let airportMsg):
                                        ConnectionIndicatorView(durationStr: duration, message: airportMsg)
                                        
                                    case .checkoutHint(let hotelName):
                                        CheckoutHintView(hotelName: hotelName)
                                            .padding(.bottom, 12)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
        }
        .navigationTitle(trip.name)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    private func eventTypeColor(_ type: EventType) -> Color {
        switch type {
        case .flight: return .blue
        case .train: return .orange
        case .car: return .green
        case .hotel: return .purple
        case .transport: return .mint
        case .activity, .other: return .gray
        }
    }
}

// MARK: - UI Sub-Components

// A specific view for the "5h 15m at PVG" style connection indicator
struct ConnectionIndicatorView: View {
    let durationStr: String
    let message: String
    
    var body: some View {
        HStack {
            // Left dotted line
            VStack { DottedLine() }.frame(height: 30)
            
            // The pill
            HStack(spacing: 4) {
                Text(durationStr)
                    .fontWeight(.semibold)
                Text(message)
                    .foregroundStyle(.secondary)
            }
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color(UIColor.tertiarySystemFill)))
            
            // Right dotted line
            VStack { DottedLine() }.frame(height: 30)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }
}

// A simple vertical dotted line shape
struct DottedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        return path
    }
    
    func path(in rect: CGRect, style: StrokeStyle) -> some Shape {
        var newStyle = style
        newStyle.dash = [4, 4] // dash pattern
        return strokedPath(newStyle)
    }
}

// The view for "Check out from Hotel Name"
struct CheckoutHintView: View {
    let hotelName: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "bed.double.circle")
                .font(.title2)
                .foregroundColor(.purple)
            
            VStack(alignment: .leading) {
                Text("Check out")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Text("from \(hotelName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        // Styling roughly matching hotel card vibe but subtler
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(UIColor.secondarySystemGroupedBackground).opacity(0.5)))
        .padding(.horizontal)
    }
}

// Update existing EventRowView to optionally hide the date
struct EventRowView: View {
    let event: Event
    var showDateHeader: Bool = true // Default to true for backward compatibility if needed elsewhere

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if showDateHeader {
                Text(event.startDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            HStack(alignment: .top, spacing: 12) {
                // Icon Column
                VStack {
                    Image(systemName: event.type.symbolName)
                        .font(.title2)
                        .foregroundColor(eventTypeColor(event.type))
                        .frame(width: 32, height: 32)
                        .background(eventTypeColor(event.type).opacity(0.1))
                        .clipShape(Circle())

                    // Connector Line (visual only, simple version)
                    if !isHotel(event.type) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 2)
                            .padding(.top, 4)
                        Spacer()
                    }
                }
                .frame(height: isHotel(event.type) ? 40 : 100) // shorter for single-point items

                // Content Column
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(event.title)
                            .font(.headline)
                        Spacer()
                        if isHotel(event.type), let end = event.endDate {
                            // Calculate nights for hotels
                            let nights = Calendar.current.dateComponents([.day], from: event.startDate, to: end).day ?? 0
                            Text("\(nights) night\(nights > 1 ? "s" : "")")
                                .font(.caption)
                                .fontWeight(.bold)
                                .padding(4)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }

                    // Location/Subtitle
                    if case .flight(let f) = event.data {
                        Text("\(f.departureAirport) → \(f.arrivalAirport)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else if case .hotel(let h) = event.data {
                         Text(h.address.isEmpty ? h.hotelName : h.address)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    // Times
                    HStack {
                        Text(event.startDate.formatted(date: .omitted, time: .shortened))
                        if let endDate = event.endDate {
                            Image(systemName: "arrow.right")
                                .font(.caption2)
                            Text(endDate.formatted(date: .omitted, time: .shortened))
                                // Add +1 day indicator if needed
                                if !Calendar.current.isDate(event.startDate, inSameDayAs: endDate) {
                                    Text("+1").font(.caption2).baselineOffset(4)
                                }
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
        }
        .padding(.horizontal)
    }

    private func isHotel(_ type: EventType) -> Bool {
        return type == .hotel
    }
    
    private func eventTypeColor(_ type: EventType) -> Color {
        switch type {
        case .flight: return .blue
        case .train: return .orange
        case .car: return .green
        case .hotel: return .purple
        case .transport: return .mint
        case .activity, .other: return .gray
        }
    }
}

// MARK: - Helper: Timeline Processor Logic
// This handles the complex business logic of arranging the timeline items.
struct TripTimelineProvider {
    
    enum TimelineItemContent {
        case event(Event)
        case connection(durationStr: String, airportMsg: String)
        case checkoutHint(hotelName: String)
    }
    
    struct TimelineItem: Identifiable {
        let id = UUID()
        let dateForSorting: Date
        let content: TimelineItemContent
    }
    
    struct DaySchedule: Identifiable {
        let id = Date()
        let date: Date
        var items: [TimelineItem]
    }
    
    static func processTimeline(events: [Event]) -> [DaySchedule] {
        let sortedEvents = events.sorted { $0.startDate < $1.startDate }
        var combinedItems: [TimelineItem] = []
        
        // 1. Generate Events and Connection Indicators
        for (index, event) in sortedEvents.enumerated() {
            // Add the actual event
            combinedItems.append(TimelineItem(dateForSorting: event.startDate, content: .event(event)))
            
            // Check for connection to the *next* event
            if index < sortedEvents.count - 1 {
                let nextEvent = sortedEvents[index + 1]
                
                // Only connect transport types (flight/train etc)
                if isTransport(event.type) && isTransport(nextEvent.type),
                   let endDate = event.endDate {
                    let layover = nextEvent.startDate.timeIntervalSince(endDate)
                    
                    // If layover is positive and less than 24 hours, add indicator
                    if layover > 0 && layover < (24 * 3600) {
                        let durationStr = formatDuration(layover)
                        // Try to get airport code from previous event data
                        var locationMsg = "connecting"
                        if case .flight(let f) = event.data {
                            locationMsg = "at \(f.arrivalAirport)"
                        }
                        
                        // Add connection item slightly after the first event ends so it sorts correctly
                        combinedItems.append(TimelineItem(
                            dateForSorting: endDate.addingTimeInterval(1),
                            content: .connection(durationStr: durationStr, airportMsg: locationMsg)
                        ))
                    }
                }
            }
        }
        
        // 2. Generate Checkout Hints based on Hotel events
        for event in sortedEvents where event.type == .hotel {
            if let endDate = event.endDate {
                // Add checkout hint at the start of the end date day
                let startOfDay = Calendar.current.startOfDay(for: endDate)
                combinedItems.append(TimelineItem(
                    dateForSorting: startOfDay,
                    content: .checkoutHint(hotelName: event.title)
                ))
            }
        }
        
        // 3. Group by Day
        let groupedDict = Dictionary(grouping: combinedItems) { item in
            Calendar.current.startOfDay(for: item.dateForSorting)
        }
        
        // 4. Create sorted DaySchedules and handle Hotel sequencing rule
        let sortedDays = groupedDict.keys.sorted().map { date -> DaySchedule in
            var itemsForDay = groupedDict[date]!.sorted { $0.dateForSorting < $1.dateForSorting }
            
            // Rule: Hotel Check-in cards must be at the bottom of the day
            // Split items into non-hotels and hotels
            var otherItems: [TimelineItem] = []
            var hotelCheckIns: [TimelineItem] = []
            
            for item in itemsForDay {
                if case .event(let e) = item.content, e.type == .hotel {
                    // It's a hotel check-in event
                    hotelCheckIns.append(item)
                } else {
                    otherItems.append(item)
                }
            }
            
            // Recombine: others first, hotels last
            itemsForDay = otherItems + hotelCheckIns
            
            return DaySchedule(date: date, items: itemsForDay)
        }
        
        return sortedDays
    }
    
    private static func isTransport(_ type: EventType) -> Bool {
        return type == .flight || type == .train || type == .transport
    }
    
    private static func formatDuration(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval) % 3600 / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}


// MARK: - Helper: Map Curve Calculation
// This handles generating curved geometry for overlapping routes.
struct MapCurveProvider {
    
    struct RoutedPolyline: Identifiable {
        let id = UUID()
        let coordinates: [CLLocationCoordinate2D]
        let color: Color
    }
    
    // Helper to identify unique paths regardless of direction (A->B is same as B->A)
    struct RouteKey: Hashable {
        let p1: String
        let p2: String
        init(c1: CLLocationCoordinate2D, c2: CLLocationCoordinate2D) {
            // Create a consistent string key by sorting coordinates roughly
            let s1 = "\(String(format: "%.4f", c1.latitude)),\(String(format: "%.4f", c1.longitude))"
            let s2 = "\(String(format: "%.4f", c2.latitude)),\(String(format: "%.4f", c2.longitude))"
            if s1 < s2 { p1 = s1; p2 = s2 } else { p1 = s2; p2 = s1 }
        }
    }
    
    static func generateCurves(for events: [Event]) -> [RoutedPolyline] {
        var routeCounts: [RouteKey: Int] = [:]
        var polylines: [RoutedPolyline] = []
        
        let journeyEvents = events.filter { $0.destinationGeoCoordinates != nil }
        
        // 1. Count repetitions of specific routes
        for event in journeyEvents {
            guard let start = event.geoCoordinates, let end = event.destinationGeoCoordinates else { continue }
            let startCoord = CLLocationCoordinate2D(latitude: start.lat, longitude: start.lng)
            let endCoord = CLLocationCoordinate2D(latitude: end.lat, longitude: end.lng)
            
            // Don't route if start/end are basically the same
            if abs(start.lat - end.lat) < 0.001 && abs(start.lng - end.lng) < 0.001 { continue }
            
            let key = RouteKey(c1: startCoord, c2: endCoord)
            routeCounts[key, default: 0] += 1
        }
        
        var currentRouteIndex: [RouteKey: Int] = [:]
        
        // 2. Generate geometry
        for event in journeyEvents {
            guard let start = event.geoCoordinates, let end = event.destinationGeoCoordinates else { continue }
            let startCoord = CLLocationCoordinate2D(latitude: start.lat, longitude: start.lng)
            let endCoord = CLLocationCoordinate2D(latitude: end.lat, longitude: end.lng)
             // Don't route if start/end are same
            if abs(start.lat - end.lat) < 0.001 && abs(start.lng - end.lng) < 0.001 { continue }

            let key = RouteKey(c1: startCoord, c2: endCoord)
            let totalCount = routeCounts[key] ?? 1
            let currentIndex = currentRouteIndex[key, default: 0]
            currentRouteIndex[key] = currentIndex + 1
            
            let color = eventTypeColor(event.type)
            
            if totalCount == 1 {
                // Simple straight line for single routes
                polylines.append(RoutedPolyline(coordinates: [startCoord, endCoord], color: color))
            } else {
                // Generate curved line for overlapping routes
                // Calculate curve intensity based on index (e.g., -1, 0, 1 for 3 routes)
                // Centering the indices around 0
                let centeredIndex = Double(currentIndex) - (Double(totalCount - 1) / 2.0)
                // Max offset factor determines how wide the curve gets
                let offsetFactor = centeredIndex * 0.2 // Adjust 0.2 to make curves wider/narrower
                
                let curvedCoords = getQuadraticBezier(from: startCoord, to: endCoord, offsetFactor: offsetFactor)
                polylines.append(RoutedPolyline(coordinates: curvedCoords, color: color))
            }
        }
        
        return polylines
    }
    
    // Math to generate points along a curve between two coordinates on a globe approximation
    private static func getQuadraticBezier(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D, offsetFactor: Double) -> [CLLocationCoordinate2D] {
        // Midpoint calculation
        let midLat = (start.latitude + end.latitude) / 2.0
        let midLng = (start.longitude + end.longitude) / 2.0
        
        // Calculate a vector perpendicular to the path (simplified planar approximation suitable for UI)
        let dLat = end.latitude - start.latitude
        let dLng = end.longitude - start.longitude
        // Perpendicular vector (-y, x)
        let perpLat = -dLng
        let perpLng = dLat
        
        // Normalize and scale perpendicular vector
        let magnitude = sqrt(perpLat*perpLat + perpLng*perpLng)
        guard magnitude > 0 else { return [start, end] }
        
        // The control point determines the peak of the curve relative to the distance
        let controlPointLat = midLat + (perpLat / magnitude) * magnitude * offsetFactor
        let controlPointLng = midLng + (perpLng / magnitude) * magnitude * offsetFactor

        var points: [CLLocationCoordinate2D] = []
        let segments = 20 // Number of points to smooth the curve
        
        for i in 0...segments {
            let t = Double(i) / Double(segments)
            let 𝐨𝐧𝐞𝐌𝐢𝐧𝐮𝐬𝐓 = 1.0 - t
            
            // Quadratic Bezier formula: B(t) = (1-t)²P₀ + 2(1-t)tP₁ + t²P₂
            let lat = (𝐨𝐧𝐞𝐌𝐢𝐧𝐮𝐬𝐓 * 𝐨𝐧𝐞𝐌𝐢𝐧𝐮𝐬𝐓 * start.latitude) +
                      (2 * 𝐨𝐧𝐞𝐌𝐢𝐧𝐮𝐬𝐓 * t * controlPointLat) +
                      (t * t * end.latitude)
            
            let lng = (𝐨𝐧𝐞𝐌𝐢𝐧𝐮𝐬𝐓 * 𝐨𝐧𝐞𝐌𝐢𝐧𝐮𝐬𝐓 * start.longitude) +
                      (2 * 𝐨𝐧𝐞𝐌𝐢𝐧𝐮𝐬𝐓 * t * controlPointLng) +
                      (t * t * end.longitude)
            
            points.append(CLLocationCoordinate2D(latitude: lat, longitude: lng))
        }
        return points
    }
    
    private static func eventTypeColor(_ type: EventType) -> Color {
         switch type {
         case .flight: return .blue
         case .train: return .orange
         case .car: return .green
         case .transport: return .mint
         default: return .gray
         }
     }
}
