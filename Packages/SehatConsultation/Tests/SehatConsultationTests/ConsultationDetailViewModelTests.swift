//
// Copyright (c) 2026 Enjel Hutasoit
//

import SehatCore
import SehatDomain
import XCTest

@testable import SehatConsultation

@MainActor
final class ConsultationDetailViewModelTests: XCTestCase {

    func test_initialState_isIdle() {
        let sut = makeSUT(id: 1, repository: RepositoryStub(.success([])))

        XCTAssertEqual(sut.state, .idle)
    }

    func test_load_publishesRequestedConsultation() async {
        let target = makeConsultation(id: 2)
        let repository = RepositoryStub(.success([makeConsultation(id: 1), target]))
        let sut = makeSUT(id: 2, repository: repository)

        await sut.load()

        XCTAssertEqual(sut.state, .loaded(target))
        let requested = await repository.requestedIDs
        XCTAssertEqual(requested, [target.id])
    }

    func test_load_publishesNotFound_whenConsultationIsMissing() async {
        let sut = makeSUT(id: 9, repository: RepositoryStub(.success([makeConsultation(id: 1)])))

        await sut.load()

        XCTAssertEqual(sut.state, .failed(.notFound))
    }

    func test_load_publishesRepositoryError() async {
        let sut = makeSUT(id: 1, repository: RepositoryStub(.failure(AppError.storage)))

        await sut.load()

        XCTAssertEqual(sut.state, .failed(.storage))
    }

    func test_load_returnsToIdle_whenCancelledBeforeAnyContent() async {
        let sut = makeSUT(id: 1, repository: RepositoryStub(.failure(CancellationError())))

        await sut.load()

        XCTAssertEqual(sut.state, .idle)
    }

    func test_load_keepsLoadedContent_whenReloadIsCancelled() async {
        let target = makeConsultation(id: 1)
        let repository = RepositoryStub(.success([target]))
        let sut = makeSUT(id: 1, repository: repository)
        await sut.load()

        await repository.update(.failure(CancellationError()))
        await sut.load()

        XCTAssertEqual(sut.state, .loaded(target))
    }

    // MARK: - Helpers

    private func makeSUT(id: Int, repository: some ConsultationRepository) -> ConsultationDetailViewModel {
        ConsultationDetailViewModel(consultationID: makeUUID(id), repository: repository)
    }
}
