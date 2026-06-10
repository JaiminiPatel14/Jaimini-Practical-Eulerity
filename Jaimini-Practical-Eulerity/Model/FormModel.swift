//
//  FormModel.swift
//  Jaimini-Practical-Eulerity
//
//  Created by Jaimini Shah on 09/06/26.
//

import SwiftUI

struct FormModel: Codable {
    let theme: FormTheme
    let formTitle: String
    let fields: [FormField]

    enum CodingKeys: String, CodingKey {
        case theme
        case formTitle = "form_title"
        case fields
    }

    init(theme: FormTheme, formTitle: String, fields: [FormField]) {
        self.theme = theme
        self.formTitle = formTitle
        self.fields = fields.sorted { $0.order < $1.order }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        theme = try container.decodeIfPresent(FormTheme.self, forKey: .theme)
            ?? FormTheme(
                backgroundColorHex: "#121212",
                textColorHex: "#E0E0E0",
                borderColorHex: "#333333",
                errorColorHex: "#CF6679"
            )
        formTitle = try container.decodeIfPresent(String.self, forKey: .formTitle) ?? ""
        let decodedFields = try container.decodeIfPresent(
            [FailableDecodable<FormField>].self,
            forKey: .fields
        ) ?? []
        fields = decodedFields.compactMap(\.value).sorted { $0.order < $1.order }
    }
}

enum FormField: Codable {
    case text(TextField)
    case dropdown(DropdownField)
    case toggle(ToggleField)
    case checkbox(CheckboxField)

