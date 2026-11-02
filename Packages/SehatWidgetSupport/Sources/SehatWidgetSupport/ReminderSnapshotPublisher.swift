//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import SehatDomain

/// Builds the snapshot from the stored reminders, saves it, and asks the
/// widget to refresh. Only enabled reminders are included.
public struct ReminderSnapshotPublisher: Sendable {
    private let repository: any MedicationReminderRepository
    private let store: any ReminderSnapshotStoring
    private let reloader: any TimelineReloading

    public init(
        repository: any MedicationReminderRepository,
        store: any ReminderSnapshotStoring,
        reloader: any TimelineReloading
    ) {
        self.repository = repository
        self.store = store
        self.reloader = reloader
    }

    /// - Throws: `AppError`. The widget is refreshed only after a successful save.
    public func publish() async throws {
        let slots = try await repository.reminders()
            .filter(\.isEnabled)
            .map { ReminderSlot($0) }
            .sorted()
        try await store.save(ReminderSnapshot(slots: slots))
        reloader.reloadTimelines()
    }
}
