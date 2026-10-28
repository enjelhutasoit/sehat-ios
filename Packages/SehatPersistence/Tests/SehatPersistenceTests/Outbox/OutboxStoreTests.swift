//
// Copyright (c) 2026 Enjel Hutasoit
//

import XCTest
import SehatCore
import SehatPersistence

final class OutboxStoreTests: XCTestCase {

    func test_pending_returnsEmpty_whenNothingEnqueued() async throws {
        let sut = try makeSUT()

        let pending = try await sut.pending()

        XCTAssertTrue(pending.isEmpty)
    }

    func test_enqueue_thenPending_roundTripsEntry() async throws {
        let sut = try makeSUT()
        let entry = makeEntry(id: 1, entityID: 5, kind: "consultation.cancel", payload: "{\"reason\":\"x\"}")

        try await sut.enqueue(entry)
        let pending = try await sut.pending()

        XCTAssertEqual(pending, [entry])
    }

    func test_pending_returnsEntriesInEnqueueOrder() async throws {
        let sut = try makeSUT()
        let entries = [makeEntry(id: 3), makeEntry(id: 1), makeEntry(id: 2)]

        for entry in entries { try await sut.enqueue(entry) }
        let pending = try await sut.pending()

        XCTAssertEqual(pending.map(\.id), entries.map(\.id))
    }

    func test_enqueue_ignoresEntryWithExistingID() async throws {
        let sut = try makeSUT()
        let first = makeEntry(id: 1, payload: "first")
        let duplicate = makeEntry(id: 1, payload: "second")

        try await sut.enqueue(first)
        try await sut.enqueue(duplicate)
        let pending = try await sut.pending()

        XCTAssertEqual(pending, [first])
    }

    func test_remove_deletesOnlyMatchingEntry() async throws {
        let sut = try makeSUT()
        let keep = makeEntry(id: 2)
        try await sut.enqueue(makeEntry(id: 1))
        try await sut.enqueue(keep)

        try await sut.remove(id: makeUUID(1))
        let pending = try await sut.pending()

        XCTAssertEqual(pending, [keep])
    }

    func test_remove_isNoOp_forUnknownID() async throws {
        let sut = try makeSUT()
        let entry = makeEntry(id: 1)
        try await sut.enqueue(entry)

        try await sut.remove(id: makeUUID(99))
        let pending = try await sut.pending()

        XCTAssertEqual(pending, [entry])
    }

    func test_enqueue_afterRemoval_keepsFIFOOrder() async throws {
        let sut = try makeSUT()
        try await sut.enqueue(makeEntry(id: 1))
        try await sut.enqueue(makeEntry(id: 2))
        try await sut.remove(id: makeUUID(1))

        try await sut.enqueue(makeEntry(id: 3))
        let pending = try await sut.pending()

        XCTAssertEqual(pending.map(\.id), [makeUUID(2), makeUUID(3)])
    }

    // MARK: - Helpers

    private func makeSUT() throws -> OutboxStore {
        OutboxStore(modelContainer: try PersistenceStack.makeContainer(inMemory: true))
    }
}
