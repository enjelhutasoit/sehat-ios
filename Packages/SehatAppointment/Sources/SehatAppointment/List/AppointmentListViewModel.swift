//
// Copyright (c) 2026 Enjel Hutasoit
//

import Observation
import SehatCore
import SehatDomain

@MainActor
@Observable
final class AppointmentListViewModel {
    private(set) var state: LoadState<[Appointment]> = .idle

    @ObservationIgnored private var generation = 0
    private let listAppointments: ListAppointmentsUseCase

    init(listAppointments: ListAppointmentsUseCase) {
        self.listAppointments = listAppointments
    }

    /// The newest call wins: a result from an older call that finishes later
    /// is discarded, so a refresh after booking is never overwritten.
    func load() async {
        generation += 1
        let thisLoad = generation

        let current = state
        let previous: LoadState<[Appointment]> = current == .loading ? .idle : current
        state = previous.startingLoad()

        do {
            let appointments = try await listAppointments.execute()
            guard thisLoad == generation else { return }
            state = .loaded(appointments)
        } catch {
            guard thisLoad == generation else { return }
            state = .afterFailure(error, restoring: previous)
        }
    }
}
