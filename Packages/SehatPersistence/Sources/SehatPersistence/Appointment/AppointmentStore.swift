//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import SehatCore
import SehatDomain
import SwiftData

/// Local appointment storage. Booking writes the appointment and its outbox
/// entry in one context and one `save()`, so both exist or neither does.
///
/// Contract: throws `AppError` only. Autosave is off to rule out partial saves.
public actor AppointmentStore: ModelActor, AppointmentRepository {
    public nonisolated let modelContainer: ModelContainer
    public nonisolated let modelExecutor: any ModelExecutor
    private let errorMapper: any ErrorMapping

    public init(
        modelContainer: ModelContainer,
        errorMapper: any ErrorMapping = StorageErrorMapper()
    ) {
        let context = ModelContext(modelContainer)
        context.autosaveEnabled = false
        self.modelContainer = modelContainer
        self.modelExecutor = DefaultSerialModelExecutor(modelContext: context)
        self.errorMapper = errorMapper
    }

    public func appointments() async throws -> [Appointment] {
        do {
            let records = try modelContext.fetch(FetchDescriptor<AppointmentRecord>())
            return try records.map { try $0.toDomain() }
        } catch {
            throw errorMapper.map(error)
        }
    }

    public func book(_ appointment: Appointment) async throws {
        do {
            let targetID = appointment.id
            var existing = FetchDescriptor<AppointmentRecord>(
                predicate: #Predicate<AppointmentRecord> { $0.id == targetID }
            )
            existing.fetchLimit = 1
            guard try modelContext.fetch(existing).isEmpty else { return }

            let entry = try AppointmentOutbox.bookEntry(for: appointment)
            modelContext.insert(AppointmentRecord(appointment))
            try modelContext.appendToOutbox(entry)
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw errorMapper.map(error)
        }
    }
}
