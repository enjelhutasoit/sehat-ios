//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

/// A doctor appointment booked by the patient. Pure domain entity.
public struct Appointment: Sendable, Hashable, Identifiable {
    public typealias ID = UUID

    public enum Status: Sendable, Hashable {
        /// Stored locally, not yet confirmed by the server.
        case pending
        case confirmed
    }

    public let id: ID
    public let doctorName: String
    public let specialty: String
    public let startsAt: Date
    public let status: Status

    public init(id: ID, doctorName: String, specialty: String, startsAt: Date, status: Status) {
        self.id = id
        self.doctorName = doctorName
        self.specialty = specialty
        self.startsAt = startsAt
        self.status = status
    }
}
