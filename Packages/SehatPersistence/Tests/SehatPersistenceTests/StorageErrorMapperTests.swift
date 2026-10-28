//
// Copyright (c) 2026 Enjel Hutasoit
//

import XCTest
import SehatCore
import SehatPersistence

final class StorageErrorMapperTests: XCTestCase {

    func test_map_passesThroughAppError() {
        XCTAssertEqual(StorageErrorMapper().map(AppError.notFound), .notFound)
    }

    func test_map_returnsCancelled_forCancellationError() {
        XCTAssertEqual(StorageErrorMapper().map(CancellationError()), .cancelled)
    }

    func test_map_returnsStorage_forAnyOtherError() {
        struct SomeError: Error {}

        XCTAssertEqual(StorageErrorMapper().map(SomeError()), .storage)
    }
}
