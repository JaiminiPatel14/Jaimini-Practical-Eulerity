//
//  Color+Extension.swift
//  Jaimini-Practical-Eulerity
//
//  Created by Jaimini Shah on 09/06/26.
//

import SwiftUI

extension Color {
    private static let hexFallback = Color(red: 0.5, green: 0.5, blue: 0.5)

    init(hex: String, fallback: Color = Color.hexFallback) {
        let sanitized = hex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
            .uppercased()

        guard sanitized.count == 6 || sanitized.count == 8,
              sanitized.allSatisfy(\.isHexDigit),
              let value = UInt64(sanitized, radix: 16) else {
            self = fallback
            return
        }

        let red: Double
        let green: Double
        let blue: Double
        let opacity: Double

        if sanitized.count == 6 {
            red = Double((value >> 16) & 0xFF) / 255
            green = Double((value >> 8) & 0xFF) / 255
            blue = Double(value & 0xFF) / 255
            opacity = 1
        } else {
            red = Double((value >> 24) & 0xFF) / 255
            green = Double((value >> 16) & 0xFF) / 255
            blue = Double((value >> 8) & 0xFF) / 255
            opacity = Double(value & 0xFF) / 255
        }

        self.init(red: red, green: green, blue: blue, opacity: opacity)
    }
}
