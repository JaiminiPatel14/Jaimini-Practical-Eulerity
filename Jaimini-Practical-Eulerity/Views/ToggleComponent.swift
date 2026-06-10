//
//  ToggleComponent.swift
//  Jaimini-Practical-Eulerity
//
//  Created by Jaimini Shah on 09/06/26.
//

import SwiftUI

struct ToggleComponent: View {
    let toggleField: ToggleField
    let theme: FormTheme
    @Binding var isOn: Bool
    var error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center) {
                Text(toggleField.label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(theme.textColor)
                    .multilineTextAlignment(.leading)

                Spacer()

                Toggle("", isOn: $isOn)
                    .labelsHidden()
                    .tint(theme.textColor)
            }
            if let error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(theme.errorColor)
            }
        }
    }
}
