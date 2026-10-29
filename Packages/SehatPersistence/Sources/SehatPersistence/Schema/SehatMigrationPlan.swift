//
// Copyright (c) 2026 Enjel Hutasoit
//

import SwiftData

/// Ordered history of schema versions and how to move between them.
/// Adding a version means: freeze the previous schema, add the new one,
/// append it here with a stage, update `CurrentSchema`, and add a test.
enum SehatMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SehatSchemaV1.self, SehatSchemaV2.self, SehatSchemaV3.self, SehatSchemaV4.self]
    }

    static var stages: [MigrationStage] {
        [
            // Adds `serverVersion` with a default value.
            .lightweight(fromVersion: SehatSchemaV1.self, toVersion: SehatSchemaV2.self),
            // Adds the appointment entity.
            .lightweight(fromVersion: SehatSchemaV2.self, toVersion: SehatSchemaV3.self),
            // Adds the medication reminder entity; existing entities are untouched.
            .lightweight(fromVersion: SehatSchemaV3.self, toVersion: SehatSchemaV4.self)
        ]
    }
}
