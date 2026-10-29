//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

public enum ReminderAuthorization: Sendable, Equatable {
    case notDetermined
    case denied
    case authorized
}

/// Delivers reminders to the patient (in the app: local notifications).
///
/// Contract: throwing methods throw `AppError` only.
public protocol ReminderScheduler: Sendable {
    func authorizationStatus() async -> ReminderAuthorization
    /// Shows the system permission prompt. Returns whether it was granted.
    func requestAuthorization() async throws -> Bool
    /// Schedules a daily reminder at `reminder.timeOfDay`, replacing any
    /// scheduled reminder with the same id.
    func schedule(_ reminder: MedicationReminder) async throws
    func cancel(reminderIDs: [MedicationReminder.ID]) async
    func scheduledReminderIDs() async -> Set<MedicationReminder.ID>
}
