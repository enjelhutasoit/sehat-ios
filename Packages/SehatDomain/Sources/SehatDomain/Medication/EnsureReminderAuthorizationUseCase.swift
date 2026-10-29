//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

/// Asks for notification permission only while it is still undecided, so the
/// system prompt never appears twice and never for an already decided choice.
public struct EnsureReminderAuthorizationUseCase: Sendable {
    private let scheduler: any ReminderScheduler

    public init(scheduler: any ReminderScheduler) {
        self.scheduler = scheduler
    }

    public func execute() async -> ReminderAuthorization {
        let status = await scheduler.authorizationStatus()
        guard status == .notDetermined else { return status }

        do {
            return try await scheduler.requestAuthorization() ? .authorized : .denied
        } catch {
            return await scheduler.authorizationStatus()
        }
    }
}
