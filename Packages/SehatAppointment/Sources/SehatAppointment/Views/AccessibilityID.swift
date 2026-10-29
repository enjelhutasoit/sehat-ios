//
// Copyright (c) 2026 Enjel Hutasoit
//

/// Identifiers that UI tests use to find controls. They do not depend on the
/// language. Keep them equal to `UITestIdentifier` in the UI test target.
enum AccessibilityID {
    static let addAppointment = "appointments.add"
    static let doctorNameField = "booking.doctorName"
    static let specialtyField = "booking.specialty"
    static let submitBooking = "booking.submit"
    static let bookingError = "booking.error"
}
