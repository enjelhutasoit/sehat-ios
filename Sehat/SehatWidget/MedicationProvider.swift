//
// Copyright (c) 2026 Enjel Hutasoit
//

import SehatWidgetSupport
import WidgetKit

/// Thin glue: all decisions are made by `WidgetTimelinePlanner` (tested).
struct MedicationProvider: TimelineProvider {
    private static let refreshInterval: TimeInterval = 86_400

    func placeholder(in context: Context) -> MedicationEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (MedicationEntry) -> Void) {
        if context.isPreview {
            completion(.placeholder)
        } else {
            completion(makeEntries(now: Date()).first ?? .placeholder)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MedicationEntry>) -> Void) {
        let now = Date()
        completion(
            Timeline(
                entries: makeEntries(now: now),
                policy: .after(now.addingTimeInterval(Self.refreshInterval))
            )
        )
    }

    private func makeEntries(now: Date) -> [MedicationEntry] {
        let directory = SharedContainer.snapshotDirectory()
        return WidgetTimelinePlanner.entries(
            loading: {
                guard let directory else { return nil }
                return try FileReminderSnapshotStore(directory: directory).load()
            },
            now: now,
            horizon: Self.refreshInterval,
            calendar: .current
        ).map { MedicationEntry(date: $0.date, content: $0.content) }
    }
}
