//
//  TripDetailView.swift
//  TripMind
//
//  Created by EXC19 on 2026/1/16.
//

import SwiftUI
import UniformTypeIdentifiers
import PDFKit // Ensure PDFKit is imported for PDFDocument

struct TripDetailView: View {
    @EnvironmentObject var tripStore: TripStore // Access the TripStore
    @State var trip: Trip // This trip will be a copy, need to update in store
    
    @State private var showingDocumentPicker = false
    @State private var showingImagePicker = false
    @State private var pastedText: String = ""
    @State private var isParsing = false
    @State private var parsingError: String?
    
    // Initialize GeminiAPIClient
    private let geminiClient = GeminiAPIClient()
    
    // Initializer to ensure @State trip is set correctly when passed
    init(trip: Trip) {
        _trip = State(initialValue: trip)
    }
    
    var body: some View {
        VStack {
            // MARK: - Upload Box (Functional)
            UploadBoxView(
                pastedText: $pastedText,
                isParsing: isParsing,
                onPaste: parsePastedText,
                onChooseFile: { showingDocumentPicker = true },
                onChooseImage: { showingImagePicker = true }
            )
            .disabled(isParsing)
            
            if isParsing {
                ProgressView("Parsing itinerary...")
                    .padding(.vertical)
            }
            
            if let error = parsingError {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }
            
            Divider()
            
            // MARK: - Detailed Timeline
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    if trip.events.isEmpty {
                        Text("No events for this trip yet. Upload or add one!")
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        ForEach(trip.events.sorted(by: { $0.startTime < $1.startTime })) { event in
                            EventCardView(event: event)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle(trip.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    print("Edit trip / Add event")
                    // TODO: Implement functionality to edit trip details or manually add an event
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPicker(onPick: handlePickedDocuments)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(onPick: handlePickedImage)
        }
        // Observe changes to the trip in the store and update local state
        .onReceive(tripStore.$trips) { updatedTrips in
            if let updatedTrip = updatedTrips.first(where: { $0.id == self.trip.id }) {
                self.trip = updatedTrip
            }
        }
    }
    
    private func parsePastedText() {
        guard !pastedText.isEmpty else { return }
        isParsing = true
        parsingError = nil
        Task {
            do {
                let parsedEvents = try await geminiClient.parseText(pastedText)
                DispatchQueue.main.async {
                    // Update the local trip and then save to the store
                    self.trip.events.append(contentsOf: parsedEvents)
                    self.trip.events.sort { $0.startTime < $1.startTime } // Keep events sorted
                    Task {
                        try await tripStore.updateTrip(self.trip)
                    }
                    self.pastedText = ""
                    self.isParsing = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.parsingError = error.localizedDescription
                    self.isParsing = false
                }
            }
        }
    }
    
    private func handlePickedDocuments(urls: [URL]) {
        guard let url = urls.first else { return }
        
        isParsing = true
        parsingError = nil
        
        Task {
            do {
                if url.pathExtension.lowercased() == "pdf" {
                    let pdfData = try Data(contentsOf: url) // Read PDF data directly
                    let parsedEvents = try await geminiClient.parsePDF(pdfData) // Use the parsePDF method
                    DispatchQueue.main.async {
                        self.trip.events.append(contentsOf: parsedEvents)
                        self.trip.events.sort { $0.startTime < $1.startTime } // Keep events sorted
                        Task {
                            try await tripStore.updateTrip(self.trip)
                        }
                        self.isParsing = false
                    }
                } else if let image = UIImage(contentsOfFile: url.path) { // Assuming image files will also go through DocumentPicker
                    let parsedEvents = try await geminiClient.parseImage(image) // Use the updated parseImage method
                    DispatchQueue.main.async {
                        self.trip.events.append(contentsOf: parsedEvents)
                        self.trip.events.sort { $0.startTime < $1.startTime } // Keep events sorted
                        Task {
                            try await tripStore.updateTrip(self.trip)
                        }
                        self.isParsing = false
                    }
                } else {
                    DispatchQueue.main.async {
                        self.parsingError = "Unsupported file type or could not read file."
                        self.isParsing = false
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.parsingError = error.localizedDescription
                    self.isParsing = false
                }
            }
        }
    }
    
    private func handlePickedImage(image: UIImage?) {
        guard let image = image else { return }
        
        isParsing = true
        parsingError = nil
        
        Task {
            do {
                let parsedEvents = try await geminiClient.parseImage(image)
                DispatchQueue.main.async {
                    self.trip.events.append(contentsOf: parsedEvents)
                    self.trip.events.sort { $0.startTime < $1.startTime } // Keep events sorted
                    Task {
                        try await tripStore.updateTrip(self.trip)
                    }
                    self.isParsing = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.parsingError = error.localizedDescription
                    self.isParsing = false
                }
            }
        }
    }
}

// MARK: - Helper Views for TripDetailView (RESTORED DEFINITIONS)

struct UploadBoxView: View {
    @Binding var pastedText: String
    let isParsing: Bool
    let onPaste: () -> Void
    let onChooseFile: () -> Void
    let onChooseImage: () -> Void
    
    var body: some View {
        VStack(spacing: 10) {
            TextEditor(text: $pastedText)
                .frame(height: 100)
                .border(Color.gray, width: 1)
                .padding(.horizontal)
                .overlay(
                    Group {
                        if pastedText.isEmpty {
                            Text("Paste itinerary text or email content here...")
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                                .padding(.top, 8)
                        }
                    }, alignment: .topLeading
                )
            
            HStack {
                Button("Paste & Parse") {
                    onPaste()
                }
                .buttonStyle(.borderedProminent)
                .disabled(pastedText.isEmpty || isParsing)
                
                Spacer()
                
                Button("Choose File (PDF/Image)") {
                    onChooseFile()
                }
                .buttonStyle(.bordered)
                .disabled(isParsing)
                
                Button("Choose Image") {
                    onChooseImage()
                }
                .buttonStyle(.bordered)
                .disabled(isParsing)
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
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
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onPick(image)
            } else {
                parent.onPick(nil)
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onPick(nil)
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

#Preview {
    NavigationView {
        TripDetailView(trip: Trip(name: "Sample Trip", startDate: Date(), endDate: Date().addingTimeInterval(86400*5), events: []))
            .environmentObject(TripStore()) // Provide a mock or actual TripStore for preview
    }
}

