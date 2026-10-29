//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import SehatCore
import SehatDomain

extension MedicationReminderRecord {
    convenience init(_ reminder: MedicationReminder) {
        self.init(
            id: reminder.id,
            medicationName: reminder.medicationName,
            dosage: reminder.dosage,
            hour: reminder.timeOfDay.hour,
            minute: reminder.timeOfDay.minute,
            isEnabled: reminder.isEnabled
        )
    }

    func update(from reminder: MedicationReminder) {
        medicationName = reminder.medicationName
        dosage = reminder.dosage
        hour = reminder.timeOfDay.hour
        minute = reminder.timeOfDay.minute
        isEnabled = reminder.isEnabled
    }

    /// - Throws: `AppError.storage` when the stored time is not a valid time of day.
    func toDomain() throws -> MedicationReminder {
        guard let timeOfDay = TimeOfDay(hour: hour, minute: minute) else {
            throw AppError.storage
        }
        return MedicationReminder(
            id: id,
            medicationName: medicationName,
            dosage: dosage,
            timeOfDay: timeOfDay,
            isEnabled: isEnabled
        )
    }
}
