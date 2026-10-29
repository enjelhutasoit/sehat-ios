//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import XCTest
import SehatDomain

func makeUUID(_ number: Int) -> UUID {
    let suffix = String(format: "%012d", number)
    guard let uuid = UUID(uuidString: "00000000-0000-0000-0000-\(suffix)") else {
        preconditionFailure("Invalid test fixture")
    }
    return uuid
}

func makeTime(_ hour: Int = 8, _ minute: Int = 0) -> TimeOfDay {
    guard let time = TimeOfDay(hour: hour, minute: minute) else {
        preconditionFailure("Invalid test fixture")
    }
    return time
}

func makeReminder(
    id: Int = 1,
    name: String = "Paracetamol",
    hour: Int = 8,
    minute: Int = 0,
    isEnabled: Bool = true
) -> MedicationReminder {
    MedicationReminder(
        id: makeUUID(id),
        medicationName: name,
        dosage: "1 tablet",
        timeOfDay: makeTime(hour, minute),
        isEnabled: isEnabled
    )
}

func makeUTCCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .gmt
    return calendar
}

/// Yields until `condition` holds. Uses no wall-clock time; the iteration
/// bound only protects against a hang when the condition can never be met.
func eventually(
    _ condition: @Sendable () async -> Bool,
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    for _ in 0..<100_000 {
        if await condition() { return }
        await Task.yield()
    }
    XCTFail("Condition was not met", file: file, line: line)
}

actor RepositoryFake: MedicationReminderRepository {
    private(set) var stored: [MedicationReminder]
    private var listFailure: Error?
    private var writeFailure: Error?

    init(_ stored: [MedicationReminder] = []) {
        self.stored = stored
    }

    func setListFailure(_ error: Error?) { listFailure = error }
    func setWriteFailure(_ error: Error?) { writeFailure = error }

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
    private(set) var scheduled: [MedicationReminder.ID: MedicationReminder] = [:]
    private let status: ReminderAuthorization

    init(status: ReminderAuthorization = .authorized) {
        self.status = status
    }

    func authorizationStatus() async -> ReminderAuthorization { status }
    func requestAuthorization() async throws -> Bool { status == .authorized }

    func schedule(_ reminder: MedicationReminder) async throws {
        scheduled[reminder.id] = reminder
    }

    func cancel(reminderIDs: [MedicationReminder.ID]) async {
        for id in reminderIDs { scheduled[id] = nil }
    }

    func scheduledReminderIDs() async -> Set<MedicationReminder.ID> {
        Set(scheduled.keys)
    }
}

/// Every `reminders()` call stays suspended until released by index.
actor GatedListRepository: MedicationReminderRepository {
    private var continuations: [CheckedContinuation<[MedicationReminder], Error>] = []

    var startedCount: Int { continuations.count }

    func reminders() async throws -> [MedicationReminder] {
        try await withCheckedThrowingContinuation { continuations.append($0) }
    }

    func save(_ reminder: MedicationReminder) async throws {}
    func delete(id: MedicationReminder.ID) async throws {}

    func release(at index: Int, with result: [MedicationReminder]) {
        continuations[index].resume(returning: result)
    }
}

/// `save` stays suspended until released.
actor GatedSaveRepository: MedicationReminderRepository {
    private(set) var saveCallCount = 0
    private var continuation: CheckedContinuation<Void, Error>?

    var isSaveWaiting: Bool { continuation != nil }

    func reminders() async throws -> [MedicationReminder] { [] }
    func delete(id: MedicationReminder.ID) async throws {}

    func save(_ reminder: MedicationReminder) async throws {
        saveCallCount += 1
        try await withCheckedThrowingContinuation { (waiting: CheckedContinuation<Void, Error>) in
            continuation = waiting
        }
    }

    func releaseSave() {
        continuation?.resume()
        continuation = nil
    }
}

@MainActor
final class SavedRecorder {
    private(set) var reminders: [MedicationReminder] = []

    func record(_ reminder: MedicationReminder) {
        reminders.append(reminder)
    }
}
