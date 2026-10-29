//
// Copyright (c) 2026 Enjel Hutasoit
//

import SehatCore
import SehatDomain
import XCTest

@testable import SehatMedication

@MainActor
final class MedicationListViewModelTests: XCTestCase {

    func test_initialState_isIdle_withoutFailure() {
        let sut = makeSUT(RepositoryFake())

        XCTAssertEqual(sut.state, .idle)
        XCTAssertNil(sut.actionFailure)
    }

    func test_load_publishesSortedRemindersAndAuthorization() async {
        let evening = makeReminder(id: 1, hour: 20)
        let morning = makeReminder(id: 2, hour: 8)
        let sut = makeSUT(RepositoryFake([evening, morning]), scheduler: SchedulerFake(status: .denied))

        await sut.load()

        XCTAssertEqual(
            sut.state,
            .loaded(ReminderOverview(reminders: [morning, evening], authorization: .denied))
        )
    }

    func test_load_publishesFailure_whenRepositoryFails() async {
        let repository = RepositoryFake()
        await repository.setListFailure(AppError.storage)
        let sut = makeSUT(repository)

        await sut.load()

        XCTAssertEqual(sut.state, .failed(.storage))
    }

    func test_load_recoversAfterFailure() async {
        let repository = RepositoryFake()
        await repository.setListFailure(AppError.storage)
        let sut = makeSUT(repository)
        await sut.load()

        await repository.setListFailure(nil)
        await sut.load()

        XCTAssertEqual(sut.state, .loaded(ReminderOverview(reminders: [], authorization: .authorized)))
    }

    func test_load_keepsLoadedContent_whenRefreshIsCancelled() async {
        let repository = RepositoryFake([makeReminder()])
        let sut = makeSUT(repository)
        await sut.load()
        let loaded = sut.state

        await repository.setListFailure(CancellationError())
        await sut.load()

        XCTAssertEqual(sut.state, loaded)
    }

    func test_load_returnsToIdle_whenCancelledBeforeAnyContent() async {
        let repository = RepositoryFake()
        await repository.setListFailure(CancellationError())
        let sut = makeSUT(repository)

        await sut.load()

        XCTAssertEqual(sut.state, .idle)
    }

    func test_load_newestLoadWins_whenOlderLoadFinishesLater() async {
        let gated = GatedListRepository()
        let sut = makeSUT(gated)
        let older = makeReminder(id: 1)
        let newer = makeReminder(id: 2)

        let first = Task { await sut.load() }
        await eventually { await gated.startedCount == 1 }
        let second = Task { await sut.load() }
        await eventually { await gated.startedCount == 2 }

        await gated.release(at: 1, with: [newer])
        await second.value
        XCTAssertEqual(sut.state.value?.reminders, [newer])

        await gated.release(at: 0, with: [older])
        await first.value
        XCTAssertEqual(sut.state.value?.reminders, [newer])
    }

    func test_setEnabled_updatesStoreSchedulerAndPublishedList() async {
        let reminder = makeReminder(id: 1, isEnabled: true)
        let scheduler = SchedulerFake()
        let sut = makeSUT(RepositoryFake([reminder]), scheduler: scheduler)
        await sut.load()

        await sut.setEnabled(reminder, isEnabled: false)

        XCTAssertEqual(sut.state.value?.reminders, [makeReminder(id: 1, isEnabled: false)])
        let scheduled = await scheduler.scheduled
        XCTAssertTrue(scheduled.isEmpty)
        XCTAssertNil(sut.actionFailure)
    }

    func test_delete_removesReminderFromListAndScheduler() async {
        let removed = makeReminder(id: 1)
        let kept = makeReminder(id: 2, hour: 20)
        let scheduler = SchedulerFake()
        let sut = makeSUT(RepositoryFake([removed, kept]), scheduler: scheduler)
        await sut.load()

        await sut.delete(removed)

        XCTAssertEqual(sut.state.value?.reminders, [kept])
        let scheduled = await scheduler.scheduled
        XCTAssertTrue(scheduled[removed.id] == nil)
    }

    func test_action_publishesFailure_andKeepsTheList() async {
        let reminder = makeReminder()
        let repository = RepositoryFake([reminder])
        let sut = makeSUT(repository)
        await sut.load()

        await repository.setWriteFailure(AppError.storage)
        await sut.setEnabled(reminder, isEnabled: false)

        XCTAssertEqual(sut.actionFailure, .storage)
        XCTAssertEqual(sut.state.value?.reminders, [reminder])
    }

    func test_dismissFailure_clearsTheFailure() async {
        let reminder = makeReminder()
        let repository = RepositoryFake([reminder])
        let sut = makeSUT(repository)
        await repository.setWriteFailure(AppError.storage)
        await sut.delete(reminder)

        sut.dismissFailure()

        XCTAssertNil(sut.actionFailure)
    }

    // MARK: - Helpers

    private func makeSUT(
        _ repository: any MedicationReminderRepository,
        scheduler: any ReminderScheduler = SchedulerFake()
    ) -> MedicationListViewModel {
        let reconcile = ReconcileRemindersUseCase(repository: repository, scheduler: scheduler)
        return MedicationListViewModel(
            loadReminders: LoadMedicationRemindersUseCase(repository: repository, scheduler: scheduler),
            setEnabled: SetReminderEnabledUseCase(repository: repository, reconcile: reconcile),
            deleteReminder: DeleteMedicationReminderUseCase(repository: repository, reconcile: reconcile)
        )
    }
}
