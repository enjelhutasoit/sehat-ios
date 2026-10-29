//
// Copyright (c) 2026 Enjel Hutasoit
//

import SehatDomain
import SwiftUI

// Temporary English literals. PR13 replaces them with string catalog lookups
// (id/en) and a locale-aware time format.

extension TimeOfDay {
    var displayText: String {
        String(format: "%02d:%02d", hour, minute)
    }
}

extension ReminderFormViewModel.Failure {
    var messageKey: LocalizedStringKey {
        switch self {
        case .validation(let error):
            switch error {
            case .missingMedicationName: return "Enter the medication name."
            case .missingDosage: return "Enter the dosage."
            case .notFound: return "This reminder no longer exists."
            }
        case .system:
            return "We couldn't save or schedule this reminder. Try again."
        }
    }
}
