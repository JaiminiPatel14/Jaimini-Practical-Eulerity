# FormTheme model implementation
_Exported on 10/06/2026 at 20:48:16 GMT+5:30 from Cursor (3.7.21)_

---

**User**

I'm building a Server-Driven UI iOS app
It renders a dynamic form from a local JSON file with i already added as form.json
Create ThemeModel.swift in Model folder, i already created Folder structure.

Req
- Create a Codable struct called FormTheme that maps to the theme object in the JSON. All color values inside the theme object are provided as hex strings
- Add a Color extension that converts hex string to SwiftUI Color
- Add computed var properties on FormTheme that return SwiftUI Color for each field using the hex extension
- If hex string is invalid, return a another safe color for alternative
- No external libraries, SwiftUI only

JSON keys use snake_case, Swift properties use camelCase.
Use CodingKeys enum to map them.

---

**Cursor**

I'll inspect the project layout and `form.json` so `ThemeModel.swift` matches your theme structure.


Creating `ThemeModel.swift` with `FormTheme`, a hex `Color` extension, and computed color properties matching `form.json`.


`ThemeModel.swift` is in the Model folder. Here's what it includes:

### `FormTheme`
Decodes the four theme hex strings from `form.json` via `CodingKeys`:

| JSON key | Stored property | Computed `Color` |
|---|---|---|
| `background_color` | `backgroundColorHex` | `backgroundColor` |
| `text_color` | `textColorHex` | `textColor` |
| `border_color` | `borderColorHex` | `borderColor` |
| `error_color` | `errorColorHex` | `errorColor` |

Stored properties keep the `Hex` suffix so the computed properties can use the natural camelCase names (`backgroundColor`, etc.) as `Color` values.

### `Color` hex extension
- Accepts `#RRGGBB` and `#RRGGBBAA` (with or without `#`)
- Trims whitespace and validates hex digits
- Falls back to neutral gray (`0.5, 0.5, 0.5`) when the string is invalid

### Usage example

```swift
let form = try JSONDecoder().decode(FormRoot.self, from: data)
form.theme.backgroundColor  // SwiftUI Color from "#121212"
```

The project uses a synchronized file group, so Xcode should pick up the new file automatically. If you want the stored hex properties named `backgroundColor` instead of `backgroundColorHex`, we can switch to a custom `init(from:)` so the computed `Color` properties keep the shorter names.

---

**User**

Now lets build formModel codable model i already created file inside Model folder
Take Json from form.json . Use polymorphic decoding for "type" inside "fields"

Types--
TEXT

PLAIN: Standard single-line TextField.
MULTILINE: Expanding multi-line TextEditor or axis-constrained TextField.
NUMBER: Text field restricted to numeric keyboards.
URI: Text field optimized for URLs/Web addresses.
SECURE: A password field that masks characters (SecureField).

DROPDOWN
TOGGLE
CHECKBOX

Unknown types (like DATE_PICKER):
- App must NOT crash
- Gracefully skip them

All fields define optional with nil default for some cases which dont have values or anycases you should handle it without crashing
@Jaimini-Practical-Eulerity/Model/ThemeModel.swift is already created so connect with it

---

**Cursor**

Reviewing `form.json`, `ThemeModel.swift`, and the existing `FormModel.swift` to design polymorphic field decoding.


Implementing `FormModel.swift` with polymorphic field decoding, lossy skipping for unknown types, and integration with `FormTheme`.


Verifying the project builds and `form.json` decodes correctly.


`FormModel.swift` is in place and builds successfully. Here's the structure:

### Root: `FormModel`
- `theme: FormTheme` — wired to your existing theme model
- `formTitle` — from `form_title`
- `fields: [FormField]` — decoded with lossy skipping, then sorted by `order`

### Polymorphic `FormField` enum
Dispatches on the `type` key:

