//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import SehatDomain

extension TimeOfDay {
    /// Follows the device language and region. A thin wrapper over the system
    /// formatter, so it has no test of its own.
    var displayText: String {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        guard let date = Calendar.current.date(from: components) else {
            return String(format: "%02d:%02d", hour, minute)
        }
        return date.formatted(date: .omitted, time: .shortened)
    }
}

extension ReminderFormViewModel.Failure {
    var message: String {
        switch self {
        case .validation(let error):
            switch error {
            case .missingMedicationName: return Strings.enterMedicationName
            case .missingDosage: return Strings.enterDosage
            case .notFound: return Strings.reminderNoLongerExists
            }
        case .system:
            return Strings.couldntSaveOrSchedule
        }
    }
}
