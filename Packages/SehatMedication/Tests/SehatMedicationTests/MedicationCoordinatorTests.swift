//
// Copyright (c) 2026 Enjel Hutasoit
//

import XCTest
import SehatDomain
@testable import SehatMedication

@MainActor
final class MedicationCoordinatorTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_000)

    func test_initialState_hasNoSheet_andNoRefreshRequest() {
        let sut = makeSUT()

        XCTAssertFalse(sut.isPresentingForm)
        XCTAssertEqual(sut.refreshToken, 0)
    }

    func test_showForm_andCancelForm_toggleTheSheet() {
        let sut = makeSUT()

        sut.showForm()
        XCTAssertTrue(sut.isPresentingForm)

        sut.cancelForm()
        XCTAssertFalse(sut.isPresentingForm)
        XCTAssertEqual(sut.refreshToken, 0)
    }

    func test_makeFormViewModel_defaultsTimeToNow() {
        XCTAssertEqual(makeSUT().makeFormViewModel().time, now)
    }

    func test_successfulSave_closesSheet_andRequestsListRefresh() async {
        let sut = makeSUT()
        sut.showForm()
        let form = sut.makeFormViewModel()
        form.medicationName = "Paracetamol"
        form.dosage = "1 tablet"

        await form.submit()

        XCTAssertFalse(sut.isPresentingForm)
        XCTAssertEqual(sut.refreshToken, 1)
    }

    func test_failedSave_keepsSheetOpen_andDoesNotRefresh() async {
        let sut = makeSUT()
        sut.showForm()

        await sut.makeFormViewModel().submit()

        XCTAssertTrue(sut.isPresentingForm)
        XCTAssertEqual(sut.refreshToken, 0)
    }

    func test_makeListViewModel_loadsRemindersSortedByTime() async {
        let evening = makeReminder(id: 1, hour: 20)
        let morning = makeReminder(id: 2, hour: 8)
        let viewModel = makeSUT(existing: [evening, morning]).makeListViewModel()

        await viewModel.load()

        XCTAssertEqual(viewModel.state.value?.reminders, [morning, evening])
    }

    private func makeSUT(existing: [MedicationReminder] = []) -> MedicationCoordinator {
        let now = self.now
        return MedicationCoordinator(
            repository: RepositoryFake(existing),
            scheduler: SchedulerFake(),
            now: { now },
            calendar: makeUTCCalendar()
        )
    }
}
