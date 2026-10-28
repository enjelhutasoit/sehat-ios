//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import SehatCore
import SehatDomain
import SehatPersistence
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
    doctorName: String = "Dr. Example",
    channel: Consultation.Channel = .chat,
    status: Consultation.Status = .scheduled,
    at seconds: TimeInterval = 1_000
) -> Consultation {
    Consultation(
        id: makeUUID(id),
        doctorName: doctorName,
        specialty: "General",
        channel: channel,
        status: status,
        scheduledAt: Date(timeIntervalSince1970: seconds)
    )
}

func makeEntry(
    id: Int,
    entityID: Int = 900,
    kind: String = "consultation.cancel",
    payload: String = "{}"
) -> OutboxEntry {
    OutboxEntry(
        id: makeUUID(id),
        entityID: makeUUID(entityID),
        kind: kind,
        payload: Data(payload.utf8)
    )
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
