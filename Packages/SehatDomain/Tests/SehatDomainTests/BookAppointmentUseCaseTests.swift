//
// Copyright (c) 2026 Enjel Hutasoit
//

import XCTest
import SehatCore
import SehatDomain

final class BookAppointmentUseCaseTests: XCTestCase {
    // "now" is 3_600 s; a valid start is 7_200 s (both whole minutes).
    private let futureStart = Date(timeIntervalSince1970: 7_200)

    func test_execute_booksPendingAppointment_andReturnsIt() async throws {
        let repository = AppointmentRepositoryStub()
        let sut = makeSUT(repository)

        let appointment = try await sut.execute(makeRequest())

        let expected = Appointment(
            id: makeUUID(42),
            doctorName: "Dr. Example",
            specialty: "General",
            startsAt: futureStart,
            status: .pending
        )
        XCTAssertEqual(appointment, expected)
        let booked = await repository.booked
        XCTAssertEqual(booked, [expected])
    }

    func test_execute_trimsNames() async throws {
        let sut = makeSUT(AppointmentRepositoryStub())

        let appointment = try await sut.execute(makeRequest(doctor: "  Dr. Example \n", specialty: " General "))

        XCTAssertEqual(appointment.doctorName, "Dr. Example")
        XCTAssertEqual(appointment.specialty, "General")
    }

    func test_execute_truncatesStartTimeToWholeMinutes() async throws {
        let sut = makeSUT(AppointmentRepositoryStub())

        let appointment = try await sut.execute(makeRequest(start: 7_245))

        XCTAssertEqual(appointment.startsAt, futureStart)
    }

    func test_execute_throwsMissingDoctorName_forBlankName_andDoesNotBook() async {
        let repository = AppointmentRepositoryStub()

        await assertThrows(.missingDoctorName, repository: repository, request: makeRequest(doctor: "  \n"))
    }

    func test_execute_throwsMissingSpecialty_forBlankSpecialty_andDoesNotBook() async {
        let repository = AppointmentRepositoryStub()

        await assertThrows(.missingSpecialty, repository: repository, request: makeRequest(specialty: " "))
    }

    func test_execute_checksDoctorNameBeforeSpecialty() async {
        await assertThrows(
            .missingDoctorName,
            repository: AppointmentRepositoryStub(),
            request: makeRequest(doctor: "", specialty: "")
        )
    }

    func test_execute_throwsStartsInThePast_forPastAndCurrentTime() async {
        let repository = AppointmentRepositoryStub()

        await assertThrows(.startsInThePast, repository: repository, request: makeRequest(start: 60))
        await assertThrows(.startsInThePast, repository: repository, request: makeRequest(start: 3_600))
    }

    func test_execute_throwsSlotAlreadyBooked_whenExistingAppointmentStartsAtSameTime() async {
        let existing = makeAppointment(id: 1, status: .confirmed, at: 7_200)
        let repository = AppointmentRepositoryStub(existing: .success([existing]))

        await assertThrows(.slotAlreadyBooked, repository: repository, request: makeRequest())
    }

    func test_execute_comparesSlotsAfterTruncation() async {
        let repository = AppointmentRepositoryStub(existing: .success([makeAppointment(at: 7_200)]))

        await assertThrows(.slotAlreadyBooked, repository: repository, request: makeRequest(start: 7_230))
    }

    func test_execute_allowsDifferentStartTimes() async throws {
        let repository = AppointmentRepositoryStub(existing: .success([makeAppointment(at: 9_000)]))
        let sut = makeSUT(repository)

        let appointment = try await sut.execute(makeRequest())

        XCTAssertEqual(appointment.startsAt, futureStart)
    }

    func test_execute_propagatesRepositoryErrors() async {
        for failing in [
            AppointmentRepositoryStub(existing: .failure(AppError.storage)),
            AppointmentRepositoryStub(bookFailure: AppError.offline)
        ] {
            do {
                _ = try await makeSUT(failing).execute(makeRequest())
                XCTFail("Expected execute to throw")
            } catch {
                XCTAssertTrue(error is AppError)
            }
        }
    }

    // MARK: - Helpers

    private func makeSUT(_ repository: some AppointmentRepository) -> BookAppointmentUseCase {
        BookAppointmentUseCase(
            repository: repository,
            now: { Date(timeIntervalSince1970: 3_600) },
            makeID: { makeUUID(42) }
        )
    }

    private func makeRequest(
        doctor: String = "Dr. Example",
        specialty: String = "General",
        start: TimeInterval = 7_200
    ) -> BookingRequest {
        BookingRequest(doctorName: doctor, specialty: specialty, startsAt: Date(timeIntervalSince1970: start))
    }

    private func assertThrows(
        _ expected: BookingError,
        repository: AppointmentRepositoryStub,
        request: BookingRequest,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            _ = try await makeSUT(repository).execute(request)
            XCTFail("Expected \(expected)", file: file, line: line)
        } catch {
            XCTAssertEqual(error as? BookingError, expected, file: file, line: line)
        }
        let booked = await repository.booked
        XCTAssertTrue(booked.isEmpty, file: file, line: line)
    }
}
