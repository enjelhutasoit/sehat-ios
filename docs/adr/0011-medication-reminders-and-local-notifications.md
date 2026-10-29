# ADR-0011: Medication reminders with local notifications

Status: Accepted

## Context
Patients want daily medication reminders that work offline. Reminders are
health-related, so what appears on the lock screen matters.

## Decision
- The repository is the source of truth; scheduled notifications are derived
  from it. `ReconcileRemindersUseCase` cancels stale notifications and
  reschedules enabled reminders. It runs after every change and at launch.
- Add order: validate, ask permission (only while undecided), save, reconcile.
  A refused permission does not block saving. If reconcile fails the reminder
  stays saved; the form keeps one reminder id, so retrying is safe.
- `ReminderScheduler` is a domain protocol. The `UNUserNotificationCenter`
  adapter lives in the app target and is verified manually, because the
  notification center cannot be used in a package test process.
- Notification text is generic; the medication name never reaches the lock screen.
- Reminders are device-local: no outbox, no server sync.
- Schema V4 adds the reminder entity (lightweight V3 to V4, with a test).
- `TimeOfDay` is validated in the domain; the form extracts it from a
  `DatePicker` through an injected `Calendar`.

## Alternatives considered
- Schedule directly from the UI and keep no stored state: reminders cannot be
  listed, toggled, or repaired.
- Put the medication name in the notification: more useful, but exposes
  health data on the lock screen.
- Ask for permission at launch: prompts before the user understands why.
- One notification per day computed ahead of time: more requests to manage
  than one repeating calendar trigger.

## Consequences / known limitations
- No banner while the app is in the foreground (no notification delegate yet).
- A reconcile failure at launch is ignored (no logging yet).
- A reminder saved but not scheduled stays that way until the next reconcile.
- Scheduling failures map to `AppError.unknown`.
- Time format is "HH:mm" until PR13; reminders cannot be edited yet.
- The calendar trigger follows the device time zone.
