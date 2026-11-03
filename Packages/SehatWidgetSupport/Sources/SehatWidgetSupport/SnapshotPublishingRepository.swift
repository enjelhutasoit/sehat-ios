//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import SehatDomain

/// Decorator: after every successful change, publishes the snapshot.
///
/// Publishing failures are ignored (there is no logging yet): the snapshot is
/// derived data, and the app publishes again at launch. Give the publisher the
/// base repository, not this decorator.
public struct SnapshotPublishingRepository: MedicationReminderRepository {
    private let base: any MedicationReminderRepository
    private let publisher: ReminderSnapshotPublisher

    public init(base: any MedicationReminderRepository, publisher: ReminderSnapshotPublisher) {
        self.base = base
        self.publisher = publisher
    }

    public func reminders() async throws -> [MedicationReminder] {
        try await base.reminders()
    }

    public func save(_ reminder: MedicationReminder) async throws {
        try await base.save(reminder)
        await publishQuietly()
    }

    public func delete(id: MedicationReminder.ID) async throws {
        try await base.delete(id: id)
        await publishQuietly()
    }

    private func publishQuietly() async {
        _ = try? await publisher.publish()
    }
}
