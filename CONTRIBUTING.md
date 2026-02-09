# Contributing to SwiftDataHelpers

This guide defines how we collaborate on this repository. It applies to both
external contributors and maintainers.

## Scope

- Feature work, bug fixes, refactors, and documentation changes.
- Swift package changes in `Sources/` and `Tests/`.
- Example app updates in `SwiftDataHelpersExample/`.

## Collaboration Principles

- Keep changes focused and minimal.
- Prefer pull requests over direct pushes.
- Align changes with the current CI and test workflow.
- Update tests and docs when behavior changes.

## Development Setup

- Use a recent Xcode version compatible with this repository.
- Ensure command line tools are installed and selected.
- Clone the repository and create a working branch from `main`.

## Local Verification Commands

Run these before opening or updating a pull request:

```bash
make test
make test-exampleApp
CONFIG=debug make build-all-platforms
CONFIG=release make build-all-platforms
make build-for-library-evolution
```

## Branch Naming

Use one of these formats:

- `feature/<issue>-<slug>`
- `fix/<issue>-<slug>`
- `chore/<slug>`
- `docs/<slug>`

Examples:

- `feature/42-livequery-pagination`
- `fix/128-crash-on-empty-schema`
- `chore/update-dependencies`
- `docs/clarify-livequery-setup`

## Issue and PR Linking Policy

- Feature and bug-fix PRs must link an issue in the PR description.
- Use `Closes #<id>` when the PR completes the issue.
- Use `Refs #<id>` when the issue remains open after merge.
- Docs and chore PRs may omit issue links when the scope is minor.

## Pull Request Requirements

Every PR should include:

- A clear summary of what changed and why.
- Scope and impact notes (what is affected and what is not).
- Test evidence from local runs.
- Linked issue when required by policy.
- Notes on docs and tests updates when behavior changes.

## Quality Gates

PRs are ready to merge only when all are true:

- CI is passing.
- At least one reviewer has approved.
- Review comments are resolved.
- Docs and tests are updated for behavioral changes.

## Review and Merge Policy

- No direct pushes to `main`.
- Use squash merge only.
- Delete source branches after merge.

## Maintainer Branch Protection Checklist

For `main`, configure GitHub branch protection with:

- Require a pull request before merging.
- Require approvals: minimum 1.
- Require conversation resolution before merging.
- Require status checks to pass before merging.
- Select all checks from the `Build & Test` workflow in
  `.github/workflows/ci.yml` (currently `macOS 26` matrix variants).
- Restrict direct pushes to administrators/maintainers as needed.
- Enable automatic branch deletion after merge at repository level.

## Release Flow

Use semantic versioning tags: `vMAJOR.MINOR.PATCH`.

1. Ensure the target PR set is merged to `main` and CI is green.
2. Choose the next semantic version.
3. Create and push an annotated tag:

```bash
git checkout main
git pull
git tag -a vX.Y.Z -m "vX.Y.Z"
git push origin vX.Y.Z
```

4. Create a GitHub Release for the new tag.
5. Build release notes from merged PRs (group by feature, fix, docs/chore).
6. Call out breaking changes and migration notes clearly.

## Communication and Review Etiquette

- Keep PRs small enough for focused review.
- Ask for clarification early when requirements are ambiguous.
- Prefer specific, actionable review comments.
- Follow up on unresolved feedback before merge.

## Need Help?

- For usage and package details, start with `README.md`.
- For API docs, use DocC content in `Sources/SwiftDataHelpers/Documentation.docc`.
