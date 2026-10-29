# ADR-0014: UI test journeys

Status: Accepted

## Context
Unit tests cover rules, but nothing proves that views, view models, stores,
and the composition root work together. UI tests are slow and the most prone
to flakiness, so they must be few, isolated, and deterministic.

## Decision
- A small set of journeys: consultation list and detail, booking, form
  validation, and persistence across relaunch.
- Isolation by launch arguments: `-ui-testing` uses a separate store and
  `-ui-testing-reset` empties it. The reset only ever receives the UI-testing
  store URL, so it cannot delete the real store.
- Removing store files lives in `SehatPersistence` and is unit-tested.
- Fixed controls are found by accessibility identifiers; rows by an
  accessibility label that contains the (unlocalized) doctor name. English is
  forced so tab and title labels are stable.
- No sleeps: every wait is `waitForExistence`.
- Not covered by UI tests: medication (system permission prompt), date
  selection, VoiceOver, Dynamic Type, and the Indonesian UI.

## Alternatives considered
- In-memory store in UI-testing mode: cannot test persistence across relaunch.
- Resetting by deleting the app: not possible from a UI test.
- Locating rows by position: breaks when data or order changes.
- Interruption monitors for the permission prompt: flaky.
- One test per screen state: slow and mostly duplicates unit tests.

## Consequences / known limitations
- UI tests do not run in `swift test` or in CI until the simulator workflow
  exists (PR15).
- Tests depend on sample data names; changing `SampleData` breaks them.
- Identifier strings are duplicated between the app and the test target.
- Known flake sources: hardware keyboard connected to the simulator, cold
  simulator starts, dirty simulator state.
- The production target contains the `-ui-testing` code path.
