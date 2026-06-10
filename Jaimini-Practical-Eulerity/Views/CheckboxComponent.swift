//
//  CheckboxComponent.swift
//  Jaimini-Practical-Eulerity
//
//  Created by Jaimini Shah on 09/06/26.
//

import SwiftUI

struct CheckboxComponent: View {
    let checkboxField: CheckboxField
    let theme: FormTheme
    @Binding var isChecked: Bool
    var error: String?

    private var borderColor: Color {
        error != nil ? theme.errorColor : theme.borderColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 12) {
                Button {
                    isChecked.toggle()
                } label: {
                    Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                        .font(.title3)
                        .foregroundStyle(isChecked ? theme.textColor : theme.borderColor)
                }
                .buttonStyle(.plain)

                Group {
                    if let metadata = checkboxField.metadata, !metadata.isEmpty {
                        Text(attributedLabel(metadata: metadata))
                    } else {
                        Text(checkboxField.label)
                            .foregroundStyle(theme.textColor)
                    }
                }
                .font(.subheadline)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(theme.errorColor)
            }
        }
    }

    private func attributedLabel(metadata: [String: String]) -> AttributedString {
        var result = AttributedString(checkboxField.label)
        result.foregroundColor = theme.textColor

        for (linkText, urlString) in metadata {
            guard let url = URL(string: urlString) else { continue }

            var searchRange = result.startIndex ..< result.endIndex
            while let range = result[searchRange].range(of: linkText) {
                result[range].link = url
                result[range].foregroundColor = checkboxField.clickableTextColor
                result[range].underlineStyle = .single
                searchRange = range.upperBound ..< result.endIndex
            }
        }

        return result
    }
}
