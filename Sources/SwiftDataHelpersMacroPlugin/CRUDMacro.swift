import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

@_documentation(visibility: internal)
public struct CRUDMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo _: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard Self.hasModelAttribute(in: declaration) else {
            context.diagnose(
                .init(
                    node: Syntax(node),
                    message: CRUDDiagnosticMessage.requiresModel
                )
            )
            return []
        }

        guard let declaredTypeName = Self.declaredTypeName(of: declaration) else {
            context.diagnose(
                .init(
                    node: Syntax(node),
                    message: CRUDDiagnosticMessage.requiresNamedType
                )
            )
            return []
        }

        return [
            """
            static func fetch(
                predicate: Predicate<\(raw: declaredTypeName)>? = nil,
                sort: [SortDescriptor<\(raw: declaredTypeName)>] = [],
                modelContext: ModelContext? = nil
            ) throws -> [\(raw: declaredTypeName)] {
                let context = if let modelContext {
                    modelContext
                } else {
                    try SwiftDataHelpersModelContextResolver.resolve()
                }
                let descriptor = FetchDescriptor<\(raw: declaredTypeName)>(predicate: predicate, sortBy: sort)

                return try context.fetch(descriptor)
            }
            """,
            """
            static func fetchOne(
                id: PersistentIdentifier,
                modelContext: ModelContext? = nil
            ) throws -> \(raw: declaredTypeName)? {
                let context = if let modelContext {
                    modelContext
                } else {
                    try SwiftDataHelpersModelContextResolver.resolve()
                }
                let descriptor = FetchDescriptor<\(raw: declaredTypeName)>(
                    predicate: #Predicate<\(raw: declaredTypeName)> { $0.persistentModelID == id }
                )
                return try context.fetch(descriptor).first
            }
            """,
            """
            @discardableResult
            static func upsert(
                _ model: \(raw: declaredTypeName),
                modelContext: ModelContext? = nil
            ) throws -> \(raw: declaredTypeName) {
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
            """,
            """
            @discardableResult
            static func upsertCollection(
                of models: [\(raw: declaredTypeName)],
                modelContext: ModelContext? = nil
            ) throws -> [\(raw: declaredTypeName)] {
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
            """,
            """
            static func deleteCollection(
                of models: [\(raw: declaredTypeName)],
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
            """,
            """
            func delete(modelContext: ModelContext? = nil) throws {
                let context = if let modelContext {
                    modelContext
                } else {
                    try SwiftDataHelpersModelContextResolver.resolve(existing: self.modelContext)
                }

                context.delete(self)
                try context.save()
            }
            """,
        ]
    }
}

private extension CRUDMacro {
    static func declaredTypeName(of declaration: some DeclGroupSyntax) -> String? {
        if let classDecl = declaration.as(ClassDeclSyntax.self) {
            return classDecl.name.text
        }

        if let structDecl = declaration.as(StructDeclSyntax.self) {
            return structDecl.name.text
        }

        if let actorDecl = declaration.as(ActorDeclSyntax.self) {
            return actorDecl.name.text
        }

        return nil
    }

    static func hasModelAttribute(in declaration: some DeclGroupSyntax) -> Bool {
        let attributes = declaration.attributes

        for element in attributes {
            guard let attribute = element.as(AttributeSyntax.self) else {
                continue
            }

            let attributeName = attribute.attributeName.trimmedDescription.filter { !$0.isWhitespace }

            if attributeName == "Model" || attributeName.hasSuffix(".Model") {
                return true
            }
        }

        return false
    }
}

private struct CRUDDiagnosticMessage: DiagnosticMessage {
    let message: String
    let diagnosticID: MessageID
    let severity: DiagnosticSeverity

    static let requiresModel = Self(
        message: "@CRUD can only be attached to SwiftData @Model types.",
        diagnosticID: .init(domain: "SwiftDataHelpers.CRUDMacro", id: "requiresModel"),
        severity: .error
    )

    static let requiresNamedType = Self(
        message: "@CRUD requires a named type declaration.",
        diagnosticID: .init(domain: "SwiftDataHelpers.CRUDMacro", id: "requiresNamedType"),
        severity: .error
    )
}
