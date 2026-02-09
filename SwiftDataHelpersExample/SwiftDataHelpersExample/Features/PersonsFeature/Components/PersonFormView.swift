import SwiftUI

struct PersonFormView: View {
    let editor: PersonEditor
    let onSave: (String, Int) -> Void
    let onCancel: () -> Void

    @FocusState private var focusedField: Field?
    @State private var name: String
    @State private var age: Int

    init(
        editor: PersonEditor,
        onSave: @escaping (String, Int) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.editor = editor
        self.onSave = onSave
        self.onCancel = onCancel
        _name = State(initialValue: editor.initialName)
        _age = State(initialValue: editor.initialAge)
    }

    var body: some View {
        Form {
            Section("Details") {
                TextField("Name", text: $name)
                    .focused($focusedField, equals: .name)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .age }

                TextField("Age", value: $age, format: .number)
                    .focused($focusedField, equals: .age)
                    .keyboardType(.numberPad)
            }
        }
        .navigationTitle(editor.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", action: onCancel)
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    onSave(name, age)
                }
            }

            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
            }
        }
    }
}

private extension PersonFormView {
    enum Field: Hashable {
        case name
        case age
    }
}
