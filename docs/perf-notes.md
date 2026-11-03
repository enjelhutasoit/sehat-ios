# Performance notes

Status: **template**. Nothing here is measured yet. Fill the tables with your
own measurements and delete the rows you did not measure. Do not copy numbers
from anywhere else.

## Rules

- Measure a **Release** build (Product > Profile builds in Release).
- Prefer a real device. A Simulator on an Intel Mac is not representative of
  an iPhone; if you can only use the Simulator, say so next to every number.
- Record device, OS, Xcode, build configuration, date, and data size for every number.
- Change one thing at a time and measure before and after on the same scenario.

## Environment

| Item | Value |
|---|---|
| Device or Simulator | [TO MEASURE: fill in] |
| OS version | [TO MEASURE: fill in] |
| Xcode | [TO MEASURE: fill in] |
| Build configuration | Release |
| Data size | [TO MEASURE: seeded consultations, appointments, reminders] |

## Scenarios

| # | Scenario | Tool | What to read | Before | After |
|---|---|---|---|---|---|
| 1 | Cold launch to the first list | Instruments: Time Profiler (or the App Launch template if your Xcode has it) | time until the list is on screen | [TO MEASURE] | [TO MEASURE] |
| 2 | Open the consultation list with a larger data set | Time Profiler | main-thread time of the load | [TO MEASURE] | [TO MEASURE] |
| 3 | Book 50 appointments in a row | Time Profiler, Allocations | time per booking, memory growth | [TO MEASURE] | [TO MEASURE] |
| 4 | Navigate through every tab and back several times | Allocations, Leaks | leaked or growing objects | [TO MEASURE] | [TO MEASURE] |

A larger data set means a **temporary local change** (do not commit it), for
example seeding more rows in `SampleData`.

## How to measure

1. Product > Profile (⌘I), choose the template, record the scenario, stop.
2. Save the trace and keep a screenshot of the relevant call tree or graph.
3. Write the finding below, change one thing, record again, and compare.
4. Field data: MetricKit payloads are archived on the device (ADR-0012). Export
   them with `xcrun simctl get_app_container booted com.example.Sehat data`
   and look in `Library/Application Support/Diagnostics/`. Inspect a file before
   you commit or share it; diagnostics can contain call stacks.

## Hypotheses to test (not findings)

- Upserting consultations loads every stored record first (known limitation in
  ADR-0006). Check the cost as the data grows.
- Each list screen reloads its data on appearance. Check how often.
- The appointment slot check reads all appointments before each booking.

## Findings

| Hotspot | Evidence (trace or screenshot) | Change (PR link) | Result |
|---|---|---|---|
| [TO MEASURE] | [TO MEASURE] | [TO MEASURE] | [TO MEASURE] |