| `type` | Case | Subtype / extras |
|---|---|---|
| `TEXT` | `.text(TextField)` | `PLAIN`, `MULTILINE`, `NUMBER`, `URI`, `SECURE` |
| `DROPDOWN` | `.dropdown(DropdownField)` | `allow_multiple`, `options` |
| `TOGGLE` | `.toggle(ToggleField)` | `default_value` (Bool) |
| `CHECKBOX` | `.checkbox(CheckboxField)` | `metadata`, `clickable_text_color` |

### Resilience
- **Unknown types** (e.g. `COLOR_PICKER`) — `FailableDecodable` skips them; the app does not crash
- **Missing optionals** — `required` defaults to `false`, `options` to `[]`, `allowMultiple` to `false`, unknown TEXT `subtype` to `.plain`
- **Shared accessors** on `FormField`: `id`, `order`, `label`, `errorMessage`, `required`

### Checkbox + theme
`CheckboxField.clickableTextColor` uses your `Color(hex:)` extension, falling back to `.accentColor` when no hex is provided.

### Usage

```swift
let url = Bundle.main.url(forResource: "form", withExtension: "json")!
let data = try Data(contentsOf: url)
let form = try JSONDecoder().decode(FormModel.self, from: data)

form.theme.backgroundColor   // from FormTheme
form.fields.count            // 9 — COLOR_PICKER is skipped
```

From `form.json`, you get 9 fields (all except `brand_color` / `COLOR_PICKER`), ordered 1–10. Next step is usually a `FormViewModel` to load this and a `FormView` to render each `FormField` case.

---

**User**

pls use decodeIfPresent for missing keys and nil values
and also use decodeSafely for wrong type

---

**Cursor**

Checking the codebase for existing decoding helpers, then updating `FormModel.swift` to use `decodeIfPresent` and safe type decoding.


Adding a `decodeSafely` helper and updating `FormModel` and `ThemeModel` to use `decodeIfPresent`/`decodeSafely` throughout.


Updated decoding to use `decodeIfPresent` under the hood via a new `decodeSafely` helper.

### New: `KeyedDecodingContainer+DecodeSafely.swift`

```swift
// Optional — nil when key missing, JSON null, or wrong type
func decodeSafely<T>(_ type: T.Type, forKey key: Key) -> T?

// With fallback — uses default when key missing, null, or wrong type
func decodeSafely<T>(_ type: T.Type, forKey key: Key, default defaultValue: T) -> T
```

Both wrap `decodeIfPresent` in `try?`, so wrong types (e.g. `"order": "four"`) resolve to `nil` or the default instead of crashing.

### `FormModel` changes
- **Root** — `theme`, `formTitle`, and `fields` all use `decodeSafely` with sensible fallbacks
- **Field structs** — optional properties use `decodeSafely` (returns `nil`); properties with defaults use `decodeSafely(..., default:)`
- **`id`** — still required; missing/invalid `id` throws so `FailableDecodable` skips that field
- **`DropdownOption`** — custom decoder with `decodeSafely`; options with empty `id` are filtered out

### `ThemeModel` changes
- Custom `init(from:)` using `decodeSafely` with the JSON’s default hex colors as fallbacks

### Behavior summary

| Situation | Result |
|---|---|
| Key missing | `nil` or default |
| JSON `null` | `nil` or default |
| Wrong type | `nil` or default |
| Unknown field `type` | Field skipped (no crash) |
| Invalid / missing `id` | Field skipped (no crash) |

---

**User**

Here is one note
Note: Optional fields (placeholder, supporting text, max length) should only apply if present in the JSON.
also Instead decodeSafely use try for handling wrong type

---

**Cursor**

Reviewing the models and updating decoding: remove `decodeSafely`, use `try`/`decodeIfPresent`, and keep optional fields unset unless present in JSON.


Replacing `decodeSafely` with `try`/`decodeIfPresent`, adding `supportingText` as a JSON-only optional, and removing the helper file.


Fixing a typo and restoring the truncated file.


