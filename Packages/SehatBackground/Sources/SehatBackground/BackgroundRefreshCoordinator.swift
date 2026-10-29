//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

/// Rules for background refresh, free of system types so they can be tested.
///
/// - Every run schedules the next one first, because a refresh request is
///   single-use.
/// - A scheduling failure never stops the work.
/// - Expiration cancels the work. The task is completed exactly once, with
///   `success == true` only when the work finished without throwing.
public struct BackgroundRefreshCoordinator: Sendable {
    private let submitter: any BackgroundRefreshSubmitting
    private let work: any BackgroundWork
    private let minimumInterval: TimeInterval
    private let now: @Sendable () -> Date

    /// - Parameter minimumInterval: seconds before the system may run the next
    ///   refresh. It is a lower bound; the system decides the actual time.
    ///   Negative or non-finite values become 0.
    public init(
        submitter: any BackgroundRefreshSubmitting,
        work: any BackgroundWork,
        minimumInterval: TimeInterval = 3_600,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.submitter = submitter
        self.work = work
        self.minimumInterval = minimumInterval.isFinite ? max(0, minimumInterval) : 0
        self.now = now
    }

    public func scheduleNextRefresh() throws {
        try submitter.submitRefreshRequest(
            earliestBeginDate: now().addingTimeInterval(minimumInterval)
        )
    }

    /// Runs one refresh for `task`. The expiration handler is installed before
    /// this method returns. The returned task finishes after the task was
    /// completed; the system adapter may ignore it, tests await it.
    @discardableResult
    public func handleRefresh(_ task: some BackgroundTaskHandle) -> Task<Void, Never> {
        _ = try? scheduleNextRefresh()

        let work = self.work
        let workTask = Task { try await work.perform() }
        task.setExpirationHandler { workTask.cancel() }

        return Task {
            let succeeded: Bool
            do {
                try await workTask.value
                succeeded = true
            } catch {
                succeeded = false
            }
            task.setTaskCompleted(success: succeeded)
        }
    }
}
