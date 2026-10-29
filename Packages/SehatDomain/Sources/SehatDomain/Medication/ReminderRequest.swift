//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

/// What the patient enters. The id is chosen by the caller once per form, so
/// submitting the same form again updates the same reminder.
public struct ReminderRequest: Sendable, Equatable {
    public let id: MedicationReminder.ID
    public let medicationName: String
    public let dosage: String
    public let timeOfDay: TimeOfDay

    public init(id: MedicationReminder.ID, medicationName: String, dosage: String, timeOfDay: TimeOfDay) {
        self.id = id
        self.medicationName = medicationName
        self.dosage = dosage
        self.timeOfDay = timeOfDay
    }
}

public enum ReminderError: Error, Sendable, Equatable {
    case missingMedicationName
    case missingDosage
    case notFound
}
