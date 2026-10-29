//
// Copyright (c) 2026 Enjel Hutasoit
//

import XCTest

@MainActor
final class AppointmentJourneyTests: UITestCase {

    func test_bookingAnAppointment_listsItAsPending() {
        let app = launchApp()

        bookAppointment(in: app, doctor: "Dr. Booking Test", specialty: "Cardiology")

        let row = element(in: app, labelContaining: "Dr. Booking Test", "Pending")
        XCTAssertTrue(row.waitForExistence(timeout: timeout), "Booked appointment was not listed as pending")
    }

    func test_submittingAnEmptyForm_showsValidationError_andKeepsTheFormOpen() {
        let app = launchApp()
        openBookingForm(in: app)

        tapWhenReady(app.buttons[UITestIdentifier.submitBooking], "Book button")

        XCTAssertTrue(app.staticTexts[UITestIdentifier.bookingError].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.textFields[UITestIdentifier.doctorNameField].exists)
    }

    func test_bookedAppointment_survivesRelaunch() {
        let app = launchApp()
        bookAppointment(in: app, doctor: "Dr. Persist Test", specialty: "Neurology")
        let booked = element(in: app, labelContaining: "Dr. Persist Test")
        XCTAssertTrue(booked.waitForExistence(timeout: timeout), "Booked appointment was not listed")

        relaunch(app)
        openTab("Appointments", in: app)

        let restored = element(in: app, labelContaining: "Dr. Persist Test", "Pending")
        XCTAssertTrue(restored.waitForExistence(timeout: timeout), "Appointment was lost after relaunch")
    }
}
