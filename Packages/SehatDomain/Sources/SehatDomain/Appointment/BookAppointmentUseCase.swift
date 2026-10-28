//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

/// Validates a booking request and stores the appointment.
///
/// Rules: names are not blank; the start time (truncated to whole minutes)
/// is strictly after now; the patient has no other appointment starting at
/// the same time. The slot check reads then writes, so two simultaneous
/// bookings could both pass; that is acceptable for one patient on one device.
public struct BookAppointmentUseCase: Sendable {
    private let repository: any AppointmentRepository
    private let now: @Sendable () -> Date
    private let makeID: @Sendable () -> UUID

    public init(
        repository: any AppointmentRepository,
        now: @escaping @Sendable () -> Date = { Date() },
        makeID: @escaping @Sendable () -> UUID = { UUID() }
    ) {
        self.repository = repository
        self.now = now
        self.makeID = makeID
    }

    /// - Throws: `BookingError` for invalid input, `AppError` for system failures.
    public func execute(_ request: BookingRequest) async throws -> Appointment {
        let doctorName = request.doctorName.trimmingCharacters(in: .whitespacesAndNewlines)
        let specialty = request.specialty.trimmingCharacters(in: .whitespacesAndNewlines)
        let startsAt = Self.truncatedToMinute(request.startsAt)

        guard !doctorName.isEmpty else { throw BookingError.missingDoctorName }
        guard !specialty.isEmpty else { throw BookingError.missingSpecialty }
        guard startsAt > now() else { throw BookingError.startsInThePast }

        let existing = try await repository.appointments()
        guard !existing.contains(where: { $0.startsAt == startsAt }) else {
            throw BookingError.slotAlreadyBooked
        }

        let appointment = Appointment(
            id: makeID(),
            doctorName: doctorName,
            specialty: specialty,
            startsAt: startsAt,
            status: .pending
        )
        try await repository.book(appointment)
        return appointment
    }

    private static func truncatedToMinute(_ date: Date) -> Date {
        Date(timeIntervalSince1970: (date.timeIntervalSince1970 / 60).rounded(.down) * 60)
    }
}
