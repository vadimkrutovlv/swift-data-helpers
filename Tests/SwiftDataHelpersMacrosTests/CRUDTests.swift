import MacroTesting
@testable import SwiftDataHelpersMacroPlugin
import Testing

@Suite(.macros([CRUDMacro.self], record: .failed))
struct CRUDTests {
    @Test("Assert CRUD generated methods on @Model")
    func crud() async throws {
        assertMacro {
            """
            @Model
            @CRUD
            final class User {
                @Attribute(.unique) var id: UUID
                var name: String
                var age: Int
            }
            """
        } expansion: {
            """
            @Model
            final class User {
                @Attribute(.unique) var id: UUID
                var name: String
                var age: Int

                static func fetch(
                    predicate: Predicate<User>? = nil,
                    sort: [SortDescriptor<User>] = [],
                    modelContext: ModelContext? = nil
                ) throws -> [User] {
                    let context = if let modelContext {
                        modelContext
                    } else {
                        try SwiftDataHelpersModelContextResolver.resolve()
                    }
                    let descriptor = FetchDescriptor<User>(predicate: predicate, sortBy: sort)

                    return try context.fetch(descriptor)
                }

                static func fetchOne(
                    id: PersistentIdentifier,
                    modelContext: ModelContext? = nil
                ) throws -> User? {
                    let context = if let modelContext {
                        modelContext
                    } else {
                        try SwiftDataHelpersModelContextResolver.resolve()
                    }
                    let descriptor = FetchDescriptor<User>(
                        predicate: #Predicate<User> {
                            $0.persistentModelID == id
                        }
                    )
                    return try context.fetch(descriptor).first
                }

                @discardableResult
                static func upsert(
                    _ model: User,
                    modelContext: ModelContext? = nil
                ) throws -> User {
                    let context = if let modelContext {
                        modelContext
                    } else {
                        try SwiftDataHelpersModelContextResolver.resolve(existing: model.modelContext)
                    }

                    if model.modelContext == nil {
                        context.insert(model)
                    }

                    try context.save()
                    return model
                }

                @discardableResult
                static func upsertCollection(
                    of models: [User],
                    modelContext: ModelContext? = nil
                ) throws -> [User] {
                    guard !models.isEmpty else {
                        return models
                    }

                    let context = if let modelContext {
                        modelContext
                    } else {
                        try SwiftDataHelpersModelContextResolver.resolve(
                            existing: models.first?.modelContext
                        )
                    }

                    for model in models where model.modelContext == nil {
                        context.insert(model)
                    }

                    try context.save()
                    return models
                }

                static func deleteCollection(
                    of models: [User],
                    modelContext: ModelContext? = nil
                ) throws {
                    guard !models.isEmpty else {
                        return
                    }

                    let context = if let modelContext {
                        modelContext
                    } else {
                        try SwiftDataHelpersModelContextResolver.resolve(
                            existing: models.first?.modelContext
                        )
                    }

                    for model in models {
                        context.delete(model)
                    }

                    try context.save()
                }

                func delete(modelContext: ModelContext? = nil) throws {
                    let context = if let modelContext {
                        modelContext
                    } else {
                        try SwiftDataHelpersModelContextResolver.resolve(existing: self.modelContext)
                    }

                    context.delete(self)
                    try context.save()
                }
            }
            """
        }
    }

    @Test("Assert CRUD failure when attached to the non @Model")
    func failure() {
        assertMacro {
            """
            @CRUD
            final class User {
                @Attribute(.unique) var id: UUID
                var name: String
                var age: Int
            }
            """
        } diagnostics: {
            """
            @CRUD
            ┬────
            ╰─ 🛑 @CRUD can only be attached to SwiftData @Model types.
            final class User {
                @Attribute(.unique) var id: UUID
                var name: String
                var age: Int
            }
            """
        }
    }

    @Test("Assert CRUD failure when attached to unsupported declaration")
    func unsupportedDeclarationFailure() {
        assertMacro {
            """
            @Model
            @CRUD
            enum User {
                case person
            }
            """
        } diagnostics: {
            """
            @Model
            @CRUD
            ┬────
            ╰─ 🛑 @CRUD requires a named type declaration.
            enum User {
                case person
            }
            """
        }
    }
}
