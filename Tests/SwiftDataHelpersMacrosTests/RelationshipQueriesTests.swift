import MacroTesting
@testable import SwiftDataHelpersMacroPlugin
import Testing

@Suite(.macros([RelationshipQueriesMacro.self], record: .failed))
struct RelationshipQueriesTests {
    @Test("Assert RelationshipQueries generated methods on @Model relationships")
    func relationshipQueries() async throws {
        assertMacro {
            """
            @Model
            @RelationshipQueries
            final class Person {
                @Relationship(inverse: \\Pet.owner) var pets: [Pet]
                @Relationship(inverse: \\Toy.owner) var toys: Array<Toy>
            }
            """
        } expansion: {
            #"""
            @Model
            final class Person {
                @Relationship(inverse: \Pet.owner) var pets: [Pet]
                @Relationship(inverse: \Toy.owner) var toys: Array<Toy>

                func pets(
                    filter: Predicate<Pet>? = nil,
                    sort: [SortDescriptor<Pet>] = [],
                    modelContext: ModelContext? = nil
                ) -> [Pet] {
                    do {
                        let context = if let modelContext {
                            modelContext
                        } else {
                            try SwiftDataHelpersModelContextResolver.resolve(existing: self.modelContext)
                        }

                        let ownerID = persistentModelID
                        let owner = #Predicate<Pet> {
                            $0.owner?.persistentModelID == ownerID
                        }
                        let predicate: Predicate<Pet>

                        if let filter {
                            predicate = #Predicate<Pet> {
                                owner.evaluate($0) && filter.evaluate($0)
                            }
                        } else {
                            predicate = #Predicate<Pet> {
                                owner.evaluate($0)
                            }
                        }

                        let descriptor = FetchDescriptor<Pet>(
                            predicate: predicate,
                            sortBy: sort
                        )

                        return try context.fetch(descriptor)
                    } catch {
                        SwiftDataHelpersRelationshipQueriesLogger.fetchFailed(
                            method: "pets",
                            relatedType: "Pet",
                            error: error
                        )
                        return []
                    }
                }

                func toys(
                    filter: Predicate<Toy>? = nil,
                    sort: [SortDescriptor<Toy>] = [],
                    modelContext: ModelContext? = nil
                ) -> [Toy] {
                    do {
                        let context = if let modelContext {
                            modelContext
                        } else {
                            try SwiftDataHelpersModelContextResolver.resolve(existing: self.modelContext)
                        }

                        let ownerID = persistentModelID
                        let owner = #Predicate<Toy> {
                            $0.owner?.persistentModelID == ownerID
                        }
                        let predicate: Predicate<Toy>

                        if let filter {
                            predicate = #Predicate<Toy> {
                                owner.evaluate($0) && filter.evaluate($0)
                            }
                        } else {
                            predicate = #Predicate<Toy> {
                                owner.evaluate($0)
                            }
                        }

                        let descriptor = FetchDescriptor<Toy>(
                            predicate: predicate,
                            sortBy: sort
                        )

                        return try context.fetch(descriptor)
                    } catch {
                        SwiftDataHelpersRelationshipQueriesLogger.fetchFailed(
                            method: "toys",
                            relatedType: "Toy",
                            error: error
                        )
                        return []
                    }
                }
            }
            """#
        }
    }

    @Test("Assert RelationshipQueries does not generate method without inverse")
    func relationshipWithoutInverse() {
        assertMacro {
            """
            @Model
            @RelationshipQueries
            final class Person {
                @Relationship var pets: [Pet]
            }
            """
        } expansion: {
            """
            @Model
            final class Person {
                @Relationship var pets: [Pet]
            }
            """
        }
    }

    @Test("Assert RelationshipQueries failure when attached to non @Model")
    func requiresModelFailure() {
        assertMacro {
            """
            @RelationshipQueries
            final class Person {
                @Relationship(inverse: \\Pet.owner) var pets: [Pet]
            }
            """
        } diagnostics: {
            #"""
            @RelationshipQueries
            ┬───────────────────
            ╰─ 🛑 @RelationshipQueries can only be attached to SwiftData @Model types.
            final class Person {
                @Relationship(inverse: \Pet.owner) var pets: [Pet]
            }
            """#
        }
    }

    @Test("Assert RelationshipQueries failure for unsupported relationship type")
    func unsupportedRelationshipPropertyFailure() {
        assertMacro {
            """
            @Model
            @RelationshipQueries
            final class Person {
                @Relationship(inverse: \\Pet.owner) var pet: Pet?
            }
            """
        } diagnostics: {
            #"""
            @Model
            @RelationshipQueries
            final class Person {
                @Relationship(inverse: \Pet.owner) var pet: Pet?
                ┬───────────────────────────────────────────────
                ╰─ 🛑 @RelationshipQueries supports collection relationships declared as [RelatedModel] or Array<RelatedModel>.
            }
            """#
        }
    }

    @Test("Assert RelationshipQueries failure for malformed inverse key path")
    func malformedInverseFailure() {
        assertMacro {
            """
            @Model
            @RelationshipQueries
            final class Person {
                @Relationship(inverse: ?) var pets: [Pet]
            }
            """
        } diagnostics: {
            """
            @Model
            @RelationshipQueries
            final class Person {
                @Relationship(inverse: ?) var pets: [Pet]
                                       ┬
                │                      ├─ 🛑 expected value in attribute
                │                      │  ✏️ insert value
                │                      ╰─ 🛑 unexpected code '?' in attribute
                ┬────────────────────────
                ╰─ 🛑 @RelationshipQueries could not parse @Relationship(inverse: ...) key path.
            }
            """
        }
    }
}
