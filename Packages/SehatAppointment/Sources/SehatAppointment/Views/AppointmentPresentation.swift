//
// Copyright (c) 2026 Enjel Hutasoit
//

import SehatCore
import SehatDomain
import SwiftUI

extension Appointment.Status {
    var title: String {
        switch self {
        case .pending: return Strings.pending
        case .confirmed: return Strings.confirmed
        }
    }

    var symbolName: String {
        switch self {
        case .pending: return "clock"
        case .confirmed: return "checkmark.circle"
        }
    }
}

extension BookingViewModel.Failure {
    var message: String {
        switch self {
        case .validation(let error):
            switch error {
            case .missingDoctorName: return Strings.enterDoctorName
            case .missingSpecialty: return Strings.enterSpecialty
            case .startsInThePast: return Strings.pickFutureTime
            case .slotAlreadyBooked: return Strings.slotAlreadyBooked
            }
        case .system(let error):
            // Only storage failures are expected here; the rest share one message.
            return error == .storage ? Strings.couldntSaveAppointment : Strings.somethingWentWrongTryAgain
        }
    }
}
