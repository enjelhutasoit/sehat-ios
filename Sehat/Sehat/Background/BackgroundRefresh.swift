//
// Copyright (c) 2026 Enjel Hutasoit
//

@preconcurrency import BackgroundTasks
import Foundation
import SehatBackground

/// Connects `BGTaskScheduler` to the coordinator.
///
/// Thin platform glue, not unit-tested: Apple documents that the debug
/// triggers for background tasks work only on devices. Verified manually (PR12).
enum BackgroundRefresh {
    /// Must also be listed under "Permitted background task scheduler identifiers".
    static let identifier = "com.enjelhutasoit.Sehat.refresh"

    static let coordinator = BackgroundRefreshCoordinator(
        submitter: RefreshSubmitter(identifier: identifier),
        work: ReminderReconcileWork()
    )

    /// Must run before the app finishes launching: call it from `SehatApp.init`.
    static func register() {
        _ = BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: nil) { task in
            coordinator.handleRefresh(TaskHandle(task: task))
        }
    }

    /// Failure is ignored: there is no logging yet, and the next time the app
    /// goes to the background tries again.
    static func scheduleNextRefresh() {
        _ = try? coordinator.scheduleNextRefresh()
    }
}

private struct RefreshSubmitter: BackgroundRefreshSubmitting {
    let identifier: String

    func submitRefreshRequest(earliestBeginDate: Date) throws {
        let request = BGAppRefreshTaskRequest(identifier: identifier)
        request.earliestBeginDate = earliestBeginDate
        try BGTaskScheduler.shared.submit(request)
    }
}

/// `BGTask` is not `Sendable`. This wrapper only forwards two calls.
private struct TaskHandle: BackgroundTaskHandle, @unchecked Sendable {
    let task: BGTask

    func setExpirationHandler(_ handler: @escaping @Sendable () -> Void) {
        task.expirationHandler = handler
    }

    func setTaskCompleted(success: Bool) {
        task.setTaskCompleted(success: success)
    }
}
