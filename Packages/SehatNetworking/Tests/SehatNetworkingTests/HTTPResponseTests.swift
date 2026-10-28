//
// Copyright (c) 2026 Enjel Hutasoit
//

import XCTest
import SehatNetworking

final class HTTPResponseTests: XCTestCase {

    func test_header_isCaseInsensitive() {
        let sut = HTTPResponse(statusCode: 200, headers: ["Retry-After": "5"])

        XCTAssertEqual(sut.header("retry-after"), "5")
        XCTAssertEqual(sut.header("RETRY-AFTER"), "5")
    }

    func test_header_returnsNil_whenAbsent() {
        let sut = HTTPResponse(statusCode: 200, headers: ["A": "1"])

        XCTAssertNil(sut.header("B"))
    }
}
