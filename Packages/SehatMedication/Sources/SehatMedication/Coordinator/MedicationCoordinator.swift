//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import Observation
import SehatDomain

/// Owns presentation of the reminder form and builds view models.
/// A saved reminder asks the list to reload through `refreshToken`.
@MainActor
@Observable
public final class MedicationCoordinator {
    var isPresentingForm = false
    private(set) var refreshToken = 0

    private let repository: any MedicationReminderRepository
    private let scheduler: any ReminderScheduler
    private let now: @Sendable () -> Date
    private let calendar: Calendar

    public init(
        repository: any MedicationReminderRepository,
        scheduler: any ReminderScheduler,
        now: @escaping @Sendable () -> Date = { Date() },
        calendar: Calendar = .current
    ) {
        self.repository = repository
        self.scheduler = scheduler
        self.now = now
        self.calendar = calendar
    }

    func makeListViewModel() -> MedicationListViewModel {
        let reconcile = makeReconcile()
        return MedicationListViewModel(
            loadReminders: LoadMedicationRemindersUseCase(repository: repository, scheduler: scheduler),
            setEnabled: SetReminderEnabledUseCase(repository: repository, reconcile: reconcile),
            deleteReminder: DeleteMedicationReminderUseCase(repository: repository, reconcile: reconcile)
        )
    }

    /// The time defaults to the current time.
    func makeFormViewModel() -> ReminderFormViewModel {
        ReminderFormViewModel(
            time: now(),
            calendar: calendar,
            addReminder: AddMedicationReminderUseCase(
                repository: repository,
                reconcile: makeReconcile(),
                ensureAuthorization: EnsureReminderAuthorizationUseCase(scheduler: scheduler)
            ),
            onSaved: { [weak self] reminder in self?.formFinished(reminder) }
        )
    }

    func showForm() {
        isPresentingForm = true
    }

    func cancelForm() {
        isPresentingForm = false
    }

    private func makeReconcile() -> ReconcileRemindersUseCase {
        ReconcileRemindersUseCase(repository: repository, scheduler: scheduler)
    }

    private func formFinished(_ reminder: MedicationReminder) {
        isPresentingForm = false
        refreshToken += 1
    }
}
