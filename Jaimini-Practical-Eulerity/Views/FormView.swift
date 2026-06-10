//
//  FormView.swift
//  Jaimini-Practical-Eulerity
//
//  Created by Jaimini Shah on 09/06/26.
//

import SwiftUI

struct FormView: View {
    @StateObject private var viewModel = FormViewModel()

    var body: some View {
        Group {
            if let loadErrorMessage = viewModel.loadErrorMessage {
                FormLoadErrorView(message: loadErrorMessage, theme: viewModel.theme)
            } else {
                formContent
            }
        }
    }

    private var formContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(viewModel.formTitle)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(viewModel.theme.textColor)

                ForEach(viewModel.fields, id: \.id) { field in
                    fieldView(for: field)
                }

                Button(action: viewModel.submit) {
                    Text("Submit")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundStyle(viewModel.theme.backgroundColor)
                        .background(viewModel.theme.textColor)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding()
        }
        .background(viewModel.theme.backgroundColor)
        .alert("Success", isPresented: $viewModel.showSubmitSuccessAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Form submitted successfully.")
        }
    }

    @ViewBuilder
    private func fieldView(for field: FormField) -> some View {
        switch field {
        case .text(let textField):
            TextFieldComponent(
                textFormField: textField,
                theme: viewModel.theme,
                text: viewModel.textBinding(for: textField.id),
                error: viewModel.error(for: textField.id)
            )

        case .dropdown(let dropdownField):
            DropdownComponent(
                dropdownField: dropdownField,
                theme: viewModel.theme,
                selectedOptionIds: viewModel.dropdownBinding(for: dropdownField.id),
                error: viewModel.error(for: dropdownField.id)
            )

        case .toggle(let toggleField):
            ToggleComponent(
                toggleField: toggleField,
                theme: viewModel.theme,
                isOn: viewModel.toggleBinding(for: toggleField.id),
                error: viewModel.error(for: toggleField.id)
            )

        case .checkbox(let checkboxField):
            CheckboxComponent(
                checkboxField: checkboxField,
                theme: viewModel.theme,
                isChecked: viewModel.checkboxBinding(for: checkboxField.id),
                error: viewModel.error(for: checkboxField.id)
            )
        }
    }
}

private struct FormLoadErrorView: View {
    let message: String
    let theme: FormTheme

    var body: some View {
        Text(message)
            .font(.body)
            .foregroundStyle(theme.errorColor)
            .multilineTextAlignment(.center)
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.backgroundColor)
    }
}

#Preview {
    FormView()
}
