//
//  DocumentPicker.swift
//  TripMind
//
//  Created by EXC19 on 2026/1/16.
//

import SwiftUI
import UniformTypeIdentifiers // For UTType
import PDFKit // For PDFDocument

struct DocumentPicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) var dismiss
    var onPick: ([URL]) -> Void
    var allowedContentTypes: [UTType] = [.pdf, .image] // Default to PDF and image
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: allowedContentTypes, asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        // Nothing to update
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.onPick(urls)
            parent.dismiss()
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.dismiss()
        }
    }
}
