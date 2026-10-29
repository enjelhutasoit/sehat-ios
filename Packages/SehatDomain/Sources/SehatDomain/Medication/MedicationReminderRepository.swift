//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

/// Storage of medication reminders. Implemented by the data layer.
///
/// Contract: implementations throw `AppError` only. No ordering is guaranteed.
public protocol MedicationReminderRepository: Sendable {
    func reminders() async throws -> [MedicationReminder]
    /// Inserts the reminder, or replaces the stored one with the same id.
    func save(_ reminder: MedicationReminder) async throws
    /// Removes the reminder. Unknown ids are ignored.
    func delete(id: MedicationReminder.ID) async throws
}
