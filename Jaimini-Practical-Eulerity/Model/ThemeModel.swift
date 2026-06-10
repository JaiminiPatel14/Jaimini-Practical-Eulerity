//
//  ThemeModel.swift
//  Jaimini-Practical-Eulerity
//
//  Created by Jaimini Shah on 09/06/26.
//

import SwiftUI

struct FormTheme: Codable {
    let backgroundColorHex: String
    let textColorHex: String
    let borderColorHex: String
    let errorColorHex: String

    enum CodingKeys: String, CodingKey {
        case backgroundColorHex = "background_color"
        case textColorHex = "text_color"
        case borderColorHex = "border_color"
        case errorColorHex = "error_color"
    }

    init(
        backgroundColorHex: String,
        textColorHex: String,
        borderColorHex: String,
        errorColorHex: String
    ) {
        self.backgroundColorHex = backgroundColorHex
        self.textColorHex = textColorHex
        self.borderColorHex = borderColorHex
        self.errorColorHex = errorColorHex
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        backgroundColorHex = try container.decodeIfPresent(String.self, forKey: .backgroundColorHex) ?? "#121212"
        textColorHex = try container.decodeIfPresent(String.self, forKey: .textColorHex) ?? "#E0E0E0"
        borderColorHex = try container.decodeIfPresent(String.self, forKey: .borderColorHex) ?? "#333333"
        errorColorHex = try container.decodeIfPresent(String.self, forKey: .errorColorHex) ?? "#CF6679"
    }

    var backgroundColor: Color {
        Color(hex: backgroundColorHex)
    }

    var textColor: Color {
        Color(hex: textColorHex)
    }

    var borderColor: Color {
        Color(hex: borderColorHex)
    }

    var errorColor: Color {
        Color(hex: errorColorHex)
    }
}
