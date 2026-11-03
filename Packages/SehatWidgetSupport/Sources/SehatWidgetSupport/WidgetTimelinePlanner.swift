//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

public enum WidgetContent: Sendable, Equatable {
    /// No snapshot yet, or it cannot be read: ask the user to open the app.
    case needsSetup
    case noReminders
    case next(medicationName: String, at: Date)
}

public struct WidgetPlanEntry: Sendable, Equatable {
    public let date: Date
    public let content: WidgetContent

    public init(date: Date, content: WidgetContent) {
        self.date = date
        self.content = content
    }
}

/// Turns the stored snapshot into what the widget shows over time.
public enum WidgetTimelinePlanner {
    public static func entries(
        loading load: () throws -> ReminderSnapshot?,
        now: Date,
        horizon: TimeInterval = 86_400,
        calendar: Calendar
    ) -> [WidgetPlanEntry] {
        let snapshot: ReminderSnapshot
        do {
            guard let loaded = try load() else {
                return [WidgetPlanEntry(date: now, content: .needsSetup)]
            }
            snapshot = loaded
        } catch {
            return [WidgetPlanEntry(date: now, content: .needsSetup)]
        }

        return NextReminderPlanner
            .timeline(snapshot.slots, from: now, horizon: horizon, calendar: calendar)
            .map { point in
                let content: WidgetContent = point.next.map {
                    .next(medicationName: $0.slot.medicationName, at: $0.date)
                } ?? .noReminders
                return WidgetPlanEntry(date: point.date, content: content)
            }
    }
}
