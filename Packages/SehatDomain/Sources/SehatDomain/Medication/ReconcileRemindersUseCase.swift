//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

/// Makes the scheduler match the repository: the repository is the source of
/// truth, scheduled notifications are derived from it.
///
/// Cancels scheduled reminders that are no longer enabled or no longer exist,
/// then (re)schedules every enabled one. Safe to run any number of times.
public struct ReconcileRemindersUseCase: Sendable {
    private let repository: any MedicationReminderRepository
    private let scheduler: any ReminderScheduler

    public init(repository: any MedicationReminderRepository, scheduler: any ReminderScheduler) {
        self.repository = repository
        self.scheduler = scheduler
    }

    public func execute() async throws {
        let enabled = try await repository.reminders().filter(\.isEnabled)
        let stale = await scheduler.scheduledReminderIDs().subtracting(enabled.map(\.id))

        if !stale.isEmpty {
            await scheduler.cancel(reminderIDs: Array(stale))
        }
        for reminder in enabled {
            try await scheduler.schedule(reminder)
        }
    }
}
