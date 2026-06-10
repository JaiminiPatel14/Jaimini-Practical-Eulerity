//
//  FormViewModel.swift
//  Jaimini-Practical-Eulerity
//
//  Created by Jaimini Shah on 09/06/26.
//

import Combine
import SwiftUI

@MainActor
final class FormViewModel: ObservableObject {
    @Published private(set) var theme: FormTheme
    @Published private(set) var formTitle: String
    @Published private(set) var fields: [FormField] = []

    @Published var textValues: [String: String] = [:]
    @Published var dropdownSelections: [String: [String]] = [:]
    @Published var toggleValues: [String: Bool] = [:]
    @Published var checkboxValues: [String: Bool] = [:]

    @Published var fieldErrors: [String: String] = [:]
    @Published var showSubmitSuccessAlert = false
    @Published private(set) var loadErrorMessage: String?

    init() {
        theme = FormTheme(
            backgroundColorHex: "#121212",
            textColorHex: "#E0E0E0",
            borderColorHex: "#333333",
            errorColorHex: "#CF6679"
        )
        formTitle = ""
        loadForm()
    }

    func error(for fieldId: String) -> String? {
        fieldErrors[fieldId]
    }

    func textBinding(for fieldId: String) -> Binding<String> {
        Binding(
            get: { self.textValues[fieldId, default: ""] },
            set: { self.textValues[fieldId] = $0 }
        )
    }

    func dropdownBinding(for fieldId: String) -> Binding<[String]> {
        Binding(
            get: { self.dropdownSelections[fieldId, default: []] },
            set: { self.dropdownSelections[fieldId] = $0 }
        )
    }

    func toggleBinding(for fieldId: String) -> Binding<Bool> {
        Binding(
            get: { self.toggleValues[fieldId, default: false] },
            set: { self.toggleValues[fieldId] = $0 }
        )
    }

    func checkboxBinding(for fieldId: String) -> Binding<Bool> {
        Binding(
            get: { self.checkboxValues[fieldId, default: false] },
            set: { self.checkboxValues[fieldId] = $0 }
        )
    }

    func submit() {
        guard validate() else { return }
        printSubmission()
        showSubmitSuccessAlert = true
    }

    @discardableResult
    func validate() -> Bool {
        fieldErrors.removeAll()

        var isValid = true

        for field in fields {
            switch field {
            case .text(let textField):
                if !validateTextField(textField) {
                    isValid = false
                }

            case .dropdown(let dropdownField):
                if !validateDropdownField(dropdownField) {
                    isValid = false
                }

            case .toggle(let toggleField):
                if !validateToggleField(toggleField) {
                    isValid = false
                }

            case .checkbox(let checkboxField):
                if !validateCheckboxField(checkboxField) {
                    isValid = false
                }
            }
        }

        return isValid
    }

    private func loadForm() {
        guard let url = Bundle.main.url(forResource: "form", withExtension: "json") else {
            loadErrorMessage = "Could not find form.json in the app bundle."
            return
        }

        guard let data = try? Data(contentsOf: url) else {
            loadErrorMessage = "Failed to read data from form.json."
            return
        }

        do {
            let form = try JSONDecoder().decode(FormModel.self, from: data)
            theme = form.theme
            formTitle = form.formTitle
            fields = form.fields
            prepopulateValues()
            loadErrorMessage = nil
        } catch {
            loadErrorMessage = "Failed to decode form.json: \(error.localizedDescription)"
        }
    }

    private func prepopulateValues() {
        textValues.removeAll()
        dropdownSelections.removeAll()
        toggleValues.removeAll()
        checkboxValues.removeAll()

        for field in fields {
            switch field {
            case .text(let textField):
                textValues[textField.id] = resolvedTextDefault(for: textField)

            case .dropdown(let dropdownField):
                dropdownSelections[dropdownField.id] = resolvedDropdownDefault(for: dropdownField)

            case .toggle(let toggleField):
                toggleValues[toggleField.id] = toggleField.defaultValue ?? false

            case .checkbox(let checkboxField):
                checkboxValues[checkboxField.id] = checkboxField.defaultValue ?? false
            }
        }
    }

