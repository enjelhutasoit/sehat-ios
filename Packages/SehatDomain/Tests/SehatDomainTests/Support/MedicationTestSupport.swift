//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import SehatCore
import SehatDomain

func makeTime(_ hour: Int = 8, _ minute: Int = 0) -> TimeOfDay {
    guard let time = TimeOfDay(hour: hour, minute: minute) else {
        preconditionFailure("Invalid test fixture")
    }
    return time
}

func makeReminder(
    id: Int = 1,
    name: String = "Paracetamol",
    dosage: String = "1 tablet",
    hour: Int = 8,
    minute: Int = 0,
    isEnabled: Bool = true
) -> MedicationReminder {
    MedicationReminder(
        id: makeUUID(id),
        medicationName: name,
        dosage: dosage,
        timeOfDay: makeTime(hour, minute),
        isEnabled: isEnabled
    )
}

actor ReminderRepositoryFake: MedicationReminderRepository {
    private(set) var stored: [MedicationReminder]
    private let listFailure: Error?
    private let writeFailure: Error?

    init(_ stored: [MedicationReminder] = [], listFailure: Error? = nil, writeFailure: Error? = nil) {
        self.stored = stored
        self.listFailure = listFailure
        self.writeFailure = writeFailure
    }

    func reminders() async throws -> [MedicationReminder] {
        if let listFailure { throw listFailure }
        return stored
    }

    func save(_ reminder: MedicationReminder) async throws {
        if let writeFailure { throw writeFailure }
        if let index = stored.firstIndex(where: { $0.id == reminder.id }) {
            stored[index] = reminder
        } else {
            stored.append(reminder)
        }
    }

    func delete(id: MedicationReminder.ID) async throws {
        if let writeFailure { throw writeFailure }
        stored.removeAll { $0.id == id }
    }
}

actor SchedulerFake: ReminderScheduler {
    private(set) var scheduled: [MedicationReminder.ID: MedicationReminder]
    private(set) var cancelCalls: [Set<MedicationReminder.ID>] = []
    private(set) var requestCount = 0
    private var status: ReminderAuthorization
    private let grantsOnRequest: Bool
    private let scheduleFailure: Error?
    private let requestFailure: Error?

    init(
        scheduled: [MedicationReminder] = [],
        status: ReminderAuthorization = .authorized,
        grantsOnRequest: Bool = true,
        scheduleFailure: Error? = nil,
        requestFailure: Error? = nil
    ) {
        self.scheduled = Dictionary(uniqueKeysWithValues: scheduled.map { ($0.id, $0) })
        self.status = status
        self.grantsOnRequest = grantsOnRequest
        self.scheduleFailure = scheduleFailure
        self.requestFailure = requestFailure
    }

    func authorizationStatus() async -> ReminderAuthorization {
        status
    }

    func requestAuthorization() async throws -> Bool {
        requestCount += 1
        if let requestFailure { throw requestFailure }
        status = grantsOnRequest ? .authorized : .denied
        return grantsOnRequest
    }

    func schedule(_ reminder: MedicationReminder) async throws {
        if let scheduleFailure { throw scheduleFailure }
        scheduled[reminder.id] = reminder
    }

    func cancel(reminderIDs: [MedicationReminder.ID]) async {
        cancelCalls.append(Set(reminderIDs))
        for id in reminderIDs { scheduled[id] = nil }
    }

    func scheduledReminderIDs() async -> Set<MedicationReminder.ID> {
        Set(scheduled.keys)
    }
}
