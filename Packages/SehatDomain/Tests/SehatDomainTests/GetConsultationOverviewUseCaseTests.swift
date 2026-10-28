//
// Copyright (c) 2026 Enjel Hutasoit
//

import XCTest
import SehatCore
import SehatDomain

final class GetConsultationOverviewUseCaseTests: XCTestCase {

    func test_execute_groupsActiveStatusesAsUpcoming_andFinishedStatusesAsHistory() async throws {
        let scheduled = makeConsultation(id: 1, status: .scheduled)
        let inProgress = makeConsultation(id: 2, status: .inProgress)
        let completed = makeConsultation(id: 3, status: .completed)
        let cancelled = makeConsultation(id: 4, status: .cancelled)
        let sut = makeSUT(.success([completed, scheduled, cancelled, inProgress]))

        let overview = try await sut.execute()

        XCTAssertEqual(Set(overview.upcoming.map(\.id)), [scheduled.id, inProgress.id])
        XCTAssertEqual(Set(overview.history.map(\.id)), [completed.id, cancelled.id])
        XCTAssertFalse(overview.isEmpty)
    }

    func test_execute_sortsUpcomingWithEarliestFirst() async throws {
        let late = makeConsultation(id: 1, status: .scheduled, at: 300)
        let early = makeConsultation(id: 2, status: .scheduled, at: 100)
        let middle = makeConsultation(id: 3, status: .inProgress, at: 200)
        let sut = makeSUT(.success([late, early, middle]))

        let overview = try await sut.execute()

        XCTAssertEqual(overview.upcoming.map(\.id), [early.id, middle.id, late.id])
    }

    func test_execute_sortsHistoryWithLatestFirst() async throws {
        let old = makeConsultation(id: 1, status: .completed, at: 100)
        let recent = makeConsultation(id: 2, status: .cancelled, at: 300)
        let middle = makeConsultation(id: 3, status: .completed, at: 200)
        let sut = makeSUT(.success([old, recent, middle]))

        let overview = try await sut.execute()

        XCTAssertEqual(overview.history.map(\.id), [recent.id, middle.id, old.id])
    }

    func test_execute_breaksDateTiesByIdForDeterministicOrder() async throws {
        let second = makeConsultation(id: 2, status: .scheduled, at: 100)
        let first = makeConsultation(id: 1, status: .scheduled, at: 100)
        let historySecond = makeConsultation(id: 4, status: .completed, at: 100)
        let historyFirst = makeConsultation(id: 3, status: .completed, at: 100)
        let sut = makeSUT(.success([second, historySecond, first, historyFirst]))

        let overview = try await sut.execute()

        XCTAssertEqual(overview.upcoming.map(\.id), [first.id, second.id])
        XCTAssertEqual(overview.history.map(\.id), [historyFirst.id, historySecond.id])
    }

    func test_execute_returnsEmptyOverview_whenRepositoryIsEmpty() async throws {
        let sut = makeSUT(.success([]))

        let overview = try await sut.execute()

        XCTAssertTrue(overview.upcoming.isEmpty)
        XCTAssertTrue(overview.history.isEmpty)
        XCTAssertTrue(overview.isEmpty)
    }

    func test_execute_propagatesRepositoryError() async {
        let sut = makeSUT(.failure(AppError.offline))

        do {
            _ = try await sut.execute()
            XCTFail("Expected execute to throw")
        } catch {
            XCTAssertEqual(error as? AppError, .offline)
        }
    }

    // MARK: - Helpers

    private func makeSUT(_ result: Result<[Consultation], Error>) -> GetConsultationOverviewUseCase {
        GetConsultationOverviewUseCase(repository: ConsultationRepositoryStub(result: result))
    }
}
