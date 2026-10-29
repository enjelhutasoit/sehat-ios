//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

/// Validates a reminder, asks for permission, stores it, and schedules it.
///
/// Order: validate, ask permission, save, reconcile. A refused permission does
/// not block saving. If reconcile fails the reminder stays saved and the error
/// is thrown; submitting the same request again is safe.
public struct AddMedicationReminderUseCase: Sendable {
    private let repository: any MedicationReminderRepository
    private let reconcile: ReconcileRemindersUseCase
    private let ensureAuthorization: EnsureReminderAuthorizationUseCase

    public init(
        repository: any MedicationReminderRepository,
        reconcile: ReconcileRemindersUseCase,
        ensureAuthorization: EnsureReminderAuthorizationUseCase
    ) {
        self.repository = repository
        self.reconcile = reconcile
        self.ensureAuthorization = ensureAuthorization
    }

    /// - Throws: `ReminderError` for invalid input, `AppError` for system failures.
    public func execute(_ request: ReminderRequest) async throws -> MedicationReminder {
        let name = request.medicationName.trimmingCharacters(in: .whitespacesAndNewlines)
        let dosage = request.dosage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { throw ReminderError.missingMedicationName }
        guard !dosage.isEmpty else { throw ReminderError.missingDosage }

        _ = await ensureAuthorization.execute()

        let reminder = MedicationReminder(
            id: request.id,
            medicationName: name,
            dosage: dosage,
            timeOfDay: request.timeOfDay,
            isEnabled: true
        )
        try await repository.save(reminder)
        try await reconcile.execute()
        return reminder
    }
}
