# Live Query - Advanced Usage

Practical patterns for ``LiveQuery`` in complex SwiftData apps.

## Overview

This guide collects advanced patterns pulled from the SwiftDataHelpers example
app. Use it when you need multiple containers, dynamic queries, or model-layer
state that stays in sync with SwiftData.

## Multiple Containers and Scoped Queries

If your app uses more than one `ModelContainer`, define them explicitly and
scope queries to the correct store. A common pattern is to centralize container
construction and select between them with an enum.

```swift
enum Database {
    case main
    case privatePersons

    var container: ModelContainer {
        switch self {
        case .main:
            .main
        case .privatePersons:
            .privatePersons
        }
    }
}
```

When a subtree should read from a non-default container, wrap it in
``LiveQueryBindable`` so `@LiveQuery` uses that container's context.

```swift
LiveQueryBindable(modelContainer: .privatePersons) {
    PrivatePeopleView()
}
```

## Dynamic Predicates and Sorting

When the predicate or sort order depends on view state, initialize the property
wrapper in your view's initializer so it stays consistent with the current
inputs.

```swift
struct FilteredPeopleList: View {
    private let filter: PersonFilter
    private let sort: PersonSort

    @LiveQuery private var people: [Person]

    init(filter: PersonFilter, sort: PersonSort) {
        self.filter = filter
        self.sort = sort
        _people = LiveQuery(predicate: filter.predicate, sort: sort.descriptors)
    }

    var body: some View {
        ForEach(people) { person in
            Text(person.name)
        }
    }
}
```

## Using LiveQuery in Observable Models

`@LiveQuery` also works in `@Observable` models, which is useful when shared
state belongs to a feature model instead of a view. Mark the property wrapper
as `@ObservationIgnored` so the wrapper itself is not observed, while the
backing data still updates when SwiftData saves. You can also consume
`$people.valuesStream` for async snapshot handling.

```swift
@MainActor
@Observable
final class PeopleFeatureModel {
    @ObservationIgnored
    @LiveQuery var people: [Person]

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

## Background Writes with @ModelActor

When writes happen on a background model actor, `@LiveQuery` still refreshes
because SwiftData posts save notifications on the container.

```swift
@ModelActor
actor PersonImporter {
    func importPeople(_ seeds: [PersonSeed]) throws {
        for seed in seeds {
            let person = Person(id: UUID(), name: seed.name, age: seed.age)
            modelContext.insert(person)
        }

        try modelContext.save()
    }
}
```

## Environment-Specific Containers for Tests and Previews

The example app uses Dependencies `context` to build live containers in the app
and in-memory containers for tests and previews. This keeps `@LiveQuery` fast
and deterministic in non-live environments.

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
