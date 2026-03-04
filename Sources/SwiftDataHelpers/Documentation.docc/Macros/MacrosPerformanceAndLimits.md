# Macros - Performance and Limits

Performance considerations and known limits for generated macro helpers.

## Overview

`@CRUD` and `@RelationshipQueries` generate convenience APIs, but performance
still depends on your predicates, sort descriptors, and context usage.

Use explicit context and focused queries to keep behavior predictable.

## CRUD Performance Notes

`fetch` and `fetchOne` use `FetchDescriptor`, so query scope matters:
- Prefer selective predicates over broad scans.
- Keep sort descriptors minimal and stable.
- Avoid unnecessary repeated fetches in hot UI paths.

`upsert` and `delete` always save.
`upsertCollection` and `deleteCollection` save for non-empty collections:
- Batch related writes at call sites when possible.
- Avoid tight loops that call save per-item unless required by consistency.

## Relationship Query Performance Notes

Generated relationship helpers do:
1. Ownership-scoped fetch.
2. Optional caller filter combined into the fetch predicate.

Implications:
- Owner predicate executes at fetch time.
- Additional `filter` predicate also executes at fetch time.
- Prefer selective predicates and minimal sort work for large datasets.

## Multi-Database Correctness

Use explicit `modelContext` in multi-store flows:
- It prevents accidental reads/writes against resolver fallback context.
- It makes test expectations deterministic when multiple containers are active.

## Known Limits

`@CRUD`:
1. Applies only to declarations with `@Model`.
2. Emits diagnostics for unsupported declaration shapes.

`@RelationshipQueries`:
1. Generates helpers only for collection relationships.
2. Requires explicit `inverse:` metadata; missing inverse is skipped.
3. Returns `[]` when fetch/context resolution fails.

## Observability Caveat

For relationship helpers, empty array results are ambiguous:
- Could mean no matching rows.
- Could mean fetch/context failure.

Check logs when you need to distinguish failure from true empty results.
