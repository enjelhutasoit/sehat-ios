//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import SehatCore

/// Keeps diagnostic payloads (JSON) as files in one directory, on the device.
///
/// File names are `<kind>-<epoch seconds>-<uuid>.json`. At most
/// `maxFilesPerKind` files are kept per kind; the oldest go first (equal
/// timestamps are ordered by id, so pruning is deterministic). Files that do
/// not match the naming scheme are ignored and never deleted.
///
/// Contract: throws `AppError` only (`.storage`, or `.notFound` for `read`).
public actor FileDiagnosticsArchive {
    private struct Entry {
        let record: DiagnosticRecord
        let url: URL
    }

    private let directory: URL
    private let maxFilesPerKind: Int
    private let now: @Sendable () -> Date
    private let makeID: @Sendable () -> UUID

    /// `maxFilesPerKind` is at least 1.
    public init(
        directory: URL,
        maxFilesPerKind: Int = 10,
        now: @escaping @Sendable () -> Date = { Date() },
        makeID: @escaping @Sendable () -> UUID = { UUID() }
    ) {
        self.directory = directory
        self.maxFilesPerKind = max(1, maxFilesPerKind)
        self.now = now
        self.makeID = makeID
    }

    public func save(_ payload: Data, kind: DiagnosticKind) throws {
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let name = Self.fileName(kind: kind, receivedAt: now(), id: makeID())
            try payload.write(to: directory.appendingPathComponent(name), options: .atomic)
            try prune(kind)
        } catch {
            throw AppError.storage
        }
    }

    /// All archived records, newest first.
    public func records() throws -> [DiagnosticRecord] {
        do {
            return try entries().reversed().map(\.record)
        } catch {
            throw AppError.storage
        }
    }

    public func read(_ record: DiagnosticRecord) throws -> Data {
        let url = directory.appendingPathComponent(record.id)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw AppError.notFound
        }
        do {
            return try Data(contentsOf: url)
        } catch {
            throw AppError.storage
        }
    }

    // MARK: - Private

    private func prune(_ kind: DiagnosticKind) throws {
        let ofKind = try entries().filter { $0.record.kind == kind }
        let excess = ofKind.count - maxFilesPerKind
        guard excess > 0 else { return }

        for entry in ofKind.prefix(excess) {
            try FileManager.default.removeItem(at: entry.url)
        }
    }

    /// Matching files, oldest first.
    private func entries() throws -> [Entry] {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: directory.path, isDirectory: &isDirectory),
              isDirectory.boolValue
        else { return [] }

        let urls = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        return urls
            .compactMap { url in
                Self.parseRecord(fileName: url.lastPathComponent).map { Entry(record: $0, url: url) }
            }
            .sorted { lhs, rhs in
                if lhs.record.receivedAt != rhs.record.receivedAt {
                    return lhs.record.receivedAt < rhs.record.receivedAt
                }
                return lhs.record.id < rhs.record.id
            }
    }

    private static func fileName(kind: DiagnosticKind, receivedAt: Date, id: UUID) -> String {
        let seconds = Int(max(0, receivedAt.timeIntervalSince1970.rounded(.down)))
        return "\(kind.rawValue)-\(seconds)-\(id.uuidString).json"
    }

    private static func parseRecord(fileName: String) -> DiagnosticRecord? {
        guard fileName.hasSuffix(".json") else { return nil }

        let stem = fileName.dropLast(".json".count)
        let parts = stem.split(separator: "-", maxSplits: 2, omittingEmptySubsequences: false)
        guard parts.count == 3,
              let kind = DiagnosticKind(rawValue: String(parts[0])),
              let seconds = Int(parts[1]),
              !parts[2].isEmpty
        else { return nil }

        return DiagnosticRecord(
            id: fileName,
            kind: kind,
            receivedAt: Date(timeIntervalSince1970: TimeInterval(seconds))
        )
    }
}
