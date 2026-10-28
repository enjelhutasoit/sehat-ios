//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

/// Access to the patient's appointments. Implemented by the data layer.
///
/// Contract: implementations throw `AppError` only. No ordering is guaranteed.
public protocol AppointmentRepository: Sendable {
    func appointments() async throws -> [Appointment]

    /// Stores the appointment and schedules it for delivery to the server.
    /// Both happen or neither does. Booking an id that already exists
    /// changes nothing.
    func book(_ appointment: Appointment) async throws
}
