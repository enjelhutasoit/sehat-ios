# ADR-0009: MVVM-C presentation with SwiftUI

Status: Accepted

## Context
Screens must stay thin, navigation must be testable, and feature code must
not depend on storage or networking implementations.

## Decision
- One feature package (`SehatConsultation`) depends on `SehatCore` and
  `SehatDomain` only. The app wires storage in its composition root.
- View models are `@MainActor @Observable`. They hold screen state
  (`LoadState`) and report events; they never navigate.
- A coordinator owns the `NavigationStack` path and builds view models.
  Rows are buttons that call the view model, so navigation stays in the
  coordinator.
- Shared load rules live in `LoadState`: content stays visible during a
  refresh and cancellation restores the previous state.
- Detail reads the repository directly (ADR-0005: no rule, no use case yet).
- View models created for pushed screens are held in `@State` once, so they
  are not rebuilt when the stack re-evaluates.
- Views use cross-platform SwiftUI only, because `swift test` compiles the
  package for macOS.
- Views are not unit-tested; behavior sits in view models and the coordinator.
  Views are covered later by UI tests.

## Alternatives considered
- `NavigationLink(value:)` in rows: navigation decided in the view.
- Combine `ObservableObject`: more boilerplate than `@Observable` on iOS 17+.
- TCA: see ADR-0001.
- Presentation code inside the app target: not reusable, harder to test.

## Consequences
- Error and UI texts are English literals until PR13 adds the string catalog.
- Sample data is seeded at launch until a remote adapter exists.
- iOS-only SwiftUI APIs need `#if os(iOS)` or a different place.
