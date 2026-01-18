//
//  TripDetailView.swift
//  TripMind
//
//  Created by EXC19 on 2026/1/18.
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Main View
struct TripDetailView: View {
    @EnvironmentObject var tripStore: TripStore
    @State var trip: Trip
    
    // MARK: - State
    @State private var showingDocumentPicker = false
    @State private var showingImagePicker = false
    @State private var showingTextInputSheet = false
    @State private var eventToEdit: TravelEvent?
    
    @State private var pastedText: String = ""
    @State private var isParsing = false
    @State private var parsingError: String?
    @State private var showPasteSuccess = false
    
    private let geminiClient = GeminiAPIClient()
    
    private var timelineDays: [TripTimelineProvider.DaySchedule] {
        TripTimelineProvider.processTimeline(events: trip.events)
    }
    
    init(trip: Trip) {
        _trip = State(initialValue: trip)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            
            // LIST CONTENT
            List {
                if isParsing {
                    VStack(spacing: 12) {
                        ProgressView().scaleEffect(1.2)
                        Text("Analyzing itinerary...").font(.subheadline).foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else if let error = parsingError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.red)
                        Text(error).font(.caption).foregroundColor(.red)
                        Spacer()
                        Button { parsingError = nil } label: { Image(systemName: "xmark") }
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else if trip.events.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "airplane.departure")
                            .font(.system(size: 48))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("No events yet")
                            .font(.title3).fontWeight(.semibold)
                        Text("Tap the + button to import your itinerary.")
                            .font(.subheadline).foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
                
                ForEach(timelineDays) { daySchedule in
                    Section(header:
                        Text(daySchedule.date.formatted(.dateTime.weekday().month().day()))
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .padding(.vertical, 8)
                    ) {
                        ForEach(daySchedule.items) { item in
                            ZStack {
                                switch item.content {
                                case .breakfast(let hotelName):
                                    BreakfastHeaderView(hotelName: hotelName)
                                case .checkoutHint(let hotelName):
                                    CheckoutHintView(hotelName: hotelName)
                                case .event(let event):
                                    EventCardView(event: event)
                                        .contentShape(Rectangle())
                                        .onTapGesture { eventToEdit = event }
                                case .connection(let duration, let msg):
                                    ConnectionIndicatorView(durationStr: duration, message: msg)
                                case .staying(let hotelName):
                                    StayingFooterView(hotelName: hotelName)
                                }
                            }
                            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                if case .event(let event) = item.content {
                                    Button(role: .destructive) {
                                        deleteEvent(event)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
                
                // ✅ FIX: Spacer is INSIDE the List.
                // This pushes content up so it's not hidden by floating buttons,
                // but allows the List background to extend fully to the bottom edge.
                Color.clear
                    .frame(height: 80)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            // ❌ REMOVED: .padding(.bottom, 80) <- This was the culprit for the cut-off
            
            // Toast
            if showPasteSuccess {
                Text("Clipboard content pasted!")
                    .font(.caption).bold()
                    .padding()
                    .background(.thinMaterial)
                    .cornerRadius(20)
                    .padding(.bottom, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(trip.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Section {
                        Button { showingDocumentPicker = true } label: { Label("Import PDF", systemImage: "doc.text") }
                        Button { showingImagePicker = true } label: { Label("Import Image", systemImage: "photo") }
                    }
                    Section {
                        Button { showingTextInputSheet = true } label: { Label("Enter Text", systemImage: "square.and.pencil") }
                        Button { parseFromClipboard() } label: { Label("Paste from Clipboard", systemImage: "doc.on.clipboard") }
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 32, height: 32)
                        .background(Color(UIColor.tertiarySystemFill))
                        .clipShape(Circle())
                }
            }
        }
        .sheet(item: $eventToEdit) { event in
            EditEventSheet(event: event, onDelete: {
                deleteEvent(event)
            }, onSave: { updated in
                saveUpdatedEvent(updated)
            })
        }
        .sheet(isPresented: $showingDocumentPicker) { DocumentPicker(onPick: handlePickedDocuments) }
        .sheet(isPresented: $showingImagePicker) { ImagePicker(onPick: handlePickedImage) }
        .sheet(isPresented: $showingTextInputSheet) {
            TextInputSheet(text: $pastedText) { showingTextInputSheet = false; parsePastedText() }
        }
        .onReceive(tripStore.$trips) { updatedTrips in
            if let updated = updatedTrips.first(where: { $0.id == trip.id }) { self.trip = updated }
        }
    }
    
    // MARK: - Handlers
    private func deleteEvent(_ event: TravelEvent) {
        if let index = trip.events.firstIndex(where: { $0.id == event.id }) {
            var newTrip = trip
            newTrip.events.remove(at: index)
            self.trip = newTrip
            Task { try? await tripStore.updateTrip(self.trip) }
        }
    }
    
    private func saveUpdatedEvent(_ updatedEvent: TravelEvent) {
        if let index = trip.events.firstIndex(where: { $0.id == updatedEvent.id }) {
            var newTrip = trip
            newTrip.events[index] = updatedEvent
            newTrip.events.sort { $0.startTime < $1.startTime }
            self.trip = newTrip
            Task { try? await tripStore.updateTrip(self.trip) }
        }
    }
    
    private func parseFromClipboard() {
        if let string = UIPasteboard.general.string {
            self.pastedText = string
            self.showPasteSuccess = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { withAnimation { self.showPasteSuccess = false } }
            parsePastedText()
        } else { parsingError = "Clipboard is empty" }
    }
    
    private func parsePastedText() {
        guard !pastedText.isEmpty else { return }
        isParsing = true; parsingError = nil
        Task {
            do {
                let parsed = try await geminiClient.parseText(pastedText)
                appendEvents(parsed)
                DispatchQueue.main.async { self.pastedText = "" }
            } catch { handleError(error) }
        }
    }
    
    private func handlePickedDocuments(urls: [URL]) {
        guard let url = urls.first else { return }
        isParsing = true; parsingError = nil
        Task {
            do {
                if url.pathExtension.lowercased() == "pdf" {
                    let data = try Data(contentsOf: url)
                    let parsed = try await geminiClient.parsePDF(data)
                    appendEvents(parsed)
                } else if let image = UIImage(contentsOfFile: url.path) {
                    let parsed = try await geminiClient.parseImage(image)
                    appendEvents(parsed)
                }
            } catch { handleError(error) }
        }
    }
    
    private func handlePickedImage(image: UIImage?) {
        guard let image = image else { return }
        isParsing = true; parsingError = nil
        Task {
            do {
                let parsed = try await geminiClient.parseImage(image)
                appendEvents(parsed)
            } catch { handleError(error) }
        }
    }
    
    @MainActor
    private func appendEvents(_ newEvents: [TravelEvent]) {
        self.trip.events.append(contentsOf: newEvents)
        self.trip.events.sort { $0.startTime < $1.startTime }
        Task { try? await tripStore.updateTrip(self.trip) }
        self.isParsing = false
    }
    
    private func handleError(_ error: Error) {
        DispatchQueue.main.async {
            self.parsingError = error.localizedDescription
            self.isParsing = false
        }
    }
}

// MARK: - Timeline Logic
struct TripTimelineProvider {
    enum TimelineItemContent {
        case event(TravelEvent)
        case connection(durationStr: String, airportMsg: String)
        case breakfast(hotelName: String)
        case staying(hotelName: String)
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
    
    static func processTimeline(events: [TravelEvent]) -> [DaySchedule] {
        let sortedEvents = events.sorted { $0.startTime < $1.startTime }
        var combinedItems: [TimelineItem] = []
        
        let hotelEvents = sortedEvents.filter { $0.type == .hotel }
        let transportEvents = sortedEvents.filter { isTransport($0.type) }
        
        for (index, event) in sortedEvents.enumerated() {
            combinedItems.append(TimelineItem(dateForSorting: event.startTime, content: .event(event)))
        }
        
        for (index, event) in transportEvents.enumerated() {
            if index < transportEvents.count - 1 {
                let nextEvent = transportEvents[index + 1]
                if let endDate = event.endTime {
                    let layover = nextEvent.startTime.timeIntervalSince(endDate)
                    if layover > 0 && layover < (24 * 3600) {
                        var loc = "Layover"
                        if case .flight(let f) = event.data { loc = "at \(f.arrivalAirport)" }
                        combinedItems.append(TimelineItem(
                            dateForSorting: endDate.addingTimeInterval(1),
                            content: .connection(durationStr: formatDuration(layover), airportMsg: loc)
                        ))
                    }
                }
            }
        }
        
        let groupedDict = Dictionary(grouping: combinedItems) { Calendar.current.startOfDay(for: $0.dateForSorting) }
        let allDates = groupedDict.keys.sorted()
        
        return allDates.map { date -> DaySchedule in
            var items = groupedDict[date]!.sorted { $0.dateForSorting < $1.dateForSorting }
            var breakfastItems: [TimelineItem] = []
            var checkoutItems: [TimelineItem] = []
            var eventItems: [TimelineItem] = []
            var hotelCheckInItems: [TimelineItem] = []
            var stayingItems: [TimelineItem] = []
            
            for item in items {
                if case .event(let e) = item.content, e.type == .hotel {
                    hotelCheckInItems.append(item)
                } else {
                    eventItems.append(item)
                }
            }
            
            if let activeMorningHotel = hotelEvents.first(where: {
                if let checkIn = $0.startTime as Date?, let checkOut = $0.endTime {
                    let startDay = Calendar.current.startOfDay(for: checkIn)
                    let endDay = Calendar.current.startOfDay(for: checkOut)
                    return date > startDay && date <= endDay
                }
                return false
            }) {
                if case .hotel(let h) = activeMorningHotel.data, h.isBreakfastIncluded == true {
                    breakfastItems.append(TimelineItem(dateForSorting: date, content: .breakfast(hotelName: h.hotelName)))
                }
                if let checkOut = activeMorningHotel.endTime, Calendar.current.isDate(date, inSameDayAs: checkOut) {
                   if !Calendar.current.isDate(activeMorningHotel.startTime, inSameDayAs: checkOut) {
                       checkoutItems.append(TimelineItem(dateForSorting: checkOut, content: .checkoutHint(hotelName: activeMorningHotel.displayTitle)))
                   }
                }
            }
            
            if let activeNightHotel = hotelEvents.first(where: {
                if let checkIn = $0.startTime as Date?, let checkOut = $0.endTime {
                    let startDay = Calendar.current.startOfDay(for: checkIn)
                    let endDay = Calendar.current.startOfDay(for: checkOut)
                    return date >= startDay && date < endDay
                }
                return false
            }) {
                let isCheckInToday = hotelCheckInItems.contains { item in
                    if case .event(let e) = item.content { return e.id == activeNightHotel.id }
                    return false
                }
                if !isCheckInToday {
                    stayingItems.append(TimelineItem(dateForSorting: date, content: .staying(hotelName: activeNightHotel.displayTitle)))
                }
            }
            
            let finalItems = breakfastItems + checkoutItems + eventItems + hotelCheckInItems + stayingItems
            return DaySchedule(date: date, items: finalItems)
        }
    }
    
    static func isTransport(_ type: EventType) -> Bool {
        type == .flight || type == .train || type == .transport
    }
    
    static func formatDuration(_ i: TimeInterval) -> String {
        let h = Int(i) / 3600, m = Int(i) % 3600 / 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }
}

// MARK: - Subviews

struct ConnectionIndicatorView: View {
    let durationStr: String
    let message: String
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack {
                Rectangle().fill(Color.gray.opacity(0.3)).frame(width: 2)
            }
            .frame(width: 20)
            
            HStack {
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: "clock").font(.caption2)
                    Text(durationStr).fontWeight(.semibold)
                    Text(message).foregroundStyle(.secondary)
                }
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.gray.opacity(0.2)))
                Spacer()
            }
            Spacer().frame(width: 20).opacity(0)
        }
        .frame(height: 40)
        .padding(.horizontal, 20)
    }
}

struct BreakfastHeaderView: View {
    let hotelName: String
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack { Circle().fill(Color.orange).frame(width: 8, height: 8) }.frame(width: 20)
            HStack(spacing: 6) {
                Image(systemName: "cup.and.saucer.fill").foregroundColor(.orange)
                Text(hotelName).font(.subheadline).fontWeight(.medium).foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }
}

struct StayingFooterView: View {
    let hotelName: String
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack { Circle().fill(Color.purple).frame(width: 8, height: 8) }.frame(width: 20)
            HStack(spacing: 6) {
                Image(systemName: "bed.double.fill").foregroundColor(.purple)
                Text(hotelName).font(.subheadline).fontWeight(.medium).foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
    }
}

struct CheckoutHintView: View {
    let hotelName: String
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack { Circle().stroke(Color.gray, lineWidth: 2).frame(width: 8, height: 8) }.frame(width: 20)
            HStack(spacing: 6) {
                Image(systemName: "figure.walk.departure").foregroundColor(.secondary)
                Text(hotelName).font(.subheadline).fontWeight(.medium).foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    var onPick: (UIImage?) -> Void
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage { parent.onPick(image) }
            parent.presentationMode.wrappedValue.dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.presentationMode.wrappedValue.dismiss() }
    }
}
