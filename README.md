# SwiftDataHelpers

![Static Badge](https://img.shields.io/badge/Swift-6.2-blue?logo=swift)
![Static Badge](https://img.shields.io/badge/Platforms-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS%7C%20visionOS-blue?logo=apple)

A growing set of SwiftData helpers for SwiftUI and app architecture.

## Overview

SwiftDataHelpers is a small, focused package that collects convenience APIs for
working with SwiftData in SwiftUI apps. The goal is to keep common patterns
simple, readable, and testable.

Today the library focuses on live SwiftUI queries powered by
`swift-dependencies`, and it will expand with more helpers over time as new
needs appear.

## Sections

- [Overview](#overview)
- [Requirements](#requirements)
- [Dependencies](#dependencies)
- [Getting Started](#getting-started)
- [Installation](#installation)
- [Documentation](#documentation)
- [Contributing](#contributing)

## Requirements

- iOS 17, macOS 14, watchOS 10, tvOS 17, visionOS 2
- Swift tools version 6.2
- SwiftData (Apple framework, available on the platforms above)

## Dependencies

- [pointfreeco/swift-dependencies](https://github.com/pointfreeco/swift-dependencies)
- SwiftData (Apple framework)

## Installation

### Swift Package Manager

```swift
let package = Package(
    dependencies: [
        .package(
            url: "https://github.com/vadimkrutovlv/swift-data-helpers.git",
            from: "1.0.0"
        )
    ],
    targets: [
        .target(
            name: "YourApp",
            dependencies: [
                .product(name: "SwiftDataHelpers", package: "SwiftDataHelpers")
            ]
        )
    ]
)
```

Update the version as new releases are published.

### Using Xcode

1. Open your Xcode project.
2. Navigate to **File > Add Packages...**
3. Enter the following URL in the search field: `https://github.com/vadimkrutovlv/swift-data-helpers.git`
4. Choose the latest available version (starting at `1.0.0`).
5. Click **Add Package** to finish.

## Getting Started

### Using LiveQuery

`LiveQuery` is a SwiftUI property wrapper that keeps your view state in sync
with SwiftData. It refreshes when the underlying model container saves, so your
lists and sections stay current without manual fetch logic.

It can be thought of as an alternative to SwiftData's `@Query` macro, with
explicit dependency-based context configuration.

You can also use `@LiveQuery` in `@Observable` models (for example, a feature
model that owns shared data) and any other main-actor-isolated type where you
want live SwiftData-backed state.

### Configure the ModelContext (primary)

`@LiveQuery` relies on the Dependencies value `liveQueryContext.modelContext`.
Configure it once at your app entry point so every view has a consistent source
of truth. This is the recommended setup for most apps.

```swift
import Dependencies
import SwiftData
import SwiftDataHelpers
import SwiftUI

@main
struct MyApp: App {
    let container: ModelContainer = try! ModelContainer(
        for: MyModel.self
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

### Consume Values as AsyncStream

Use the projected value (`$people`) to iterate over live snapshots:

```swift
@MainActor
@Observable
final class PeopleFeatureModel {
    @ObservationIgnored
    @LiveQuery(sort: [SortDescriptor(\Person.name)])
    var people: [Person]

    @ObservationIgnored
    private var observationTask: Task<Void, Never>?

    func startObservingPeople() {
        observationTask?.cancel()
        observationTask = Task {
            for await snapshot in $people.valuesStream {
                print("Current people count: \(snapshot.count)")
            }
        }
    }

    deinit {
        observationTask?.cancel()
    }
}
```

### Multiple Containers (optional)

If your app uses more than one `ModelContainer` (for example, main and private
stores), use `LiveQueryBindable` to scope queries to the desired container.

```swift
LiveQueryBindable(modelContainer: .privatePersons) {
    PrivatePeopleView()
}
```

### Previews and Tests (optional)

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

**I see a fatal error about `liveQueryContext.modelContext` not set. What does it mean?**
`@LiveQuery` requires a `ModelContext` from `DependencyValues.liveQueryContext`.
Configure it once at your app entry point with `prepareDependencies`, or scope
a subtree with `LiveQueryBindable`.

**Can I use `@LiveQuery` outside of views?**
Yes. It works in `@Observable` models or other main-actor-isolated types. When
used inside an observable model, mark the property wrapper with
`@ObservationIgnored` to avoid conflicts with Observation.

**How do I query multiple containers?**
Use `LiveQueryBindable` to scope queries to a specific container, or override
the dependency for a particular subtree.

## Documentation

The latest documentation for the library APIs is available [here](https://vadimkrutovlv.github.io/swift-data-helpers/documentation/swiftdatahelpers/).

## Contributing

Contribution workflow, review rules, and release flow are documented in
[CONTRIBUTING.md](CONTRIBUTING.md).

## Example App

A working example app is included in `SwiftDataHelpersExample/` and shows:
- Multiple containers
- Dynamic predicates and sorting
- `@LiveQuery` inside an `@Observable` model
- `@LiveQuery` inside a UIKit `UIViewController` via `$valuesStream`
- Background writes with `@ModelActor`
- Test and preview setup
