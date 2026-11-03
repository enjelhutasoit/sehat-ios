//
// Copyright (c) 2026 Enjel Hutasoit
//

import SehatAppointment
import SehatConsultation
import SehatDomain
import SehatMedication
import SehatPersistence
import SehatWidgetSupport
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
                        repository: await makeMedicationRepository(base: medicationStore),
                        scheduler: reminderScheduler
                    )
                )
            )
        } catch {
            return .failed
        }
    }

    /// With the App Group available, every reminder change is published to the
    /// widget, and the snapshot is rebuilt now (heals drift). Without it the
    /// app works unchanged and the widget asks the user to open the app.
    private static func makeMedicationRepository(
        base: MedicationStore
    ) async -> any MedicationReminderRepository {
        guard let directory = SharedContainer.snapshotDirectory() else { return base }

        let publisher = ReminderSnapshotPublisher(
            repository: base,
            store: FileReminderSnapshotStore(directory: directory),
            reloader: WidgetCenterReloader()
        )
        _ = try? await publisher.publish()
        return SnapshotPublishingRepository(base: base, publisher: publisher)
    }
}
