//
// Copyright (c) 2026 Enjel Hutasoit
//

import XCTest
import SwiftData
import SehatCore
import SehatDomain
@testable import SehatPersistence

final class MedicationStoreTests: XCTestCase {

    func test_reminders_returnsEmpty_whenNothingIsSaved() async throws {
        let (sut, _) = try makeSUT()

        let loaded = try await sut.reminders()

        XCTAssertTrue(loaded.isEmpty)
    }

    func test_save_thenReminders_roundTripsTimeAndEnabledFlag() async throws {
        let (sut, _) = try makeSUT()
        let items = [
            makeReminder(id: 1, hour: 0, minute: 0, isEnabled: true),
            makeReminder(id: 2, hour: 23, minute: 59, isEnabled: false)
        ]

        for item in items { try await sut.save(item) }
        let loaded = try await sut.reminders()

        XCTAssertEqual(Set(loaded), Set(items))
    }

    func test_save_replacesExistingReminderWithSameID() async throws {
        let (sut, _) = try makeSUT()
        try await sut.save(makeReminder(id: 1, name: "Old", hour: 8))

        let updated = makeReminder(id: 1, name: "New", hour: 9, isEnabled: false)
        try await sut.save(updated)
        let loaded = try await sut.reminders()

        XCTAssertEqual(loaded, [updated])
    }

    func test_delete_removesOnlyTheMatchingReminder() async throws {
        let (sut, _) = try makeSUT()
        let kept = makeReminder(id: 2)
        try await sut.save(makeReminder(id: 1))
        try await sut.save(kept)

        try await sut.delete(id: makeUUID(1))
        let loaded = try await sut.reminders()

        XCTAssertEqual(loaded, [kept])
    }

    func test_delete_ignoresUnknownID() async throws {
        let (sut, _) = try makeSUT()
        let reminder = makeReminder(id: 1)
        try await sut.save(reminder)

        try await sut.delete(id: makeUUID(99))
        let loaded = try await sut.reminders()

        XCTAssertEqual(loaded, [reminder])
    }

    func test_reminders_throwsStorage_whenStoredTimeIsInvalid() async throws {
        let (sut, container) = try makeSUT()
        let context = ModelContext(container)
        context.insert(
            MedicationReminderRecord(
                id: makeUUID(1), medicationName: "Broken", dosage: "1 tablet",
                hour: 99, minute: 0, isEnabled: true
            )
        )
        try context.save()

        do {
            _ = try await sut.reminders()
            XCTFail("Expected reminders to throw")
        } catch {
            XCTAssertEqual(error as? AppError, .storage)
        }
    }

    private func makeSUT() throws -> (MedicationStore, ModelContainer) {
        let container = try PersistenceStack.makeContainer(inMemory: true)
        return (MedicationStore(modelContainer: container), container)
    }
}
