//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

/// Loads consultations and groups them for the list screen.
///
/// Grouping depends on status only, not on the current time, so the result
/// is deterministic. Date ties are ordered by id.
public struct GetConsultationOverviewUseCase: Sendable {
    private let repository: any ConsultationRepository

    public init(repository: any ConsultationRepository) {
        self.repository = repository
    }

    public func execute() async throws -> ConsultationOverview {
        let all = try await repository.consultations()

        return ConsultationOverview(
            upcoming: all.filter { $0.status.isUpcoming }.sorted(by: Self.isSoonerFirst),
            history: all.filter { !$0.status.isUpcoming }.sorted(by: Self.isMostRecentFirst)
        )
    }

    private static func isSoonerFirst(_ lhs: Consultation, _ rhs: Consultation) -> Bool {
        if lhs.scheduledAt != rhs.scheduledAt {
            return lhs.scheduledAt < rhs.scheduledAt
        }
        return lhs.id.uuidString < rhs.id.uuidString
    }

    private static func isMostRecentFirst(_ lhs: Consultation, _ rhs: Consultation) -> Bool {
        if lhs.scheduledAt != rhs.scheduledAt {
            return lhs.scheduledAt > rhs.scheduledAt
        }
        return lhs.id.uuidString < rhs.id.uuidString
    }
}
