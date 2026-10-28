//
// Copyright (c) 2026 Enjel Hutasoit
//

import SehatAppointment
import SehatConsultation
import SehatPersistence
import SwiftData

/// Composition root: builds storage and the coordinators.
/// If storage cannot be opened it reports `.failed` and deletes nothing.
/// There is no logging yet, so the cause is not recorded.
@MainActor
enum Startup {
    struct Coordinators {
        let consultation: ConsultationCoordinator
        let appointment: AppointmentCoordinator
    }

    case loading
    case ready(Coordinators)
    case failed

    static func make() async -> Startup {
        do {
            let container = try PersistenceStack.makeContainer()
            let consultationStore = ConsultationStore(modelContainer: container)
            try await consultationStore.upsert(SampleData.consultations())
            let appointmentStore = AppointmentStore(modelContainer: container)

            return .ready(
                Coordinators(
                    consultation: ConsultationCoordinator(repository: consultationStore),
                    appointment: AppointmentCoordinator(repository: appointmentStore)
                )
            )
        } catch {
            return .failed
        }
    }
}
