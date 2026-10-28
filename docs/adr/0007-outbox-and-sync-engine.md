# ADR-0007: Outbox queue and sync engine

Status: Accepted

## Context
Users act while offline. Their intent must survive until the connection
returns, without duplicating effects, and server data must not silently
overwrite changes that were not sent yet.

## Decision
- Writes are recorded as `OutboxEntry` in a FIFO SwiftData queue
  (`OutboxStore`). Order comes from a `sequence` column, not a timestamp.
- `entry.id` is the idempotency key sent to the server.
- `SyncEngine` (stateless) pushes oldest first. Retryable errors and
  unauthorized stop the run and keep the rest queued. Other errors reject
  only that entry, which is removed and reported.
- Pull writes remote data except records with pending entries
  (`LocalPendingWinsPolicy`). The policy is a protocol and can be replaced.
- The engine depends on protocols only. HTTP-backed adapters arrive with
  the first real endpoint contract.

## Alternatives considered
- Last-write-wins: needs server timestamps or versions that the model lacks.
- Always server-wins: loses unsent user changes.
- Skip a failing entry and continue: breaks ordering between dependent writes.
- CRDTs or field-level merge: heavy for this domain.

## Consequences / known limitations
- Rejected entries are not persisted after removal; the caller must surface them.
- A failing entry blocks those behind it (head-of-line blocking).
- Enqueue is not atomic with the domain write yet; PR10 combines both in one
  transaction (same container).
- A small race remains between reading pending entries and the upsert in pull.
- Server-side deletions are not synced; the engine never deletes local data.
- Concurrent `sync()` calls are not coalesced.
