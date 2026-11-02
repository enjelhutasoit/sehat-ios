# ADR-0015: CI with Fastlane lanes and simulator tests

Status: Accepted

## Context
Tests ran only on one Mac. Code that compiles only for iOS (BackgroundTasks,
MetricKit, UserNotifications) was not checked at all by `swift test`. Runner
images change over time, and the development Mac is Intel while the default
GitHub macOS runner is arm64.

## Decision
- Fastlane lanes are the single entry point for local runs and CI. They call
  `swift test` and `xcodebuild` directly, so there is no hidden retry layer.
- Logic that can be wrong (Xcode choice, simulator choice, package discovery,
  coverage command) is plain Ruby in `fastlane/lib`, tested with minitest.
  The Fastfile only connects it to the tools.
- CI selects the newest installed Xcode 16.x and fails clearly when none exists.
  The simulator is the base-model iPhone on the newest iOS runtime that is at
  least iOS 17.0 and not newer than the selected Xcode's simulator SDK.
- Two jobs: package tests and coverage (arm64 and Intel), and the app build
  with UI tests (arm64).
- Coverage is reported to the log; no minimum is enforced until real numbers
  have been measured.
- Superseded runs are cancelled, permissions are read-only, jobs have
  timeouts, and test results are uploaded only on failure.

## Alternatives considered
- `scan`: more features, but retries and extra layers can hide flaky tests.
- A hard-coded simulator name or Xcode path: breaks when the image changes.
- Jenkins: needs a server to maintain.
- Xcode Cloud: to my knowledge it needs a paid Apple Developer Program.
- A matrix with one job per package: more runner start-ups for the same checks.

## Consequences / known limitations
- There is no release lane and no App Store delivery.
- UI tests run on arm64 only; the Intel simulator is covered by local runs.
- CI uses Xcode 16.x (Swift 6.1 or newer) while development uses Xcode 16.2.
- A broken coverage report only warns, so it can go unnoticed.
- Actions are pinned to major tags, not commit SHAs.
- Fastlane and Ruby versions follow the lockfile and need periodic updates.
- Build times have not been measured yet.