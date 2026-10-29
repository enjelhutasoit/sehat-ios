//
// Copyright (c) 2026 Enjel Hutasoit
//

import SehatAppointment
import SehatConsultation
import SehatDomain
import SehatMedication
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
        let medication: MedicationCoordinator
    }

    case loading
    case ready(Coordinators)
    case failed

    static func make() async -> Startup {
        do {
            let container = try await AppEnvironment.shared.container()
            let consultationStore = ConsultationStore(modelContainer: container)
            try await consultationStore.upsert(SampleData.consultations())
            let appointmentStore = AppointmentStore(modelContainer: container)
            let medicationStore = MedicationStore(modelContainer: container)
            let reminderScheduler = UserNotificationReminderScheduler()

            // Heals drift between stored reminders and scheduled notifications.
            // A failure is not fatal: the next change or launch retries.
            _ = try? await ReconcileRemindersUseCase(
                repository: medicationStore,
                scheduler: reminderScheduler
            ).execute()

            return .ready(
                Coordinators(
                    consultation: ConsultationCoordinator(repository: consultationStore),
                    appointment: AppointmentCoordinator(repository: appointmentStore),
                    medication: MedicationCoordinator(
                        repository: medicationStore,
                        scheduler: reminderScheduler
                    )
                )
            )
        } catch {
            return .failed
        }
    }
}
