//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

/// A daily medication reminder. Pure domain entity.
public struct MedicationReminder: Sendable, Hashable, Identifiable {
    public typealias ID = UUID

    public let id: ID
    public let medicationName: String
    public let dosage: String
    public let timeOfDay: TimeOfDay
    public let isEnabled: Bool

    public init(id: ID, medicationName: String, dosage: String, timeOfDay: TimeOfDay, isEnabled: Bool) {
        self.id = id
        self.medicationName = medicationName
        self.dosage = dosage
        self.timeOfDay = timeOfDay
        self.isEnabled = isEnabled
    }

    public func settingEnabled(_ isEnabled: Bool) -> MedicationReminder {
        MedicationReminder(
            id: id,
            medicationName: medicationName,
            dosage: dosage,
            timeOfDay: timeOfDay,
            isEnabled: isEnabled
        )
    }
}
