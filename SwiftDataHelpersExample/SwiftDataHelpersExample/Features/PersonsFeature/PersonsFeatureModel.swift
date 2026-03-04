import Observation
import OSLog
import SwiftData
import SwiftDataHelpers

@MainActor
@Observable
final class PersonsFeatureModel {
    @ObservationIgnored
    @LiveQuery var persons: [Person]

    var editor: PersonEditor?
    var filter: PersonFilter = .all
    var sort: PersonSort = .name

    private let logger = Logger(
        subsystem: "lv.krutov.SwiftDataHelpersExample",
        category: "PersonsFeatureModel"
    )

    func addPerson(database: Database) {
        editor = .new(database: database)
    }

    func editPerson(_ person: Person, database: Database) {
        editor = .edit(person, database: database)
    }

    func savePerson(editor: PersonEditor, name: String, age: Int) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            let context = editor.database.container.mainContext
            let person: Person

            if let existingPerson = editor.existingPerson {
                person = existingPerson
                person.name = trimmedName
                person.age = age

            } else {
                person = Person(id: UUID(), name: trimmedName, age: age)
            }

            try Person.upsert(person, modelContext: context)
        } catch {
            logger.error("Failed to save person: \(error)")
        }
    }

    func deletePerson(_ person: Person, database: Database) {
        do {
            try person.delete(modelContext: database.container.mainContext)
        } catch {
            logger.error("Failed to delete person: \(error)")
        }
    }

    func importRandomPeople(count: Int, database: Database) {
        let seeds = (0..<count).map { _ in PersonSeed.random() }
        let container = database.container

        Task {
            let importer = PersonImporter(modelContainer: container)

            do {
                try await importer.importPeople(seeds)
            } catch {
                logger.error("Failed to import people: \(error)")
            }
        }
    }

    func addRandomPet(to owner: Person) {
        do {
            let context = Database.main.container.mainContext
            try Pet.upsert(.random(owner: owner), modelContext: context)
        } catch {
            logger.error("Failed to save pet: \(error)")
        }
    }

    func deletePet(_ pet: Pet) {
        do {
            let context = Database.main.container.mainContext
            try pet.delete(modelContext: context)
        } catch {
            logger.error("Failed to delete pet: \(error)")
        }
    }
}
