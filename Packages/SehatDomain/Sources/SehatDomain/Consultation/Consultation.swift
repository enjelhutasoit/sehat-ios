//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

/// A doctor consultation. Pure domain entity: no persistence or network
/// annotations. The data layer maps its own models to this type.
public struct Consultation: Sendable, Hashable, Identifiable {
    public typealias ID = UUID

    public enum Channel: Sendable, Hashable {
        case chat
        case video
        case voice
    }

    public enum Status: Sendable, Hashable {
        case scheduled
        case inProgress
        case completed
        case cancelled

        /// `true` while the consultation is still ahead of or part of the
        /// patient's active schedule.
        public var isUpcoming: Bool {
            switch self {
            case .scheduled, .inProgress: return true
            case .completed, .cancelled: return false
            }
        }
    }

    public let id: ID
    public let doctorName: String
    public let specialty: String
    public let channel: Channel
    public let status: Status
    public let scheduledAt: Date

    public init(
        id: ID,
        doctorName: String,
        specialty: String,
        channel: Channel,
        status: Status,
        scheduledAt: Date
    ) {
        self.id = id
        self.doctorName = doctorName
        self.specialty = specialty
        self.channel = channel
        self.status = status
        self.scheduledAt = scheduledAt
    }
}
