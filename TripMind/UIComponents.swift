//
//  UIComponents.swift
//  TripMind
//
//  Created by EXC19 on 2026/1/18.
//

import SwiftUI

// ✅ NEW: Logo.dev Configuration
let LOGO_DEV_PUBLIC_KEY = "pk_EcUNocp3RJOn4qZwg9KGTA"

struct BrandLogoView: View {
    let brandDomain: String?
    let fallbackIcon: String
    
    var body: some View {
        if let domain = brandDomain, !domain.isEmpty,
           let url = URL(string: "https://img.logo.dev/\(domain)?token=\(LOGO_DEV_PUBLIC_KEY)") {
            
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable()
                        .aspectRatio(contentMode: .fit)
                case .failure:
                    fallbackImage // Fallback if Logo.dev fails
                case .empty:
                    ProgressView() // Spinner while loading
                        .frame(width: 24, height: 24)
                @unknown default:
                    fallbackImage
                }
            }
            .frame(width: 40, height: 40)
            .background(Color.white)
            .clipShape(Circle())
            // Add a subtle border so white logos don't disappear on white backgrounds
            .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
            
        } else {
            fallbackImage
        }
    }
    
    var fallbackImage: some View {
        Image(systemName: fallbackIcon)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 20, height: 20)
            .padding(10)
            .background(Color.gray.opacity(0.1))
            .foregroundColor(.gray)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
    }
}

// Custom Colors for the Timeline UI
extension Color {
    static let cardBackground = Color(UIColor.secondarySystemGroupedBackground)
    static let timelineLine = Color.gray.opacity(0.3)
}   
