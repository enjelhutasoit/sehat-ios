//
// Copyright (c) 2026 Enjel Hutasoit
//

import SehatCore
import SehatDomain
import XCTest

@testable import SehatAppointment

@MainActor
final class AppointmentListViewModelTests: XCTestCase {

    func test_initialState_isIdle() {
        XCTAssertEqual(makeSUT(RepositoryStub()).state, .idle)
    }

    func test_load_publishesAppointmentsSortedByStartTime() async {
        let late = makeAppointment(id: 1, at: 300)
        let early = makeAppointment(id: 2, at: 100)
        let sut = makeSUT(RepositoryStub(.success([late, early])))

        await sut.load()

        XCTAssertEqual(sut.state, .loaded([early, late]))
    }

    func test_load_publishesEmptyList_whenNothingIsBooked() async {
        let sut = makeSUT(RepositoryStub(.success([])))

        await sut.load()

        XCTAssertEqual(sut.state, .loaded([]))
    }

    func test_load_publishesFailure_whenRepositoryFails() async {
        let sut = makeSUT(RepositoryStub(.failure(AppError.storage)))

        await sut.load()

        XCTAssertEqual(sut.state, .failed(.storage))
    }

    func test_load_recoversAfterFailure() async {
        let repository = RepositoryStub(.failure(AppError.storage))
        let sut = makeSUT(repository)
        await sut.load()

        await repository.update(.success([]))
        await sut.load()

        XCTAssertEqual(sut.state, .loaded([]))
    }

    func test_load_keepsLoadedContent_whenRefreshIsCancelled() async {
        let repository = RepositoryStub(.success([makeAppointment()]))
        let sut = makeSUT(repository)
        await sut.load()
        let loaded = sut.state

        await repository.update(.failure(CancellationError()))
        await sut.load()

        XCTAssertEqual(sut.state, loaded)
    }

    func test_load_returnsToIdle_whenCancelledBeforeAnyContent() async {
        let sut = makeSUT(RepositoryStub(.failure(CancellationError())))

        await sut.load()

        XCTAssertEqual(sut.state, .idle)
    }

    func test_load_newestLoadWins_whenOlderLoadFinishesLater() async {
        let gated = GatedListRepository()
        let sut = makeSUT(gated)
        let older = makeAppointment(id: 1)
        let newer = makeAppointment(id: 2)

        let first = Task { await sut.load() }
        await eventually { await gated.startedCount == 1 }
        let second = Task { await sut.load() }
        await eventually { await gated.startedCount == 2 }

        await gated.release(at: 1, with: [newer])
        await second.value
        XCTAssertEqual(sut.state, .loaded([newer]))

        await gated.release(at: 0, with: [older])
        await first.value
        XCTAssertEqual(sut.state, .loaded([newer]))
    }

    // MARK: - Helpers

    private func makeSUT(_ repository: some AppointmentRepository) -> AppointmentListViewModel {
        AppointmentListViewModel(listAppointments: ListAppointmentsUseCase(repository: repository))
    }
}
