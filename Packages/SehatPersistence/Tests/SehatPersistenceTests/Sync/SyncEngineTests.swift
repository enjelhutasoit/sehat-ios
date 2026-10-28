//
// Copyright (c) 2026 Enjel Hutasoit
//

import SehatCore
import SehatDomain
import SehatPersistence
import XCTest

final class SyncEngineTests: XCTestCase {

    // MARK: - pushPending

    func test_pushPending_returnsEmptyReport_whenQueueIsEmpty() async throws {
        let harness = makeHarness()

        let report = try await harness.sut.pushPending()

        XCTAssertEqual(report, PushReport(sentEntryIDs: [], rejections: [], stoppedBy: nil))
    }

    func test_pushPending_sendsEntriesInOrder_andRemovesThem() async throws {
        let entries = [makeEntry(id: 1), makeEntry(id: 2), makeEntry(id: 3)]
        let harness = makeHarness(queue: entries)

        let report = try await harness.sut.pushPending()

        XCTAssertEqual(report.sentEntryIDs, entries.map(\.id))
        XCTAssertNil(report.stoppedBy)
        let attempted = await harness.sender.attemptedIDs
        let remaining = await harness.outbox.entries
        XCTAssertEqual(attempted, entries.map(\.id))
        XCTAssertTrue(remaining.isEmpty)
    }

    func test_pushPending_stopsAtRetryableFailure_andKeepsRemainingEntriesQueued() async throws {
        let entries = [makeEntry(id: 1), makeEntry(id: 2), makeEntry(id: 3)]
        let harness = makeHarness(queue: entries, senderFailures: [entries[1].id: AppError.offline])

        let report = try await harness.sut.pushPending()

        XCTAssertEqual(report.sentEntryIDs, [entries[0].id])
        XCTAssertEqual(report.stoppedBy, .offline)
        let attempted = await harness.sender.attemptedIDs
        let remaining = await harness.outbox.entries
        XCTAssertEqual(attempted, [entries[0].id, entries[1].id])
        XCTAssertEqual(remaining, [entries[1], entries[2]])
    }

    func test_pushPending_stopsOnUnauthorized() async throws {
        let entries = [makeEntry(id: 1), makeEntry(id: 2)]
        let harness = makeHarness(queue: entries, senderFailures: [entries[0].id: AppError.unauthorized])

        let report = try await harness.sut.pushPending()

        XCTAssertEqual(report.stoppedBy, .unauthorized)
        XCTAssertTrue(report.sentEntryIDs.isEmpty)
        let remaining = await harness.outbox.entries
        XCTAssertEqual(remaining, entries)
    }

    func test_pushPending_mapsRawSenderErrors() async throws {
        let entry = makeEntry(id: 1)
        let harness = makeHarness(queue: [entry], senderFailures: [entry.id: URLError(.timedOut)])

        let report = try await harness.sut.pushPending()

        XCTAssertEqual(report.stoppedBy, .timedOut)
    }

    func test_pushPending_rejectsPermanentFailure_removesEntry_andContinues() async throws {
        let rejected = makeEntry(id: 1)
        let accepted = makeEntry(id: 2)
        let harness = makeHarness(
            queue: [rejected, accepted],
            senderFailures: [rejected.id: AppError.server(statusCode: 400)]
        )

        let report = try await harness.sut.pushPending()

        XCTAssertEqual(
            report.rejections,
            [PushReport.Rejection(entry: rejected, error: .server(statusCode: 400))]
        )
        XCTAssertEqual(report.sentEntryIDs, [accepted.id])
        XCTAssertNil(report.stoppedBy)
        let remaining = await harness.outbox.entries
        XCTAssertTrue(remaining.isEmpty)
    }

    func test_pushPending_throwsCancelled_andKeepsEntryQueued() async {
        let entry = makeEntry(id: 1)
        let harness = makeHarness(queue: [entry], senderFailures: [entry.id: CancellationError()])

        await assertThrowsAppError(.cancelled) { _ = try await harness.sut.pushPending() }

        let remaining = await harness.outbox.entries
        XCTAssertEqual(remaining, [entry])
    }

    func test_pushPending_propagatesOutboxError_withoutSending() async {
        let harness = makeHarness(queue: [makeEntry(id: 1)], outboxFailure: .storage)

        await assertThrowsAppError(.storage) { _ = try await harness.sut.pushPending() }

        let attempted = await harness.sender.attemptedIDs
        XCTAssertTrue(attempted.isEmpty)
    }

