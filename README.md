# Sehat iOS

Offline-first telehealth reference app for iOS. All data is fake.

[![CI](https://github.com/enjelhutasoit/sehat-ios/actions/workflows/ci.yml/badge.svg)](https://github.com/enjelhutasoit/sehat-ios/actions/workflows/ci.yml)

## Checks

One time: install Ruby 3.3 (rbenv or Homebrew, not the system Ruby), then run
`bundle config set --local path vendor/bundle && bundle install`.

- `bundle exec fastlane package_tests` runs the tests and prints the coverage of
  every package (`package:SehatCore` for one).
- `bundle exec fastlane ui_tests` builds the app and runs the UI tests on an iOS Simulator.
- `bundle exec fastlane tooling_tests` tests the scripts in `fastlane/lib`.
Built as an engineering portfolio project: modular SPM, MVVM-C + Clean
Architecture, async/await, SwiftData, and a test pyramid with CI.

Status: in progress. See docs/adr for decisions.

## Run

1. Open `Sehat/Sehat.xcodeproj` in Xcode 16.2+.
2. Select an iPhone simulator and press Run.
3. Package tests: `cd Packages/SehatCore && swift test`.

## Requirements

iOS 17+, Swift 6 language mode.
