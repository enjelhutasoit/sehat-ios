//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

/// Deletes a reminder, then reconciles the scheduler so its notification is cancelled.
public struct DeleteMedicationReminderUseCase: Sendable {
    private let repository: any MedicationReminderRepository
    private let reconcile: ReconcileRemindersUseCase

    public init(repository: any MedicationReminderRepository, reconcile: ReconcileRemindersUseCase) {
        self.repository = repository
        self.reconcile = reconcile
    }

    public func execute(id: MedicationReminder.ID) async throws {
        try await repository.delete(id: id)
        try await reconcile.execute()
    }
}
