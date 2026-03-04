# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.0] - 2026-03-04

### Added

- `@CRUD` macro — generates `fetch`, `fetchOne`, `upsert`, `upsertCollection`,
  `deleteCollection`, and `delete` methods on `@Model` types.
- `@RelationshipQueries` macro — generates typed query methods for
  `@Relationship(inverse:)` collection properties.
- `SwiftDataHelpersMacros` library product exposing both macros.
- `SwiftDataHelpersModelContextResolver` for shared context resolution across
  macros and manual usage.
- DocC guides: `CRUDUsage`, `RelationshipQueriesUsage`, `MacrosPerformanceAndLimits`.

## [1.0.2] - 2026-02-11

### Improved

- UIKit ergonomics for `LiveQueryViewController` and observation lifecycle.

### Added

- Documentation generation and publishing to GitHub Pages.

## [1.0.1] - 2026-02-09

### Changed

- Updated Swift tools version.

### Fixed

- Missing documentation symbols.

## [1.0.0] - 2026-02-09

### Added

- `@LiveQuery` SwiftUI property wrapper for live SwiftData queries.
- `LiveQueryBindable` for scoping queries to a specific `ModelContainer`.
- `LiveQueryViewController` for UIKit integration via `AsyncStream`.
- `SwiftDataHelpersModelContext` dependency for `swift-dependencies` integration.
- DocC documentation catalog with guides for advanced usage, testing, performance,
  and schema migrations.

[Unreleased]: https://github.com/vadimkrutovlv/swift-data-helpers/compare/1.1.0...HEAD
[1.1.0]: https://github.com/vadimkrutovlv/swift-data-helpers/compare/1.0.2...1.1.0
[1.0.2]: https://github.com/vadimkrutovlv/swift-data-helpers/compare/1.0.1...1.0.2
[1.0.1]: https://github.com/vadimkrutovlv/swift-data-helpers/compare/1.0.0...1.0.1
[1.0.0]: https://github.com/vadimkrutovlv/swift-data-helpers/releases/tag/1.0.0
