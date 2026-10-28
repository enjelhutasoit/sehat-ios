//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

extension OutboxRecord {
    convenience init(_ entry: OutboxEntry, sequence: Int) {
        self.init(
            id: entry.id,
            sequence: sequence,
            entityID: entry.entityID,
            kind: entry.kind,
            payload: entry.payload
        )
    }

    func toEntry() -> OutboxEntry {
        OutboxEntry(id: id, entityID: entityID, kind: kind, payload: payload)
    }
}
