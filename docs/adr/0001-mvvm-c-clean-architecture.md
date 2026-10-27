# ADR-0001: MVVM-C + Clean Architecture over TCA

Status: Accepted

## Context
The app needs clear module boundaries, testable business logic, and
navigation that does not live inside views.

## Decision
Use MVVM-C (Coordinators own navigation) with Clean Architecture layers
(Domain, Data, Presentation), split into local Swift packages.

## Alternatives considered
- TCA: strong testability and unidirectional flow, but adds a third-party
  dependency and a steeper learning curve for contributors.
- Plain MVVM without coordinators: simpler, but navigation logic leaks into
  views and becomes hard to test.

## Consequences
- More boilerplate for coordinators and protocols.
- Domain and Data packages stay UI-free and testable with `swift test`.
- Revisit if state management complexity outgrows view models.
