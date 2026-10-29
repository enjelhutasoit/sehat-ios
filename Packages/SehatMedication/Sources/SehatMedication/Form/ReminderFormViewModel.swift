//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import Observation
import SehatCore
import SehatDomain

@MainActor
@Observable
final class ReminderFormViewModel {
    enum Failure: Equatable {
        case validation(ReminderError)
        case system(AppError)
    }

    enum Phase: Equatable {
        case editing
        case submitting
        case failed(Failure)
    }

    var medicationName = ""
    var dosage = ""
    var time: Date
    private(set) var phase: Phase = .editing

    /// Chosen once per form: submitting again after a failure updates the
    /// same reminder instead of creating a second one.
    private let reminderID: UUID
    private let calendar: Calendar
    private let addReminder: AddMedicationReminderUseCase
    private let onSaved: @MainActor (MedicationReminder) -> Void

    init(
        reminderID: UUID = UUID(),
        time: Date,
        calendar: Calendar = .current,
        addReminder: AddMedicationReminderUseCase,
        onSaved: @escaping @MainActor (MedicationReminder) -> Void
    ) {
        self.reminderID = reminderID
        self.time = time
        self.calendar = calendar
        self.addReminder = addReminder
        self.onSaved = onSaved
    }

    /// Saves the reminder. A call made while another is running is ignored.
    func submit() async {
        guard phase != .submitting else { return }
        phase = .submitting

        do {
            let reminder = try await addReminder.execute(
                ReminderRequest(
                    id: reminderID,
                    medicationName: medicationName,
                    dosage: dosage,
                    timeOfDay: TimeOfDay(date: time, calendar: calendar)
                )
            )
            phase = .editing
            onSaved(reminder)
        } catch let error as ReminderError {
            phase = .failed(.validation(error))
        } catch {
            let appError = DefaultErrorMapper().map(error)
            phase = appError == .cancelled ? .editing : .failed(.system(appError))
        }
    }
}
