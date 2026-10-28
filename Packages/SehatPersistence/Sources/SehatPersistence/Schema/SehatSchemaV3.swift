//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import SwiftData

import Foundation
import SwiftData

/// Schema 3.0.0: adds appointments. Consultation and outbox models are
/// unchanged copies of V2. Freeze this file when V4 is introduced.
enum SehatSchemaV3: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(3, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [ConsultationRecord.self, OutboxRecord.self, AppointmentRecord.self]
    }

    @Model
    final class ConsultationRecord {
        @Attribute(.unique) var id: UUID
        var doctorName: String
        var specialty: String
        var channelRaw: String
        var statusRaw: String
        var scheduledAt: Date
        /// Server-side revision of this record. 0 means unknown.
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

    @Model
    final class AppointmentRecord {
        @Attribute(.unique) var id: UUID
        var doctorName: String
        var specialty: String
        var startsAt: Date
        var statusRaw: String

        init(id: UUID, doctorName: String, specialty: String, startsAt: Date, statusRaw: String) {
            self.id = id
            self.doctorName = doctorName
            self.specialty = specialty
            self.startsAt = startsAt
            self.statusRaw = statusRaw
        }
    }
}
