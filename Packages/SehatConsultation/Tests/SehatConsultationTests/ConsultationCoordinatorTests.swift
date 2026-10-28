//
// Copyright (c) 2026 Enjel Hutasoit
//

import SehatDomain
import XCTest

@testable import SehatConsultation

@MainActor
final class ConsultationCoordinatorTests: XCTestCase {

    func test_path_isEmptyInitially() {
        let sut = makeSUT()

        XCTAssertTrue(sut.path.isEmpty)
    }

    func test_showDetail_appendsDetailRoute() {
        let sut = makeSUT()

        sut.showDetail(id: makeUUID(1))
        sut.showDetail(id: makeUUID(2))

        XCTAssertEqual(sut.path, [.detail(makeUUID(1)), .detail(makeUUID(2))])
    }

    func test_selectingFromListViewModel_pushesDetailRoute() {
        let sut = makeSUT()
        let consultation = makeConsultation(id: 3)

        sut.makeListViewModel().select(consultation)

        XCTAssertEqual(sut.path, [.detail(consultation.id)])
    }

    func test_makeDetailViewModel_loadsTheRequestedConsultation() async {
        let target = makeConsultation(id: 4)
        let sut = makeSUT(consultations: [makeConsultation(id: 1), target])
        let viewModel = sut.makeDetailViewModel(id: target.id)

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .loaded(target))
    }

    func test_makeListViewModel_loadsOverviewFromRepository() async {
        let upcoming = makeConsultation(id: 1, status: .scheduled)
        let sut = makeSUT(consultations: [upcoming])
        let viewModel = sut.makeListViewModel()

        await viewModel.load()

        XCTAssertEqual(
            viewModel.state,
            .loaded(ConsultationOverview(upcoming: [upcoming], history: []))
        )
    }

    // MARK: - Helpers

    private func makeSUT(consultations: [Consultation] = []) -> ConsultationCoordinator {
        ConsultationCoordinator(repository: RepositoryStub(.success(consultations)))
    }
}
