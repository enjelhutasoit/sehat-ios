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

func makeConsultation(
    id: Int = 1,
    status: Consultation.Status = .scheduled,
    at seconds: TimeInterval = 1_000
) -> Consultation {
    Consultation(
        id: makeUUID(id),
        doctorName: "Dr. Example",
        specialty: "General",
        channel: .chat,
        status: status,
        scheduledAt: Date(timeIntervalSince1970: seconds)
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

actor RepositoryStub: ConsultationRepository {
    private var result: Result<[Consultation], Error>
    private(set) var requestedIDs: [Consultation.ID] = []

    init(_ result: Result<[Consultation], Error>) {
        self.result = result
    }

    func update(_ newResult: Result<[Consultation], Error>) {
        result = newResult
    }

    func consultations() async throws -> [Consultation] {
        try result.get()
    }

    func consultation(id: Consultation.ID) async throws -> Consultation {
        requestedIDs.append(id)
        guard let found = try result.get().first(where: { $0.id == id }) else {
            throw AppError.notFound
        }
        return found
    }
}

/// Keeps `consultations()` suspended until the test releases it.
actor GatedRepository: ConsultationRepository {
    private(set) var listCallCount = 0
    private var continuation: CheckedContinuation<[Consultation], Error>?

    var isWaiting: Bool { continuation != nil }

    func consultations() async throws -> [Consultation] {
        listCallCount += 1
        return try await withCheckedThrowingContinuation { continuation = $0 }
    }

    func consultation(id: Consultation.ID) async throws -> Consultation {
        throw AppError.notFound
    }

    func release(with consultations: [Consultation]) {
        continuation?.resume(returning: consultations)
        continuation = nil
    }
}

@MainActor
final class SelectionRecorder {
    private(set) var ids: [Consultation.ID] = []

    func record(_ id: Consultation.ID) {
        ids.append(id)
    }
}
