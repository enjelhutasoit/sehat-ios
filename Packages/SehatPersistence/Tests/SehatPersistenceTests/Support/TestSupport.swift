//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
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
