import SwiftUI

struct PersonRow: View {
    let person: Person
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        content
            .contentShape(Rectangle())
            .swipeActions {
                Button("Edit", action: onEdit)

                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            }
    }
}

private extension PersonRow {
    var content: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(person.name.isEmpty ? "Unnamed" : person.name)
                .font(.headline)
                .foregroundStyle(person.name.isEmpty ? .secondary : .primary)

            Spacer()

            Text(person.age.formatted())
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(person.name.isEmpty ? "Unnamed" : person.name)
        .accessibilityValue("Age \(person.age)")
    }
}
