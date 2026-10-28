//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import SehatCore
import SehatDomain

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

struct ConsultationRepositoryStub: ConsultationRepository {
    let result: Result<[Consultation], Error>

    func consultations() async throws -> [Consultation] {
        try result.get()
    }

    func consultation(id: Consultation.ID) async throws -> Consultation {
        guard let found = try result.get().first(where: { $0.id == id }) else {
            throw AppError.notFound
        }
        return found
    }
}
