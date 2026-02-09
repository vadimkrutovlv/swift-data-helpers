//

import Dependencies
import Foundation
import SwiftData

extension ModelContainer {
    static let main: ModelContainer = {
        @Dependency(\.context) var context

        if context == .live {
            return try! ModelContainer(for: Schema([Person.self, Pet.self]))
        }

        return makeTestContainer(name: "main")
    }()

    static let privatePersons: ModelContainer = {
        @Dependency(\.context) var context

        if context == .live {
            return try! ModelContainer(
                for: Schema([Person.self, Pet.self]),
                configurations: .init(url: .documentsDirectory.appendingPathComponent("private-persons.sqlite"))
            )
        }

        return makeTestContainer(name: "private")
    }()

    private static func makeTestContainer(name: String) -> ModelContainer {
        try! ModelContainer(
            for: Schema([Person.self, Pet.self]),
            configurations: .init(name, isStoredInMemoryOnly: true)
        )
    }
}
