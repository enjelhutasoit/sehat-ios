//
// Copyright (c) 2026 Enjel Hutasoit
//

import XCTest

@MainActor
final class ConsultationJourneyTests: UITestCase {

    func test_consultationList_showsSeededConsultations_underUpcomingAndHistory() {
        let app = launchApp()

        let upcoming = element(in: app, labelContaining: "Dr. Contoh A")
        XCTAssertTrue(upcoming.waitForExistence(timeout: timeout), "Upcoming consultation row not found")
        XCTAssertTrue(element(in: app, labelContaining: "Dr. Contoh C").exists, "History consultation row not found")
        XCTAssertTrue(sectionHeader("Upcoming", in: app).exists)
        XCTAssertTrue(sectionHeader("History", in: app).exists)
    }

    func test_selectingAConsultation_opensItsDetails() {
        let app = launchApp()
        let row = element(in: app, labelContaining: "Dr. Contoh A")
        XCTAssertTrue(row.waitForExistence(timeout: timeout), "Consultation row not found")

        row.tap()

        XCTAssertTrue(app.navigationBars["Consultation"].waitForExistence(timeout: timeout))
        // "Specialty" is a label that exists on the detail screen only.
        XCTAssertTrue(element(in: app, labelContaining: "Specialty").waitForExistence(timeout: timeout))
    }
}
