# ADR-0016: Medication widget, App Intent, and build-vs-wait

Status: Accepted

## Context
Patients should see their next medication reminder without opening the app.
The widget runs in another process and cannot use the app's store directly.

## Decision
- The app publishes a small JSON snapshot (enabled reminders: id, name, time)
  to the App Group container; the widget only reads it. The snapshot is
  derived data and is rebuilt at launch and after every reminder change
  (decorator over the repository; failures are ignored for now).
- All logic lives in `SehatWidgetSupport` (planner, snapshot, store,
  publisher) and is tested; the widget views and providers are thin.
- The snapshot is written atomically and read synchronously by the widget.
- The App Intent lives in the app target and runs in the app's process, so it
  does not need the App Group. It speaks only the time, never the name.
- Without the App Group the app works and the widget asks the user to open it.
- Medication names are `privacySensitive` in the widget.
- Build-vs-wait: WidgetKit and App Intents are built now. Live Activities and
  Dynamic Island wait: there is no ongoing event to track, remote updates need
  push (to my knowledge a paid developer program), and Dynamic Island exists
  only on some devices. Revisit when a live consultation flow exists.

## Alternatives considered
- Move the SwiftData store into the App Group: risky migration of existing data.
- Share the store without moving it: not possible across sandboxes.
- UserDefaults(suiteName:): works, but a typed file with a version is easier
  to test and evolve.
- A widget configuration intent: no user choice worth configuring yet.

## Consequences / known limitations
- Needs an App Group, which needs an Apple ID in Xcode (a free Personal Team
  is reported to be enough; not confirmed by Apple documentation).
- Redaction of the medication name on the Lock Screen is not verified.
- DST behavior of `Calendar.nextDate` is not covered by tests.
- Siri phrases are English only.
- A failed publish leaves the widget stale until the next change or launch.
- Only two widget families are supported.