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

            if let existingPerson = editor.existingPerson {
                existingPerson.name = trimmedName
                existingPerson.age = age
            } else {
                let newPerson = Person(id: UUID(), name: trimmedName, age: age)
                context.insert(newPerson)
            }

            try context.save()
        } catch {
            logger.error("Failed to save person: \(error)")
        }
    }

    func deletePerson(_ person: Person, database: Database) {
        do {
            let context = database.container.mainContext
            context.delete(person)
            try context.save()
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
            let pet = Pet.random(owner: owner)
            context.insert(pet)
            try context.save()
        } catch {
            logger.error("Failed to save pet: \(error)")
        }
    }

    func deletePet(_ pet: Pet) {
        do {
            let context = Database.main.container.mainContext
            context.delete(pet)
            try context.save()
        } catch {
            logger.error("Failed to delete pet: \(error)")
        }
    }
}
