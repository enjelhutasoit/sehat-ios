# ADR-0002: Typed AppError with localization keys

Status: Accepted

## Context
Each layer throws different errors (URLError, DecodingError, persistence
errors). The UI should react to what happened, not to where it came from.

## Decision
A single `AppError` enum in `SehatCore`, a `ErrorMapping` protocol that each
layer implements, and localization keys instead of user-facing strings.

## Alternatives considered
- Pass raw `Error` upward: leaks framework types into the UI layer.
- `LocalizedError` with strings in core: couples the package to a language.
- Store the underlying error inside `AppError`: more debug detail, but loses
  `Equatable` and complicates `Sendable`.

## Consequences
- Original error details must be logged at the mapping site.
- New failure modes require a new case; a switch in tests forces the update.
- `isRetryable` is a first, simple classification and may be refined.
