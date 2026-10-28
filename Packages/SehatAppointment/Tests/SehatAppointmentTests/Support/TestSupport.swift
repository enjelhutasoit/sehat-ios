//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import SehatCore
import SehatDomain
import XCTest

func makeUUID(_ number: Int) -> UUID {
    let suffix = String(format: "%012d", number)
    guard let uuid = UUID(uuidString: "00000000-0000-0000-0000-\(suffix)") else {
        preconditionFailure("Invalid test fixture")
    }
    return uuid
}

func makeAppointment(id: Int = 1, at seconds: TimeInterval = 7_200) -> Appointment {
    Appointment(
        id: makeUUID(id),
        doctorName: "Dr. Example",
        specialty: "General",
        startsAt: Date(timeIntervalSince1970: seconds),
        status: .pending
    )
}

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

actor RepositoryStub: AppointmentRepository {
    private var result: Result<[Appointment], Error>
    private let bookFailure: Error?
    private(set) var booked: [Appointment] = []

    init(_ result: Result<[Appointment], Error> = .success([]), bookFailure: Error? = nil) {
        self.result = result
        self.bookFailure = bookFailure
    }

    func update(_ newResult: Result<[Appointment], Error>) {
        result = newResult
    }

    func appointments() async throws -> [Appointment] {
        try result.get()
    }

    func book(_ appointment: Appointment) async throws {
        if let bookFailure { throw bookFailure }
        booked.append(appointment)
    }
}

/// Every `appointments()` call stays suspended until released by index.
actor GatedListRepository: AppointmentRepository {
    private var continuations: [CheckedContinuation<[Appointment], Error>] = []

    var startedCount: Int { continuations.count }

    func appointments() async throws -> [Appointment] {
        try await withCheckedThrowingContinuation { continuations.append($0) }
    }

    func book(_ appointment: Appointment) async throws {}

    func release(at index: Int, with result: [Appointment]) {
        continuations[index].resume(returning: result)
    }
}

/// `book` stays suspended until released.
actor GatedBookRepository: AppointmentRepository {
    private(set) var bookCallCount = 0
    private var continuation: CheckedContinuation<Void, Error>?

    var isBookWaiting: Bool { continuation != nil }

    func appointments() async throws -> [Appointment] { [] }

    func book(_ appointment: Appointment) async throws {
        bookCallCount += 1
        try await withCheckedThrowingContinuation { (waiting: CheckedContinuation<Void, Error>) in
            continuation = waiting
        }
    }

    func releaseBook() {
        continuation?.resume()
        continuation = nil
    }
}

@MainActor
final class BookedRecorder {
    private(set) var appointments: [Appointment] = []

    func record(_ appointment: Appointment) {
        appointments.append(appointment)
    }
}