    private enum CodingKeys: String, CodingKey {
        case type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type.uppercased() {
        case "TEXT":
            self = .text(try TextField(from: decoder))
        case "DROPDOWN":
            self = .dropdown(try DropdownField(from: decoder))
        case "TOGGLE":
            self = .toggle(try ToggleField(from: decoder))
        case "CHECKBOX":
            self = .checkbox(try CheckboxField(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Unsupported field type: \(type)"
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        switch self {
        case .text(let field):
            try field.encode(to: encoder)
        case .dropdown(let field):
            try field.encode(to: encoder)
        case .toggle(let field):
            try field.encode(to: encoder)
        case .checkbox(let field):
            try field.encode(to: encoder)
        }
    }
}

extension FormField {
    var id: String {
        switch self {
        case .text(let field): field.id
        case .dropdown(let field): field.id
        case .toggle(let field): field.id
        case .checkbox(let field): field.id
        }
    }

    var order: Int {
        switch self {
        case .text(let field): field.order
        case .dropdown(let field): field.order
        case .toggle(let field): field.order
        case .checkbox(let field): field.order
        }
    }

    var label: String {
        switch self {
        case .text(let field): field.label
        case .dropdown(let field): field.label
        case .toggle(let field): field.label
        case .checkbox(let field): field.label
        }
    }

    var errorMessage: String? {
        switch self {
        case .text(let field): field.errorMessage
        case .dropdown(let field): field.errorMessage
        case .toggle(let field): field.errorMessage
        case .checkbox(let field): field.errorMessage
        }
    }

    var required: Bool {
        switch self {
        case .text(let field): field.required
        case .dropdown(let field): field.required
        case .toggle(let field): field.required
        case .checkbox(let field): field.required
        }
    }
}

enum TextSubtype: String, Codable {
    case plain = "PLAIN"
    case multiline = "MULTILINE"
    case number = "NUMBER"
    case uri = "URI"
    case secure = "SECURE"
}

struct TextField: Codable {
    let id: String
    let order: Int
    let label: String
    let subtype: TextSubtype
    let defaultValue: String?
    let maxLength: Int?
    let placeholder: String?
    let supportingText: String?
    let regexPattern: String?
    let errorMessage: String?
    let required: Bool

    enum CodingKeys: String, CodingKey {
        case type
        case id
        case order
        case label
        case subtype
        case placeholder
        case required
        case defaultValue = "default_value"
        case maxLength = "max_length"
        case supportingText = "supporting_text"
        case regexPattern = "regex_pattern"
        case errorMessage = "error_message"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        guard !id.isEmpty else {
            throw DecodingError.dataCorruptedError(
                forKey: .id,
                in: container,
                debugDescription: "Field id cannot be empty"
            )
        }

        order = try container.decodeIfPresent(Int.self, forKey: .order) ?? 0
        label = try container.decodeIfPresent(String.self, forKey: .label) ?? ""
        subtype = try container.decodeIfPresent(TextSubtype.self, forKey: .subtype) ?? .plain
        defaultValue = try container.decodeIfPresent(String.self, forKey: .defaultValue)
        maxLength = try container.decodeIfPresent(Int.self, forKey: .maxLength)
        placeholder = try container.decodeIfPresent(String.self, forKey: .placeholder)
        supportingText = try container.decodeIfPresent(String.self, forKey: .supportingText)
        regexPattern = try container.decodeIfPresent(String.self, forKey: .regexPattern)
        errorMessage = try container.decodeIfPresent(String.self, forKey: .errorMessage)
        required = try container.decodeIfPresent(Bool.self, forKey: .required) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("TEXT", forKey: .type)
        try container.encode(id, forKey: .id)
        try container.encode(order, forKey: .order)
        try container.encode(label, forKey: .label)
        try container.encode(subtype, forKey: .subtype)
        try container.encodeIfPresent(defaultValue, forKey: .defaultValue)
        try container.encodeIfPresent(maxLength, forKey: .maxLength)
        try container.encodeIfPresent(placeholder, forKey: .placeholder)
        try container.encodeIfPresent(supportingText, forKey: .supportingText)
        try container.encodeIfPresent(regexPattern, forKey: .regexPattern)
        try container.encodeIfPresent(errorMessage, forKey: .errorMessage)
        try container.encode(required, forKey: .required)
    }
}

struct DropdownOption: Codable, Identifiable {
    let id: String
    let label: String

    enum CodingKeys: String, CodingKey {
        case id
        case label
    }

    init(id: String, label: String) {
        self.id = id
        self.label = label
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        label = try container.decodeIfPresent(String.self, forKey: .label) ?? ""
    }
}

struct DropdownField: Codable {
    let id: String
    let order: Int
    let label: String
    let allowMultiple: Bool
    let options: [DropdownOption]
    let defaultOptionIds: [String]?
    let errorMessage: String?
    let required: Bool

    enum CodingKeys: String, CodingKey {
        case type
        case id
        case order
        case label
        case options
        case required
        case allowMultiple = "allow_multiple"
        case defaultValue = "default_values"
        case errorMessage = "error_message"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        guard !id.isEmpty else {
            throw DecodingError.dataCorruptedError(
                forKey: .id,
                in: container,
                debugDescription: "Field id cannot be empty"
            )
        }

        order = try container.decodeIfPresent(Int.self, forKey: .order) ?? 0
        label = try container.decodeIfPresent(String.self, forKey: .label) ?? ""
        allowMultiple = try container.decodeIfPresent(Bool.self, forKey: .allowMultiple) ?? false
        options = try container.decodeIfPresent([DropdownOption].self, forKey: .options) ?? []
        defaultOptionIds = try container.decodeIfPresent(DropdownDefaultValue.self, forKey: .defaultValue)?.optionIds
        errorMessage = try container.decodeIfPresent(String.self, forKey: .errorMessage)
        required = try container.decodeIfPresent(Bool.self, forKey: .required) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("DROPDOWN", forKey: .type)
        try container.encode(id, forKey: .id)
        try container.encode(order, forKey: .order)
        try container.encode(label, forKey: .label)
        try container.encode(allowMultiple, forKey: .allowMultiple)
        try container.encode(options, forKey: .options)
        try container.encodeIfPresent(defaultOptionIds, forKey: .defaultValue)
        try container.encodeIfPresent(errorMessage, forKey: .errorMessage)
        try container.encode(required, forKey: .required)
    }
}

struct ToggleField: Codable {
    let id: String
    let order: Int
    let label: String
    let defaultValue: Bool?
    let errorMessage: String?
    let required: Bool

    enum CodingKeys: String, CodingKey {
        case type
        case id
        case order
        case label
        case required
        case defaultValue = "default_value"
        case errorMessage = "error_message"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        guard !id.isEmpty else {
            throw DecodingError.dataCorruptedError(
                forKey: .id,
                in: container,
                debugDescription: "Field id cannot be empty"
            )
        }

        order = try container.decodeIfPresent(Int.self, forKey: .order) ?? 0
        label = try container.decodeIfPresent(String.self, forKey: .label) ?? ""
        defaultValue = try container.decodeIfPresent(Bool.self, forKey: .defaultValue)
        errorMessage = try container.decodeIfPresent(String.self, forKey: .errorMessage)
        required = try container.decodeIfPresent(Bool.self, forKey: .required) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("TOGGLE", forKey: .type)
        try container.encode(id, forKey: .id)
        try container.encode(order, forKey: .order)
        try container.encode(label, forKey: .label)
        try container.encodeIfPresent(defaultValue, forKey: .defaultValue)
        try container.encodeIfPresent(errorMessage, forKey: .errorMessage)
        try container.encode(required, forKey: .required)
    }
}

struct CheckboxField: Codable {
    let id: String
    let order: Int
    let label: String
    let metadata: [String: String]?
    let clickableTextColorHex: String?
    let defaultValue: Bool?
    let errorMessage: String?
    let required: Bool

    enum CodingKeys: String, CodingKey {
        case type
        case id
        case order
        case label
        case metadata
        case required
        case defaultValue = "default_value"
        case clickableTextColorHex = "clickable_text_color"
        case errorMessage = "error_message"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        guard !id.isEmpty else {
            throw DecodingError.dataCorruptedError(
                forKey: .id,
                in: container,
                debugDescription: "Field id cannot be empty"
            )
        }

        order = try container.decodeIfPresent(Int.self, forKey: .order) ?? 0
        label = try container.decodeIfPresent(String.self, forKey: .label) ?? ""
        metadata = try container.decodeIfPresent([String: String].self, forKey: .metadata)
        clickableTextColorHex = try container.decodeIfPresent(String.self, forKey: .clickableTextColorHex)
        defaultValue = try container.decodeIfPresent(Bool.self, forKey: .defaultValue)
        errorMessage = try container.decodeIfPresent(String.self, forKey: .errorMessage)
        required = try container.decodeIfPresent(Bool.self, forKey: .required) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("CHECKBOX", forKey: .type)
        try container.encode(id, forKey: .id)
        try container.encode(order, forKey: .order)
        try container.encode(label, forKey: .label)
        try container.encodeIfPresent(metadata, forKey: .metadata)
        try container.encodeIfPresent(clickableTextColorHex, forKey: .clickableTextColorHex)
        try container.encodeIfPresent(defaultValue, forKey: .defaultValue)
        try container.encodeIfPresent(errorMessage, forKey: .errorMessage)
        try container.encode(required, forKey: .required)
    }

    var clickableTextColor: Color {
        guard let clickableTextColorHex else {
            return Color.accentColor
        }
        return Color(hex: clickableTextColorHex)
    }
}

private struct DropdownDefaultValue: Decodable {
    let optionIds: [String]

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let optionId = try? container.decode(String.self) {
            optionIds = [optionId]
            return
        }

        optionIds = try container.decode([String].self)
    }
}

private struct FailableDecodable<Value: Decodable>: Decodable {
    let value: Value?

    init(from decoder: Decoder) throws {
        value = try? Value(from: decoder)
    }
}
