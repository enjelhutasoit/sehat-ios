//
// Copyright (c) 2026 Enjel Hutasoit
//

import SehatBackground
import SehatDomain
import SehatPersistence

/// The only background job today: heal drift between stored reminders and
/// scheduled notifications. It does not sync with a server: no remote
/// adapter exists yet (see ADR-0012).
struct ReminderReconcileWork: BackgroundWork {
    func perform() async throws {
        let container = try await AppEnvironment.shared.container()
        let store = MedicationStore(modelContainer: container)
        try await ReconcileRemindersUseCase(
            repository: store,
            scheduler: UserNotificationReminderScheduler()
        ).execute()
    }
}
