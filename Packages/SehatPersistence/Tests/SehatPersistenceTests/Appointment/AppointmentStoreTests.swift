//
// Copyright (c) 2026 Enjel Hutasoit
//

import XCTest
import SwiftData
import SehatCore
import SehatDomain
@testable import SehatPersistence

final class AppointmentStoreTests: XCTestCase {

    func test_appointments_returnsEmpty_whenNothingIsBooked() async throws {
        let (sut, _, _) = try makeSUT()

        let loaded = try await sut.appointments()

        XCTAssertTrue(loaded.isEmpty)
    }

    func test_book_thenAppointments_returnsBookedAppointment() async throws {
        let (sut, _, _) = try makeSUT()
        let appointment = makeAppointment(id: 1)

        try await sut.book(appointment)
        let loaded = try await sut.appointments()

        XCTAssertEqual(loaded, [appointment])
    }

    func test_book_roundTripsEveryStatus() async throws {
        let (sut, _, _) = try makeSUT()
        let items = [makeAppointment(id: 1, status: .pending), makeAppointment(id: 2, status: .confirmed)]

        for item in items { try await sut.book(item) }
        let loaded = try await sut.appointments()

        XCTAssertEqual(Set(loaded), Set(items))
    }

    func test_book_queuesOneOutboxEntryForTheAppointment() async throws {
        let (sut, outbox, _) = try makeSUT()
        let appointment = makeAppointment(id: 7)

        try await sut.book(appointment)
        let pending = try await outbox.pending()

        let entry = try XCTUnwrap(pending.first)
        XCTAssertEqual(pending.count, 1)
        XCTAssertEqual(entry.id, appointment.id)
        XCTAssertEqual(entry.entityID, appointment.id)
        XCTAssertEqual(entry.kind, AppointmentOutbox.bookKind)
        let payload = try AppointmentOutbox.bookingPayload(from: entry)
        XCTAssertEqual(payload.id, appointment.id)
        XCTAssertEqual(payload.doctorName, appointment.doctorName)
        XCTAssertEqual(payload.startsAt, appointment.startsAt)
    }

    func test_book_isIdempotent_forSameID() async throws {
        let (sut, outbox, _) = try makeSUT()
        let appointment = makeAppointment(id: 1)

        try await sut.book(appointment)
        try await sut.book(appointment)
        let loaded = try await sut.appointments()
        let pending = try await outbox.pending()

        XCTAssertEqual(loaded, [appointment])
        XCTAssertEqual(pending.count, 1)
    }

    func test_book_keepsOutboxInBookingOrder() async throws {
        let (sut, outbox, _) = try makeSUT()

        try await sut.book(makeAppointment(id: 2))
        try await sut.book(makeAppointment(id: 1))
        let pending = try await outbox.pending()

        XCTAssertEqual(pending.map(\.id), [makeUUID(2), makeUUID(1)])
    }

    func test_appointments_throwsStorage_whenRecordHasUnknownStatus() async throws {
        let (sut, _, container) = try makeSUT()
        let context = ModelContext(container)
        context.insert(
            AppointmentRecord(
                id: makeUUID(1), doctorName: "Dr. Broken", specialty: "General",
                startsAt: Date(timeIntervalSince1970: 0), statusRaw: "unknown"
            )
        )
        try context.save()

        await assertThrowsAppError(.storage) { _ = try await sut.appointments() }
    }

    // MARK: - Helpers

    private func makeSUT() throws -> (AppointmentStore, OutboxStore, ModelContainer) {
        let container = try PersistenceStack.makeContainer(inMemory: true)
        return (AppointmentStore(modelContainer: container), OutboxStore(modelContainer: container), container)
    }
}
