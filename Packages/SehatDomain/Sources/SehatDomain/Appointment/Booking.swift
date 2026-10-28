//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

/// What the patient asks for. Validated and turned into an `Appointment`
/// by `BookAppointmentUseCase`.
public struct BookingRequest: Sendable, Equatable {
    public let doctorName: String
    public let specialty: String
    public let startsAt: Date

    public init(doctorName: String, specialty: String, startsAt: Date) {
        self.doctorName = doctorName
        self.specialty = specialty
        self.startsAt = startsAt
    }
}

/// Input mistakes the patient can fix. System failures use `AppError`.
public enum BookingError: Error, Sendable, Equatable {
    case missingDoctorName
    case missingSpecialty
    case startsInThePast
    case slotAlreadyBooked
}
