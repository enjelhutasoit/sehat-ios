//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import SehatCore
import XCTest

func makeUUID(_ number: Int) -> UUID {
    let suffix = String(format: "%012d", number)
    guard let uuid = UUID(uuidString: "00000000-0000-0000-0000-\(suffix)") else {
        preconditionFailure("Invalid test fixture")
    }
    return uuid
}

final class TestClock: @unchecked Sendable {
    private let lock = NSLock()
    private var seconds: TimeInterval

    init(_ seconds: TimeInterval = 0) {
        self.seconds = seconds
    }

    func set(_ seconds: TimeInterval) {
        lock.withLock { self.seconds = seconds }
    }

    var date: Date {
        lock.withLock { Date(timeIntervalSince1970: seconds) }
    }
}

final class IDSource: @unchecked Sendable {
    private let lock = NSLock()
    private var counter = 0

    func next() -> UUID {
        lock.withLock {
            counter += 1
            return makeUUID(counter)
        }
    }
}

func assertThrowsAppError(
    _ expected: AppError,
    file: StaticString = #filePath,
    line: UInt = #line,
    _ operation: () async throws -> Void
) async {
    do {
        try await operation()
        XCTFail("Expected \(expected) but operation succeeded", file: file, line: line)
    } catch {
        XCTAssertEqual(error as? AppError, expected, file: file, line: line)
    }
}
