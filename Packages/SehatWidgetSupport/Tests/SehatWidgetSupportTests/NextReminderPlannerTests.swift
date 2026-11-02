//
// Copyright (c) 2026 Enjel Hutasoit
//

import SehatDomain
import SehatWidgetSupport
import XCTest

final class NextReminderPlannerTests: XCTestCase {
    private let calendar = makeUTCCalendar()
    private let now = makeDate(2026, 1, 1, 7, 0)

    // MARK: - nextDate

    func test_nextDate_isTodayWhenTheTimeIsStillAhead() {
        let result = NextReminderPlanner.nextDate(of: makeTime(8), after: makeDate(2026, 1, 1, 7, 59, 59), calendar: calendar)

        XCTAssertEqual(result, makeDate(2026, 1, 1, 8))
    }

    func test_nextDate_isStrictlyAfterNow() {
        XCTAssertEqual(
            NextReminderPlanner.nextDate(of: makeTime(8), after: makeDate(2026, 1, 1, 8, 0, 0), calendar: calendar),
            makeDate(2026, 1, 2, 8)
        )
        XCTAssertEqual(
            NextReminderPlanner.nextDate(of: makeTime(8), after: makeDate(2026, 1, 1, 8, 0, 1), calendar: calendar),
            makeDate(2026, 1, 2, 8)
        )
    }

    func test_nextDate_crossesTheEndOfAMonth() {
        let result = NextReminderPlanner.nextDate(of: makeTime(8), after: makeDate(2026, 1, 31, 23), calendar: calendar)

        XCTAssertEqual(result, makeDate(2026, 2, 1, 8))
    }

    // MARK: - upcoming

    func test_upcoming_ordersByNextDate() {
        let morning = makeSlot(id: 1, name: "A", hour: 8)
        let evening = makeSlot(id: 2, name: "B", hour: 20)

        let result = NextReminderPlanner.upcoming([morning, evening], after: makeDate(2026, 1, 1, 9), calendar: calendar)

        XCTAssertEqual(result, [
            ReminderOccurrence(slot: evening, date: makeDate(2026, 1, 1, 20)),
            ReminderOccurrence(slot: morning, date: makeDate(2026, 1, 2, 8))
        ])
    }

    func test_upcoming_breaksTiesByNameThenID() {
        let first = makeSlot(id: 2, name: "A", hour: 8)
        let second = makeSlot(id: 1, name: "B", hour: 8)
        let third = makeSlot(id: 3, name: "B", hour: 8)

        let result = NextReminderPlanner.upcoming([third, second, first], after: now, calendar: calendar)

        XCTAssertEqual(result.map(\.slot), [first, second, third])
    }

    func test_upcoming_isEmptyWithoutSlots() {
        XCTAssertEqual(NextReminderPlanner.upcoming([], after: now, calendar: calendar), [])
    }

    // MARK: - timeline

    func test_timeline_changesTheNextReminderAtEachReminderTime() {
        let morning = makeSlot(id: 1, name: "A", hour: 8)
        let evening = makeSlot(id: 2, name: "B", hour: 20)

        let points = NextReminderPlanner.timeline([evening, morning], from: now, horizon: 86_400, calendar: calendar)

        XCTAssertEqual(points, [
            TimelinePoint(date: now, next: ReminderOccurrence(slot: morning, date: makeDate(2026, 1, 1, 8))),
            TimelinePoint(date: makeDate(2026, 1, 1, 8), next: ReminderOccurrence(slot: evening, date: makeDate(2026, 1, 1, 20))),
            TimelinePoint(date: makeDate(2026, 1, 1, 20), next: ReminderOccurrence(slot: morning, date: makeDate(2026, 1, 2, 8)))
        ])
    }

    func test_timeline_hasASinglePointWithoutNextReminder_whenThereAreNoSlots() {
        let points = NextReminderPlanner.timeline([], from: now, horizon: 86_400, calendar: calendar)

        XCTAssertEqual(points, [TimelinePoint(date: now, next: nil)])
    }

    func test_timeline_mergesSlotsThatShareATime() {
        let first = makeSlot(id: 1, name: "A", hour: 8)
        let second = makeSlot(id: 2, name: "B", hour: 8)

        let points = NextReminderPlanner.timeline([second, first], from: now, horizon: 3_600, calendar: calendar)

        XCTAssertEqual(points.map(\.date), [now, makeDate(2026, 1, 1, 8)])
        XCTAssertEqual(points.first?.next?.slot, first)
    }

    func test_timeline_includesAChangeThatFallsExactlyOnTheHorizon() {
        let slot = makeSlot(hour: 8)

        let points = NextReminderPlanner.timeline([slot], from: now, horizon: 3_600, calendar: calendar)

        XCTAssertEqual(points.map(\.date), [now, makeDate(2026, 1, 1, 8)])
    }

    func test_timeline_excludesChangesAfterTheHorizon() {
        let points = NextReminderPlanner.timeline([makeSlot(hour: 8)], from: now, horizon: 3_599, calendar: calendar)

        XCTAssertEqual(points.map(\.date), [now])
    }

    func test_timeline_coversEveryDayOfAMultiDayHorizon() {
        let points = NextReminderPlanner.timeline([makeSlot(hour: 8)], from: now, horizon: 2 * 86_400, calendar: calendar)

        XCTAssertEqual(points.map(\.date), [now, makeDate(2026, 1, 1, 8), makeDate(2026, 1, 2, 8)])
    }

    func test_timeline_treatsInvalidHorizonsAsZero() {
        for horizon in [-1, .nan, .infinity] as [TimeInterval] {
            let points = NextReminderPlanner.timeline([makeSlot(hour: 8)], from: now, horizon: horizon, calendar: calendar)

            XCTAssertEqual(points.map(\.date), [now], "horizon: \(horizon)")
        }
    }

    func test_timeline_capsTheHorizonAtTheMaximum() {
        let points = NextReminderPlanner.timeline([makeSlot(hour: 8)], from: now, horizon: 100 * 86_400, calendar: calendar)

        // 7 days from Jan 1 07:00: reminders on Jan 1 to Jan 7, plus the first point.
        XCTAssertEqual(points.count, 8)
        XCTAssertEqual(NextReminderPlanner.maximumHorizon, 7 * 86_400)
    }
}
