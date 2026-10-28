# Sehat iOS

Offline-first telehealth reference app for iOS. All data is fake.

Built as an engineering portfolio project: modular SPM, MVVM-C + Clean
Architecture, async/await, SwiftData, and a test pyramid with CI.

Status: in progress. See docs/adr for decisions.

## Run

1. Open `Sehat/Sehat.xcodeproj` in Xcode 16.2+.
2. Select an iPhone simulator and press Run.
3. Package tests: `cd Packages/SehatCore && swift test`.

## Requirements

iOS 17+, Swift 6 language mode.
