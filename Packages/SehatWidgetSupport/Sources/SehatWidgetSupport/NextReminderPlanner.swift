//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import SehatDomain

public struct ReminderOccurrence: Sendable, Equatable {
    public let slot: ReminderSlot
    public let date: Date

    public init(slot: ReminderSlot, date: Date) {
        self.slot = slot
        self.date = date
    }
}

/// From `date` on, the next reminder to show is `next` (nil: none).
public struct TimelinePoint: Sendable, Equatable {
    public let date: Date
    public let next: ReminderOccurrence?

    public init(date: Date, next: ReminderOccurrence?) {
        self.date = date
        self.next = next
    }
}

/// Pure planning of "what is the next reminder, and when does that change".
/// The calendar is injected, so results do not depend on the device.
/// Daylight-saving transitions are handled by `Calendar` (`.nextTime`) and
/// are not covered by tests.
public enum NextReminderPlanner {
    /// Upper bound for a timeline horizon, in seconds.
    public static let maximumHorizon: TimeInterval = 7 * 86_400

    /// The first date strictly after `now` at which `time` occurs.
    public static func nextDate(of time: TimeOfDay, after now: Date, calendar: Calendar) -> Date? {
        calendar.nextDate(
            after: now,
            matching: DateComponents(hour: time.hour, minute: time.minute, second: 0),
            matchingPolicy: .nextTime
        )
    }

    /// Every slot once, with its next date, soonest first (ties: name, then id).
    public static func upcoming(_ slots: [ReminderSlot], after now: Date, calendar: Calendar) -> [ReminderOccurrence] {
        slots
            .compactMap { slot in
                nextDate(of: slot.timeOfDay, after: now, calendar: calendar)
                    .map { ReminderOccurrence(slot: slot, date: $0) }
            }
            .sorted { lhs, rhs in
                if lhs.date != rhs.date { return lhs.date < rhs.date }
                return lhs.slot < rhs.slot
            }
    }

    /// One point at `now`, and one at each reminder time up to `horizon`
    /// seconds later (inclusive). Invalid horizons count as 0, large ones are
    /// capped at `maximumHorizon`.
    public static func timeline(
        _ slots: [ReminderSlot],
        from now: Date,
        horizon: TimeInterval,
        calendar: Calendar
    ) -> [TimelinePoint] {
        let span = horizon.isFinite ? min(max(0, horizon), maximumHorizon) : 0
        let end = now.addingTimeInterval(span)

        var changeDates = Set<Date>()
        for slot in slots {
            var date = nextDate(of: slot.timeOfDay, after: now, calendar: calendar)
            while let current = date, current <= end {
                changeDates.insert(current)
                date = nextDate(of: slot.timeOfDay, after: current, calendar: calendar)
            }
        }

        return ([now] + changeDates.sorted()).map { date in
            TimelinePoint(date: date, next: upcoming(slots, after: date, calendar: calendar).first)
        }
    }
}
