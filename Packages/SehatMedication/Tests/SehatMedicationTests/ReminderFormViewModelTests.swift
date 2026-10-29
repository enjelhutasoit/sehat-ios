//
// Copyright (c) 2026 Enjel Hutasoit
//

import XCTest
import SehatCore
import SehatDomain
@testable import SehatMedication

@MainActor
final class ReminderFormViewModelTests: XCTestCase {
    private let time = Date(timeIntervalSince1970: 13 * 3_600 + 45 * 60)

    func test_initialState_isEditing_withEmptyFields() {
        let (sut, _) = makeSUT(RepositoryFake())

        XCTAssertEqual(sut.phase, .editing)
        XCTAssertEqual(sut.medicationName, "")
        XCTAssertEqual(sut.dosage, "")
        XCTAssertEqual(sut.time, time)
    }

    func test_submit_savesAndSchedulesReminder_andReportsIt() async {
        let repository = RepositoryFake()
        let scheduler = SchedulerFake()
        let (sut, recorder) = makeSUT(repository, scheduler: scheduler)
        fill(sut)

        await sut.submit()

        let expected = makeReminder(id: 42, name: "Paracetamol", hour: 13, minute: 45)
        XCTAssertEqual(recorder.reminders, [expected])
        let stored = await repository.stored
        let scheduled = await scheduler.scheduled
        XCTAssertEqual(stored, [expected])
        XCTAssertEqual(scheduled, [expected.id: expected])
        XCTAssertEqual(sut.phase, .editing)
    }

    func test_submit_publishesValidationFailure_andDoesNotReport() async {
        let (sut, recorder) = makeSUT(RepositoryFake())

        await sut.submit()

        XCTAssertEqual(sut.phase, .failed(.validation(.missingMedicationName)))
        XCTAssertTrue(recorder.reminders.isEmpty)
    }

    func test_submit_publishesSystemFailure_whenSavingFails() async {
        let repository = RepositoryFake()
        await repository.setWriteFailure(AppError.storage)
        let (sut, recorder) = makeSUT(repository)
        fill(sut)

        await sut.submit()

        XCTAssertEqual(sut.phase, .failed(.system(.storage)))
        XCTAssertTrue(recorder.reminders.isEmpty)
    }

    func test_submit_returnsToEditing_whenCancelled() async {
        let repository = RepositoryFake()
        await repository.setWriteFailure(CancellationError())
        let (sut, recorder) = makeSUT(repository)
        fill(sut)

        await sut.submit()

        XCTAssertEqual(sut.phase, .editing)
        XCTAssertTrue(recorder.reminders.isEmpty)
    }

    func test_submit_retryAfterFailure_reusesTheSameReminder() async {
        let repository = RepositoryFake()
        await repository.setWriteFailure(AppError.storage)
        let (sut, recorder) = makeSUT(repository)
        fill(sut)
        await sut.submit()

        await repository.setWriteFailure(nil)
        await sut.submit()

        let stored = await repository.stored
        XCTAssertEqual(stored.map(\.id), [makeUUID(42)])
        XCTAssertEqual(recorder.reminders.map(\.id), [makeUUID(42)])
    }

    func test_submit_ignoresSecondCall_whileFirstIsInFlight() async {
        let gated = GatedSaveRepository()
        let (sut, recorder) = makeSUT(gated)
        fill(sut)
        let first = Task { await sut.submit() }
        await eventually { await gated.isSaveWaiting }

        await sut.submit()

        let calls = await gated.saveCallCount
        XCTAssertEqual(calls, 1)
        XCTAssertEqual(sut.phase, .submitting)

        await gated.releaseSave()
        await first.value
        XCTAssertEqual(sut.phase, .editing)
        XCTAssertEqual(recorder.reminders.count, 1)
    }

    // MARK: - Helpers

    private func makeSUT(
        _ repository: any MedicationReminderRepository,
        scheduler: any ReminderScheduler = SchedulerFake()
    ) -> (ReminderFormViewModel, SavedRecorder) {
        let recorder = SavedRecorder()
        let reconcile = ReconcileRemindersUseCase(repository: repository, scheduler: scheduler)
        let sut = ReminderFormViewModel(
            reminderID: makeUUID(42),
            time: time,
            calendar: makeUTCCalendar(),
            addReminder: AddMedicationReminderUseCase(
                repository: repository,
                reconcile: reconcile,
                ensureAuthorization: EnsureReminderAuthorizationUseCase(scheduler: scheduler)
            ),
            onSaved: { recorder.record($0) }
        )
        return (sut, recorder)
    }

    private func fill(_ sut: ReminderFormViewModel) {
        sut.medicationName = "Paracetamol"
        sut.dosage = "1 tablet"
    }
}
