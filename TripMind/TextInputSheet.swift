//
//  TextInputSheet.swift
//  TripMind
//
//  Created by EXC19 on 2026/1/18.
//

import SwiftUI

struct TextInputSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var text: String
    var onParse: () -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Paste your flight confirmation, hotel booking, or itinerary email below.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                TextEditor(text: $text)
                    .frame(maxHeight: .infinity)
                    .padding(4)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Import Text")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Parse") {
                        onParse()
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
