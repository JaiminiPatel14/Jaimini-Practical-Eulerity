//
//  DropdownComponent.swift
//  Jaimini-Practical-Eulerity
//
//  Created by Jaimini Shah on 09/06/26.
//

import SwiftUI

struct DropdownComponent: View {
    let dropdownField: DropdownField
    let theme: FormTheme
    @Binding var selectedOptionIds: [String]
    var error: String?

    @State private var showSheet = false
    @State private var showNoOptionsAlert = false
    @State private var draftSelection: [String] = []

    private var borderColor: Color {
        error != nil ? theme.errorColor : theme.borderColor
    }

    private var optionsById: [String: DropdownOption] {
        Dictionary(uniqueKeysWithValues: dropdownField.options.map { ($0.id, $0) })
    }

    private var displayText: String {
        let labels = selectedOptionIds.compactMap { optionsById[$0]?.label }
        if labels.isEmpty {
            return "Select…"
        }
        return labels.joined(separator: ", ")
    }

    var body: some View {
        if dropdownField.options.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text(dropdownField.label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(theme.textColor)
                
                HStack {
                    Text("No options available")
                        .foregroundStyle(theme.textColor.opacity(0.4))
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(theme.textColor.opacity(0.3))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(theme.borderColor.opacity(0.4), lineWidth: 1)
                )
                if dropdownField.required {
                    Text("This field is required but no options are configured")
                        .font(.caption)
                        .foregroundStyle(theme.errorColor.opacity(0.7))  // slightly muted vs real error
                }
            }
            .opacity(0.6)
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Text(dropdownField.label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(theme.textColor)

                Button(action: openPicker) {
                    HStack {
                        Text(displayText)
                            .foregroundStyle(
                                selectedOptionIds.isEmpty
                                    ? theme.textColor.opacity(0.5)
                                    : theme.textColor
                            )
                            .lineLimit(1)

                        Spacer()

                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(theme.textColor.opacity(0.7))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(borderColor, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                if let error {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(theme.errorColor)
                }
            }
            .sheet(isPresented: $showSheet) {
                DropdownPickerSheet(
                    options: dropdownField.options,
                    allowMultiple: dropdownField.allowMultiple,
                    theme: theme,
                    draftSelection: $draftSelection,
                    onCancel: { showSheet = false },
                    onDone: {
                        selectedOptionIds = draftSelection
                        showSheet = false
                    }
                )
                .presentationDetents([.height(300)])
            }
        }
    }

    private func openPicker() {
        if dropdownField.options.isEmpty {
            showNoOptionsAlert = true
            return
        }

        draftSelection = selectedOptionIds
        showSheet = true
    }
}

private struct DropdownPickerSheet: View {
    let options: [DropdownOption]
    let allowMultiple: Bool
    let theme: FormTheme
    @Binding var draftSelection: [String]
    let onCancel: () -> Void
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Cancel", action: onCancel)
                    .foregroundStyle(theme.textColor)

                Spacer()

                Button("Done", action: onDone)
                    .fontWeight(.semibold)
                    .foregroundStyle(theme.textColor)
            }
            .padding()

            Divider()
                .overlay(theme.borderColor)

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(options) { option in
                        Button {
                            toggleSelection(for: option.id)
                        } label: {
                            HStack(spacing: 12) {
                                Image(
                                    systemName: draftSelection.contains(option.id)
                                        ? "checkmark.square.fill"
                                        : "square"
                                )
                                .foregroundStyle(theme.textColor)

                                Text(option.label)
                                    .foregroundStyle(theme.textColor)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)

                        Divider()
                            .overlay(theme.borderColor)
                    }
                }
            }
        }
        .frame(height: 300)
        .background(theme.backgroundColor)
    }

    private func toggleSelection(for optionId: String) {
        if allowMultiple {
            if draftSelection.contains(optionId) {
                draftSelection.removeAll { $0 == optionId }
            } else {
                draftSelection.append(optionId)
            }
        } else {
            draftSelection = [optionId]
        }
    }
}
