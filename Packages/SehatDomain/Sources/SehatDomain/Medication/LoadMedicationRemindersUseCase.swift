//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

public struct ReminderOverview: Sendable, Equatable {
    /// Ordered by time of day, then name, then id.
    public let reminders: [MedicationReminder]
    public let authorization: ReminderAuthorization

    public init(reminders: [MedicationReminder], authorization: ReminderAuthorization) {
        self.reminders = reminders
        self.authorization = authorization
    }
}

/// Loads reminders in a stable order, together with the notification permission
/// so the screen can warn when reminders cannot be delivered.
public struct LoadMedicationRemindersUseCase: Sendable {
    private let repository: any MedicationReminderRepository
    private let scheduler: any ReminderScheduler

    public init(repository: any MedicationReminderRepository, scheduler: any ReminderScheduler) {
        self.repository = repository
        self.scheduler = scheduler
    }

    public func execute() async throws -> ReminderOverview {
        let reminders = try await repository.reminders().sorted(by: Self.isEarlier)
        let authorization = await scheduler.authorizationStatus()
        return ReminderOverview(reminders: reminders, authorization: authorization)
    }

    private static func isEarlier(_ lhs: MedicationReminder, _ rhs: MedicationReminder) -> Bool {
        if lhs.timeOfDay != rhs.timeOfDay { return lhs.timeOfDay < rhs.timeOfDay }
        if lhs.medicationName != rhs.medicationName { return lhs.medicationName < rhs.medicationName }
        return lhs.id.uuidString < rhs.id.uuidString
    }
}
