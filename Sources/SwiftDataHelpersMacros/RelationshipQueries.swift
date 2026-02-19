/// Generates typed query methods for each `@Relationship(inverse:)` collection
/// property on a SwiftData `@Model` type.
///
/// For every stored property declared as `[RelatedModel]` (or `Array<RelatedModel>`)
/// with an explicit `inverse:` key path, `@RelationshipQueries` synthesizes:
///
/// ```swift
/// func <propertyName>(
///     filter: Predicate<RelatedModel>? = nil,
///     sort: [SortDescriptor<RelatedModel>] = [],
///     modelContext: ModelContext? = nil
/// ) -> [RelatedModel]
/// ```
///
/// The generated method builds a predicate scoped to the owning model's
/// `persistentModelID`, optionally combined with the caller's `filter`,
/// and executes a `FetchDescriptor` against the resolved context.
///
/// Context resolution follows the same precedence as ``CRUD``:
/// 1. Explicit `modelContext` argument, when provided.
/// 2. ``SwiftDataHelpersModelContextResolver`` fallback otherwise.
///
/// - Note: On fetch failure the method logs via `os.Logger` and returns an
///   empty array instead of throwing. Check console logs
///   (subsystem `lv.krutov.SwiftDataHelpers`) for diagnostics.
///
/// - Important: `@RelationshipQueries` must be attached to a SwiftData `@Model`
///   declaration. Properties without `inverse:` are silently skipped.
///   Non-collection relationship types emit a compile-time diagnostic.
@attached(member, names: arbitrary)
public macro RelationshipQueries() = #externalMacro(module: "SwiftDataHelpersMacroPlugin", type: "RelationshipQueriesMacro")
