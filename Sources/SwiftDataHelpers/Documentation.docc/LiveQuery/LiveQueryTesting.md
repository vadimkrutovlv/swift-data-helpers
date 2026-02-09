# Live Query - Testing

Guidance for testing ``LiveQuery``-powered features with deterministic
SwiftData stores and dependency overrides.

## Overview

`@LiveQuery` depends on a configuration of
``Dependencies/DependencyValues/liveQueryContext``. In tests and previews you
can inject an in-memory `ModelContext` and keep your SwiftData state isolated
from disk.

## In-Memory Containers

The example app builds in-memory containers for tests and previews. This keeps
state fast and disposable:

```swift
extension ModelContainer {
    static let main: ModelContainer = {
        @Dependency(\.context) var context

        if context == .live {
            return try! ModelContainer(for: Schema([Person.self, Pet.self]))
        }

        return makeTestContainer(name: "main")
    }()

    private static func makeTestContainer(name: String) -> ModelContainer {
        try! ModelContainer(
            for: Schema([Person.self, Pet.self]),
            configurations: .init(name, isStoredInMemoryOnly: true)
        )
    }
}
```

## Injecting the ModelContext

Override the dependency for a test run so `@LiveQuery` uses your in-memory
container:

```swift
@MainActor
private func withTestDependencies<T>(_ operation: () throws -> T) rethrows -> T {
    try withDependencies {
        $0.liveQueryContext.modelContext = { ModelContainer.main.mainContext }
    } operation: {
        try operation()
    }
}
```

## Resetting State Between Tests

If you reuse containers across tests, delete existing data to keep each test
independent:

```swift
@MainActor
private func deleteAll<M: PersistentModel>(
    in context: ModelContext,
    _ type: M.Type
) throws {
    let models = try context.fetch(FetchDescriptor<M>())
    for model in models {
        context.delete(model)
    }
    try context.save()
}
```
