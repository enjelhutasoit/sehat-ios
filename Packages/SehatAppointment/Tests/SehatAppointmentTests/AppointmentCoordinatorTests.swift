//
// Copyright (c) 2026 Enjel Hutasoit
//

import XCTest
import SehatDomain
@testable import SehatAppointment

@MainActor
final class AppointmentCoordinatorTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_000)

    func test_initialState_hasNoSheet_andNoRefreshRequest() {
        let sut = makeSUT()

        XCTAssertFalse(sut.isPresentingBooking)
        XCTAssertEqual(sut.refreshToken, 0)
    }

    func test_showBooking_andCancelBooking_toggleTheSheet() {
        let sut = makeSUT()

        sut.showBooking()
        XCTAssertTrue(sut.isPresentingBooking)

        sut.cancelBooking()
        XCTAssertFalse(sut.isPresentingBooking)
        XCTAssertEqual(sut.refreshToken, 0)
    }

    func test_makeBookingViewModel_defaultsStartTimeToTheFuture() {
        let sut = makeSUT()

        XCTAssertGreaterThan(sut.makeBookingViewModel().startsAt, now)
    }

    func test_successfulBooking_closesSheet_andRequestsListRefresh() async {
        let sut = makeSUT()
        sut.showBooking()
        let booking = sut.makeBookingViewModel()
        booking.doctorName = "Dr. Example"
        booking.specialty = "General"

        await booking.submit()

        XCTAssertFalse(sut.isPresentingBooking)
        XCTAssertEqual(sut.refreshToken, 1)
    }

    func test_failedBooking_keepsSheetOpen_andDoesNotRefresh() async {
        let sut = makeSUT()
        sut.showBooking()

        await sut.makeBookingViewModel().submit()

        XCTAssertTrue(sut.isPresentingBooking)
        XCTAssertEqual(sut.refreshToken, 0)
    }

    func test_makeListViewModel_loadsSortedAppointments() async {
        let late = makeAppointment(id: 1, at: 300)
        let early = makeAppointment(id: 2, at: 100)
        let sut = makeSUT(existing: [late, early])
        let viewModel = sut.makeListViewModel()

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .loaded([early, late]))
    }

    private func makeSUT(existing: [Appointment] = []) -> AppointmentCoordinator {
        let now = self.now
        return AppointmentCoordinator(repository: RepositoryStub(.success(existing)), now: { now })
    }
}
