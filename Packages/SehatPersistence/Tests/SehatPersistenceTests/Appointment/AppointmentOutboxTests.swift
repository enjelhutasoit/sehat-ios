//
// Copyright (c) 2026 Enjel Hutasoit
//

import XCTest
import SehatCore
@testable import SehatPersistence

final class AppointmentOutboxTests: XCTestCase {

    func test_bookEntry_usesAppointmentIDAsEntryAndEntityID() throws {
        let appointment = makeAppointment(id: 7)

        let entry = try AppointmentOutbox.bookEntry(for: appointment)

        XCTAssertEqual(entry.id, appointment.id)
        XCTAssertEqual(entry.entityID, appointment.id)
        XCTAssertEqual(entry.kind, AppointmentOutbox.bookKind)
    }

    func test_bookEntry_encodesStablePayload() throws {
        let entry = try AppointmentOutbox.bookEntry(for: makeAppointment(id: 1))

        XCTAssertEqual(
            String(decoding: entry.payload, as: UTF8.self),
            #"{"doctorName":"Dr. Example","id":"00000000-0000-0000-0000-000000000001","specialty":"General","startsAt":"1970-01-01T00:16:40Z"}"#
        )
    }

    func test_bookingPayload_roundTripsEncodedEntry() throws {
        let appointment = makeAppointment(id: 3)
        let entry = try AppointmentOutbox.bookEntry(for: appointment)

        let payload = try AppointmentOutbox.bookingPayload(from: entry)

        XCTAssertEqual(
            payload,
            AppointmentOutbox.BookingPayload(
                id: appointment.id,
                doctorName: appointment.doctorName,
                specialty: appointment.specialty,
                startsAt: appointment.startsAt
            )
        )
    }

    func test_bookingPayload_throwsDecoding_forInvalidPayload() {
        let entry = OutboxEntry(
            id: makeUUID(1), entityID: makeUUID(1),
            kind: AppointmentOutbox.bookKind, payload: Data("not json".utf8)
        )

        XCTAssertThrowsError(try AppointmentOutbox.bookingPayload(from: entry)) { error in
            XCTAssertEqual(error as? AppError, .decoding)
        }
    }

    func test_bookingPayload_throwsDecoding_forOtherKind() throws {
        let valid = try AppointmentOutbox.bookEntry(for: makeAppointment())
        let other = OutboxEntry(id: valid.id, entityID: valid.entityID, kind: "consultation.cancel", payload: valid.payload)

        XCTAssertThrowsError(try AppointmentOutbox.bookingPayload(from: other)) { error in
            XCTAssertEqual(error as? AppError, .decoding)
        }
    }
}
