//
// Copyright (c) 2026 Enjel Hutasoit
//

import SehatCore
import SehatWidgetSupport
import XCTest

final class FileReminderSnapshotStoreTests: XCTestCase {

    func test_load_returnsNil_whenNothingWasSaved() throws {
        let sut = makeSUT()

        XCTAssertNil(try sut.load())
    }

    func test_save_thenLoad_roundTripsTheSnapshot() throws {
        let sut = makeSUT()
        let snapshot = ReminderSnapshot(slots: [makeSlot(id: 1), makeSlot(id: 2, name: "B", hour: 20)])

        try sut.save(snapshot)

        XCTAssertEqual(try sut.load(), snapshot)
    }

    func test_save_createsMissingDirectories() throws {
        let nested = makeDirectory().appendingPathComponent("a/b", isDirectory: true)
        let sut = FileReminderSnapshotStore(directory: nested)

        try sut.save(ReminderSnapshot(slots: []))

        XCTAssertEqual(try sut.load(), ReminderSnapshot(slots: []))
    }

    func test_save_replacesThePreviousSnapshot() throws {
        let sut = makeSUT()
        try sut.save(ReminderSnapshot(slots: [makeSlot(id: 1)]))

        let replacement = ReminderSnapshot(slots: [makeSlot(id: 2)])
        try sut.save(replacement)

        XCTAssertEqual(try sut.load(), replacement)
    }

    func test_load_throwsDecoding_whenTheFileIsCorrupt() throws {
        let directory = makeDirectory()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data("corrupt".utf8).write(
            to: directory.appendingPathComponent(FileReminderSnapshotStore.defaultFileName)
        )
        let sut = FileReminderSnapshotStore(directory: directory)

        XCTAssertThrowsError(try sut.load()) { error in
            XCTAssertEqual(error as? AppError, .decoding)
        }
    }

    func test_save_throwsStorage_whenTheDirectoryPathIsAFile() throws {
        let path = makeDirectory()
        XCTAssertTrue(FileManager.default.createFile(atPath: path.path, contents: Data()))
        let sut = FileReminderSnapshotStore(directory: path)

        XCTAssertThrowsError(try sut.save(ReminderSnapshot(slots: []))) { error in
            XCTAssertEqual(error as? AppError, .storage)
        }
    }

    // MARK: - Helpers

    private func makeSUT() -> FileReminderSnapshotStore {
        FileReminderSnapshotStore(directory: makeDirectory())
    }

    private func makeDirectory() -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("sehat-snapshot-\(UUID().uuidString)", isDirectory: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        return url
    }
}
