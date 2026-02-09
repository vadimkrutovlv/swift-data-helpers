import Foundation
import SwiftData

@Model
final class Pet: Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String
    var kind: String
    var createdAt: Date
    @Relationship(inverse: \Person.pets) var owner: Person?

    init(
        id: UUID = UUID(),
        name: String,
        kind: String,
        createdAt: Date = .now,
        owner: Person? = nil
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.createdAt = createdAt
        self.owner = owner
    }
}

extension Pet {
    static func random(owner: Person) -> Pet {
        let name = SampleData.names.randomElement() ?? "Scout"
        let kind = SampleData.kinds.randomElement() ?? "Cat"
        return Pet(name: name, kind: kind, owner: owner)
    }
}

private enum SampleData {
    static let names = [
        "Buddy", "Clover", "Daisy", "Echo", "Gizmo", "Hazel", "Juniper",
        "Kona", "Milo", "Nova", "Olive", "Piper", "Remy", "Rory", "Toby"
    ]

    static let kinds = [
        "Cat", "Dog", "Parrot", "Rabbit", "Turtle", "Hamster"
    ]
}
