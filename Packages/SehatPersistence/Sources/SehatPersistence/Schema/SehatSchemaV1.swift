//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import SwiftData

/// Schema 1.0.0. FROZEN: a snapshot of the models as first released.
/// Never edit this file; changes go into a new schema version.
enum SehatSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [ConsultationRecord.self, OutboxRecord.self]
    }

    @Model
    final class ConsultationRecord {
        @Attribute(.unique) var id: UUID
        var doctorName: String
        var specialty: String
        var channelRaw: String
        var statusRaw: String
        var scheduledAt: Date

        init(
            id: UUID,
            doctorName: String,
            specialty: String,
            channelRaw: String,
            statusRaw: String,
            scheduledAt: Date
        ) {
            self.id = id
            self.doctorName = doctorName
            self.specialty = specialty
            self.channelRaw = channelRaw
            self.statusRaw = statusRaw
            self.scheduledAt = scheduledAt
        }
    }

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
}
