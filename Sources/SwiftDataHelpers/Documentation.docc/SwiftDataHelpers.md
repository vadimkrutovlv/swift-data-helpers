# ``SwiftDataHelpers``

A growing set of SwiftData helpers for SwiftUI and app architecture.

## Overview

SwiftDataHelpers is a small, focused package that collects convenience APIs for
working with SwiftData in SwiftUI apps. The goal is to keep common patterns
simple, readable, and testable.

Today the library focuses on live SwiftUI queries powered by
`swift-dependencies`, and it will expand with more helpers over time as new
needs appear.

## Requirements

- iOS 17, macOS 14, watchOS 10, tvOS 17, visionOS 2
- Swift tools version 6.2
- SwiftData (Apple framework, available on the platforms above)

## Dependencies

- [pointfreeco/swift-dependencies](https://github.com/pointfreeco/swift-dependencies)
- SwiftData (Apple framework)

## Get Started

### Add the package in Xcode

1. Open your project in Xcode and choose File > Add Packages.
2. Enter `https://github.com/vadimkrutovlv/swift-data-helpers.git`.
3. Select the `SwiftDataHelpers` product and add it to your target.

### Add the package in Swift Package Manager

```swift
// Package.swift

dependencies: [
    .package(url: "https://github.com/vadimkrutovlv/swift-data-helpers.git", from: "1.0.0")
],

targets: [
    .target(
        name: "YourApp",
        dependencies: ["SwiftDataHelpers"]
    )
]
```

Update the version as new releases are published.

## Using LiveQuery

`LiveQuery` is a SwiftUI property wrapper that keeps your view state in sync
with SwiftData. It refreshes when the underlying model container saves, so your
lists and sections stay current without manual fetch logic.

It can be thought of as an alternative to SwiftData's `@Query` macro, with
explicit dependency-based context configuration.

You can also use `@LiveQuery` in `@Observable` models (for example, a feature
model that owns shared data) and any other main-actor-isolated type where you
want live SwiftData-backed state.

> Note: When using `@LiveQuery` inside an `@Observable` model, mark the property
> with `@ObservationIgnored` to avoid conflicts with the Observation framework:
>
> ```swift
> @Observable
> final class MyFeatureModel {
>     @ObservationIgnored
>     @LiveQuery var items: [Item]
> }
> ```

### Configure the ModelContext (primary)

`@LiveQuery` relies on the Dependencies value `liveQueryContext.modelContext`.
Configure it once at your app entry point so every view has a consistent source
of truth. This is the recommended setup for most apps.

If you do not already have a container, create a main container up front and
pass its `mainContext` into the dependency:

```swift
import Dependencies
import SwiftData
import SwiftDataHelpers
import SwiftUI

@main
struct MyApp: App {
    let container: ModelContainer = try! ModelContainer(
        for: Person.self
    )

    init() {
        let container = self.container
        prepareDependencies {
            $0.liveQueryContext.modelContext = { container.mainContext }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
        }
    }
}
```

### Use @LiveQuery

`@LiveQuery` keeps SwiftUI in sync with SwiftData by refreshing when the
underlying container saves. You can pass a predicate and sort descriptors to
filter and order results.

```swift
import SwiftDataHelpers
import SwiftUI

struct PeopleList: View {
    @LiveQuery(
        predicate: #Predicate<Person> { $0.isActive },
        sort: [SortDescriptor(\Person.name)]
    )
    private var people: [Person]

    var body: some View {
        List(people) { person in
            Text(person.name)
        }
    }
}
```

### Consume LiveQuery as AsyncStream

Use `$people.valuesStream` when you need async iteration over snapshots:

```swift
@MainActor
@Observable
final class PeopleFeatureModel {
    @ObservationIgnored
    @LiveQuery(sort: [SortDescriptor(\Person.name)])
    var people: [Person]

    @ObservationIgnored
    private var valuesTask: Task<Void, Never>?

    func observePeople() {
        valuesTask?.cancel()
        valuesTask = Task {
            for await snapshot in $people.valuesStream {
                print("People count: \(snapshot.count)")
            }
        }
    }

    deinit {
        valuesTask?.cancel()
    }
}
```

### Multiple Containers (optional)

If your app uses more than one `ModelContainer` (for example, main and private
stores), use ``LiveQueryBindable`` to scope queries to the desired container.
This is ideal for subtrees of your UI that should read from a non-default
container.

```swift
LiveQueryBindable(modelContainer: .privatePersons) {
    PrivatePeopleView()
}
```

### Previews and Tests (optional)

For previews and tests, inject a `ModelContext` directly. This keeps `@LiveQuery`
functional without bootstrapping your full app lifecycle.

```swift
#Preview {
    prepareDependencies {
        $0.liveQueryContext.modelContext = { ModelContainer.main.mainContext }
    }

    return PeopleList()
        .modelContainer(.main)
}
```

## FAQ

### I see logs about `liveQueryContext.modelContext` not set. What does it mean?

`@LiveQuery` requires a `ModelContext` from
``Dependencies/DependencyValues/liveQueryContext``.
If this dependency is not configured, SwiftDataHelpers logs a fault and the
query returns empty results until a context is provided. Configure it once at
your app entry point with `prepareDependencies`, or scope a subtree with
``LiveQueryBindable``.

### Can I use `@LiveQuery` outside of views?

Yes. It works in `@Observable` models or other main-actor-isolated types. When
used inside an observable model, mark the property wrapper with
`@ObservationIgnored` to avoid conflicts with Observation.

### How do I query multiple containers?

Use ``LiveQueryBindable`` to scope queries to a specific container, or override
the dependency for a particular subtree. The advanced guide shows patterns for
main/private container setups.

### Is `@LiveQuery` a replacement for `@Query`?

It is an alternative with explicit dependency-based context configuration. If
you prefer SwiftData's `@Query` macro, you can continue using it alongside this
library.

## Topics

### Guides

- <doc:LiveQueryAdvancedUsage>
- <doc:LiveQueryTesting>
- <doc:LiveQueryPerformance>
- <doc:SwiftDataMigrations>

### Live Queries

- ``LiveQuery``

### Dependency Setup

- ``LiveQueryBindable``
- ``Dependencies/DependencyValues/liveQueryContext``
