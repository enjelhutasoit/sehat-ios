//
// Copyright (c) 2026 Enjel Hutasoit
//

import SwiftData

/// Builds the SwiftData container. Called once from the app's composition root.
public enum PersistenceStack {
    /// - Parameter inMemory: `true` for tests and previews; nothing touches disk.
    /// - Throws: the underlying SwiftData error. The caller decides how to recover.
    ///
    /// CloudKit is explicitly off: health data must not sync to iCloud by accident.
    public static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema([ConsultationRecord.self, OutboxRecord.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: schema, configurations: configuration)
    }
}
