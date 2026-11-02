//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import SehatCore
import SehatDomain
import SehatWidgetSupport

func makeUUID(_ number: Int) -> UUID {
    let suffix = String(format: "%012d", number)
    guard let uuid = UUID(uuidString: "00000000-0000-0000-0000-\(suffix)") else {
        preconditionFailure("Invalid test fixture")
    }
    return uuid
}

func makeTime(_ hour: Int, _ minute: Int = 0) -> TimeOfDay {
    guard let time = TimeOfDay(hour: hour, minute: minute) else {
        preconditionFailure("Invalid test fixture")
    }
    return time
}

func makeSlot(id: Int = 1, name: String = "Paracetamol", hour: Int = 8, minute: Int = 0) -> ReminderSlot {
    ReminderSlot(id: makeUUID(id), medicationName: name, timeOfDay: makeTime(hour, minute))
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

func makeDate(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0, _ second: Int = 0) -> Date {
    let components = DateComponents(year: year, month: month, day: day, hour: hour, minute: minute, second: second)
    guard let date = makeUTCCalendar().date(from: components) else {
        preconditionFailure("Invalid test fixture")
    }
    return date
}

/// Thread-safe, ordered log shared by the doubles.
final class EventLog: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String] = []

    func append(_ event: String) {
        lock.withLock { storage.append(event) }
    }

    var events: [String] {
        lock.withLock { storage }
    }
}

actor RepositoryFake: MedicationReminderRepository {
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
        stored.removeAll { $0.id == reminder.id }
        stored.append(reminder)
    }

    func delete(id: MedicationReminder.ID) async throws {
        if let writeFailure { throw writeFailure }
        stored.removeAll { $0.id == id }
    }
}

actor SnapshotStoreFake: ReminderSnapshotStoring {
    private(set) var saved: [ReminderSnapshot] = []
    private let saveFailure: Error?
    private let log: EventLog?

    init(saveFailure: Error? = nil, log: EventLog? = nil) {
        self.saveFailure = saveFailure
        self.log = log
    }

    func save(_ snapshot: ReminderSnapshot) async throws {
        log?.append("save")
        if let saveFailure { throw saveFailure }
        saved.append(snapshot)
    }

    func load() async throws -> ReminderSnapshot? {
        saved.last
    }
}

final class ReloaderFake: TimelineReloading, @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0
    private let log: EventLog?

    init(log: EventLog? = nil) {
        self.log = log
    }

    var reloadCount: Int {
        lock.withLock { count }
    }

    func reloadTimelines() {
        log?.append("reload")
        lock.withLock { count += 1 }
    }
}
