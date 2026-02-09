import Foundation
import SwiftData

@Model
final class Person: Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String
    var age: Int
    @Relationship(deleteRule: .cascade) var pets: [Pet]

    init(id: UUID, name: String, age: Int, pets: [Pet] = []) {
        self.id = id
        self.name = name
        self.age = age
        self.pets = pets
    }
}

extension Person {
    static var blank: Person { Person(id: .init(), name: "", age: 0) }
}
