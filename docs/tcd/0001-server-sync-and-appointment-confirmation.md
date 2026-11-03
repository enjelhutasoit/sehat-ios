# TCD-0001: Server sync and appointment confirmation

Status: **Proposed. Not implemented. Out of scope for v1.0.0.**
Effort and dates are intentionally not estimated.

## Context

Bookings are stored locally and queued in the outbox (ADR-0010) but nothing
sends them: no HTTP adapter exists, so appointments stay pending forever. The
sync engine, conflict policy, retry policy and background coordinator already
exist behind protocols (ADR-0003, ADR-0007, ADR-0012).

## Goals

- Deliver queued appointment bookings to a server, once each.
- Show a booking as confirmed or rejected, with a reason.
- Pull consultations and appointment changes without losing unsent local changes.

## Non-goals

- Authentication and sign-in screens.
- Server-side deletions.
- Multi-device conflict resolution beyond the proposed policy.

## Proposal

1. **Adapters (SehatNetworking or a new package):** an `OutboxSender` that sends
   an entry with `Idempotency-Key = entry.id`, and a `ConsultationRemote`. Compose
   `Deduplicating(Retrying(URLSession))` as before.
2. **Appointment pull:** a remote for appointments and an upsert that updates
   `status`. This needs a schema change (V5), for example a server version column.
3. **Rejections:** persist rejected entries (dead letter) so the UI can explain
   them. Today they exist only in the sync report.
4. **Conflict policy:** keep "local pending wins"; add a version-based rule once
   the server provides record versions (the `serverVersion` column exists).
5. **Wiring:** foreground sync on launch and pull-to-refresh first; then a
   `BackgroundWork` that runs the sync engine.

## Impact

| Area | Change |
|---|---|
| SehatNetworking | New adapters; honor `Retry-After` |
| SehatPersistence | Appointment pull and upsert, dead-letter storage, schema V5 |
| SehatAppointment | Status and rejection reasons in the UI |
| SehatBackground | A sync job next to the reminder job |
| Backend and other platforms | Idempotency semantics, status values, error body, record versions must match (see the API contract review) |

## Failure modes

| Failure | Handling |
|---|---|
| Response lost after the server accepted | Same key is sent again; the server must return the first result |
| Offline | Entry stays queued; sync stops at the first retryable error |
| Entry rejected (4xx other than 401) | Removed from the queue and stored as a rejection |
| Unauthorized | Sync stops; the user must sign in again |
| Two syncs at once | Harmless because of the key, but wasteful; serialize triggers |

## Testing

- Adapters: stub the transport (no network), as in the existing client tests.
- Sync: reuse the engine tests; add cases for appointment status updates.
- UI: add a journey that books, syncs against a fake server, and shows the status.

## Alternatives

- Fire the request at booking time: lost on a crash or without a network.
- A CRDT or field-level merge: too heavy for this domain.
- Server-wins only: loses unsent changes.

## Open questions

1. Does the backend accept client-generated ids and idempotency keys?
2. Which status values and reasons exist for a rejected booking?
3. Is there a per-record version or ETag?
4. Which authentication flow does the app have to follow?
5. How do other platforms represent the same statuses?