//
// Copyright (c) 2026 Enjel Hutasoit
//

import SehatDomain
import SehatPersistence
import XCTest

final class StoreRemovalTests: XCTestCase {

    func test_removeStoreFiles_emptiesTheStore() async throws {
        let url = try makeStoreURL()
        try await writeConsultation(at: url)

        try PersistenceStack.removeStoreFiles(at: url)
        let loaded = try await readConsultations(at: url)

        XCTAssertTrue(loaded.isEmpty)
    }

    func test_removeStoreFiles_deletesStoreAndSqliteSideFiles_butLeavesOtherFilesAlone() throws {
        let url = try makeStoreURL()
        let directory = url.deletingLastPathComponent()
        let sideFiles = ["-wal", "-shm"].map { URL(fileURLWithPath: url.path + $0) }
        let sibling = directory.appendingPathComponent("keep.txt")
        for file in [url, sibling] + sideFiles {
            try Data("x".utf8).write(to: file)
        }

        try PersistenceStack.removeStoreFiles(at: url)

        for file in [url] + sideFiles {
            XCTAssertFalse(FileManager.default.fileExists(atPath: file.path), file.lastPathComponent)
        }
        XCTAssertTrue(FileManager.default.fileExists(atPath: sibling.path))
    }

    func test_removeStoreFiles_ignoresAMissingStore() throws {
        let url = try makeStoreURL()

        XCTAssertNoThrow(try PersistenceStack.removeStoreFiles(at: url))
    }

    // MARK: - Helpers

    private func makeStoreURL() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("sehat-store-removal-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: directory) }
        return directory.appendingPathComponent("store.sqlite")
    }

    /// The container goes out of scope when this returns, so the store can be reopened.
    private func writeConsultation(at url: URL) async throws {
        let container = try PersistenceStack.makeContainer(storeURL: url)
        try await ConsultationStore(modelContainer: container).upsert([makeConsultation(id: 1)])
    }

    private func readConsultations(at url: URL) async throws -> [Consultation] {
        let container = try PersistenceStack.makeContainer(storeURL: url)
        return try await ConsultationStore(modelContainer: container).consultations()
    }
}
