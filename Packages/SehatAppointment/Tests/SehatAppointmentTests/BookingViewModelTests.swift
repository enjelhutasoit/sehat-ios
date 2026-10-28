//
// Copyright (c) 2026 Enjel Hutasoit
//

import SehatCore
import SehatDomain
import XCTest

@testable import SehatAppointment

@MainActor
final class BookingViewModelTests: XCTestCase {
    private let startsAt = Date(timeIntervalSince1970: 7_200)

    func test_initialState_isEditing_withEmptyFields() {
        let (sut, _) = makeSUT(RepositoryStub())

        XCTAssertEqual(sut.phase, .editing)
        XCTAssertEqual(sut.doctorName, "")
        XCTAssertEqual(sut.specialty, "")
        XCTAssertEqual(sut.startsAt, startsAt)
    }

    func test_submit_booksAppointment_andReportsIt() async {
        let repository = RepositoryStub()
        let (sut, recorder) = makeSUT(repository)
        fill(sut)

        await sut.submit()

        let expected = Appointment(
            id: makeUUID(42), doctorName: "Dr. Example", specialty: "General",
            startsAt: startsAt, status: .pending
        )
        XCTAssertEqual(recorder.appointments, [expected])
        let booked = await repository.booked
        XCTAssertEqual(booked, [expected])
        XCTAssertEqual(sut.phase, .editing)
    }

    func test_submit_publishesValidationFailure_andDoesNotReport() async {
        let (sut, recorder) = makeSUT(RepositoryStub())

        await sut.submit()

        XCTAssertEqual(sut.phase, .failed(.validation(.missingDoctorName)))
        XCTAssertTrue(recorder.appointments.isEmpty)
    }

    func test_submit_publishesSystemFailure_whenBookingFails() async {
        let (sut, recorder) = makeSUT(RepositoryStub(bookFailure: AppError.storage))
        fill(sut)

        await sut.submit()

        XCTAssertEqual(sut.phase, .failed(.system(.storage)))
        XCTAssertTrue(recorder.appointments.isEmpty)
    }

    func test_submit_returnsToEditing_whenCancelled() async {
        let (sut, recorder) = makeSUT(RepositoryStub(bookFailure: CancellationError()))
        fill(sut)

        await sut.submit()

        XCTAssertEqual(sut.phase, .editing)
        XCTAssertTrue(recorder.appointments.isEmpty)
    }

    func test_submit_canBeRetried_afterFailure() async {
        let repository = RepositoryStub()
        let (sut, recorder) = makeSUT(repository)
        await sut.submit()
        fill(sut)

        await sut.submit()

        XCTAssertEqual(sut.phase, .editing)
        XCTAssertEqual(recorder.appointments.count, 1)
    }

    func test_submit_ignoresSecondCall_whileFirstIsInFlight() async {
        let gated = GatedBookRepository()
        let (sut, recorder) = makeSUT(gated)
        fill(sut)
        let first = Task { await sut.submit() }
        await eventually { await gated.isBookWaiting }

        await sut.submit()

        let calls = await gated.bookCallCount
        XCTAssertEqual(calls, 1)
        XCTAssertEqual(sut.phase, .submitting)

        await gated.releaseBook()
        await first.value
        XCTAssertEqual(sut.phase, .editing)
        XCTAssertEqual(recorder.appointments.count, 1)
    }

    // MARK: - Helpers

    private func makeSUT(_ repository: some AppointmentRepository) -> (BookingViewModel, BookedRecorder) {
        let recorder = BookedRecorder()
        let sut = BookingViewModel(
            startsAt: startsAt,
            bookAppointment: BookAppointmentUseCase(
                repository: repository,
                now: { Date(timeIntervalSince1970: 3_600) },
                makeID: { makeUUID(42) }
            ),
            onBooked: { recorder.record($0) }
        )
        return (sut, recorder)
    }

    private func fill(_ sut: BookingViewModel) {
        sut.doctorName = "Dr. Example"
        sut.specialty = "General"
    }
}
