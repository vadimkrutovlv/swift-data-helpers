import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

@_documentation(visibility: internal)
public struct RelationshipQueriesMacro: MemberMacro {
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
                    message: RelationshipQueriesDiagnosticMessage.requiresModel
                )
            )
            return []
        }

        var generatedMembers: [DeclSyntax] = []

        for member in declaration.memberBlock.members {
            guard let variable = member.decl.as(VariableDeclSyntax.self) else {
                continue
            }

            guard let relationshipAttribute = Self.relationshipAttribute(in: variable) else {
                continue
            }

            guard let inverseExpression = Self.inverseExpression(from: relationshipAttribute) else {
                // Per locked behavior, relationships without explicit inverse are ignored.
                continue
            }

            guard let inversePropertyName = Self.inversePropertyName(from: inverseExpression) else {
                context.diagnose(
                    .init(
                        node: Syntax(relationshipAttribute),
                        message: RelationshipQueriesDiagnosticMessage.invalidInverse
                    )
                )
                continue
            }

            for binding in variable.bindings {
                guard let identifierPattern = binding.pattern.as(IdentifierPatternSyntax.self),
                      let typeAnnotation = binding.typeAnnotation,
                      let relatedTypeName = Self.relatedTypeName(from: typeAnnotation.type)
                else {
                    context.diagnose(
                        .init(
                            node: Syntax(variable),
                            message: RelationshipQueriesDiagnosticMessage.unsupportedRelationshipProperty
                        )
                    )
                    continue
                }

                let propertyName = identifierPattern.identifier.text
                let fetchMethodName = propertyName

                generatedMembers.append(
                    """
                    func \(raw: fetchMethodName)(
                        filter: Predicate<\(raw: relatedTypeName)>? = nil,
                        sort: [SortDescriptor<\(raw: relatedTypeName)>] = [],
                        modelContext: ModelContext? = nil
                    ) -> [\(raw: relatedTypeName)] {
                        do {
                            let context = if let modelContext {
                                modelContext
                            } else {
                                try SwiftDataHelpersModelContextResolver.resolve(existing: self.modelContext)
                            }
                        
                            let ownerID = persistentModelID
                            let owner = #Predicate<\(raw: relatedTypeName)> {
                                $0.\(raw: inversePropertyName)?.persistentModelID == ownerID
                            }
                            let predicate: Predicate<\(raw: relatedTypeName)>
                        
                            if let filter {
                                predicate = #Predicate<\(raw: relatedTypeName)> {
                                    owner.evaluate($0) && filter.evaluate($0)
                                }
                            } else {
                                predicate = #Predicate<\(raw: relatedTypeName)> {
                                    owner.evaluate($0)
                                }
                            }
                        
                            let descriptor = FetchDescriptor<\(raw: relatedTypeName)>(
                                predicate: predicate,
                                sortBy: sort
                            )
                        
                            return try context.fetch(descriptor)
                        } catch {
                            SwiftDataHelpersRelationshipQueriesLogger.fetchFailed(
                                method: "\(raw: fetchMethodName)",
                                relatedType: "\(raw: relatedTypeName)",
                                error: error
                            )
                            return []
                        }
                    }
                    """
                )
            }
        }

        return generatedMembers
    }
}

private extension RelationshipQueriesMacro {
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

    static func relationshipAttribute(in variable: VariableDeclSyntax) -> AttributeSyntax? {
        for element in variable.attributes {
            guard let attribute = element.as(AttributeSyntax.self) else {
                continue
            }

            let attributeName = attribute.attributeName.trimmedDescription.filter { !$0.isWhitespace }

            if attributeName == "Relationship" || attributeName.hasSuffix(".Relationship") {
                return attribute
            }
        }

        return nil
    }

    static func inverseExpression(from attribute: AttributeSyntax) -> String? {
        let text = attribute.trimmedDescription.filter { !$0.isWhitespace }

        guard let inverseRange = text.firstRange(of: "inverse:") else {
            return nil
        }

        var expression = ""
        var depth = 0
        var current = inverseRange.upperBound

        while current < text.endIndex {
            let character = text[current]

            if character == "," && depth == 0 {
                break
            }

            if character == ")" && depth == 0 {
                break
            }

            if character == "(" || character == "[" || character == "<" {
                depth += 1
            } else if character == ")" || character == "]" || character == ">" {
                depth = max(0, depth - 1)
            }

            expression.append(character)
            current = text.index(after: current)
        }

        return expression.isEmpty ? nil : expression
    }

    static func inversePropertyName(from inverseExpression: String) -> String? {
        let segments = inverseExpression.split(separator: ".")
        guard var propertyName = segments.last.map(String.init), !propertyName.isEmpty else {
            return nil
        }

        if propertyName.hasSuffix("?") {
            propertyName.removeLast()
        }

        return propertyName.isEmpty ? nil : propertyName
    }

    static func relatedTypeName(from typeSyntax: TypeSyntax) -> String? {
        let text = typeSyntax.trimmedDescription.filter { !$0.isWhitespace }

        if text.hasPrefix("[") && text.hasSuffix("]") {
            return String(text.dropFirst().dropLast())
        }

        if text.hasPrefix("Array<") && text.hasSuffix(">") {
            return String(text.dropFirst("Array<".count).dropLast())
        }

        return nil
    }
}

private struct RelationshipQueriesDiagnosticMessage: DiagnosticMessage {
    let message: String
    let diagnosticID: MessageID
    let severity: DiagnosticSeverity

    static let requiresModel = Self(
        message: "@RelationshipQueries can only be attached to SwiftData @Model types.",
        diagnosticID: .init(domain: "SwiftDataHelpers.RelationshipQueriesMacro", id: "requiresModel"),
        severity: .error
    )

    static let invalidInverse = Self(
        message: "@RelationshipQueries could not parse @Relationship(inverse: ...) key path.",
        diagnosticID: .init(domain: "SwiftDataHelpers.RelationshipQueriesMacro", id: "invalidInverse"),
        severity: .error
    )

    static let unsupportedRelationshipProperty = Self(
        message: "@RelationshipQueries supports collection relationships declared as [RelatedModel] or Array<RelatedModel>.",
        diagnosticID: .init(domain: "SwiftDataHelpers.RelationshipQueriesMacro", id: "unsupportedRelationshipProperty"),
        severity: .error
    )
}
