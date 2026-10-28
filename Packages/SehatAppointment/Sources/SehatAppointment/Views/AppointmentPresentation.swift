//
// Copyright (c) 2026 Enjel Hutasoit
//

import SehatCore
import SehatDomain
import SwiftUI

// Temporary English literals. PR13 replaces them with string catalog lookups (id/en).

extension Appointment.Status {
    var titleKey: LocalizedStringKey {
        switch self {
        case .pending: return "Pending"
        case .confirmed: return "Confirmed"
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
    var messageKey: LocalizedStringKey {
        switch self {
        case .validation(let error):
            switch error {
            case .missingDoctorName: return "Enter the doctor's name."
            case .missingSpecialty: return "Enter the specialty."
            case .startsInThePast: return "Pick a time in the future."
            case .slotAlreadyBooked: return "You already have an appointment at this time."
            }
        case .system(let error):
            // Only storage failures are expected here; the rest share one message.
            return error == .storage
                ? "We couldn't save this appointment on your device."
                : "Something went wrong. Try again."
        }
    }
}
