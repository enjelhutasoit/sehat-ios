//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

/// Keeps the snapshot where the widget can read it.
///
/// Contract: implementations throw `AppError` only.
public protocol ReminderSnapshotStoring: Sendable {
    func save(_ snapshot: ReminderSnapshot) async throws
    /// `nil` when no snapshot was saved yet.
    func load() async throws -> ReminderSnapshot?
}

/// Asks the system to refresh the widget. In the app this wraps WidgetCenter.
public protocol TimelineReloading: Sendable {
    func reloadTimelines()
}
