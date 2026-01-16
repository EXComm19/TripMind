//
//  PDFKit+Extensions.swift
//  TripMind
//
//  Created by EXC19 on 2026/1/16.
//

import Foundation
import PDFKit

extension PDFDocument {
    func extractText() -> String? {
        guard let pageCount = self.pageCount as Int?, pageCount > 0 else {
            return nil
        }
        
        var fullText = ""
        for i in 0..<pageCount {
            if let page = self.page(at: i) {
                fullText += (page.string ?? "") + "\n"
            }
        }
        return fullText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
