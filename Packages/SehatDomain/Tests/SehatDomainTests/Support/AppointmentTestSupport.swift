//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import SehatDomain

func makeAppointment(
    id: Int = 1,
    status: Appointment.Status = .pending,
    at seconds: TimeInterval = 7_200
) -> Appointment {
    Appointment(
        id: makeUUID(id),
        doctorName: "Dr. Example",
        specialty: "General",
        startsAt: Date(timeIntervalSince1970: seconds),
        status: status
    )
}

actor AppointmentRepositoryStub: AppointmentRepository {
    private let existing: Result<[Appointment], Error>
    private let bookFailure: Error?
    private(set) var booked: [Appointment] = []

    init(existing: Result<[Appointment], Error> = .success([]), bookFailure: Error? = nil) {
        self.existing = existing
        self.bookFailure = bookFailure
    }

    func appointments() async throws -> [Appointment] {
        try existing.get()
    }

    func book(_ appointment: Appointment) async throws {
        if let bookFailure { throw bookFailure }
        booked.append(appointment)
    }
}
