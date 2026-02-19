# CRUD - Usage

Practical usage patterns for the `@CRUD` macro.

## Overview

`@CRUD` generates common SwiftData operations directly on your `@Model` type:
- `fetch(predicate:sort:modelContext:)`
- `fetchOne(id:modelContext:)`
- `upsert(_:modelContext:)`
- `upsertCollection(of:modelContext:)`
- `deleteCollection(of:modelContext:)`
- `delete(modelContext:)`

This keeps model operations consistent while still allowing explicit context
control for multi-store applications.

## Add the Macro Product

Import the macros product in targets where you define models:

```swift
import SwiftDataHelpersMacros
```

Then annotate your model:

```swift
@Model
@CRUD
final class Person {
    @Attribute(.unique) var id: UUID
    var name: String
    var age: Int

    init(id: UUID, name: String, age: Int) {
        self.id = id
        self.name = name
        self.age = age
    }
}
```

## Context Precedence

Generated methods resolve context in this order:
1. Use explicit `modelContext` when passed.
2. Otherwise use ``SwiftDataHelpers/SwiftDataHelpersModelContext``.

This lets you use one API shape for both default and multi-database flows.

## Save Semantics

- `upsert(_:modelContext:)` always saves.
- `upsertCollection(of:modelContext:)` always saves (unless the collection is empty).
- `deleteCollection(of:modelContext:)` always saves (unless the collection is empty).
- `delete(modelContext:)` always saves.

`fetch` and `fetchOne` are read-only and do not save.

## Single-Store Example

```swift
let activePeople = try Person.fetch(
    predicate: #Predicate<Person> { $0.age >= 18 },
    sort: [SortDescriptor(\.name)]
)

if let first = activePeople.first {
    try first.delete()
}
```

## Multi-Store Example

```swift
let privateContext = privateContainer.mainContext

let person = Person(id: UUID(), name: "Sam", age: 30)
try Person.upsert(person, modelContext: privateContext)

let samePerson = try Person.fetchOne(
    id: person.persistentModelID,
    modelContext: privateContext
)
```

## Collection Write Example

```swift
let privateContext = privateContainer.mainContext

let batch = [
    Person(id: UUID(), name: "Alex", age: 32),
    Person(id: UUID(), name: "Rina", age: 28),
]

try Person.upsertCollection(of: batch, modelContext: privateContext)
try Person.deleteCollection(of: batch, modelContext: privateContext)
```

## Diagnostics

`@CRUD` emits compile diagnostics when:
- It is attached to a declaration without `@Model`.
- It is attached to an unsupported declaration shape.
