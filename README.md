# Jaimini Practical Eulerity

A Server-Driven UI (SDUI) iOS app built with SwiftUI. The form layout, field types, validation rules, and theme are defined in a local `form.json` file and rendered at runtime.

## Architecture

The app follows a simple MVVM structure:

```
form.json
    ↓
FormModel (Codable)          — decodes JSON into typed field models
    ↓
FormViewModel (ObservableObject) — loads form, holds field state, validates, submits
    ↓
FormView + Components        — renders each field type with shared FormTheme
```

### Layers

| Layer | Responsibility |
|---|---|
| **Model** | `FormModel`, `FormTheme`, and per-type field structs (`TextField`, `DropdownField`, etc.) |
| **ViewModel** | Loads `form.json`, prepopulates defaults, validates on submit, prints results |
| **Views** | `FormView` orchestrates fields; each type has its own component (`TextFieldComponent`, `DropdownComponent`, `ToggleComponent`, `CheckboxComponent`) |
| **Utility** | `Color+Extension` for hex string → SwiftUI `Color` conversion |

### Key design choices

- **Polymorphic decoding** — the `fields` array is decoded into a `FormField` enum that dispatches on the `type` key. Unknown types (e.g. `COLOR_PICKER`) are skipped via lossy array decoding so the app never crashes on unsupported fields.
- **Theme-driven UI** — all components accept a `FormTheme` and apply colors from JSON (`background_color`, `text_color`, `border_color`, `error_color`).
- **State by field id** — the ViewModel stores values in dictionaries keyed by field id (`textValues`, `dropdownSelections`, `toggleValues`, `checkboxValues`), with bindings exposed to each component.
- **Dropdown picker** — custom sheet (300pt) with a scrollable checkbox list and Done/Cancel, instead of the system `Menu`.
- **Load error handling** — if `form.json` is missing, unreadable, or fails to decode, a full-screen error view is shown instead of an empty form.

## Product Decisions

### Empty options dropdown

The document didn't specify what to do when a dropdown has no options. I chose to show the field in a **disabled state** with a "No options available" label and **skip it during validation**, rather than blocking form submission for a field the user can never satisfy (e.g. `billing_account` in the sample JSON).

### Max length on pre-iOS 17

On pre-iOS 17 - iOS 17 truncates text while typing with onChange. Before 17, I Chose to let the user type freely and show the error on submit instead.

## What I'd Improve With More Time

- **Add unit tests**

## What I Got Stuck On

- **Polymorphic JSON decoding** — decoding a single `fields` array into different Swift types wasn't straightforward.

## Project Structure

```
Jaimini-Practical-Eulerity/
├── Model/
│   ├── FormModel.swift
│   └── ThemeModel.swift
├── ViewModel/
│   └── FormViewModel.swift
├── Views/
│   ├── FormView.swift
│   ├── TextFieldComponent.swift
│   ├── DropdownComponent.swift
│   ├── ToggleComponent.swift
│   └── CheckboxComponent.swift
├── Utility/
│   └── Color+Extension.swift
└── Resources/
    └── form.json
```

## Requirements

- iOS 16.6+
- Xcode 15+
- SwiftUI only — no third-party dependencies