    private func resolvedTextDefault(for textField: TextField) -> String {
        guard var value = textField.defaultValue else { return "" }

        if let maxLength = textField.maxLength {
            value = String(value.prefix(maxLength))
        }

        return value
    }

    private func resolvedDropdownDefault(for dropdownField: DropdownField) -> [String] {
        guard let defaultOptionIds = dropdownField.defaultOptionIds, !defaultOptionIds.isEmpty else {
            return []
        }

        let validOptionIds = defaultOptionIds.filter { optionId in
            dropdownField.options.contains { $0.id == optionId }
        }

        if dropdownField.allowMultiple {
            return validOptionIds
        }

        if let firstValidId = validOptionIds.first {
            return [firstValidId]
        }

        return []
    }

    private func validateTextField(_ textField: TextField) -> Bool {
        let value = textValues[textField.id, default: ""]
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if textField.required && value.isEmpty {
            fieldErrors[textField.id] = textField.errorMessage ?? "This field is required."
            return false
        }

        if let maxLength = textField.maxLength, value.count > maxLength {
            fieldErrors[textField.id] = textField.errorMessage
                ?? "Cannot exceed \(maxLength) characters."
            return false
        }

        if !value.isEmpty,
           let pattern = textField.regexPattern,
           !pattern.isEmpty,
           !matchesRegex(pattern: pattern, value: value) {
            fieldErrors[textField.id] = textField.errorMessage ?? "Invalid format."
            return false
        }

        return true
    }

    private func matchesRegex(pattern: String, value: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return true
        }

        let range = NSRange(value.startIndex ..< value.endIndex, in: value)
        return regex.firstMatch(in: value, options: [], range: range) != nil
    }

    private func validateDropdownField(_ dropdownField: DropdownField) -> Bool {
        let selectedIds = dropdownSelections[dropdownField.id, default: []]

        if dropdownField.required && selectedIds.isEmpty && !dropdownField.options.isEmpty{
            fieldErrors[dropdownField.id] = dropdownField.errorMessage ?? "Please select an option."
            return false
        }

        return true
    }

    private func validateToggleField(_ toggleField: ToggleField) -> Bool {
        let isOn = toggleValues[toggleField.id, default: false]

        if toggleField.required && !isOn {
            fieldErrors[toggleField.id] = toggleField.errorMessage ?? "This field is required."
            return false
        }

        return true
    }

    private func validateCheckboxField(_ checkboxField: CheckboxField) -> Bool {
        let isChecked = checkboxValues[checkboxField.id, default: false]

        if checkboxField.required && !isChecked {
            fieldErrors[checkboxField.id] = checkboxField.errorMessage ?? "This field is required."
            return false
        }

        return true
    }

    private func printSubmission() {
        var result: [String: Any] = [:]
        for field in fields {
            switch field {
            case .text(let textField):
                result[textField.id] = textValues[textField.id, default: ""]

            case .dropdown(let dropdownField):
                let selectedIds = dropdownSelections[dropdownField.id, default: []]
                let selectedLabels = selectedIds.compactMap { id in
                    dropdownField.options.first(where: { $0.id == id })?.label
                }
                result[dropdownField.id] = selectedLabels

            case .toggle(let toggleField):
                result[toggleField.id] = toggleValues[toggleField.id, default: false]

            case .checkbox(let checkboxField):
                result[checkboxField.id] = checkboxValues[checkboxField.id, default: false]
            }
        }
        if let jsonData = try? JSONSerialization.data(withJSONObject: result, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print("——— Form Submission ———")
            print(jsonString)
            print("———————————————————————")
        }
    }
}
