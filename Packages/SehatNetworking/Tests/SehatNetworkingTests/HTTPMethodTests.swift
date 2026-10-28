//
// Copyright (c) 2026 Enjel Hutasoit
//

import XCTest
import SehatNetworking

final class HTTPMethodTests: XCTestCase {

    func test_isIdempotent_isTrueOnlyForIdempotentMethods() {
        XCTAssertTrue(HTTPMethod.get.isIdempotent)
        XCTAssertTrue(HTTPMethod.put.isIdempotent)
        XCTAssertTrue(HTTPMethod.delete.isIdempotent)
        XCTAssertFalse(HTTPMethod.post.isIdempotent)
        XCTAssertFalse(HTTPMethod.patch.isIdempotent)
    }
}
