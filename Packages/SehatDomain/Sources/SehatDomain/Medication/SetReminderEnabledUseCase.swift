//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

/// Turns a reminder on or off, then reconciles the scheduler.
public struct SetReminderEnabledUseCase: Sendable {
    private let repository: any MedicationReminderRepository
    private let reconcile: ReconcileRemindersUseCase

    public init(repository: any MedicationReminderRepository, reconcile: ReconcileRemindersUseCase) {
        self.repository = repository
        self.reconcile = reconcile
    }

    /// - Throws: `ReminderError.notFound` for an unknown id, `AppError` otherwise.
    public func execute(id: MedicationReminder.ID, isEnabled: Bool) async throws {
        guard let existing = try await repository.reminders().first(where: { $0.id == id }) else {
            throw ReminderError.notFound
        }
        try await repository.save(existing.settingEnabled(isEnabled))
        try await reconcile.execute()
    }
}
