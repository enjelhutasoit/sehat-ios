//
// Copyright (c) 2026 Enjel Hutasoit
//

import SehatCore
import SehatDomain
import SwiftData
import XCTest

@testable import SehatPersistence

final class SchemaMigrationTests: XCTestCase {

    // Matches the raw V1 rows written by `writeV1Store`.
    private let expectedConsultations = [
        makeConsultation(id: 1, doctorName: "Dr. A", channel: .video, status: .inProgress, at: 500),
        makeConsultation(id: 2, doctorName: "Dr. B", channel: .voice, status: .completed, at: 600)
    ]
    private let expectedEntries = [
        makeEntry(id: 1, entityID: 1, kind: "consultation.cancel", payload: "a"),
        makeEntry(id: 2, entityID: 2, kind: "consultation.cancel", payload: "b")
    ]

    // MARK: - V1 to V2

    func test_migrationFromV1_preservesConsultations() async throws {
        let url = try makeStoreURL()
        try writeV1Store(at: url)

        let loaded = try await readConsultations(at: url)

        XCTAssertEqual(Set(loaded), Set(expectedConsultations))
    }

    func test_migrationFromV1_setsDefaultServerVersion() throws {
        let url = try makeStoreURL()
        try writeV1Store(at: url)

        let container = try PersistenceStack.makeContainer(storeURL: url)
        let records = try ModelContext(container).fetch(FetchDescriptor<ConsultationRecord>())

        XCTAssertEqual(records.count, 2)
        XCTAssertTrue(records.allSatisfy { $0.serverVersion == 0 })
    }

    func test_migrationFromV1_preservesOutboxOrder_andKeepsAppending() async throws {
        let url = try makeStoreURL()
        try writeV1Store(at: url)
        let container = try PersistenceStack.makeContainer(storeURL: url)
        let outbox = OutboxStore(modelContainer: container)

        let pending = try await outbox.pending()
        XCTAssertEqual(pending, expectedEntries)

        let next = makeEntry(id: 3, entityID: 3)
        try await outbox.enqueue(next)
        let afterEnqueue = try await outbox.pending()
        XCTAssertEqual(afterEnqueue, expectedEntries + [next])
    }

    func test_migratedStore_acceptsNewWrites() async throws {
        let url = try makeStoreURL()
        try writeV1Store(at: url)
        let container = try PersistenceStack.makeContainer(storeURL: url)
        let store = ConsultationStore(modelContainer: container)
        let added = makeConsultation(id: 3)

        try await store.upsert([added])
        let loaded = try await store.consultations()

        XCTAssertEqual(Set(loaded), Set(expectedConsultations + [added]))
    }

    func test_reopeningMigratedStore_keepsData() async throws {
        let url = try makeStoreURL()
        try writeV1Store(at: url)

        _ = try await readConsultations(at: url)
        let reopened = try await readConsultations(at: url)

        XCTAssertEqual(Set(reopened), Set(expectedConsultations))
    }
    
    // MARK: - V2 to V3

    func test_migrationFromV2_preservesConsultationsOutboxAndServerVersion() async throws {
        let url = try makeStoreURL()
        try writeV2Store(at: url)
        let container = try PersistenceStack.makeContainer(storeURL: url)

        let records = try ModelContext(container).fetch(FetchDescriptor<ConsultationRecord>())
        let consultations = try await ConsultationStore(modelContainer: container).consultations()
        let pending = try await OutboxStore(modelContainer: container).pending()

        XCTAssertEqual(records.map(\.serverVersion), [4])
        XCTAssertEqual(consultations, [makeConsultation(id: 1, doctorName: "Dr. V2", at: 700)])
        XCTAssertEqual(pending, [makeEntry(id: 1, entityID: 1, kind: "consultation.cancel", payload: "v2")])
    }

    func test_migrationFromV2_allowsBookingAppointments_afterExistingOutboxEntries() async throws {
        let url = try makeStoreURL()
        try writeV2Store(at: url)
        let container = try PersistenceStack.makeContainer(storeURL: url)
        let store = AppointmentStore(modelContainer: container)
        let appointment = makeAppointment(id: 50)

        try await store.book(appointment)
        let stored = try await store.appointments()
        let pending = try await OutboxStore(modelContainer: container).pending()

        XCTAssertEqual(stored, [appointment])
        XCTAssertEqual(pending.map(\.id), [makeUUID(1), appointment.id])
    }

    // MARK: - V3 to V4

    func test_migrationFromV3_preservesAppointmentsConsultationsAndOutbox() async throws {
        let url = try makeStoreURL()
        try writeV3Store(at: url)
        let container = try PersistenceStack.makeContainer(storeURL: url)

        let appointments = try await AppointmentStore(modelContainer: container).appointments()
        let consultations = try await ConsultationStore(modelContainer: container).consultations()
        let pending = try await OutboxStore(modelContainer: container).pending()

        XCTAssertEqual(appointments, [makeAppointment(id: 1, doctorName: "Dr. V3", at: 800)])
        XCTAssertEqual(consultations, [makeConsultation(id: 1, doctorName: "Dr. V3", at: 700)])
        XCTAssertEqual(pending.map(\.id), [makeUUID(1)])
    }

