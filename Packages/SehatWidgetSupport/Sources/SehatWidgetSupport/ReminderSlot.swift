//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import SehatDomain

/// The part of a medication reminder that the widget needs: which medication
/// and when. The dosage is left out on purpose: the widget never shows it.
public struct ReminderSlot: Sendable, Hashable, Identifiable, Comparable {
    public let id: UUID
    public let medicationName: String
    public let timeOfDay: TimeOfDay

    public init(id: UUID, medicationName: String, timeOfDay: TimeOfDay) {
        self.id = id
        self.medicationName = medicationName
        self.timeOfDay = timeOfDay
    }

    public init(_ reminder: MedicationReminder) {
        self.init(id: reminder.id, medicationName: reminder.medicationName, timeOfDay: reminder.timeOfDay)
    }

    /// Time of day, then name, then id: lists are always in the same order.
    public static func < (lhs: ReminderSlot, rhs: ReminderSlot) -> Bool {
        if lhs.timeOfDay != rhs.timeOfDay { return lhs.timeOfDay < rhs.timeOfDay }
        if lhs.medicationName != rhs.medicationName { return lhs.medicationName < rhs.medicationName }
        return lhs.id.uuidString < rhs.id.uuidString
    }
}
