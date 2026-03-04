# Relationship Queries - Usage

Practical usage patterns for the `@RelationshipQueries` macro.

## Overview

`@RelationshipQueries` generates relationship-scoped query helpers for
collection relationships declared with explicit inverse metadata.

For each supported relationship property, it generates:
- `<propertyName>(filter:sort:modelContext:) -> [RelatedModel]`, for example `pets(...)`

## Supported Relationship Shapes

Generation runs only for relationship properties that meet all conditions:
1. Property uses `@Relationship(inverse: ...)`.
2. Property type is `[RelatedModel]` or `Array<RelatedModel>`.
3. The parent declaration has `@Model`.

Relationships without explicit `inverse:` are skipped.

## Ownership Scoping

Generated methods always apply ownership filtering with `persistentModelID`:

```swift
$0.owner?.persistentModelID == self.persistentModelID
```

This owner-link filtering is automatic; callers do not provide it manually.

## Filter Behavior

Generated methods build a single predicate used by `FetchDescriptor`:
1. Ownership predicate (`inverse?.persistentModelID == self.persistentModelID`).
2. Optional caller predicate from `filter`.

When `filter` is provided, it is combined with ownership using `&&`, so both
conditions run at fetch time.

## Context Precedence

Generated methods resolve context in this order:
1. Use explicit `modelContext` when passed.
2. Otherwise resolve via ``SwiftDataHelpers/SwiftDataHelpersModelContext``.

## Error Behavior

On context or fetch failure, generated methods:
1. Log the failure via `SwiftDataHelpersRelationshipQueriesLogger`.
2. Return `[]`.

- Warning: `[]` can mean either no records or fetch failure. Use logs when you
  need to distinguish those cases.

## Example

```swift
import SwiftDataHelpersMacros

@Model
@RelationshipQueries
final class Person {
    @Attribute(.unique) var id: UUID
    var name: String
    @Relationship(inverse: \Pet.owner) var pets: [Pet]

    init(id: UUID, name: String, pets: [Pet] = []) {
        self.id = id
        self.name = name
        self.pets = pets
    }
}

let privateContext = privateContainer.mainContext
let dogs = person.pets(
    filter: #Predicate<Pet> { $0.kind == "Dog" },
    sort: [SortDescriptor(\.createdAt, order: .reverse)],
    modelContext: privateContext
)
```
