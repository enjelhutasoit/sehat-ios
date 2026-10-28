//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import SehatDomain

/// Fake data for the reference app. Temporary: replaced by synced data once
/// a remote adapter exists. Ids are fixed so seeding twice changes nothing.
enum SampleData {
    static func consultations(now: Date = .now) -> [Consultation] {
        [
            make(1, "Dr. Contoh A", "General", .chat, .inProgress, now.addingTimeInterval(-600)),
            make(2, "Dr. Contoh B", "Pediatrics", .video, .scheduled, now.addingTimeInterval(26 * 3_600)),
            make(3, "Dr. Contoh C", "Dermatology", .voice, .completed, now.addingTimeInterval(-3 * 86_400)),
            make(4, "Dr. Contoh D", "Internal Medicine", .chat, .completed, now.addingTimeInterval(-10 * 86_400)),
            make(5, "Dr. Contoh E", "Nutrition", .video, .cancelled, now.addingTimeInterval(-20 * 86_400))
        ]
    }

    private static func make(
        _ number: Int,
        _ doctorName: String,
        _ specialty: String,
        _ channel: Consultation.Channel,
        _ status: Consultation.Status,
        _ scheduledAt: Date
    ) -> Consultation {
        Consultation(
            id: id(number),
            doctorName: doctorName,
            specialty: specialty,
            channel: channel,
            status: status,
            scheduledAt: scheduledAt
        )
    }

    private static func id(_ number: Int) -> UUID {
        let suffix = String(format: "%012d", number)
        guard let uuid = UUID(uuidString: "10000000-0000-0000-0000-\(suffix)") else {
            preconditionFailure("Invalid sample id")
        }
        return uuid
    }
}
