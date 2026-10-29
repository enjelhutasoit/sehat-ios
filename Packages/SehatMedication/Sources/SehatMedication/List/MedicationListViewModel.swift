//
// Copyright (c) 2026 Enjel Hutasoit
//

import Observation
import SehatCore
import SehatDomain

@MainActor
@Observable
final class MedicationListViewModel {
    private(set) var state: LoadState<ReminderOverview> = .idle
    /// Set when the last toggle or delete failed. The list stays visible.
    private(set) var actionFailure: AppError?

    @ObservationIgnored private var generation = 0
    private let loadReminders: LoadMedicationRemindersUseCase
    private let setEnabledUseCase: SetReminderEnabledUseCase
    private let deleteUseCase: DeleteMedicationReminderUseCase

    init(
        loadReminders: LoadMedicationRemindersUseCase,
        setEnabled: SetReminderEnabledUseCase,
        deleteReminder: DeleteMedicationReminderUseCase
    ) {
        self.loadReminders = loadReminders
        self.setEnabledUseCase = setEnabled
        self.deleteUseCase = deleteReminder
    }

    /// The newest call wins: a result from an older call that finishes later
    /// is discarded, so a reload after a change is never overwritten.
    func load() async {
        generation += 1
        let thisLoad = generation

        let current = state
        let previous: LoadState<ReminderOverview> = current == .loading ? .idle : current
        state = previous.startingLoad()

        do {
            let overview = try await loadReminders.execute()
            guard thisLoad == generation else { return }
            state = .loaded(overview)
        } catch {
            guard thisLoad == generation else { return }
            state = .afterFailure(error, restoring: previous)
        }
    }

    func setEnabled(_ reminder: MedicationReminder, isEnabled: Bool) async {
        await perform { try await setEnabledUseCase.execute(id: reminder.id, isEnabled: isEnabled) }
    }

    func delete(_ reminder: MedicationReminder) async {
        await perform { try await deleteUseCase.execute(id: reminder.id) }
    }

    func dismissFailure() {
        actionFailure = nil
    }

    /// Runs a change, then reloads whatever the outcome: a failed change can
    /// still have updated the store.
    private func perform(_ action: () async throws -> Void) async {
        actionFailure = nil
        do {
            try await action()
        } catch {
            let appError = DefaultErrorMapper().map(error)
            if appError != .cancelled { actionFailure = appError }
        }
        await load()
    }
}
