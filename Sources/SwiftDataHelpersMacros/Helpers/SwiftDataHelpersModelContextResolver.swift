import Dependencies
import SwiftData

/// Resolves a `ModelContext` for use by generated macro methods.
///
/// Resolution order:
/// 1. The explicit `existing` value, when non-`nil`.
/// 2. The context returned by `@Dependency(\.liveQueryContext)`.
///
/// Both ``CRUD`` and ``RelationshipQueries`` generated methods delegate to this
/// resolver so that callers can either pass a context explicitly or rely on the
/// app-wide dependency configured via `prepareDependencies`.
public enum SwiftDataHelpersModelContextResolver {
    /// Returns `existing` if provided; otherwise resolves the context through
    /// `DependencyValues.liveQueryContext`.
    ///
    /// - Parameter modelContext: An optional context the caller already holds.
    ///   Pass `nil` (the default) to fall back to the dependency.
    /// - Throws: Re-throws any error from `liveQueryContext.modelContext()` when
    ///   the dependency is not configured.
    public static func resolve(existing modelContext: ModelContext? = nil) throws -> ModelContext {
        if let modelContext {
            return modelContext
        }

        @Dependency(\.liveQueryContext) var liveQueryContext
        return try liveQueryContext.modelContext()
    }
}
