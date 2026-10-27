//
// Copyright (c) 2026 Enjel Hutasoit
//

import XCTest
import SehatCore

final class RetryPolicyTests: XCTestCase {

    // MARK: - delay(afterFailureCount:)

    func test_delay_returnsBaseDelay_afterFirstFailure() throws {
        let sut = makePolicy()

        try assertDelay(sut, failures: 1, equals: 0.5)
    }

    func test_delay_growsByMultiplier_afterEachFailure() throws {
        let sut = makePolicy()

        try assertDelay(sut, failures: 2, equals: 1)
        try assertDelay(sut, failures: 3, equals: 2)
    }

    func test_delay_neverExceedsMaxDelay() throws {
        let sut = makePolicy(maxDelay: 3)

        try assertDelay(sut, failures: 4, equals: 3)
    }

    func test_delay_returnsNil_whenFailureCountReachesMaxAttempts() {
        let sut = makePolicy(maxAttempts: 5)

        XCTAssertNil(sut.delay(afterFailureCount: 5))
        XCTAssertNil(sut.delay(afterFailureCount: 6))
    }

    func test_delay_returnsNil_forNonPositiveFailureCount() {
        let sut = makePolicy()

        XCTAssertNil(sut.delay(afterFailureCount: 0))
        XCTAssertNil(sut.delay(afterFailureCount: -1))
    }

    func test_delay_returnsZero_whenBaseDelayIsZero() throws {
        let sut = makePolicy(baseDelay: 0)

        try assertDelay(sut, failures: 2, equals: 0)
    }

    func test_delay_staysAtMaxDelay_whenGrowthOverflows() throws {
        let sut = RetryPolicy(maxAttempts: Int.max, baseDelay: 1, multiplier: 10, maxDelay: 5)

        try assertDelay(sut, failures: 1_000, equals: 5)
    }

    // MARK: - init normalization

    func test_init_normalizesInvalidInputs() {
        let sut = RetryPolicy(maxAttempts: -3, baseDelay: -1, multiplier: 0.5, maxDelay: -9)

        XCTAssertEqual(sut.maxAttempts, 0)
        XCTAssertEqual(sut.baseDelay, 0)
        XCTAssertEqual(sut.multiplier, 1)
        XCTAssertEqual(sut.maxDelay, 0)
    }

    func test_init_raisesMaxDelayToBaseDelay_whenMaxDelayIsSmaller() {
        let sut = RetryPolicy(maxAttempts: 2, baseDelay: 4, multiplier: 2, maxDelay: 1)

        XCTAssertEqual(sut.maxDelay, 4)
    }

    func test_init_treatsNonFiniteValuesAsSafeDefaults() throws {
        let sut = RetryPolicy(maxAttempts: 3, baseDelay: 2, multiplier: .nan, maxDelay: .infinity)

        XCTAssertEqual(sut.multiplier, 1)
        XCTAssertEqual(sut.maxDelay, 2)
        try assertDelay(sut, failures: 2, equals: 2)
        XCTAssertEqual(RetryPolicy(maxAttempts: 1, baseDelay: .infinity, maxDelay: 1).baseDelay, 0)
    }

    // MARK: - Helpers

    private func makePolicy(
        maxAttempts: Int = 5,
        baseDelay: TimeInterval = 0.5,
        multiplier: Double = 2,
        maxDelay: TimeInterval = 60
    ) -> RetryPolicy {
        RetryPolicy(
            maxAttempts: maxAttempts,
            baseDelay: baseDelay,
            multiplier: multiplier,
            maxDelay: maxDelay
        )
    }

    private func assertDelay(
        _ sut: RetryPolicy,
        failures: Int,
        equals expected: TimeInterval,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let delay = try XCTUnwrap(sut.delay(afterFailureCount: failures), file: file, line: line)
        XCTAssertEqual(delay, expected, accuracy: 0.0001, file: file, line: line)
    }
}
