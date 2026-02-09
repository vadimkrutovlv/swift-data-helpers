import Dependencies
import SwiftData
import SwiftUI

/// A container view that configures ``Dependencies/DependencyValues/liveQueryContext`` for `@LiveQuery`.
///
/// `LiveQueryBindable` injects the provided `ModelContainer` into both the
/// Dependencies system and the SwiftUI environment, ensuring `@LiveQuery`
/// can resolve a valid `ModelContext`.
///
/// ## Example
///
/// ```swift
/// LiveQueryBindable(modelContainer: container) {
///     PeopleView()
/// }
/// ```
public struct LiveQueryBindable<Content: View>: View {
    private let modelContainer: ModelContainer
    private let content: () -> Content

    /// Creates a container view for a model container and its content.
    ///
    /// - Parameters:
    ///   - modelContainer: The container used to supply `ModelContext` to
    ///     ``Dependencies/DependencyValues/liveQueryContext`` and the SwiftUI environment.
    ///   - content: The view content that uses `@LiveQuery` or other
    ///     SwiftData APIs.
    public init(
        modelContainer: ModelContainer,
        @ViewBuilder content: @escaping () -> Content,
    ) {
        self.content = content
        self.modelContainer = modelContainer
    }

    /// The content view with live query dependencies configured.
    public var body: some View {
        withDependencies {
            $0.liveQueryContext.modelContext = { modelContainer.mainContext }
        } operation: {
            content()
                .modelContainer(modelContainer)
        }
    }
}
