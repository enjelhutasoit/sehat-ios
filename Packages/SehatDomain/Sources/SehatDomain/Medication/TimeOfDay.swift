//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

/// A wall-clock time without a date, as used by daily reminders.
public struct TimeOfDay: Sendable, Hashable, Comparable {
    public let hour: Int
    public let minute: Int

    /// Returns `nil` unless `hour` is 0...23 and `minute` is 0...59.
    public init?(hour: Int, minute: Int) {
        guard (0..<24).contains(hour), (0..<60).contains(minute) else { return nil }
        self.hour = hour
        self.minute = minute
    }

    /// The time of day of `date` in `calendar`.
    public init(date: Date, calendar: Calendar = .current) {
        hour = min(max(calendar.component(.hour, from: date), 0), 23)
        minute = min(max(calendar.component(.minute, from: date), 0), 59)
    }

    public static func < (lhs: TimeOfDay, rhs: TimeOfDay) -> Bool {
        (lhs.hour, lhs.minute) < (rhs.hour, rhs.minute)
    }
}
