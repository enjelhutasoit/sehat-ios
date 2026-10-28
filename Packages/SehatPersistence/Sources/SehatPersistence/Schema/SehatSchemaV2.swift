//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import SwiftData

/// Schema 2.0.0: adds `serverVersion` to consultations.
enum SehatSchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(2, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [ConsultationRecord.self, OutboxRecord.self]
    }

    /// Storage model. Internal on purpose: it never leaves this package.
    /// Enums are stored as strings so on-disk values do not depend on Swift case names.
    @Model
    final class ConsultationRecord {
        @Attribute(.unique) var id: UUID
        var doctorName: String
        var specialty: String
        var channelRaw: String
        var statusRaw: String
        var scheduledAt: Date
        /// Server-side revision of this record. 0 means unknown.
        /// Not read or written yet; prepared for a version-based conflict policy.
        var serverVersion: Int = 0

        init(
            id: UUID,
            doctorName: String,
            specialty: String,
            channelRaw: String,
            statusRaw: String,
            scheduledAt: Date,
            serverVersion: Int = 0
        ) {
            self.id = id
            self.doctorName = doctorName
            self.specialty = specialty
            self.channelRaw = channelRaw
            self.statusRaw = statusRaw
            self.scheduledAt = scheduledAt
            self.serverVersion = serverVersion
        }
    }

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
}
