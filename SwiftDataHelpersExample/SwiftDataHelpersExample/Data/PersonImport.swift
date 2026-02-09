import Foundation
import SwiftData

struct PersonSeed: Sendable {
    let name: String
    let age: Int

    static func random() -> PersonSeed {
        let first = SampleData.firstNames.randomElement() ?? "Taylor"
        let last = SampleData.lastNames.randomElement() ?? "Reed"
        return PersonSeed(name: "\(first) \(last)", age: Int.random(in: 4...85))
    }
}

@ModelActor
actor PersonImporter {
    func importPeople(_ seeds: [PersonSeed]) throws {
        for seed in seeds {
            let person = Person(id: UUID(), name: seed.name, age: seed.age)
            modelContext.insert(person)
        }

        try modelContext.save()
    }
}

private enum SampleData {
    static let firstNames = [
        "Alex", "Bailey", "Casey", "Drew", "Emery", "Finley", "Gray", "Hayden",
        "Indigo", "Jordan", "Kai", "Logan", "Morgan", "Nico", "Parker", "Quinn"
    ]

    static let lastNames = [
        "Adler", "Bennett", "Campbell", "Dalton", "Ellis", "Foster", "Garcia",
        "Hughes", "Irving", "Jordan", "Keene", "Lawson", "Miller", "Nguyen"
    ]
}
