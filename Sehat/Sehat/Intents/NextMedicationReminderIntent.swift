//
// Copyright (c) 2026 Enjel Hutasoit
//

import AppIntents
import Foundation
import SehatDomain
import SehatPersistence
import SehatWidgetSupport

/// Tells the user when the next medication reminder is due. Only the time is
/// spoken, never the medication name. It runs in the app's process, so it does
/// not need the App Group. Thin glue over tested logic; verified manually.
struct NextMedicationReminderIntent: AppIntent {
    static let title: LocalizedStringResource = "Next medication reminder"
    static let description = IntentDescription("Tells you when your next medication reminder is due.")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = try await AppEnvironment.shared.container()
        let reminders = try await MedicationStore(modelContainer: container).reminders()
        let slots = reminders.filter(\.isEnabled).map { ReminderSlot($0) }

        guard let next = NextReminderPlanner.upcoming(slots, after: .now, calendar: .current).first else {
            return .result(dialog: "You have no medication reminders.")
        }

        let time = next.date.formatted(date: .omitted, time: .shortened)
        if Calendar.current.isDateInToday(next.date) {
            return .result(dialog: "Your next medication reminder is at \(time).")
        }
        return .result(dialog: "Your next medication reminder is tomorrow at \(time).")
    }
}
