//
//  UIComponents.swift
//  TripMind
//
//  Created by EXC19 on 2026/1/18.
//

import SwiftUI

// Logo.dev Configuration
let LOGO_DEV_PUBLIC_KEY = "pk_EcUNocp3RJOn4qZwg9KGTA"

struct BrandLogoView: View {
    let brandDomain: String?
    let fallbackIcon: String
    var size: CGFloat = 40
    
    // ✅ DYNAMIC RADIUS: Adjusted ratio for sharper corners.
    // 16px icon -> 3.2px radius (Distinctly rounded square)
    // 40px icon -> 8px radius
    private var cornerRadius: CGFloat {
        return size * 0.2
    }
    
    var body: some View {
        if let domain = brandDomain, !domain.isEmpty,
           let url = URL(string: "https://img.logo.dev/\(domain)?token=\(LOGO_DEV_PUBLIC_KEY)") {
            
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable()
                        .aspectRatio(contentMode: .fit)
                case .failure:
                    fallbackImage
                case .empty:
                    ProgressView()
                        .frame(width: size * 0.6, height: size * 0.6)
                @unknown default:
                    fallbackImage
                }
            }
            .frame(width: size, height: size)
            .background(Color.white)
            // ✅ Clip shape applied here
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(RoundedRectangle(cornerRadius: cornerRadius).stroke(Color.gray.opacity(0.2), lineWidth: 1))
            
        } else {
            fallbackImage
        }
    }
    
    var fallbackImage: some View {
        Image(systemName: fallbackIcon)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size * 0.5, height: size * 0.5)
            .padding(size * 0.25)
            .background(Color.gray.opacity(0.1))
            .foregroundColor(.gray)
            // ✅ Clip shape applied here
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(RoundedRectangle(cornerRadius: cornerRadius).stroke(Color.gray.opacity(0.2), lineWidth: 1))
            .frame(width: size, height: size)
    }
}

// Custom Colors for the Timeline UI
extension Color {
    static let cardBackground = Color(UIColor.secondarySystemGroupedBackground)
    static let timelineLine = Color.gray.opacity(0.3)
}
