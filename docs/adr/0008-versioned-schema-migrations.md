# ADR-0008: Versioned schemas and tested migrations

Status: Accepted

## Context
Once users have data on disk, changing the schema without a migration path
breaks or loses that data. The sync design (ADR-0007) also needs a server
version per record, which means the first schema change is already due.

## Decision
- Every released schema is a `VersionedSchema` with its own frozen copy of
  the models. A frozen schema is never edited.
- `SehatMigrationPlan` lists the versions and the stage between each pair.
- `CurrentSchema` is the one alias that names the newest version; the rest of
  the package uses `ConsultationRecord` and `OutboxRecord` aliases.
- V1 to V2 is lightweight: it only adds `serverVersion` with a default of 0.
- Migrations are tested on disk: write a store with the frozen old schema,
  reopen it through `PersistenceStack`, and check data, order and writes.
- A failed migration throws; the store is never deleted automatically.

## Alternatives considered
- Unversioned schema: no safe path for later changes.
- Custom stage now: only needed when data must be transformed.
- Delete the store when opening fails: loses user data.
- Core Data mapping models: more tooling, but we already chose SwiftData.

## Consequences
- Each schema change costs a frozen copy, a stage, and a test.
- `serverVersion` is unused until a version-based conflict policy exists.
- Tests run through `swift test` on macOS; iOS runtime behavior is covered
  later by UI tests on the simulator.
- Schema version order is not tested automatically.
