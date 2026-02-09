import SwiftData
import SwiftDataHelpers
import SwiftUI

struct PetsSection: View {
    @State private var selectedPersonID: UUID?
    @LiveQuery(sort: [SortDescriptor(\.name)]) private var persons: [Person]

    let model: PersonsFeatureModel

    var body: some View {
        Section {
            content
        } header: {
            Label("Pets", systemImage: "pawprint")
        } footer: {
            Text("Pets are deleted automatically when their owner is deleted (cascade rule).")
        }
        .onAppear(perform: syncSelection)
        .onChange(of: persons.map(\.id)) { _, _ in
            syncSelection()
        }
    }
}

private extension PetsSection {
    @ViewBuilder
    var content: some View {
        if persons.isEmpty {
            ContentUnavailableView(
                "No people yet",
                systemImage: "person.2",
                description: Text("Add a person first to attach pets.")
            )
        } else {
            ownerPicker

            if let selectedPerson {
                PetsList(ownerID: selectedPerson.id, onDelete: model.deletePet)

                Button("Add Random Pet") {
                    model.addRandomPet(to: selectedPerson)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    var ownerPicker: some View {
        Picker("Owner", selection: $selectedPersonID) {
            ForEach(persons) { person in
                Text(person.name.isEmpty ? "Unnamed" : person.name)
                    .tag(Optional(person.id))
            }
        }
        .pickerStyle(.menu)
    }

    var selectedPerson: Person? {
        guard let selectedPersonID else { return nil }
        return persons.first { $0.id == selectedPersonID }
    }

    func syncSelection() {
        if let selectedPersonID,
           persons.contains(where: { $0.id == selectedPersonID }) {
            return
        }

        selectedPersonID = persons.first?.id
    }
}

private struct PetsList: View {
    private let ownerID: UUID
    private let onDelete: (Pet) -> Void

    @LiveQuery private var pets: [Pet]

    init(ownerID: UUID, onDelete: @escaping (Pet) -> Void) {
        self.ownerID = ownerID
        self.onDelete = onDelete
        _pets = LiveQuery(
            predicate: #Predicate<Pet> { $0.owner?.id == ownerID },
            sort: [SortDescriptor(\.name)]
        )
    }

    var body: some View {
        if pets.isEmpty {
            ContentUnavailableView(
                "No pets yet",
                systemImage: "pawprint",
                description: Text("Add one with the button below.")
            )
        } else {
            ForEach(pets) { pet in
                PetRow(pet: pet, onDelete: { onDelete(pet) })
            }
        }
    }
}

private struct PetRow: View {
    let pet: Pet
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(pet.name.isEmpty ? "Unnamed" : pet.name)
                .font(.headline)
                .foregroundStyle(pet.name.isEmpty ? .secondary : .primary)

            Spacer()

            Text(pet.kind)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .swipeActions {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(pet.name.isEmpty ? "Unnamed" : pet.name)
        .accessibilityValue(pet.kind)
    }
}
