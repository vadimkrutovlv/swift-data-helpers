import Foundation
import Dependencies
import SwiftData
import Testing
@testable import SwiftDataHelpersExample
internal import SwiftDataHelpers

@Suite("PersonsFeatureModel")
@MainActor
struct PersonsFeatureModelTests {
    @Test("Add person sets editor")
    func addPersonSetsEditor() throws {
        try withTestDependencies {
            try resetStores()
            let model = PersonsFeatureModel()

            model.addPerson(database: .main)

            let editor = try #require(model.editor)
            #expect(editor.mode == .create)
            #expect(editor.database == .main)
            #expect(editor.existingPerson == nil)
        }
    }

    @Test("Edit person sets editor")
    func editPersonSetsEditor() throws {
        try withTestDependencies {
            try resetStores()
            let model = PersonsFeatureModel()
            let context = ModelContainer.main.mainContext
            let person = Person(id: UUID(), name: "Alex", age: 28)
            context.insert(person)
            try context.save()

            model.editPerson(person, database: .main)

            let editor = try #require(model.editor)
            #expect(editor.mode == .edit)
            #expect(editor.database == .main)
            #expect(editor.existingPerson?.id == person.id)
        }
    }

    @Test("Save new person in main DB")
    func saveNewPersonInMain() throws {
        try withTestDependencies {
            try resetStores()
            let model = PersonsFeatureModel()

            model.savePerson(editor: .new(database: .main), name: "  Sam  ", age: 30)

            let context = ModelContainer.main.mainContext
            let people = try context.fetch(FetchDescriptor<Person>())
            #expect(people.count == 1)
            #expect(people.first?.name == "Sam")
            #expect(people.first?.age == 30)
        }
    }

    @Test("Save edit updates main DB")
    func saveEditUpdatesMain() throws {
        try withTestDependencies {
            try resetStores()
            let model = PersonsFeatureModel()
            let context = ModelContainer.main.mainContext
            let person = Person(id: UUID(), name: "Old", age: 19)
            context.insert(person)
            try context.save()

            model.savePerson(editor: .edit(person, database: .main), name: "New", age: 40)

            let people = try context.fetch(FetchDescriptor<Person>())
            #expect(people.count == 1)
            #expect(people.first?.name == "New")
            #expect(people.first?.age == 40)
        }
    }

    @Test("Delete person removes from main DB")
    func deletePersonRemovesFromMain() throws {
        try withTestDependencies {
            try resetStores()
            let model = PersonsFeatureModel()
            let context = ModelContainer.main.mainContext
            let person = Person(id: UUID(), name: "Delete", age: 33)
            context.insert(person)
            try context.save()

            model.deletePerson(person, database: .main)

            let people = try context.fetch(FetchDescriptor<Person>())
            #expect(people.isEmpty)
        }
    }

    @Test("Save new person in private DB")
    func saveNewPersonInPrivate() throws {
        try withTestDependencies {
            try resetStores()
            let model = PersonsFeatureModel()

            model.savePerson(editor: .new(database: .privatePersons), name: "Private", age: 22)

            let privateContext = ModelContainer.privatePersons.mainContext
            let privatePeople = try privateContext.fetch(FetchDescriptor<Person>())
            #expect(privatePeople.count == 1)
            #expect(privatePeople.first?.name == "Private")
            #expect(privatePeople.first?.age == 22)

            let mainContext = ModelContainer.main.mainContext
            let mainPeople = try mainContext.fetch(FetchDescriptor<Person>())
            #expect(mainPeople.isEmpty)
        }
    }

    @Test("Delete person removes from private DB")
    func deletePersonRemovesFromPrivate() throws {
        try withTestDependencies {
            try resetStores()
            let model = PersonsFeatureModel()
            let context = ModelContainer.privatePersons.mainContext
            let person = Person(id: UUID(), name: "Private", age: 45)
            context.insert(person)
            try context.save()

            model.deletePerson(person, database: .privatePersons)

            let people = try context.fetch(FetchDescriptor<Person>())
            #expect(people.isEmpty)
        }
    }

    @Test("Add random pet attaches to owner")
    func addRandomPetAttachesToOwner() throws {
        try withTestDependencies {
            try resetStores()
            let model = PersonsFeatureModel()
            let context = ModelContainer.main.mainContext
            let owner = Person(id: UUID(), name: "Owner", age: 29)
            context.insert(owner)
            try context.save()

            model.addRandomPet(to: owner)

            let pets = try context.fetch(FetchDescriptor<Pet>())
            #expect(pets.count == 1)
            #expect(pets.first?.owner?.id == owner.id)
        }
    }

    @Test("Delete pet removes from main DB")
    func deletePetRemovesFromMain() throws {
        try withTestDependencies {
            try resetStores()
            let model = PersonsFeatureModel()
            let context = ModelContainer.main.mainContext
            let owner = Person(id: UUID(), name: "Owner", age: 29)
            let pet = Pet(name: "Buddy", kind: "Dog", owner: owner)
            context.insert(owner)
            context.insert(pet)
            try context.save()

            model.deletePet(pet)

            let pets = try context.fetch(FetchDescriptor<Pet>())
            #expect(pets.isEmpty)
        }
    }
}

@MainActor
private func withTestDependencies<T>(_ operation: () throws -> T) rethrows -> T {
    try withDependencies {
        $0.liveQueryContext.modelContext = { ModelContainer.main.mainContext }
    } operation: {
        try operation()
    }
}

@MainActor
private func resetStores() throws {
    let mainContext = ModelContainer.main.mainContext
    try deleteAll(in: mainContext, Pet.self)
    try deleteAll(in: mainContext, Person.self)

    let privateContext = ModelContainer.privatePersons.mainContext
    try deleteAll(in: privateContext, Pet.self)
    try deleteAll(in: privateContext, Person.self)
}

@MainActor
private func deleteAll<M: PersistentModel>(
    in context: ModelContext,
    _ type: M.Type
) throws {
    let models = try context.fetch(FetchDescriptor<M>())
    for model in models {
        context.delete(model)
    }
    try context.save()
}
