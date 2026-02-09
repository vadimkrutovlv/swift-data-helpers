import Foundation

struct PersonEditor: Identifiable {
    enum Mode {
        case create
        case edit
    }

    let id: UUID
    let database: Database
    let mode: Mode
    let existingPerson: Person?

    var title: String {
        switch mode {
        case .create:
            switch database {
            case .main:
                "Add to Main DB"
            case .privatePersons:
                "Add to Private DB"
            }
        case .edit:
            "Edit Person"
        }
    }

    var initialName: String { existingPerson?.name ?? "" }
    var initialAge: Int { existingPerson?.age ?? 0 }

    static func new(database: Database) -> PersonEditor {
        PersonEditor(
            id: UUID(),
            database: database,
            mode: .create,
            existingPerson: nil
        )
    }

    static func edit(_ person: Person, database: Database) -> PersonEditor {
        PersonEditor(
            id: UUID(),
            database: database,
            mode: .edit,
            existingPerson: person
        )
    }
}