Updated decoding to use `try` + `decodeIfPresent` throughout, and removed `decodeSafely`.

### Changes

**Removed** `KeyedDecodingContainer+DecodeSafely.swift`

**Optional fields** (`placeholder`, `maxLength`, `supportingText`, `defaultValue`, `errorMessage`, etc.) now use:
```swift
placeholder = try container.decodeIfPresent(String.self, forKey: .placeholder)
```
They stay `nil` when the key is absent or JSON `null` — no synthetic defaults.

**Wrong types** propagate via `try`:
- `decodeIfPresent` / `decode` throw on type mismatch
- `FailableDecodable` catches per-field failures and skips bad entries (unknown types, corrupt fields)
- Required keys like `id` and `type` use `try container.decode(...)` so invalid data fails that field cleanly

**Added** `supportingText` on `TextField` mapped from `supporting_text`

### Field decoding pattern

| Category | Example | Behavior |
|---|---|---|
| Required | `id`, `type` | `try decode` — missing or wrong type skips field |
| Optional UI | `placeholder`, `maxLength`, `supportingText` | `try decodeIfPresent` — only set when in JSON |
| Semantic defaults | `required`, `order`, `subtype` | `try decodeIfPresent(...) ?? default` |
| Unknown field types | `COLOR_PICKER` | Throws → skipped by `FailableDecodable` |

In the UI layer, only show placeholder, supporting text, or max-length validation when the corresponding property is non-`nil`.

---

**User**

Now lets create UI
First, Create TextFieldComponent  view file
Subtype:
- PLAIN → TextField default keyboard
- MULTILINE → TextField axis:.vertical lineLimit(3...6)
- NUMBER → TextField keyboardType(.numberPad)
- URI → TextField keyboardType(.URL)
- SECURE → SecureField

Theme: FormTheme

Styling:
Label above the field for fieldname
Rounded border 1px cornerRadius 8. - Border colors : ThemeModel (Normal nd errorcolor)
Tiny label will show error msg and only appears when error is not nil

Validation: If max_length is provided, prevent typing past the limit and display a character counter.

Inputs: formFields - > textFormField

Also implement preview code so i can checkit


---

**Cursor**

Reviewing the project structure and models before implementing `TextFieldComponent`.


Creating `TextFieldComponent` with subtype-specific inputs, theme styling, max-length enforcement, and previews. Resolving the `TextField` naming conflict with SwiftUI.


`TextFieldComponent` is in `Views/TextFieldComponent.swift`.

### API

```swift
TextFieldComponent(
    textFormField: textField,  // model TextField from FormModel
    theme: theme,              // FormTheme
    text: $text,                // binding
    error: validationError     // nil hides error label
)
```

### Subtypes

| Subtype | Control |
|---|---|
| `PLAIN` | `TextField` — default keyboard |
| `MULTILINE` | `TextField(axis: .vertical)` + `lineLimit(3...6)` |
| `NUMBER` | `TextField` + `.keyboardType(.numberPad)` |
| `URI` | `TextField` + `.keyboardType(.URL)` |
| `SECURE` | `SecureField` |

### Styling
- Label above the input (`textFormField.label`)
- 1px rounded border (`cornerRadius: 8`) — `theme.borderColor` normally, `theme.errorColor` when `error != nil`
- Caption error text below (only when `error != nil`)
- Character counter `count/max` when `max_length` is in JSON

### Max length
A custom binding truncates input so users cannot type past `max_length`.

### Previews
Six previews in the canvas:
- **Plain** — with counter (max 20)
- **Plain — Error** — error state + red border
- **Multiline**, **Number**, **URI**, **Secure**

All use the dark theme from `form.json`. Open the file and use the canvas preview picker to switch between them.

---

**User**

Use TextEditor for MULTILINE instead of textfield

---

**Cursor**

Updated the `MULTILINE` case to use `TextEditor` with:

