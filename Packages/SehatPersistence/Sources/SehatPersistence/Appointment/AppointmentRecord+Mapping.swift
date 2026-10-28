//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import SehatCore
import SehatDomain

extension AppointmentRecord {
    convenience init(_ appointment: Appointment) {
        self.init(
            id: appointment.id,
            doctorName: appointment.doctorName,
            specialty: appointment.specialty,
            startsAt: appointment.startsAt,
            statusRaw: appointment.status.storageValue
        )
    }

    /// - Throws: `AppError.storage` when the stored status is not recognized.
    func toDomain() throws -> Appointment {
        guard let status = Appointment.Status(storageValue: statusRaw) else {
            throw AppError.storage
        }
        return Appointment(
            id: id,
            doctorName: doctorName,
            specialty: specialty,
            startsAt: startsAt,
            status: status
        )
    }
}

private extension Appointment.Status {
    var storageValue: String {
        switch self {
        case .pending: return "pending"
        case .confirmed: return "confirmed"
        }
    }

    init?(storageValue: String) {
        switch storageValue {
        case "pending": self = .pending
        case "confirmed": self = .confirmed
        default: return nil
        }
    }
}
