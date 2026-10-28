//
// Copyright (c) 2026 Enjel Hutasoit
//

import SehatCore
import SehatDomain
import XCTest

@testable import SehatConsultation

@MainActor
final class ConsultationListViewModelTests: XCTestCase {

    private let emptyOverview = ConsultationOverview(upcoming: [], history: [])

    func test_initialState_isIdle() {
        let sut = makeSUT(RepositoryStub(.success([])))

        XCTAssertEqual(sut.state, .idle)
    }

    func test_load_publishesOverviewFromRepository() async {
        let upcoming = makeConsultation(id: 1, status: .scheduled)
        let finished = makeConsultation(id: 2, status: .completed)
        let sut = makeSUT(RepositoryStub(.success([finished, upcoming])))

        await sut.load()

        XCTAssertEqual(
            sut.state,
            .loaded(ConsultationOverview(upcoming: [upcoming], history: [finished]))
        )
    }

    func test_load_publishesEmptyOverview_whenRepositoryIsEmpty() async {
        let sut = makeSUT(RepositoryStub(.success([])))

        await sut.load()

        XCTAssertEqual(sut.state, .loaded(emptyOverview))
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

        XCTAssertEqual(sut.state, .loaded(emptyOverview))
    }

    func test_load_keepsLoadedContent_whenRefreshIsCancelled() async {
        let repository = RepositoryStub(.success([makeConsultation(id: 1)]))
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

    func test_load_ignoresSecondCall_whileFirstIsInFlight() async {
        let gated = GatedRepository()
        let sut = makeSUT(gated)
        let first = Task { await sut.load() }
        await eventually { await gated.isWaiting }

        await sut.load()

        let callsWhileInFlight = await gated.listCallCount
        XCTAssertEqual(callsWhileInFlight, 1)
        XCTAssertEqual(sut.state, .loading)

        await gated.release(with: [])
        await first.value
        XCTAssertEqual(sut.state, .loaded(emptyOverview))
    }

    func test_select_notifiesWithConsultationID() {
        let recorder = SelectionRecorder()
        let sut = makeSUT(RepositoryStub(.success([])), recorder: recorder)
        let consultation = makeConsultation(id: 5)

        sut.select(consultation)

        XCTAssertEqual(recorder.ids, [consultation.id])
    }

    // MARK: - Helpers

    private func makeSUT(
        _ repository: some ConsultationRepository,
        recorder: SelectionRecorder = SelectionRecorder()
    ) -> ConsultationListViewModel {
        ConsultationListViewModel(
            getOverview: GetConsultationOverviewUseCase(repository: repository),
            onSelect: { recorder.record($0) }
        )
    }
}
