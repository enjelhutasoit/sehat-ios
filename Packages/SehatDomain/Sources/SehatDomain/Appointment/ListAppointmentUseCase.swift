//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

/// Loads appointments ordered by start time (earliest first, ties by id).
public struct ListAppointmentsUseCase: Sendable {
    private let repository: any AppointmentRepository

    public init(repository: any AppointmentRepository) {
        self.repository = repository
    }

    public func execute() async throws -> [Appointment] {
        try await repository.appointments().sorted { lhs, rhs in
            if lhs.startsAt != rhs.startsAt {
                return lhs.startsAt < rhs.startsAt
            }
            return lhs.id.uuidString < rhs.id.uuidString
        }
    }
}
