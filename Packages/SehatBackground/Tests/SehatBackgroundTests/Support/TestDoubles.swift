//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import SehatBackground
import XCTest

struct TestError: Error, Equatable {}

/// Yields until `condition` holds. Uses no wall-clock time; the iteration
/// bound only protects against a hang when the condition can never be met.
func eventually(
    _ condition: @Sendable () async -> Bool,
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    for _ in 0..<100_000 {
        if await condition() { return }
        await Task.yield()
    }
    XCTFail("Condition was not met", file: file, line: line)
}

/// Thread-safe, ordered log shared by the doubles.
final class EventLog: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String] = []

    func append(_ event: String) {
        lock.withLock { storage.append(event) }
    }

    var events: [String] {
        lock.withLock { storage }
    }
}

final class SubmitterFake: BackgroundRefreshSubmitting, @unchecked Sendable {
    private let lock = NSLock()
    private var dates: [Date] = []
    private let failure: Error?
    private let log: EventLog?

    init(failure: Error? = nil, log: EventLog? = nil) {
        self.failure = failure
        self.log = log
    }

    var submittedDates: [Date] {
        lock.withLock { dates }
    }

    func submitRefreshRequest(earliestBeginDate: Date) throws {
        log?.append("submit")
        lock.withLock { dates.append(earliestBeginDate) }
        if let failure { throw failure }
    }
}

final class TaskHandleFake: BackgroundTaskHandle, @unchecked Sendable {
    private let lock = NSLock()
    private var expiration: (@Sendable () -> Void)?
    private var results: [Bool] = []

    var hasExpirationHandler: Bool {
        lock.withLock { expiration != nil }
    }

    var completions: [Bool] {
        lock.withLock { results }
    }

    func setExpirationHandler(_ handler: @escaping @Sendable () -> Void) {
        lock.withLock { expiration = handler }
    }

    func setTaskCompleted(success: Bool) {
        lock.withLock { results.append(success) }
    }

    func fireExpiration() {
        let handler = lock.withLock { expiration }
        handler?()
    }
}

actor WorkFake: BackgroundWork {
    private let failure: Error?
    private let log: EventLog?
    private(set) var performCount = 0

    init(failure: Error? = nil, log: EventLog? = nil) {
        self.failure = failure
        self.log = log
    }

    func perform() async throws {
        performCount += 1
        log?.append("work")
        if let failure { throw failure }
    }
}

/// Runs until its task is cancelled, then throws `CancellationError`.
actor UntilCancelledWork: BackgroundWork {
    private(set) var isRunning = false
    private(set) var sawCancellation = false

    func perform() async throws {
        isRunning = true
        while !Task.isCancelled {
            await Task.yield()
        }
        sawCancellation = true
        throw CancellationError()
    }
}
