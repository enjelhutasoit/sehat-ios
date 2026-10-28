//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import Observation
import SehatDomain

/// Owns presentation of the booking sheet and builds view models.
/// A finished booking asks the list to reload through `refreshToken`.
@MainActor
@Observable
public final class AppointmentCoordinator {
    var isPresentingBooking = false
    private(set) var refreshToken = 0

    private let repository: any AppointmentRepository
    private let now: @Sendable () -> Date

    public init(
        repository: any AppointmentRepository,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.repository = repository
        self.now = now
    }

    func makeListViewModel() -> AppointmentListViewModel {
        AppointmentListViewModel(listAppointments: ListAppointmentsUseCase(repository: repository))
    }

    /// The start time defaults to one hour from now.
    func makeBookingViewModel() -> BookingViewModel {
        BookingViewModel(
            startsAt: now().addingTimeInterval(3_600),
            bookAppointment: BookAppointmentUseCase(repository: repository, now: now),
            onBooked: { [weak self] appointment in self?.bookingFinished(appointment) }
        )
    }

    func showBooking() {
        isPresentingBooking = true
    }

    func cancelBooking() {
        isPresentingBooking = false
    }

    private func bookingFinished(_ appointment: Appointment) {
        isPresentingBooking = false
        refreshToken += 1
    }
}