- `lineLimit(3...6)` for vertical expansion
- `scrollContentBackground(.hidden)` so it fits inside the bordered container
- Placeholder overlay when text is empty (since `TextEditor` has no built-in placeholder)

Check the **Multiline** preview in the canvas to verify the layout.

---

**User**

Same way create DropdownComponent View
Chevron down icon right side, use Menu for showing options
Data Mapping: The UI shows the label, but state tracks the id.
Multi-Select: If allow_multiple is true, support selecting multiple options (e.g., checkboxes inside a menu).

Same way also create ToggleComponent View
Leftside show Label title and right side Toggle

Also create CheckBoxComponent View same way
for acceptiong terms and conditions
check box with text
If "metadata" is there:
create hyperlink according to key as  hyperlink text and value as link using attributed string


---

**Cursor**

Reviewing existing components and models to match styling and data structures for the three new views.


Creating the three components with consistent styling and previews.


Created three components matching `TextFieldComponent` styling.

### `DropdownComponent`
- Label above the control
- `Menu` trigger with selected label(s) + chevron on the right
- **State:** `@Binding var selectedOptionIds: [String]` — tracks option **ids**
- **Display:** resolves ids to option **labels** for the trigger text
- **Single select:** tap sets `[id]`; checkmark on active item
- **Multi-select** (`allow_multiple`): checkbox rows inside the menu; toggle ids in the array
- Error caption below when `error != nil`
- Previews: Single Select, Multi Select, Multi Select — Error

### `ToggleComponent`
- `HStack`: label on the left, `Toggle` on the right
- Bordered container + optional error caption
- **State:** `@Binding var isOn: Bool`
- Previews: on / off states

### `CheckboxComponent`
- Checkbox button + label text in a bordered row
- **State:** `@Binding var isChecked: Bool`
- **Metadata:** builds an `AttributedString` — each metadata **key** in the label becomes a hyperlink to its **value** URL, styled with `clickableTextColor`
- Plain label when no metadata
- Previews: Terms & Conditions (with links), error state, plain checkbox

### Usage

```swift
DropdownComponent(dropdownField: field, theme: theme, selectedOptionIds: $ids, error: err)
ToggleComponent(toggleField: field, theme: theme, isOn: $isOn, error: err)
CheckboxComponent(checkboxField: field, theme: theme, isChecked: $isChecked, error: err)
```

Open each file in the canvas to preview the variants.

---

**User**

Create FormViewModel as ObservableObject

Prepopulate:
dropdown values, toggle value, form title
Create required published properties

Validation:
Loop through all fields
For required fields - check Textfield, dropdown, toggle or checkbox  is not empty and  populate proper error msg
TextFIeld - If max_length is provided, prevent typing past the limit and display a character counter.

Submit:
Validate first
if succeed: Show alert of succeed and print all type and values to console

clear previous errors before revalidating

---

**Cursor**

Reviewing existing files to implement `FormViewModel` and wire it into the form UI.


Implementing `FormViewModel` and wiring `FormView` for validation, submit, and the success alert.


`FormViewModel` is implemented and wired into `FormView` (with `ContentView` pointing to it so you can run the full flow).

### Published state
| Property | Purpose |
|---|---|
| `theme`, `formTitle`, `fields` | Loaded from `form.json` |
| `textValues` | Text field values keyed by field id |
| `dropdownSelections` | Selected option **ids** per dropdown |
| `toggleValues` | Toggle on/off per field id |
| `checkboxValues` | Checkbox checked state per field id |
| `fieldErrors` | Validation errors keyed by field id |
| `showSubmitSuccessAlert` | Drives success alert on submit |

### Prepopulation
- **Form title** from JSON
- **Text fields** from `default_value` (e.g. campaign name)
- **Toggles** from `default_value` (e.g. `enable_ai_opt` → `true`)
- **Dropdowns** start as `[]` (no defaults in JSON)
- **Checkboxes** start as `false`