    // MARK: - pull

    func test_pull_upsertsRemoteConsultations() async throws {
        let remote = [makeConsultation(id: 1), makeConsultation(id: 2)]
        let harness = makeHarness(remote: .success(remote))

        let count = try await harness.sut.pull()

        XCTAssertEqual(count, 2)
        let upserts = await harness.local.upserts
        XCTAssertEqual(upserts, [remote])
    }

    func test_pull_skipsConsultationsThatHavePendingEntries() async throws {
        let protected = makeConsultation(id: 1)
        let other = makeConsultation(id: 2)
        let harness = makeHarness(
            queue: [makeEntry(id: 11, entityID: 1)],
            remote: .success([protected, other])
        )

        let count = try await harness.sut.pull()

        XCTAssertEqual(count, 1)
        let upserts = await harness.local.upserts
        XCTAssertEqual(upserts, [[other]])
    }

    func test_pull_appliesInjectedConflictPolicy() async throws {
        let first = makeConsultation(id: 1)
        let harness = makeHarness(
            remote: .success([first, makeConsultation(id: 2)]),
            conflictPolicy: FirstOnlyPolicy()
        )

        let count = try await harness.sut.pull()

        XCTAssertEqual(count, 1)
        let upserts = await harness.local.upserts
        XCTAssertEqual(upserts, [[first]])
    }

    func test_pull_throwsMappedError_whenRemoteFails_andDoesNotWrite() async {
        let harness = makeHarness(remote: .failure(URLError(.notConnectedToInternet)))

        await assertThrowsAppError(.offline) { _ = try await harness.sut.pull() }

        let upserts = await harness.local.upserts
        XCTAssertTrue(upserts.isEmpty)
    }

    func test_pull_propagatesLocalStoreError() async {
        let harness = makeHarness(remote: .success([makeConsultation(id: 1)]), localFailure: AppError.storage)

        await assertThrowsAppError(.storage) { _ = try await harness.sut.pull() }
    }

    // MARK: - sync

    func test_sync_pushesThenPulls() async throws {
        let entry = makeEntry(id: 1)
        let remote = [makeConsultation(id: 1)]
        let harness = makeHarness(queue: [entry], remote: .success(remote))

        let report = try await harness.sut.sync()

        XCTAssertEqual(report.push.sentEntryIDs, [entry.id])
        XCTAssertEqual(report.pulledCount, 1)
        let upserts = await harness.local.upserts
        XCTAssertEqual(upserts, [remote])
    }

    func test_sync_skipsPull_whenPushStoppedEarly() async throws {
        let entry = makeEntry(id: 1)
        let harness = makeHarness(
            queue: [entry],
            senderFailures: [entry.id: AppError.offline],
            remote: .success([makeConsultation(id: 1)])
        )

        let report = try await harness.sut.sync()

        XCTAssertEqual(report.push.stoppedBy, .offline)
        XCTAssertNil(report.pulledCount)
        let upserts = await harness.local.upserts
        XCTAssertTrue(upserts.isEmpty)
    }

    func test_sync_propagatesPullError() async {
        let harness = makeHarness(remote: .failure(AppError.timedOut))

        await assertThrowsAppError(.timedOut) { _ = try await harness.sut.sync() }
    }

    // MARK: - Helpers

    private struct Harness {
        let sut: SyncEngine
        let outbox: OutboxFake
        let sender: SenderStub
        let local: LocalSpy
    }

    private func makeHarness(
        queue: [OutboxEntry] = [],
        senderFailures: [UUID: Error] = [:],
        remote: Result<[Consultation], Error> = .success([]),
        outboxFailure: AppError? = nil,
        localFailure: Error? = nil,
        conflictPolicy: any ConflictPolicy = LocalPendingWinsPolicy()
    ) -> Harness {
        let outbox = OutboxFake(entries: queue, failure: outboxFailure)
        let sender = SenderStub(failures: senderFailures)
        let local = LocalSpy(failure: localFailure)
        let sut = SyncEngine(
            outbox: outbox,
            sender: sender,
            remote: RemoteStub(result: remote),
            local: local,
            conflictPolicy: conflictPolicy
        )
        return Harness(sut: sut, outbox: outbox, sender: sender, local: local)
    }
}
