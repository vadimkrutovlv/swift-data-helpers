/// Generates CRUD convenience methods for a SwiftData `@Model` type.
///
/// Attach `@CRUD` to a declaration marked with `@Model` to synthesize:
/// - `fetch(predicate:sort:modelContext:)`
/// - `fetchOne(id:modelContext:)`
/// - `upsert(_:modelContext:)`
/// - `upsertCollection(of:modelContext:)`
/// - `deleteCollection(of:modelContext:)`
/// - `delete(modelContext:)`
///
/// Context resolution for generated methods is:
/// 1. Explicit `modelContext` argument, when provided.
/// 2. `SwiftDataHelpersModelContextResolver` fallback otherwise.
///
/// Save behavior:
/// - `upsert` and `delete` always save.
/// - `upsertCollection` and `deleteCollection` save when the collection is non-empty.
/// - `fetch` and `fetchOne` are read-only.
///
/// - Important: `@CRUD` must be attached to a SwiftData `@Model` declaration.
///   Invalid attachment emits a compile-time diagnostic.
@attached(member, names: named(fetch), named(fetchOne), named(upsert), named(upsertCollection), named(deleteCollection), named(delete))
public macro CRUD() = #externalMacro(module: "SwiftDataHelpersMacroPlugin", type: "CRUDMacro")
