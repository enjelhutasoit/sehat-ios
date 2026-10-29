# ADR-0012: Background refresh coordinator and diagnostics archive

Status: Accepted

## Context
The app should be able to do small maintenance work in the background and
collect field performance data (MetricKit). System types (BGTask, MetricKit
payloads) cannot be created in tests, and a background launch has no UI.

## Decision
- `BackgroundRefreshCoordinator` (package `SehatBackground`, no dependencies)
  holds the rules: schedule the next refresh first, never let a scheduling
  failure stop the work, cancel the work on expiration, and complete the task
  exactly once with success only if the work did not throw.
- BGTaskScheduler and BGTask are wrapped by two small protocols; the adapters
  live in the app target and are verified manually on a device.
- The only job today is reminder reconciliation. Server sync is not wired:
  no remote adapter exists.
- `AppEnvironment` creates the SwiftData container once and is reachable
  without UI, so a background launch and the normal startup share it.
- Handlers are registered in `SehatApp.init`, before launch completes; the
  next refresh is scheduled when the scene goes to the background.
- MetricKit payloads are stored as JSON files on the device by
  `FileDiagnosticsArchive`, with a per-kind retention limit. Nothing is uploaded.

## Alternatives considered
- Calling BGTaskScheduler directly from the app: untestable rules.
- Building dependencies in `Startup` only: a background launch may never run it.
- Logging payloads to the console: lost after the run, no retention.
- Uploading payloads: needs a backend and a privacy review.
- A Crashlytics-style third-party SDK: out of scope and not free of review.

## Consequences / known limitations
- The BGTask adapter cannot be verified on the simulator (Apple: the debug
  triggers work only on devices). Without a device it stays unverified.
- Scheduling, work and archive failures are not logged (no logging yet).
- The system decides when, or whether, a refresh runs.
- Payload contents were not audited; exported files must not be committed
  without review.
- `BGTask` is wrapped with `@unchecked Sendable`.
- Server sync wiring is decided in PR17.
