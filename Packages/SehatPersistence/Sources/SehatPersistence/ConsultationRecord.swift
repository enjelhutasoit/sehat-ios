//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import SwiftData

/// Storage model. Internal on purpose: it never leaves this package.
/// Enums are stored as strings so on-disk values do not depend on Swift case names.
@Model
final class ConsultationRecord {
    @Attribute(.unique) var id: UUID
    var doctorName: String
    var specialty: String
    var channelRaw: String
    var statusRaw: String
    var scheduledAt: Date

    init(
        id: UUID,
        doctorName: String,
        specialty: String,
        channelRaw: String,
        statusRaw: String,
        scheduledAt: Date
    ) {
        self.id = id
        self.doctorName = doctorName
        self.specialty = specialty
        self.channelRaw = channelRaw
        self.statusRaw = statusRaw
        self.scheduledAt = scheduledAt
    }
}
