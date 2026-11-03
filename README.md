# Sehat iOS

Offline-first telehealth reference app for iOS. All data is fake.

[![CI](https://github.com/enjelhutasoit/sehat-ios/actions/workflows/ci.yml/badge.svg)](https://github.com/enjelhutasoit/sehat-ios/actions/workflows/ci.yml)

## Documentation

- [Architecture decisions (ADRs)](docs/adr/README.md)
- [Test strategy](docs/test-strategy.md)
- [Performance notes](docs/perf-notes.md): a template until measured
- [API contract review](docs/api-contract-review.md): a proposal for a fictional backend
- [TCD-0001: server sync and appointment confirmation](docs/tcd/0001-server-sync-and-appointment-confirmation.md): proposed, not implemented

## Checks

One time: install Ruby 3.3 (rbenv or Homebrew, not the system Ruby), then run
`bundle config set --local path vendor/bundle && bundle install`.

- `bundle exec fastlane package_tests` runs the tests and prints the coverage of
  every package (`package:SehatCore` for one).
- `bundle exec fastlane ui_tests` builds the app and runs the UI tests on an iOS Simulator.
- `bundle exec fastlane tooling_tests` tests the scripts in `fastlane/lib`.
- `bundle exec fastlane docs_check` checks that the relative links in the docs resolve.
Built as an engineering portfolio project: modular SPM, MVVM-C + Clean
Architecture, async/await, SwiftData, and a test pyramid with CI.

Status: in progress. See docs/adr for decisions.

## Run

1. Open `Sehat/Sehat.xcodeproj` in Xcode 16.2+.
2. Select an iPhone simulator and press Run.
3. Package tests: `cd Packages/SehatCore && swift test`.

## Requirements

iOS 17+, Swift 6 language mode.
