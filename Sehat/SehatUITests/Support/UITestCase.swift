//
// Copyright (c) 2026 Enjel Hutasoit
//

import XCTest

/// Identifiers set on the app's views. They do not depend on the language and
/// must match `AccessibilityID` in the SehatAppointment package.
enum UITestIdentifier {
    static let addAppointment = "appointments.add"
    static let doctorNameField = "booking.doctorName"
    static let specialtyField = "booking.specialty"
    static let submitBooking = "booking.submit"
    static let bookingError = "booking.error"
}

/// Base class for journeys. Every journey starts its own app instance:
/// - `-ui-testing` makes the app use a separate store, never the real one.
/// - `-ui-testing-reset` empties that store at launch.
/// - English is forced, so tests may rely on English tab and title labels.
@MainActor
class UITestCase: XCTestCase {
    let timeout: TimeInterval = 10

    func launchApp(resetData: Bool = true) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        if resetData {
            app.launchArguments.append("-ui-testing-reset")
        }
        app.launch()
        return app
    }

    /// Terminates and starts the app again without resetting its data.
    func relaunch(_ app: XCUIApplication) {
        app.terminate()
        app.launchArguments.removeAll { $0 == "-ui-testing-reset" }
        app.launch()
    }

    /// Any element (cell, button, ...) whose accessibility label contains all of `texts`.
    func element(in app: XCUIApplication, labelContaining texts: String...) -> XCUIElement {
        let predicate = NSCompoundPredicate(
            andPredicateWithSubpredicates: texts.map { NSPredicate(format: "label CONTAINS[c] %@", $0) }
        )
        return app.descendants(matching: .any).matching(predicate).firstMatch
    }

    func sectionHeader(_ title: String, in app: XCUIApplication) -> XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "label ==[c] %@", title)).firstMatch
    }

    func openTab(_ name: String, in app: XCUIApplication) {
        let tab = app.tabBars.buttons[name]
        XCTAssertTrue(tab.waitForExistence(timeout: timeout), "Tab '\(name)' was not found")
        tab.tap()
    }

    func tapWhenReady(_ element: XCUIElement, _ description: String) {
        XCTAssertTrue(element.waitForExistence(timeout: timeout), "\(description) was not found")
        element.tap()
    }

    func typeText(_ text: String, into field: XCUIElement, _ description: String) {
        tapWhenReady(field, description)
        field.typeText(text)
    }

    func openBookingForm(in app: XCUIApplication) {
        openTab("Appointments", in: app)
        tapWhenReady(app.buttons[UITestIdentifier.addAppointment], "Add appointment button")
    }

    func bookAppointment(in app: XCUIApplication, doctor: String, specialty: String) {
        openBookingForm(in: app)
        typeText(doctor, into: app.textFields[UITestIdentifier.doctorNameField], "Doctor name field")
        typeText(specialty, into: app.textFields[UITestIdentifier.specialtyField], "Specialty field")
        tapWhenReady(app.buttons[UITestIdentifier.submitBooking], "Book button")
    }
}
