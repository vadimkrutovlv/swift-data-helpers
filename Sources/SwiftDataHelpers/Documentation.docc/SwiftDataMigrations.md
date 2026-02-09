# SwiftData Migrations

How schema changes affect ``LiveQuery`` and what to plan for.

## Overview

`@LiveQuery` reacts to SwiftData saves, but it does not manage schema
migrations. When your models change, the underlying SwiftData stores still need
an explicit migration strategy.

## Plan for Schema Changes

SwiftData requires a stable schema. When you add or modify models, make sure
your app can open existing stores. In production apps, prefer a migration plan
or a staged rollout that preserves user data.

## Development vs Production

During early development it is common to delete and recreate the store after
schema changes. For production, this is not acceptable, so plan migrations
before shipping.

## Multiple Containers

If your app uses multiple `ModelContainer` instances (for example, main and
private stores), each store must be migrated independently. Keep container
configuration centralized so updates are applied consistently.
