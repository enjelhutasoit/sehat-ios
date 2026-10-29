//
// Copyright (c) 2026 Enjel Hutasoit
//

import SehatCore
import SehatDiagnostics
import XCTest

final class FileDiagnosticsArchiveTests: XCTestCase {

    // MARK: - Saving and reading

    func test_records_returnsEmpty_whenDirectoryDoesNotExist() async throws {
        let sut = makeSUT()

        let records = try await sut.records()

        XCTAssertTrue(records.isEmpty)
    }

    func test_save_createsMissingDirectories_andStoresReadablePayload() async throws {
        let nested = makeDirectory().appendingPathComponent("a/b", isDirectory: true)
        let sut = makeSUT(directory: nested, clock: TestClock(1_000))
        let payload = Data(#"{"a":1}"#.utf8)

        try await sut.save(payload, kind: .metrics)
        let records = try await sut.records()

        let record = try XCTUnwrap(records.first)
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(record.kind, .metrics)
        XCTAssertEqual(record.receivedAt, Date(timeIntervalSince1970: 1_000))
        let stored = try await sut.read(record)
        XCTAssertEqual(stored, payload)
    }

    func test_save_truncatesTimestampToWholeSeconds() async throws {
        let sut = makeSUT(clock: TestClock(1_000.9))

        try await sut.save(Data("x".utf8), kind: .diagnostics)
        let records = try await sut.records()

        XCTAssertEqual(records.first?.receivedAt, Date(timeIntervalSince1970: 1_000))
    }

    func test_save_storesDatesBeforeTheEpochAsZero() async throws {
        let sut = makeSUT(clock: TestClock(-5))

        try await sut.save(Data("x".utf8), kind: .metrics)
        let records = try await sut.records()

        XCTAssertEqual(records.first?.receivedAt, Date(timeIntervalSince1970: 0))
    }

    func test_records_returnsNewestFirst_acrossKinds() async throws {
        let clock = TestClock()
        let sut = makeSUT(clock: clock)

        clock.set(100)
        try await sut.save(Data("a".utf8), kind: .metrics)
        clock.set(200)
        try await sut.save(Data("b".utf8), kind: .diagnostics)
        clock.set(300)
        try await sut.save(Data("c".utf8), kind: .metrics)
        let records = try await sut.records()

        XCTAssertEqual(records.map(\.receivedAt), [300, 200, 100].map { Date(timeIntervalSince1970: $0) })
        XCTAssertEqual(records.map(\.kind), [.metrics, .diagnostics, .metrics])
    }

    func test_read_throwsNotFound_whenFileWasRemoved() async throws {
        let directory = makeDirectory()
        let sut = makeSUT(directory: directory)
        try await sut.save(Data("x".utf8), kind: .metrics)
        let records = try await sut.records()
        let record = try XCTUnwrap(records.first)
        try FileManager.default.removeItem(at: directory.appendingPathComponent(record.id))

        await assertThrowsAppError(.notFound) { _ = try await sut.read(record) }
    }

    // MARK: - Retention

    func test_save_keepsOnlyTheNewestFilesPerKind() async throws {
        let clock = TestClock()
        let sut = makeSUT(max: 2, clock: clock)

        for (second, name) in [(1, "m1"), (2, "m2"), (3, "m3")] {
            clock.set(TimeInterval(second))
            try await sut.save(Data(name.utf8), kind: .metrics)
        }
        clock.set(4)
        try await sut.save(Data("d1".utf8), kind: .diagnostics)

        let records = try await sut.records()
        var payloads: [String] = []
        for record in records {
            payloads.append(String(decoding: try await sut.read(record), as: UTF8.self))
        }
        XCTAssertEqual(payloads, ["d1", "m3", "m2"])
    }

    func test_save_prunesDeterministically_whenTimestampsAreEqual() async throws {
        let sut = makeSUT(max: 1, clock: TestClock(50))

        try await sut.save(Data("first".utf8), kind: .metrics)
        try await sut.save(Data("second".utf8), kind: .metrics)

        let records = try await sut.records()
        let record = try XCTUnwrap(records.first)
        let remaining = try await sut.read(record)
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(String(decoding: remaining, as: UTF8.self), "second")
    }

    func test_init_keepsAtLeastOneFilePerKind() async throws {
        let clock = TestClock(1)
        let sut = makeSUT(max: 0, clock: clock)

        try await sut.save(Data("a".utf8), kind: .metrics)
        clock.set(2)
        try await sut.save(Data("b".utf8), kind: .metrics)
        let records = try await sut.records()

        XCTAssertEqual(records.count, 1)
    }

    // MARK: - Robustness

    func test_records_ignoresUnrelatedFiles() async throws {
        let directory = makeDirectory()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        for name in [".DS_Store", "notes.txt", "metrics-abc-xyz.json", "other-100-id.json", "metrics-100-.json"] {
            try Data().write(to: directory.appendingPathComponent(name))
        }
        let sut = makeSUT(directory: directory)

        let records = try await sut.records()

        XCTAssertTrue(records.isEmpty)
    }

    func test_save_throwsStorage_whenDirectoryPathIsAFile() async throws {
        let path = makeDirectory()
        XCTAssertTrue(FileManager.default.createFile(atPath: path.path, contents: Data()))
        let sut = makeSUT(directory: path)

        await assertThrowsAppError(.storage) { try await sut.save(Data("x".utf8), kind: .metrics) }
    }

    // MARK: - Helpers

    private func makeSUT(
        directory: URL? = nil,
        max: Int = 10,
        clock: TestClock = TestClock()
    ) -> FileDiagnosticsArchive {
        let ids = IDSource()
        return FileDiagnosticsArchive(
            directory: directory ?? makeDirectory(),
            maxFilesPerKind: max,
            now: { clock.date },
            makeID: { ids.next() }
        )
    }

    private func makeDirectory() -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("sehat-diagnostics-\(UUID().uuidString)", isDirectory: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        return url
    }
}