### Validation (`validate()`)
- Clears `fieldErrors` first
- Loops every field; for **required** fields:
  - **Text** — non-empty (trimmed); also checks `max_length` if set
  - **Dropdown** — at least one selected id
  - **Toggle** — must be `true` when required
  - **Checkbox** — must be checked
- Uses each field’s `error_message` from JSON when present

Max-length typing is still enforced in `TextFieldComponent`; validation is a second check on submit.

### Submit (`submit()`)
1. Runs `validate()`
2. On success → prints all field types/values to console and sets `showSubmitSuccessAlert = true`
3. On failure → errors show on the relevant components

### Console output example
```
——— Form Submission ———
Title: Comprehensive Campaign Setup
TEXT (PLAIN) campaign_name: "Summer Sale 2026"
DROPDOWN ad_networks: ids=["net_google"] labels=["Google Search"]
TOGGLE enable_ai_opt: true
CHECKBOX accept_legal: true
———————————————————————
```

Run the app, fill the form, and tap **Submit**. Check Xcode’s console for the printed output. Note: `billing_account` is required but has no options in JSON, so submit will fail until that field is addressed in the data or validation logic.

---

**User**

Add optional regex_pattern into form.json into TextFieldData
on Save: if a TEXT field has regex_pattern and the value is not empty, validate with RegularExpression show error
Skip regex when pattern is missing,  don’t crash on invalid pattern

---

**Cursor**

Adding optional `regex_pattern` to the model and JSON, then wiring regex validation into submit without crashing on invalid patterns.


Added optional `regex_pattern` support across the model, JSON, and submit validation.

### `TextField` model
- New optional property: `regexPattern` mapped from `regex_pattern`
- Decoded with `decodeIfPresent` — omitted from JSON when not needed

### `form.json` examples
| Field | Pattern |
|---|---|
| `daily_budget` | `^\d+(\.\d{1,2})?$` |
| `destination_url` | `^https?://\S+$` |

### Submit validation (`FormViewModel`)
After required and `max_length` checks:
- Runs only when `regex_pattern` is present **and** the value is non-empty
- Uses `NSRegularExpression` via `try?` — invalid patterns are skipped (no crash)
- On mismatch → sets `fieldErrors` using the field’s `error_message`

```swift
private func matchesRegex(pattern: String, value: String) -> Bool {
    guard let regex = try? NSRegularExpression(pattern: pattern) else {
        return true  // invalid pattern → skip
    }
    let range = NSRange(value.startIndex ..< value.endIndex, in: value)
    return regex.firstMatch(in: value, options: [], range: range) != nil
}
```

---

**User**

DOnt touch form.json

---

**Cursor**

Reverting `form.json` to its original state while keeping model and validation changes.


Reverted `form.json` to its original content — removed the `regex_pattern` entries and restored the original error messages.

`regex_pattern` support remains in `TextField` and `FormViewModel`; it only runs when that key is present in the JSON. I won’t modify `form.json` going forward unless you ask.

---

**User**

create simple popup view with 300 height of popup and then use scrolling list
in list we just need checkbox and label
instead u used menuview we want custom menu with done and cancel button
dont make it so complex and use theme for UI
and present it as .sheet

also manage when json file dont have options pls dont show popop instead show alert of options are not available

---

**Cursor**

Reviewing `DropdownComponent` to replace the Menu with a themed sheet popup.


Replacing the Menu with a themed sheet picker (300pt height, Done/Cancel) and an alert when options are empty.


Updated `DropdownComponent` to use a custom sheet instead of `Menu`.

### Behavior
- **Tap field** → if `options` is empty, shows alert: **"Options are not available"** (no sheet)
- **Has options** → presents a `.sheet` at **300pt** height

### Sheet (`DropdownPickerSheet`)
- **Cancel** / **Done** bar at the top (themed)
- **ScrollView** list — each row is checkbox + label
- **Multi-select** — toggles checkboxes in a draft selection
- **Single-select** — one selection at a time (still checkbox UI)
- **Cancel** — dismisses without saving
- **Done** — applies draft to `selectedOptionIds`

