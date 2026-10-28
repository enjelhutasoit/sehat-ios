# ADR-0010: Appointment booking with a transactional outbox

Status: Accepted

## Context
Patients must be able to book while offline without losing the booking or
sending it twice. ADR-0007 left enqueue non-atomic with the domain write.

## Decision
- `AppointmentStore` writes the appointment and its outbox entry through one
  `ModelContext` and one `save()`. Autosave is off for this store.
- Appending to the queue is shared as `ModelContext.appendToOutbox`.
- Entry id and entity id equal the appointment id: a stable idempotency key.
  Booking an existing id changes nothing.
- The payload is JSON with sorted keys and ISO 8601 dates, pinned by a test,
  because it will become a contract with the server.
- Booking rules live in `BookAppointmentUseCase`. Input mistakes use
  `BookingError`; system failures stay `AppError`.
- Schema V3 adds `AppointmentRecord` with a lightweight V2 to V3 stage and a
  migration test (ADR-0008).
- `LoadState` moved to `SehatCore` because two features use it.
- The appointment list uses "newest load wins" instead of ignoring a second
  load, so a reload after booking is not overwritten by an older result.

## Alternatives considered
- Two saves (domain, then outbox): a crash in between loses the booking.
- A random id per outbox entry: a retried booking would look like a new one.
- Putting validation errors into `AppError`: mixes user mistakes with failures.
- Duplicating `LoadState` per feature: drift between copies.

## Consequences / known limitations
- Bookings stay pending until a sender and remote adapter exist.
- The slot rule reads then writes; simultaneous bookings could both pass.
- Outbox order assumes one writer; a second writer in another actor could
  produce equal sequence numbers.
- The rollback path after a failed save is not covered by tests.
- UI texts are English literals until PR13.
