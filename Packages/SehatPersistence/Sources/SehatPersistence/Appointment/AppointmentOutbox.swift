//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import SehatCore
import SehatDomain

/// Outbox contract for appointments. The payload is the wire format the
/// server-facing sender will send, so changing it is a contract change.
public enum AppointmentOutbox {
    public static let bookKind = "appointment.book"

    public struct BookingPayload: Codable, Sendable, Equatable {
        public let id: UUID
        public let doctorName: String
        public let specialty: String
        public let startsAt: Date
    }

    /// Entry id and entity id both equal the appointment id, so the
    /// idempotency key is stable across retries.
    static func bookEntry(for appointment: Appointment) throws -> OutboxEntry {
        let payload = BookingPayload(
            id: appointment.id,
            doctorName: appointment.doctorName,
            specialty: appointment.specialty,
            startsAt: appointment.startsAt
        )
        return OutboxEntry(
            id: appointment.id,
            entityID: appointment.id,
            kind: bookKind,
            payload: try makeEncoder().encode(payload)
        )
    }

    /// - Throws: `AppError.decoding` for another kind or an invalid payload.
    public static func bookingPayload(from entry: OutboxEntry) throws -> BookingPayload {
        guard entry.kind == bookKind else { throw AppError.decoding }
        do {
            return try makeDecoder().decode(BookingPayload.self, from: entry.payload)
        } catch {
            throw AppError.decoding
        }
    }

    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
