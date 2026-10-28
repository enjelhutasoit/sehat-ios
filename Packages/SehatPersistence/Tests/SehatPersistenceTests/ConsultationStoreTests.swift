//
// Copyright (c) 2026 Enjel Hutasoit
//

import XCTest
import SwiftData
import SehatCore
import SehatDomain
@testable import SehatPersistence

final class ConsultationStoreTests: XCTestCase {

    // MARK: - Reading

    func test_consultations_returnsEmpty_whenStoreIsEmpty() async throws {
        let (sut, _) = try makeSUT()

        let loaded = try await sut.consultations()

        XCTAssertTrue(loaded.isEmpty)
    }

    func test_upsert_thenConsultations_returnsSavedItems() async throws {
        let (sut, _) = try makeSUT()
        let items = [makeConsultation(id: 1), makeConsultation(id: 2, status: .completed)]

        try await sut.upsert(items)
        let loaded = try await sut.consultations()

        XCTAssertEqual(Set(loaded), Set(items))
    }

    func test_upsert_roundTripsEveryChannelAndStatus() async throws {
        let (sut, _) = try makeSUT()
        let channels: [Consultation.Channel] = [.chat, .video, .voice]
        let statuses: [Consultation.Status] = [.scheduled, .inProgress, .completed, .cancelled]
        var items: [Consultation] = []
        var number = 1
        for channel in channels {
            for status in statuses {
                items.append(makeConsultation(id: number, channel: channel, status: status))
                number += 1
            }
        }

        try await sut.upsert(items)
        let loaded = try await sut.consultations()

        XCTAssertEqual(Set(loaded), Set(items))
    }

    func test_consultationByID_returnsMatchingConsultation() async throws {
        let (sut, _) = try makeSUT()
        let target = makeConsultation(id: 2, doctorName: "Dr. Target")
        try await sut.upsert([makeConsultation(id: 1), target])

        let found = try await sut.consultation(id: target.id)

        XCTAssertEqual(found, target)
    }

    func test_consultationByID_throwsNotFound_whenMissing() async throws {
        let (sut, _) = try makeSUT()

        await assertThrows(.notFound) { _ = try await sut.consultation(id: makeUUID(99)) }
    }

    // MARK: - Writing

    func test_upsert_updatesExistingConsultation_withSameID() async throws {
        let (sut, _) = try makeSUT()
        try await sut.upsert([makeConsultation(id: 1, doctorName: "Old", status: .scheduled)])

        let updated = makeConsultation(id: 1, doctorName: "New", status: .completed)
        try await sut.upsert([updated])
        let loaded = try await sut.consultations()

        XCTAssertEqual(loaded, [updated])
    }

    func test_upsert_lastItemWins_forDuplicateIDsInInput() async throws {
        let (sut, _) = try makeSUT()
        let first = makeConsultation(id: 1, doctorName: "First")
        let second = makeConsultation(id: 1, doctorName: "Second")

        try await sut.upsert([first, second])
        let loaded = try await sut.consultations()

        XCTAssertEqual(loaded, [second])
    }

    func test_upsert_keepsUnrelatedConsultations() async throws {
        let (sut, _) = try makeSUT()
        let untouched = makeConsultation(id: 1)
        try await sut.upsert([untouched, makeConsultation(id: 2)])

        try await sut.upsert([makeConsultation(id: 2, doctorName: "Changed")])
        let loaded = try await sut.consultations()

        XCTAssertEqual(loaded.count, 2)
        XCTAssertTrue(loaded.contains(untouched))
    }

    func test_data_isVisibleToAnotherStoreSharingTheContainer() async throws {
        let (writer, container) = try makeSUT()
        let reader = ConsultationStore(modelContainer: container)
        let items = [makeConsultation(id: 1)]

        try await writer.upsert(items)
        let loaded = try await reader.consultations()

        XCTAssertEqual(loaded, items)
    }

    // MARK: - Corrupted data

    func test_consultations_throwsStorage_whenRecordHasUnknownValues() async throws {
        let (sut, container) = try makeSUT()
        let context = ModelContext(container)
        context.insert(
            ConsultationRecord(
                id: makeUUID(1),
                doctorName: "Dr. Broken",
                specialty: "General",
                channelRaw: "unknown-channel",
                statusRaw: "scheduled",
                scheduledAt: Date(timeIntervalSince1970: 0)
            )
        )
        try context.save()

        await assertThrows(.storage) { _ = try await sut.consultations() }
    }

    // MARK: - Helpers

    private func makeSUT() throws -> (ConsultationStore, ModelContainer) {
        let container = try PersistenceStack.makeContainer(inMemory: true)
        return (ConsultationStore(modelContainer: container), container)
    }

    private func assertThrows(
        _ expected: AppError,
        file: StaticString = #filePath,
        line: UInt = #line,
        _ operation: () async throws -> Void
    ) async {
        do {
            try await operation()
            XCTFail("Expected \(expected) but operation succeeded", file: file, line: line)
        } catch {
            XCTAssertEqual(error as? AppError, expected, file: file, line: line)
        }
    }
}
