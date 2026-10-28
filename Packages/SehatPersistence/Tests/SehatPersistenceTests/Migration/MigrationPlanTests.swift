//
// Copyright (c) 2026 Enjel Hutasoit
//

import XCTest
@testable import SehatPersistence

final class MigrationPlanTests: XCTestCase {

    func test_stages_coverEveryTransitionBetweenSchemas() {
        XCTAssertEqual(SehatMigrationPlan.stages.count, SehatMigrationPlan.schemas.count - 1)
    }

    func test_lastSchema_isTheCurrentSchema() throws {
        let last = try XCTUnwrap(SehatMigrationPlan.schemas.last)

        XCTAssertEqual(ObjectIdentifier(last), ObjectIdentifier(CurrentSchema.self))
    }
}
