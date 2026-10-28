# ADR-0006: SwiftData persistence behind a ModelActor

Status: Accepted

## Context
The app must read consultations without a network. Storage details must not
leak into the domain or the UI, and health data must stay on the device.

## Decision
- SwiftData, because the minimum target is already iOS 17 and it removes
  most Core Data boilerplate.
- `@Model` classes are internal to `SehatPersistence`; only domain entities
  cross the boundary.
- All access goes through `ConsultationStore`, a `ModelActor`, so the
  context is confined to one actor.
- Enums are stored as strings; unknown values are treated as corrupted data
  and surface as `AppError.storage`.
- The store configuration disables CloudKit explicitly.
- `upsert` loads all records and updates by id. `@Attribute(.unique)` is
  kept as an integrity guard.

## Alternatives considered
- Core Data: more mature tooling and migration support, but more
  boilerplate. It remains the fallback if SwiftData blocks us.
- Raw SQLite or a third-party library: extra dependency and mapping code.
- Skipping corrupted records silently: hides data loss.
- Predicate-based upsert: better for large datasets; not needed yet.

## Consequences
- One corrupted record makes a full read fail until a logging and
  recovery policy exists.
- Upsert cost grows with the stored dataset size.
- The rollback path after a failed save is not covered by tests.
