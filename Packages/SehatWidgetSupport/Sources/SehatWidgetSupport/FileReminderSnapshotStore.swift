//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import SehatCore

/// Snapshot stored as one JSON file. Writes are atomic, so a reader sees the
/// old or the new file, never half of one. The methods are synchronous so a
/// widget can call them directly; they also satisfy the async protocol.
///
/// Contract: throws `AppError` only. No file protection class is set, so the
/// system default applies.
public struct FileReminderSnapshotStore: ReminderSnapshotStoring {
    public static let defaultFileName = "reminders-snapshot.json"

    private let directory: URL
    private let fileURL: URL

    public init(directory: URL, fileName: String = FileReminderSnapshotStore.defaultFileName) {
        self.directory = directory
        self.fileURL = directory.appendingPathComponent(fileName)
    }

    public func save(_ snapshot: ReminderSnapshot) throws {
        do {
            let data = try snapshot.encoded()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            throw AppError.storage
        }
    }

    public func load() throws -> ReminderSnapshot? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }

        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch {
            throw AppError.storage
        }
        return try ReminderSnapshot.decode(data)
    }
}
