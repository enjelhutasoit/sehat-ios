# ADR-0003: Networking layering and retry rules

Status: Accepted

## Context
The app must behave well on unstable connections without duplicating
side effects (for example a booking sent twice).

## Decision
- `HTTPClient` is a one-method protocol that throws `AppError` only.
- `URLSessionHTTPClient` adapts `URLSession` (through `HTTPTransport`).
- `RetryingHTTPClient` is a decorator applying `RetryPolicy`.
- Only idempotent methods (GET, PUT, DELETE) are retried automatically.
  POST and PATCH go through the offline outbox with idempotency keys.

## Alternatives considered
- Retry inside the URLSession client: couples two concerns, harder to test.
- Retry every method: risks duplicate writes.
- Test with `URLProtocol` stubs: global state, flaky under Swift 6.

## Consequences
- Callers compose clients: `RetryingHTTPClient(base: URLSessionHTTPClient(), ...)`.
- `Retry-After` is not honored yet.
- The `AppError`-only contract is enforced by tests, not by the compiler.
