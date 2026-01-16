//
//  ContentView.swift
//  TripMind
//
//  Created by EXC19 on 2026/1/16.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        // The main view will be a NavigationView hosting the list of trips
        NavigationView {
            TripListView()
        }
    }
}

#Preview {
    ContentView()
}

