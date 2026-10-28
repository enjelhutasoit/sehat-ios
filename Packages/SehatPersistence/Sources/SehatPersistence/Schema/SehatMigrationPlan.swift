//
// Copyright (c) 2026 Enjel Hutasoit
//

import SwiftData

/// Ordered history of schema versions and how to move between them.
/// Adding a version means: freeze the previous schema, add the new one,
/// append it here with a stage, update `CurrentSchema`, and add a test.
enum SehatMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SehatSchemaV1.self, SehatSchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [
            // Only adds `serverVersion` with a default value, so lightweight is enough.
            .lightweight(fromVersion: SehatSchemaV1.self, toVersion: SehatSchemaV2.self)
        ]
    }
}
