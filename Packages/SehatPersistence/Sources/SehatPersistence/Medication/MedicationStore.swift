//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import SwiftData
import SehatCore
import SehatDomain

/// Local medication reminder storage. All SwiftData access is confined to
/// this actor, and only domain entities leave it.
///
/// Contract: throws `AppError` only. Reminders are device-local: no outbox.
public actor MedicationStore: ModelActor, MedicationReminderRepository {
    public nonisolated let modelContainer: ModelContainer
    public nonisolated let modelExecutor: any ModelExecutor
    private let errorMapper: any ErrorMapping

    public init(
        modelContainer: ModelContainer,
        errorMapper: any ErrorMapping = StorageErrorMapper()
    ) {
        let context = ModelContext(modelContainer)
        self.modelContainer = modelContainer
        self.modelExecutor = DefaultSerialModelExecutor(modelContext: context)
        self.errorMapper = errorMapper
    }

    public func reminders() async throws -> [MedicationReminder] {
        do {
            let records = try modelContext.fetch(FetchDescriptor<MedicationReminderRecord>())
            return try records.map { try $0.toDomain() }
        } catch {
            throw errorMapper.map(error)
        }
    }

    public func save(_ reminder: MedicationReminder) async throws {
        do {
            let targetID = reminder.id
            var descriptor = FetchDescriptor<MedicationReminderRecord>(
                predicate: #Predicate<MedicationReminderRecord> { $0.id == targetID }
            )
            descriptor.fetchLimit = 1

            if let record = try modelContext.fetch(descriptor).first {
                record.update(from: reminder)
            } else {
                modelContext.insert(MedicationReminderRecord(reminder))
            }
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw errorMapper.map(error)
        }
    }

    public func delete(id: MedicationReminder.ID) async throws {
        do {
            let targetID = id
            let matches = try modelContext.fetch(
                FetchDescriptor<MedicationReminderRecord>(
                    predicate: #Predicate<MedicationReminderRecord> { $0.id == targetID }
                )
            )
            guard !matches.isEmpty else { return }

            for record in matches {
                modelContext.delete(record)
            }
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw errorMapper.map(error)
        }
    }
}
