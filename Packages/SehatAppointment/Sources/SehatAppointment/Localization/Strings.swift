//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

/// UI text of the appointment feature, looked up in this package's string
/// catalog. Properties are computed so the language is read at display time.
enum Strings {
    static var appointments: String { String(localized: "Appointments", bundle: .module) }
    static var bookAppointment: String { String(localized: "Book appointment", bundle: .module) }
    static var couldntLoadAppointments: String {
        String(localized: "Couldn't load appointments", bundle: .module)
    }
    static var tryAgain: String { String(localized: "Try again", bundle: .module) }
    static var noAppointments: String { String(localized: "No appointments", bundle: .module) }
    static var noAppointmentsDescription: String {
        String(localized: "Book one with the plus button.", bundle: .module)
    }
    static var loading: String { String(localized: "Loading", bundle: .module) }

    static var doctor: String { String(localized: "Doctor", bundle: .module) }
    static var doctorName: String { String(localized: "Doctor name", bundle: .module) }
    static var specialty: String { String(localized: "Specialty", bundle: .module) }
    static var when: String { String(localized: "When", bundle: .module) }
    static var startsAt: String { String(localized: "Starts at", bundle: .module) }
    static var cancel: String { String(localized: "Cancel", bundle: .module) }
    static var book: String { String(localized: "Book", bundle: .module) }

    static var pending: String { String(localized: "Pending", bundle: .module) }
    static var confirmed: String { String(localized: "Confirmed", bundle: .module) }

    static var enterDoctorName: String { String(localized: "Enter the doctor's name.", bundle: .module) }
    static var enterSpecialty: String { String(localized: "Enter the specialty.", bundle: .module) }
    static var pickFutureTime: String { String(localized: "Pick a time in the future.", bundle: .module) }
    static var slotAlreadyBooked: String {
        String(localized: "You already have an appointment at this time.", bundle: .module)
    }
    static var couldntSaveAppointment: String {
        String(localized: "We couldn't save this appointment on your device.", bundle: .module)
    }
    static var somethingWentWrongTryAgain: String {
        String(localized: "Something went wrong. Try again.", bundle: .module)
    }
}
