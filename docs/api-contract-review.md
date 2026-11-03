# API contract review

This is a **proposal for a fictional backend**, written to practice reviewing a
contract early. It is not the API of any real company. It describes what the
client in this repository needs and what it would ask the backend team before
implementation starts.

## What the client has today

- Offline-first: writes are queued in an outbox and sent later, oldest first.
- The outbox entry id is the idempotency key. For appointments the entry id and
  entity id both equal the appointment id, and the payload is pinned by a test
  (`AppointmentOutbox`).
- HTTP errors map to `AppError`: 401 to unauthorized, 404 to not found, any other
  non-2xx to a server error with the status code.
- Only GET, PUT and DELETE are retried automatically.

## Proposed endpoints

| Method and path | Purpose | Notes |
|---|---|---|
| `POST /v1/appointments` | Create a booking | Header `Idempotency-Key`. Body equals the outbox payload. |
| `GET /v1/appointments?updatedSince=` | Pull changes | Includes `status` and `version`. |
| `GET /v1/consultations?updatedSince=` | Pull consultations | Includes `version`. |

## Questions for the backend team

| Topic | Question | Client assumption today | Risk if wrong |
|---|---|---|---|
| Idempotency | Does the server accept the same key twice and return the original result? For how long is a key remembered? | Yes, indefinitely | Duplicate bookings after a lost response |
| Client ids | May the client choose the resource id (UUID)? | Yes | Ids must be remapped after creation |
| Conflicts | Which status for "slot already taken"? | Not defined; any 4xx other than 401 and 404 rejects the entry | The user never learns why a booking failed |
| Versioning | URL version, header, or both? How are breaking changes announced? | `/v1` in the URL | Silent decoding failures |
| Record version | Is there a per-record version or ETag? | A `serverVersion` column exists but is unused | Conflict policy stays "local pending wins" |
| Deletions | Are deletions sent as tombstones? | The client never deletes local data because of a missing record | Deleted items stay visible |
| Pagination | Cursor or page number? What is the maximum page size? | Not implemented; the sync pull expects one list | Large lists are slow or truncated |
| Time | Timestamps in ISO 8601 UTC? Is the start time truncated to the minute? | UTC, truncated to the minute | Off-by-timezone bookings |
| Rate limits | Does the server send `Retry-After` on 429 and 503? | Ignored for now (see below) | Retries that make an overload worse |
| Auth | How do tokens expire and refresh? | 401 stops the sync and asks for sign-in | Sync stalls without a way to recover |
| Payload size | Which fields are truly needed in list responses? Is compression on? | Full entities | Wasted data on slow connections |
| Privacy | Where is health data stored and logged? What is the retention? | No data leaves the device today | Legal exposure; see the note below |

## Error mapping

| Server response | Client today | Change worth discussing |
|---|---|---|
| 401 | `unauthorized`, sync stops | Refresh the token, then retry |
| 404 | `notFound` | None |
| 409 or 422 | `server(statusCode:)`, entry rejected | A stable error body with a machine-readable reason |
| 429 or 503 | `server(statusCode:)`, retryable | Honor `Retry-After` |
| other 5xx | `server(statusCode:)`, retryable | None |

## Privacy note

Indonesian law treats health information as specific personal data, and health
data processing has location rules (high-level reading of the sources found in
research; **not legal advice**). The backend questions above about storage,
logging and retention matter for that reason.