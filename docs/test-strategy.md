# Test strategy

## Layers

| Layer | What it proves | Where | How to run |
|---|---|---|---|
| Unit | Rules of each package | `Packages/*/Tests` | `bundle exec fastlane package_tests` |
| Tooling | Scripts used by CI | `fastlane/test` | `bundle exec fastlane tooling_tests` |
| Localization gate | Every string has a translated Indonesian value | `SehatLocalizationChecks` | part of `package_tests` |
| Docs links | Relative links resolve | `fastlane/lib/markdown_links.rb` | `bundle exec fastlane docs_check` |
| UI | Five journeys work end to end on a simulator | `Sehat/SehatUITests` | `bundle exec fastlane ui_tests` |
| Manual | System behavior no test reaches | ADR-0012, ADR-0013, ADR-0016 | checklists in each PR |

Most tests are unit tests; there are few UI tests because they are slow and the
most likely to be flaky.

## Conventions

- Test first: write a failing test, then the code.
- No sleeps. Concurrency is controlled with test doubles and a helper that
  yields until a condition holds.
- Dependencies are protocols; fakes are small actors or classes.
- Test names read `test_<unit>_<expectation>`.
- No test for a rigid or unreliable thing (default values, system formatters,
  view layout).
- A flaky test is fixed or deleted, never retried.

## Coverage

- Target: 80 to 90 percent of the logic of each package.
- Excluded on purpose: `Views/` and `Localization/` folders (ADR-0009, ADR-0013),
  and thin system adapters that cannot run in a package test.
- CI prints the numbers; it does not enforce a minimum yet.

| Package | Line coverage |
|---|---|
| SehatCore | [TO MEASURE] |
| SehatNetworking | [TO MEASURE] |
| SehatDomain | [TO MEASURE] |
| SehatPersistence | [TO MEASURE] |
| SehatConsultation | [TO MEASURE] |
| SehatAppointment | [TO MEASURE] |
| SehatMedication | [TO MEASURE] |
| SehatBackground | [TO MEASURE] |
| SehatDiagnostics | [TO MEASURE] |
| SehatWidgetSupport | [TO MEASURE] |

Take the numbers from the log of `package_tests`, and fill in the table with
what you see.

## Known gaps

- No snapshot tests here; the design-system repository (`[VaneKit](https://github.com/enjelhutasoit/VaneKit)`) covers them.
- EarlGrey is not used; XCUITest covers the journeys. If a team uses EarlGrey,
  ask what it gives them beyond XCUITest.
- The medication flow and date selection have no UI test (system permission prompt).
- No automated accessibility audit, performance test, or network test.
- Background task and notification adapters are verified manually; the
  background trigger can only be exercised on a physical device.
- DST behavior of the widget planner is not tested.

## Flaky tests

1. Reproduce and read the xcresult from CI.
2. Fix the cause (waiting on a condition, shared state, environment).
3. If it cannot be fixed quickly, delete the test and record why in the ADR.
