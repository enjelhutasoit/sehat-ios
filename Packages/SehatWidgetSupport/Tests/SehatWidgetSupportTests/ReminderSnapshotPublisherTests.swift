//
// Copyright (c) 2026 Enjel Hutasoit
//

import SehatCore
import SehatDomain
import SehatWidgetSupport
import XCTest

final class ReminderSnapshotPublisherTests: XCTestCase {

    // MARK: - Publisher

    func test_publish_savesOnlyEnabledReminders_inStableOrder() async throws {
        let late = makeReminder(id: 1, name: "B", hour: 20)
        let earlyB = makeReminder(id: 3, name: "B", hour: 8)
        let earlyA = makeReminder(id: 2, name: "A", hour: 8)
        let disabled = makeReminder(id: 4, name: "Z", hour: 6, isEnabled: false)
        let (sut, store, _) = makePublisher(RepositoryFake([late, disabled, earlyB, earlyA]))

        try await sut.publish()

        let saved = await store.saved
        XCTAssertEqual(saved, [ReminderSnapshot(slots: [
            ReminderSlot(earlyA), ReminderSlot(earlyB), ReminderSlot(late)
        ])])
    }

    func test_publish_savesAnEmptySnapshot_whenNothingIsEnabled() async throws {
        let (sut, store, reloader) = makePublisher(RepositoryFake([makeReminder(isEnabled: false)]))

        try await sut.publish()

        let saved = await store.saved
        XCTAssertEqual(saved, [ReminderSnapshot(slots: [])])
        XCTAssertEqual(reloader.reloadCount, 1)
    }

    func test_publish_reloadsTimelinesAfterSaving() async throws {
        let log = EventLog()
        let (sut, _, _) = makePublisher(RepositoryFake([makeReminder()]), log: log)

        try await sut.publish()

        XCTAssertEqual(log.events, ["save", "reload"])
    }

    func test_publish_throwsAndDoesNothing_whenTheRepositoryFails() async {
        let (sut, store, reloader) = makePublisher(RepositoryFake(listFailure: AppError.storage))

        await assertThrowsAppError(.storage) { try await sut.publish() }

        let saved = await store.saved
        XCTAssertTrue(saved.isEmpty)
        XCTAssertEqual(reloader.reloadCount, 0)
    }

    func test_publish_doesNotReload_whenSavingFails() async {
        let (sut, _, reloader) = makePublisher(RepositoryFake([makeReminder()]), saveFailure: AppError.storage)

        await assertThrowsAppError(.storage) { try await sut.publish() }

        XCTAssertEqual(reloader.reloadCount, 0)
    }

    // MARK: - Decorator

    func test_save_delegatesToTheBase_thenPublishes() async throws {
        let base = RepositoryFake()
        let (sut, store, reloader) = makeDecorator(base)
        let reminder = makeReminder(id: 5, name: "Aspirin")

        try await sut.save(reminder)

        let stored = await base.stored
        let saved = await store.saved
        XCTAssertEqual(stored, [reminder])
        XCTAssertEqual(saved, [ReminderSnapshot(slots: [ReminderSlot(reminder)])])
        XCTAssertEqual(reloader.reloadCount, 1)
    }

    func test_delete_delegatesToTheBase_thenPublishesWithoutTheDeletedReminder() async throws {
        let removed = makeReminder(id: 1)
        let kept = makeReminder(id: 2, hour: 20)
        let base = RepositoryFake([removed, kept])
        let (sut, store, _) = makeDecorator(base)

        try await sut.delete(id: removed.id)

        let saved = await store.saved
        XCTAssertEqual(saved, [ReminderSnapshot(slots: [ReminderSlot(kept)])])
    }

    func test_reminders_passesThroughWithoutPublishing() async throws {
        let reminder = makeReminder()
        let (sut, store, reloader) = makeDecorator(RepositoryFake([reminder]))

        let loaded = try await sut.reminders()

        let saved = await store.saved
        XCTAssertEqual(loaded, [reminder])
        XCTAssertTrue(saved.isEmpty)
        XCTAssertEqual(reloader.reloadCount, 0)
    }

    func test_save_propagatesTheBaseFailure_andDoesNotPublish() async {
        let base = RepositoryFake(writeFailure: AppError.storage)
        let (sut, store, reloader) = makeDecorator(base)

        await assertThrowsAppError(.storage) { try await sut.save(makeReminder()) }

        let saved = await store.saved
        XCTAssertTrue(saved.isEmpty)
        XCTAssertEqual(reloader.reloadCount, 0)
    }

    func test_save_succeeds_whenPublishingFails() async throws {
        let base = RepositoryFake()
        let (sut, _, reloader) = makeDecorator(base, saveFailure: AppError.storage)

        try await sut.save(makeReminder())

        let stored = await base.stored
        XCTAssertEqual(stored.count, 1)
        XCTAssertEqual(reloader.reloadCount, 0)
    }

    // MARK: - Helpers

    private func makePublisher(
        _ repository: RepositoryFake,
        saveFailure: Error? = nil,
        log: EventLog? = nil
    ) -> (ReminderSnapshotPublisher, SnapshotStoreFake, ReloaderFake) {
        let store = SnapshotStoreFake(saveFailure: saveFailure, log: log)
        let reloader = ReloaderFake(log: log)
        return (ReminderSnapshotPublisher(repository: repository, store: store, reloader: reloader), store, reloader)
    }

    private func makeDecorator(
        _ base: RepositoryFake,
        saveFailure: Error? = nil
    ) -> (SnapshotPublishingRepository, SnapshotStoreFake, ReloaderFake) {
        let (publisher, store, reloader) = makePublisher(base, saveFailure: saveFailure)
        return (SnapshotPublishingRepository(base: base, publisher: publisher), store, reloader)
    }

    private func assertThrowsAppError(
        _ expected: AppError,
        file: StaticString = #filePath,
        line: UInt = #line,
        _ operation: () async throws -> Void
    ) async {
        do {
            try await operation()
            XCTFail("Expected \(expected) but operation succeeded", file: file, line: line)
        } catch {
            XCTAssertEqual(error as? AppError, expected, file: file, line: line)
        }
    }
}
