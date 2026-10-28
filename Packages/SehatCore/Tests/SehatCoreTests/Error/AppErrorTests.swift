//
// Copyright (c) 2026 Enjel Hutasoit
//

import XCTest
import SehatCore

final class AppErrorTests: XCTestCase {

    // MARK: - isRetryable

    func test_isRetryable_isTrue_forTransientFailures() {
        let transient: [AppError] = [
            .offline,
            .timedOut,
            .server(statusCode: 408),
            .server(statusCode: 429),
            .server(statusCode: 500),
            .server(statusCode: 503),
            .server(statusCode: 599)
        ]

        for error in transient {
            XCTAssertTrue(error.isRetryable, "\(error) should be retryable")
        }
    }

    func test_isRetryable_isFalse_forPermanentFailures() {
        let permanent: [AppError] = [
            .unauthorized,
            .notFound,
            .decoding,
            .storage,
            .cancelled,
            .unknown,
            .server(statusCode: 400),
            .server(statusCode: 403),
            .server(statusCode: 499),
            .server(statusCode: 600)
        ]

        for error in permanent {
            XCTAssertFalse(error.isRetryable, "\(error) should not be retryable")
        }
    }

    // MARK: - localizationKey

    func test_localizationKey_isNonEmptyAndUniquePerCase() {
        Self.allCases.forEach(Self.exhaustivenessGuard)
        let keys = Self.allCases.map(\.localizationKey)

        XCTAssertFalse(keys.contains(where: \.isEmpty))
        XCTAssertEqual(Set(keys).count, keys.count)
    }

    func test_localizationKey_doesNotDependOnStatusCode() {
        XCTAssertEqual(
            AppError.server(statusCode: 500).localizationKey,
            AppError.server(statusCode: 503).localizationKey
        )
    }

    // MARK: - Helpers

    private static let allCases: [AppError] = [
        .offline, .timedOut, .server(statusCode: 500), .unauthorized,
        .notFound, .decoding, .storage, .cancelled, .unknown
    ]

    /// Compile-time guard: adding a case to `AppError` breaks this switch,
    /// which reminds you to extend `allCases` above.
    private static func exhaustivenessGuard(_ error: AppError) {
        switch error {
        case .offline, .timedOut, .server, .unauthorized,
             .notFound, .decoding, .storage, .cancelled, .unknown:
            break
        }
    }
}
