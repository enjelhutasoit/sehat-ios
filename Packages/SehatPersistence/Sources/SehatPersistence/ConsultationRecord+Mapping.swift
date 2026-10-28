//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import SehatCore
import SehatDomain

extension ConsultationRecord {
    convenience init(_ consultation: Consultation) {
        self.init(
            id: consultation.id,
            doctorName: consultation.doctorName,
            specialty: consultation.specialty,
            channelRaw: consultation.channel.storageValue,
            statusRaw: consultation.status.storageValue,
            scheduledAt: consultation.scheduledAt
        )
    }

    func update(from consultation: Consultation) {
        doctorName = consultation.doctorName
        specialty = consultation.specialty
        channelRaw = consultation.channel.storageValue
        statusRaw = consultation.status.storageValue
        scheduledAt = consultation.scheduledAt
    }

    /// - Throws: `AppError.storage` when the stored values are not recognized.
    func toDomain() throws -> Consultation {
        guard let channel = Consultation.Channel(storageValue: channelRaw),
              let status = Consultation.Status(storageValue: statusRaw)
        else {
            throw AppError.storage
        }
        return Consultation(
            id: id,
            doctorName: doctorName,
            specialty: specialty,
            channel: channel,
            status: status,
            scheduledAt: scheduledAt
        )
    }
}

private extension Consultation.Channel {
    var storageValue: String {
        switch self {
        case .chat: return "chat"
        case .video: return "video"
        case .voice: return "voice"
        }
    }

    init?(storageValue: String) {
        switch storageValue {
        case "chat": self = .chat
        case "video": self = .video
        case "voice": self = .voice
        default: return nil
        }
    }
}

private extension Consultation.Status {
    var storageValue: String {
        switch self {
        case .scheduled: return "scheduled"
        case .inProgress: return "in_progress"
        case .completed: return "completed"
        case .cancelled: return "cancelled"
        }
    }

    init?(storageValue: String) {
        switch storageValue {
        case "scheduled": self = .scheduled
        case "in_progress": self = .inProgress
        case "completed": self = .completed
        case "cancelled": self = .cancelled
        default: return nil
        }
    }
}
