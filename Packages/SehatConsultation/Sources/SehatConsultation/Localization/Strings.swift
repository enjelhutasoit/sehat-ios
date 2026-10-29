//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import SehatCore

/// UI text of the consultation feature, looked up in this package's string
/// catalog. Properties are computed so the language is read at display time.
enum Strings {
    static var consultations: String { String(localized: "Consultations", bundle: .module) }
    static var consultation: String { String(localized: "Consultation", bundle: .module) }
    static var noConsultations: String { String(localized: "No consultations", bundle: .module) }
    static var noConsultationsDescription: String {
        String(localized: "Your consultations will appear here.", bundle: .module)
    }
    static var upcoming: String { String(localized: "Upcoming", bundle: .module) }
    static var history: String { String(localized: "History", bundle: .module) }

    static var doctor: String { String(localized: "Doctor", bundle: .module) }
    static var specialty: String { String(localized: "Specialty", bundle: .module) }
    static var channel: String { String(localized: "Channel", bundle: .module) }
    static var status: String { String(localized: "Status", bundle: .module) }
    static var date: String { String(localized: "Date", bundle: .module) }

    static var chat: String { String(localized: "Chat", bundle: .module) }
    static var videoCall: String { String(localized: "Video call", bundle: .module) }
    static var voiceCall: String { String(localized: "Voice call", bundle: .module) }

    static var scheduled: String { String(localized: "Scheduled", bundle: .module) }
    static var inProgress: String { String(localized: "In progress", bundle: .module) }
    static var completed: String { String(localized: "Completed", bundle: .module) }
    static var cancelled: String { String(localized: "Cancelled", bundle: .module) }

    static var somethingWentWrong: String { String(localized: "Something went wrong", bundle: .module) }
    static var tryAgain: String { String(localized: "Try again", bundle: .module) }
    static var loading: String { String(localized: "Loading", bundle: .module) }
    static var opensConsultationDetails: String {
        String(localized: "Opens consultation details", bundle: .module)
    }

    /// Message for an error, found by the key that `AppError` provides.
    /// A missing entry shows the key itself, which makes the gap visible.
    static func message(for error: AppError) -> String {
        Bundle.module.localizedString(forKey: error.localizationKey, value: nil, table: nil)
    }
}
