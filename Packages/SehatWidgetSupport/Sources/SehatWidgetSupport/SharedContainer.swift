//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

/// Where the app and the widget exchange data. A thin wrapper over the system
/// API, so it has no test: without the App Group entitlement it returns nil.
public enum SharedContainer {
    /// Must equal the App Groups entitlement of the app and the widget.
    public static let appGroupIdentifier = "group.com.example.Sehat"

    public static func snapshotDirectory(fileManager: FileManager = .default) -> URL? {
        fileManager
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)?
            .appendingPathComponent("Widget", isDirectory: true)
    }
}

public enum WidgetKind {
    /// Shared by the app (to reload the widget) and the widget (to declare it).
    public static let medication = "com.example.Sehat.MedicationWidget"
}
