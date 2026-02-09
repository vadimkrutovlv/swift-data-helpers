import Dependencies
import OSLog
import SwiftData

/// A dependency value that supplies a SwiftData `ModelContext`.
///
/// Set ``Dependencies/DependencyValues/liveQueryContext`` dependency to provide a `ModelContext`
/// for ``LiveQuery`` and other helpers that rely on SwiftData.
public struct SwiftDataHelpersModelContext {
    /// Returns a `ModelContext` used by SwiftData helpers.
    ///
    /// - Throws: Any error raised while creating or accessing the context.
    /// - Important: If this is not configured, the default live value
    ///   logs a fault and throws.
    public var modelContext: () throws -> ModelContext
}

enum SwiftDataHelpersModelContextError: Error {
    case missingModelContext
}

extension SwiftDataHelpersModelContext: DependencyKey {
    public static let liveValue = UncheckedSendable(
        wrappedValue: SwiftDataHelpersModelContext {
            Logger.liveQuery.fault(
                """
                SwiftDataHelpers misconfiguration: `liveQueryContext.modelContext` is not set.

                You must configure it before creating any `@LiveQuery`:

                  prepareDependencies {
                    $0.liveQueryContext.modelContext = { container.mainContext }
                  }
                """
            )
            throw SwiftDataHelpersModelContextError.missingModelContext
        }
    )
}

public extension DependencyValues {
    /// Access to the SwiftData helpers context dependency.
    ///
    /// Configure this before creating any `@LiveQuery`:
    ///
    /// ```swift
    /// prepareDependencies {
    ///     $0.liveQueryContext.modelContext = { container.mainContext }
    /// }
    /// ```
    var liveQueryContext: SwiftDataHelpersModelContext {
        get { self[SwiftDataHelpersModelContext.self].value }
        set { self[SwiftDataHelpersModelContext.self].value = newValue }
    }
}
