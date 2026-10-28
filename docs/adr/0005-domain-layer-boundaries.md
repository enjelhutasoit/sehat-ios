# ADR-0005: Domain layer boundaries

Status: Accepted

## Context
Business rules must stay independent from network formats, storage and UI,
so they can change and be tested separately.

## Decision
- `SehatDomain` has no production dependencies. Entities are plain value
  types and are not `Codable`; the data layer owns DTOs and maps them.
- Repository protocols live in the domain and are implemented by the data
  layer. They throw `AppError` only.
- A use case exists only when it holds a business rule. The overview use
  case groups and orders consultations. Simple reads (for example detail)
  go straight through the repository until a rule appears.
- Grouping depends on status, not on the current time (no clock needed).

## Alternatives considered
- A use case per screen action: pass-through classes add boilerplate and
  hide where the real rules are.
- `Codable` entities: couples the domain to the API format.
- Domain depending on persistence types: blocks swapping storage.

## Consequences
- The data layer needs explicit mapping code and tests.
- Status semantics are a modeling choice for this fake-data app, not
  Halodoc's real statuses.
