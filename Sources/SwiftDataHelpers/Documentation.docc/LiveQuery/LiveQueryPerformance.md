# Live Query - Performance

Tips for keeping ``LiveQuery`` fast and predictable in larger apps.

## Overview

`@LiveQuery` refreshes when a SwiftData container saves, then resolves model IDs
into full models and optionally sorts them. Keeping the result set focused will
help your UI stay responsive.

## Use Focused Predicates

Prefer narrow predicates that fetch only what a screen needs. This reduces
in-memory work and makes list diffs cheaper.

```swift
@LiveQuery(
    predicate: #Predicate<Person> { $0.isActive },
    sort: [SortDescriptor(\Person.name)]
)
private var activePeople: [Person]
```

## Keep Sorts Stable and Minimal

If ordering matters, pass a small set of `SortDescriptor`s. Avoid extra sorting
work in your view body, especially for large collections.

## Batch Saves When Possible

Every save on the observed container triggers a refresh. If you are importing
or updating many models, prefer batching changes and saving once per batch.
This keeps refresh work to a predictable cadence.

## Avoid Heavy Work in the Body

Transforming or filtering large collections inside `body` can cause repeated
work during view updates. Push expensive transforms into model-layer helpers or
use predicates to pre-filter data.
