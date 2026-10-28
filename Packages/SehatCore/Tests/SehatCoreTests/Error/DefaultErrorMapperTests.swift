//
// Copyright (c) 2026 Enjel Hutasoit
//

import XCTest
import SehatCore

final class DefaultErrorMapperTests: XCTestCase {

    func test_map_returnsSameError_whenAlreadyAppError() {
        let sut = DefaultErrorMapper()

        XCTAssertEqual(sut.map(AppError.notFound), .notFound)
        XCTAssertEqual(sut.map(AppError.server(statusCode: 503)), .server(statusCode: 503))
    }

    func test_map_returnsCancelled_forCancellationError() {
        XCTAssertEqual(DefaultErrorMapper().map(CancellationError()), .cancelled)
    }

    func test_map_returnsOffline_forConnectivityURLErrors() {
        let codes: [URLError.Code] = [
            .notConnectedToInternet,
            .networkConnectionLost,
            .dataNotAllowed,
            .internationalRoamingOff
        ]

        for code in codes {
            XCTAssertEqual(DefaultErrorMapper().map(URLError(code)), .offline, "\(code)")
        }
    }

    func test_map_returnsTimedOut_forURLErrorTimedOut() {
        XCTAssertEqual(DefaultErrorMapper().map(URLError(.timedOut)), .timedOut)
    }

    func test_map_returnsCancelled_forURLErrorCancelled() {
        XCTAssertEqual(DefaultErrorMapper().map(URLError(.cancelled)), .cancelled)
    }

    func test_map_returnsUnknown_forOtherURLErrors() {
        XCTAssertEqual(DefaultErrorMapper().map(URLError(.badURL)), .unknown)
    }

    func test_map_returnsDecoding_forDecodingError() {
        let error = DecodingError.dataCorrupted(
            DecodingError.Context(codingPath: [], debugDescription: "corrupted")
        )

        XCTAssertEqual(DefaultErrorMapper().map(error), .decoding)
    }

    func test_map_returnsUnknown_forUnrecognizedError() {
        struct SomeError: Error {}

        XCTAssertEqual(DefaultErrorMapper().map(SomeError()), .unknown)
    }
}
