//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import Observation
import SehatCore
import SehatDomain

@MainActor
@Observable
final class BookingViewModel {
    enum Failure: Equatable {
        case validation(BookingError)
        case system(AppError)
    }

    enum Phase: Equatable {
        case editing
        case submitting
        case failed(Failure)
    }

    var doctorName = ""
    var specialty = ""
    var startsAt: Date
    private(set) var phase: Phase = .editing

    private let bookAppointment: BookAppointmentUseCase
    private let onBooked: @MainActor (Appointment) -> Void

    init(
        startsAt: Date,
        bookAppointment: BookAppointmentUseCase,
        onBooked: @escaping @MainActor (Appointment) -> Void
    ) {
        self.startsAt = startsAt
        self.bookAppointment = bookAppointment
        self.onBooked = onBooked
    }

    /// Books the appointment. A call made while another is running is ignored.
    func submit() async {
        guard phase != .submitting else { return }
        phase = .submitting

        do {
            let appointment = try await bookAppointment.execute(
                BookingRequest(doctorName: doctorName, specialty: specialty, startsAt: startsAt)
            )
            phase = .editing
            onBooked(appointment)
        } catch let error as BookingError {
            phase = .failed(.validation(error))
        } catch {
            let appError = DefaultErrorMapper().map(error)
            phase = appError == .cancelled ? .editing : .failed(.system(appError))
        }
    }
}
