//
// Copyright (c) 2026 Enjel Hutasoit
//

import XCTest
import SehatCore
import SehatDomain

final class ListAppointmentsUseCaseTests: XCTestCase {

    func test_execute_sortsByStartTime_earliestFirst() async throws {
        let late = makeAppointment(id: 1, at: 300)
        let early = makeAppointment(id: 2, at: 100)
        let middle = makeAppointment(id: 3, at: 200)

        let result = try await makeSUT(.success([late, early, middle])).execute()

        XCTAssertEqual(result.map(\.id), [early.id, middle.id, late.id])
    }

    func test_execute_breaksTiesByID() async throws {
        let second = makeAppointment(id: 2, at: 100)
        let first = makeAppointment(id: 1, at: 100)

        let result = try await makeSUT(.success([second, first])).execute()

        XCTAssertEqual(result.map(\.id), [first.id, second.id])
    }

    func test_execute_returnsEmpty_whenNothingIsBooked() async throws {
        let result = try await makeSUT(.success([])).execute()

        XCTAssertTrue(result.isEmpty)
    }

    func test_execute_propagatesRepositoryError() async {
        do {
            _ = try await makeSUT(.failure(AppError.storage)).execute()
            XCTFail("Expected execute to throw")
        } catch {
            XCTAssertEqual(error as? AppError, .storage)
        }
    }

    private func makeSUT(_ result: Result<[Appointment], Error>) -> ListAppointmentsUseCase {
        ListAppointmentsUseCase(repository: AppointmentRepositoryStub(existing: result))
    }
}
