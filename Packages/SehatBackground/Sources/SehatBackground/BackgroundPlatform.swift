//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

/// Asks the system for a future background refresh. In the app this wraps
/// `BGTaskScheduler`. Implementations may throw any error; the coordinator
/// treats a throw as "could not schedule".
public protocol BackgroundRefreshSubmitting: Sendable {
    func submitRefreshRequest(earliestBeginDate: Date) throws
}

/// The running background task as the system hands it over. In the app this
/// wraps `BGTask`.
public protocol BackgroundTaskHandle: Sendable {
    /// The handler runs when the system is about to end the task.
    func setExpirationHandler(_ handler: @escaping @Sendable () -> Void)
    /// Must be called exactly once when the work is over.
    func setTaskCompleted(success: Bool)
}
