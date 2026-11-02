//
// Copyright (c) 2026 Enjel Hutasoit
//

import SehatCore
import SehatWidgetSupport
import XCTest

final class WidgetTimelinePlannerTests: XCTestCase {
    private let calendar = makeUTCCalendar()
    private let now = makeDate(2026, 1, 1, 7, 0)

    func test_entries_needSetup_whenThereIsNoSnapshot() {
        let entries = plan { nil }

        XCTAssertEqual(entries, [WidgetPlanEntry(date: now, content: .needsSetup)])
    }

    func test_entries_needSetup_whenLoadingFails() {
        let entries = plan { throw AppError.storage }

        XCTAssertEqual(entries, [WidgetPlanEntry(date: now, content: .needsSetup)])
    }

    func test_entries_showNoReminders_forAnEmptySnapshot() {
        let entries = plan { ReminderSnapshot(slots: []) }

        XCTAssertEqual(entries, [WidgetPlanEntry(date: now, content: .noReminders)])
    }

    func test_entries_followTheTimeline_forASnapshotWithReminders() {
        let snapshot = ReminderSnapshot(slots: [
            makeSlot(id: 1, name: "Morning pill", hour: 8),
            makeSlot(id: 2, name: "Evening pill", hour: 20)
        ])

        let entries = plan { snapshot }

        XCTAssertEqual(entries, [
            WidgetPlanEntry(date: now, content: .next(medicationName: "Morning pill", at: makeDate(2026, 1, 1, 8))),
            WidgetPlanEntry(date: makeDate(2026, 1, 1, 8), content: .next(medicationName: "Evening pill", at: makeDate(2026, 1, 1, 20))),
            WidgetPlanEntry(date: makeDate(2026, 1, 1, 20), content: .next(medicationName: "Morning pill", at: makeDate(2026, 1, 2, 8)))
        ])
    }

    func test_entries_usesTheGivenHorizon() {
        let snapshot = ReminderSnapshot(slots: [makeSlot(hour: 8)])

        let entries = WidgetTimelinePlanner.entries(
            loading: { snapshot },
            now: now,
            horizon: 0,
            calendar: calendar
        )

        XCTAssertEqual(entries.map(\.date), [now])
    }

    private func plan(_ load: () throws -> ReminderSnapshot?) -> [WidgetPlanEntry] {
        WidgetTimelinePlanner.entries(loading: load, now: now, horizon: 86_400, calendar: calendar)
    }
}
