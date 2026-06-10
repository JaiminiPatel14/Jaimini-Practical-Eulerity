//
//  TextFieldComponent.swift
//  Jaimini-Practical-Eulerity
//
//  Created by Jaimini Shah on 09/06/26.
//

import SwiftUI

struct TextFieldComponent: View {
    let textFormField: TextField
    let theme: FormTheme
    @Binding var text: String
    var error: String?

    private var borderColor: Color {
        error != nil ? theme.errorColor : theme.borderColor
    }

    private var placeholder: String {
        textFormField.placeholder ?? ""
    }

    var body: some View {
        if #available(iOS 17.0, *) {
            VStack(alignment: .leading, spacing: 6) {
                Text(textFormField.label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(theme.textColor)
                
                fieldInput
                    .foregroundStyle(theme.textColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(borderColor, lineWidth: 1)
                    )
                
                footer
            }
            .onChange(of: text) { _, newValue in
                if textFormField.maxLength != nil{
                    if newValue.count > textFormField.maxLength ?? 0 {
                        text = String(newValue.prefix(textFormField.maxLength ?? 0))
                    }
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Text(textFormField.label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(theme.textColor)
                
                fieldInput
                    .foregroundStyle(theme.textColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(borderColor, lineWidth: 1)
                    )
                
                footer
            }
        }
    }

    @ViewBuilder
    private var fieldInput: some View {
        switch textFormField.subtype {
        case .plain:
            SwiftUI.TextField(placeholder, text: $text)
                    
        case .multiline:
            ZStack(alignment: .topLeading) {
                if text.isEmpty, !placeholder.isEmpty {
                    Text(placeholder)
                        .foregroundStyle(theme.textColor.opacity(0.5))
                        .padding(.top, 8)
                        .padding(.leading, 4)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $text)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 44, maxHeight: 200)
                    .padding(-4)
            }

        case .number:
            SwiftUI.TextField(placeholder, text: $text)
                .keyboardType(.numberPad)

        case .uri:
            SwiftUI.TextField(placeholder, text: $text)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

        case .secure:
            SecureField(placeholder, text: $text)
        }
    }

    @ViewBuilder
    private var footer: some View {
        if error != nil || textFormField.maxLength != nil {
            HStack(alignment: .firstTextBaseline) {
                if let error {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(theme.errorColor)
                }

                Spacer()

                if let maxLength = textFormField.maxLength {
                    Text("\(text.count)/\(maxLength)")
                        .font(.caption)
                        .foregroundStyle(theme.textColor.opacity(0.7))
                }
            }
        }
    }
}
