//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

/// FIFO queue of pending writes.
///
/// Contract: implementations throw `AppError` only.
public protocol OutboxQueue: Sendable {
    /// Adds an entry at the end. Enqueuing an id that already exists is a no-op.
    func enqueue(_ entry: OutboxEntry) async throws
    /// All pending entries, oldest first.
    func pending() async throws -> [OutboxEntry]
    /// Removes an entry. Removing an unknown id is a no-op.
    func remove(id: UUID) async throws
}
