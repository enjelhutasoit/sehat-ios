//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import SwiftData

/// Storage model for `OutboxEntry`. Internal on purpose.
/// `sequence` gives a strict FIFO order, independent of clock resolution.
@Model
final class OutboxRecord {
    @Attribute(.unique) var id: UUID
    var sequence: Int
    var entityID: UUID
    var kind: String
    var payload: Data

    init(id: UUID, sequence: Int, entityID: UUID, kind: String, payload: Data) {
        self.id = id
        self.sequence = sequence
        self.entityID = entityID
        self.kind = kind
        self.payload = payload
    }
}

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
