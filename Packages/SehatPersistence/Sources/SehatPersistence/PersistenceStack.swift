//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import SwiftData

/// Builds the SwiftData container. Called once from the app's composition root.
///
/// Containers always open with `SehatMigrationPlan`, so stores written by
/// older versions are migrated on open. Failures are thrown as the underlying
/// SwiftData error; the caller decides how to recover. A failed migration is
/// never "fixed" by deleting the store.
///
/// CloudKit is explicitly off: health data must not sync to iCloud by accident.
public enum PersistenceStack {
    /// - Parameter inMemory: `true` for tests and previews; nothing touches disk.
    public static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        try makeContainer(
            configuration: ModelConfiguration(
                schema: Schema(versionedSchema: CurrentSchema.self),
                isStoredInMemoryOnly: inMemory,
                cloudKitDatabase: .none
            )
        )
    }

    /// Opens (and migrates, if needed) the store at `storeURL`.
    public static func makeContainer(storeURL: URL) throws -> ModelContainer {
        try makeContainer(
            configuration: ModelConfiguration(
                schema: Schema(versionedSchema: CurrentSchema.self),
                url: storeURL,
                cloudKitDatabase: .none
            )
        )
    }

    private static func makeContainer(configuration: ModelConfiguration) throws -> ModelContainer {
        try ModelContainer(
            for: Schema(versionedSchema: CurrentSchema.self),
            migrationPlan: SehatMigrationPlan.self,
            configurations: configuration
        )
    }
}
