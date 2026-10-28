//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import SwiftData

extension ModelContext {
    /// Adds `entry` at the end of the outbox queue without saving, so the
    /// caller can save it together with other changes in one transaction.
    /// An entry whose id is already queued is ignored.
    func appendToOutbox(_ entry: OutboxEntry) throws {
        let targetID = entry.id
        var existing = FetchDescriptor<OutboxRecord>(
            predicate: #Predicate<OutboxRecord> { $0.id == targetID }
        )
        existing.fetchLimit = 1
        guard try fetch(existing).isEmpty else { return }

        var latest = FetchDescriptor<OutboxRecord>(
            sortBy: [SortDescriptor(\OutboxRecord.sequence, order: .reverse)]
        )
        latest.fetchLimit = 1
        let nextSequence = (try fetch(latest).first?.sequence ?? 0) + 1

        insert(OutboxRecord(entry, sequence: nextSequence))
    }
}
