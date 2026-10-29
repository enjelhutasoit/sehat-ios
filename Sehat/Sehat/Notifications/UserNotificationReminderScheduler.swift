//
// Copyright (c) 2026 Enjel Hutasoit
//

@preconcurrency import UserNotifications
import SehatCore
import SehatDomain

/// `ReminderScheduler` backed by local notifications.
///
/// Thin on purpose and not unit-tested: `UNUserNotificationCenter.current()`
/// cannot be used from a package test process. It is verified manually (see
/// PR11). The text is generic so no medication name reaches the lock screen.
struct UserNotificationReminderScheduler: ReminderScheduler {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func authorizationStatus() async -> ReminderAuthorization {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined: return .notDetermined
        case .denied: return .denied
        case .authorized, .provisional, .ephemeral: return .authorized
        @unknown default: return .denied
        }
    }

    func requestAuthorization() async throws -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound])
        } catch {
            throw AppError.unknown
        }
    }

    func schedule(_ reminder: MedicationReminder) async throws {
        var time = DateComponents()
        time.hour = reminder.timeOfDay.hour
        time.minute = reminder.timeOfDay.minute

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Medication reminder")
        content.body = String(localized: "It's time to take your medication.")
        content.sound = .default

        let identifier = reminder.id.uuidString
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
        )

        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        do {
            try await center.add(request)
        } catch {
            throw AppError.unknown
        }
    }

    func cancel(reminderIDs: [MedicationReminder.ID]) async {
        center.removePendingNotificationRequests(withIdentifiers: reminderIDs.map(\.uuidString))
    }

    func scheduledReminderIDs() async -> Set<MedicationReminder.ID> {
        let pending = await center.pendingNotificationRequests()
        return Set(pending.compactMap { UUID(uuidString: $0.identifier) })
    }
}