### Styling
Uses `FormTheme` for background, text, borders, and checkbox icons.

Previews include Single Select, Multi Select, and Empty Options (tap to see the alert).

---

**User**

if default value is provided in json pls consider as final value nd make it also editable by user

---

**Cursor**

Checking how defaults are handled across models and the view model.


Enhancing default-value handling: applying text defaults (respecting `max_length`), and adding `default_value` support for dropdowns and checkboxes in the model—without modifying `form.json`.


Updated default value handling across models and `FormViewModel`. `form.json` was not changed.

### `FormViewModel` prepopulation
All fields with `default_value` in JSON now load into published state on launch. Values stay bound to the UI so the user can edit them.

| Field type | Behavior |
|---|---|
| **TEXT** | Uses `default_value` as initial text; truncated to `max_length` when set (e.g. campaign name → first 20 chars) |
| **TOGGLE** | Uses `default_value` bool (e.g. `enable_ai_opt` → `true`) |
| **DROPDOWN** | Uses `default_value` as option id(s); only ids that exist in `options` are applied |
| **CHECKBOX** | Uses `default_value` bool when provided; otherwise `false` |

### Model updates
- **`DropdownField`** — optional `defaultOptionIds` from `default_value` (string or `[string]`)
- **`CheckboxField`** — optional `defaultValue` from `default_value`

Defaults are the starting values in `textValues`, `toggleValues`, `dropdownSelections`, and `checkboxValues` — not placeholders. Users can change them normally through each component.

---

**User**

In my loadForm(), I handle 3 failure scenarios
For each, show a full-screen error view with just an error message label instead of returning silently.

---

**Cursor**

Adding a published load error state to the view model and a full-screen error view in `FormView`.


Each `loadForm()` failure now sets `loadErrorMessage` and shows a full-screen error instead of failing silently.

### `FormViewModel`
- `@Published private(set) var loadErrorMessage: String?`
- **File not found** → `"Could not find form.json in the app bundle."`
- **Read failed** → `"Failed to read data from form.json."`
- **Decode failed** → `"Failed to decode form.json: …"` (includes `localizedDescription`)
- On success → `loadErrorMessage = nil`

### `FormView`
- If `loadErrorMessage` is set → `FormLoadErrorView` (full screen, centered label, theme background + error color)
- Otherwise → normal form content

Uses the default theme from init when load fails before JSON is parsed.

---

**User**

Make Textview Only expand till 200 height for multiline

---

**Cursor**

Updated the multiline `TextEditor` to use `.frame(minHeight: 44, maxHeight: 200)` instead of `lineLimit(3...6)`. It grows with content up to 200pt, then scrolls inside the field.

---

**User**

Now create simple README file for this project

- Your overall approach and architecture.

cover below points
- Product Decisions:
   • Empty options dropdown - document didn't say what to do when a dropdown has no options. Chose to show the field in a disabled state with "No options available" label and skip it during validation, since blocking the form for submission.
   • Max length on pre-iOS 17 - iOS 17 truncates text while typing with onChange. Before 17, I Chose to let the user type freely and show the error on submit instead.

- What I'd Improve With More Time
   • Add unit tests

- What I Got Stuck On
   • Polymorphic JSON decoding - decoding a single fields array into different types wasn't straightforward.


---

**Cursor**

Checking the project structure and a few implementation details so the README is accurate.


Created `README.md` at the project root. It covers:

- **Architecture** — SDUI flow from `form.json` → Model → ViewModel → Views, with a structure table
- **Design choices** — polymorphic decoding, theme-driven UI, dropdown sheet, load errors
- **Product decisions** — empty dropdown (disabled + skip validation) and pre-iOS 17 max length
- **What I'd improve** — unit tests
- **What I got stuck on** — polymorphic JSON decoding
- **Project structure** and requirements

Say if you want the tone more formal or more interview-style.

