# ADR-0013: Localization and accessibility

Status: Accepted

## Context
The app needs Indonesian and English text, and every screen must work with
VoiceOver and large text. Until now UI text was temporary English literals.

## Decision
- One String Catalog per UI package and one for the app. Keys are English
  text, except `error.*` keys (identifiers from `AppError.localizationKey`)
  which carry an explicit English value and a manual extraction state.
- Package text is read with `String(localized:bundle: .module)` and passed to
  SwiftUI's string-based APIs: SwiftUI looks up literal keys in the main
  bundle, not in a package bundle. A `Strings` enum per package holds them;
  properties are computed so the language is read at display time.
- A test-only package (`SehatLocalizationChecks`) reads every catalog as JSON
  and checks: source language `en`, a translated non-empty `id` value for each
  string, an `en` value for symbolic keys, and equal format specifiers.
- Dynamic Type: system text styles, `@ScaledMetric` for icon width, and a
  vertical layout for rows at accessibility sizes.
- VoiceOver: rows are one element with a combined label; decorative icons are
  hidden; hints on row buttons and toggles; labels on progress indicators.
- Notification text is localized in the app target; its language is fixed when
  the notification is scheduled.

## Alternatives considered
- `Text("key")` in packages: looks in the wrong bundle.
- Per-view `Text(..., bundle: .module)`: not available on every API used here.
- A shared strings package: couples features; duplicated common words are cheap.
- `.strings` and `.stringsdict` files: more files, no editor support for state.
- Snapshot tests for large text: not in the current roadmap.

## Consequences / known limitations
- Indonesian text was written without a professional translator and needs review.
- Views, `Strings`, and the time formatter are not unit-tested; VoiceOver and
  Dynamic Type are verified manually (and by UI tests from PR14).
- The checks do not judge translation quality, text length, or layout.
- No RTL, plural, or count handling (no such strings exist).
- Dates and times follow the device region, which can differ from the app language.
- Sample data is not localized.