    func test_migrationFromV3_allowsSavingMedicationReminders() async throws {
        let url = try makeStoreURL()
        try writeV3Store(at: url)
        let container = try PersistenceStack.makeContainer(storeURL: url)
        let store = MedicationStore(modelContainer: container)
        let reminder = makeReminder(id: 5)

        try await store.save(reminder)
        let loaded = try await store.reminders()

        XCTAssertEqual(loaded, [reminder])
    }

    // MARK: - On-disk store without migration

    func test_makeContainer_persistsDataAcrossReopen() async throws {
        let url = try makeStoreURL()
        let consultation = makeConsultation(id: 7)

        let container = try PersistenceStack.makeContainer(storeURL: url)
        try await ConsultationStore(modelContainer: container).upsert([consultation])

        let loaded = try await readConsultations(at: url)

        XCTAssertEqual(loaded, [consultation])
    }

    // MARK: - Helpers

    private func makeStoreURL() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("sehat-migration-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: directory) }
        return directory.appendingPathComponent("store.sqlite")
    }

    /// Writes rows with the frozen V1 schema, then lets the container go out
    /// of scope so the store can be reopened with the current schema.
    private func writeV1Store(at url: URL) throws {
        let schema = Schema(versionedSchema: SehatSchemaV1.self)
        let container = try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
        )
        let context = ModelContext(container)

        context.insert(SehatSchemaV1.ConsultationRecord(
            id: makeUUID(1), doctorName: "Dr. A", specialty: "General",
            channelRaw: "video", statusRaw: "in_progress",
            scheduledAt: Date(timeIntervalSince1970: 500)
        ))
        context.insert(SehatSchemaV1.ConsultationRecord(
            id: makeUUID(2), doctorName: "Dr. B", specialty: "General",
            channelRaw: "voice", statusRaw: "completed",
            scheduledAt: Date(timeIntervalSince1970: 600)
        ))
        // Inserted out of order on purpose: `sequence` decides the FIFO order.
        context.insert(SehatSchemaV1.OutboxRecord(
            id: makeUUID(2), sequence: 2, entityID: makeUUID(2),
            kind: "consultation.cancel", payload: Data("b".utf8)
        ))
        context.insert(SehatSchemaV1.OutboxRecord(
            id: makeUUID(1), sequence: 1, entityID: makeUUID(1),
            kind: "consultation.cancel", payload: Data("a".utf8)
        ))
        try context.save()
    }

    private func readConsultations(at url: URL) async throws -> [Consultation] {
        let container = try PersistenceStack.makeContainer(storeURL: url)
        return try await ConsultationStore(modelContainer: container).consultations()
    }
    
    /// Writes rows with the frozen V2 schema (before appointments existed).
    private func writeV2Store(at url: URL) throws {
        let schema = Schema(versionedSchema: SehatSchemaV2.self)
        let container = try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
        )
        let context = ModelContext(container)
        context.insert(SehatSchemaV2.ConsultationRecord(
            id: makeUUID(1), doctorName: "Dr. V2", specialty: "General",
            channelRaw: "chat", statusRaw: "scheduled",
            scheduledAt: Date(timeIntervalSince1970: 700), serverVersion: 4
        ))
        context.insert(SehatSchemaV2.OutboxRecord(
            id: makeUUID(1), sequence: 1, entityID: makeUUID(1),
            kind: "consultation.cancel", payload: Data("v2".utf8)
        ))
        try context.save()
    }
    
    /// Writes rows with the frozen V3 schema (before medication reminders existed).
    private func writeV3Store(at url: URL) throws {
        let schema = Schema(versionedSchema: SehatSchemaV3.self)
        let container = try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
        )
        let context = ModelContext(container)
        context.insert(SehatSchemaV3.ConsultationRecord(
            id: makeUUID(1), doctorName: "Dr. V3", specialty: "General",
            channelRaw: "chat", statusRaw: "scheduled",
            scheduledAt: Date(timeIntervalSince1970: 700)
        ))
        context.insert(SehatSchemaV3.AppointmentRecord(
            id: makeUUID(1), doctorName: "Dr. V3", specialty: "General",
            startsAt: Date(timeIntervalSince1970: 800), statusRaw: "pending"
        ))
        context.insert(SehatSchemaV3.OutboxRecord(
            id: makeUUID(1), sequence: 1, entityID: makeUUID(1),
            kind: "appointment.book", payload: Data("v3".utf8)
        ))
        try context.save()
    }
}
