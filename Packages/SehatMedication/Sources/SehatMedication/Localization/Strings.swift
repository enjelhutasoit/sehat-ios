//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

/// UI text of the medication feature, looked up in this package's string
/// catalog. Properties are computed so the language is read at display time.
enum Strings {
    static var medication: String { String(localized: "Medication", bundle: .module) }
    static var addReminder: String { String(localized: "Add reminder", bundle: .module) }
    static var couldntUpdateReminder: String {
        String(localized: "Couldn't update the reminder", bundle: .module)
    }
    static var ok: String { String(localized: "OK", bundle: .module) }
    static var tryAgain: String { String(localized: "Try again", bundle: .module) }
    static var couldntLoadReminders: String {
        String(localized: "Couldn't load reminders", bundle: .module)
    }
    static var notificationsAreOff: String {
        String(localized: "Notifications are off. Turn them on in Settings to receive reminders.", bundle: .module)
    }
    static var delete: String { String(localized: "Delete", bundle: .module) }
    static var noRemindersYet: String {
        String(localized: "No reminders yet. Add one with the plus button.", bundle: .module)
    }
    static var loading: String { String(localized: "Loading", bundle: .module) }
    static var turnsReminderOnOrOff: String {
        String(localized: "Turns the reminder on or off.", bundle: .module)
    }

    static var name: String { String(localized: "Name", bundle: .module) }
    static var dosagePlaceholder: String {
        String(localized: "Dosage (for example, 1 tablet)", bundle: .module)
    }
    static var time: String { String(localized: "Time", bundle: .module) }
    static var everyDayAt: String { String(localized: "Every day at", bundle: .module) }
    static var newReminder: String { String(localized: "New reminder", bundle: .module) }
    static var cancel: String { String(localized: "Cancel", bundle: .module) }
    static var save: String { String(localized: "Save", bundle: .module) }
    static var notificationPrivacyNote: String {
        String(localized: "The notification shows a general message and never the medication name.", bundle: .module)
    }

    static var enterMedicationName: String {
        String(localized: "Enter the medication name.", bundle: .module)
    }
    static var enterDosage: String { String(localized: "Enter the dosage.", bundle: .module) }
    static var reminderNoLongerExists: String {
        String(localized: "This reminder no longer exists.", bundle: .module)
    }
    static var couldntSaveOrSchedule: String {
        String(localized: "We couldn't save or schedule this reminder. Try again.", bundle: .module)
    }
}
