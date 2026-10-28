//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import SwiftData
import SehatCore
import SehatDomain

/// Local consultation storage. All SwiftData access happens inside this
/// actor, and only domain entities leave it.
///
/// Contract: throws `AppError` only. No ordering is guaranteed on reads;
/// ordering is a domain rule (see `GetConsultationOverviewUseCase`).
public actor ConsultationStore: ModelActor, ConsultationRepository, ConsultationWriting {
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

    public func consultations() async throws -> [Consultation] {
        do {
            let records = try modelContext.fetch(FetchDescriptor<ConsultationRecord>())
            return try records.map { try $0.toDomain() }
        } catch {
            throw errorMapper.map(error)
        }
    }

    public func consultation(id: Consultation.ID) async throws -> Consultation {
        do {
            let targetID = id
            var descriptor = FetchDescriptor<ConsultationRecord>(
                predicate: #Predicate<ConsultationRecord> { $0.id == targetID }
            )
            descriptor.fetchLimit = 1

            guard let record = try modelContext.fetch(descriptor).first else {
                throw AppError.notFound
            }
            return try record.toDomain()
        } catch {
            throw errorMapper.map(error)
        }
    }

    /// Inserts new consultations and updates existing ones by id.
    /// When the input contains the same id twice, the last item wins.
    public func upsert(_ consultations: [Consultation]) async throws {
        do {
            let existing = try modelContext.fetch(FetchDescriptor<ConsultationRecord>())
            var recordsByID = Dictionary(
                existing.map { ($0.id, $0) },
                uniquingKeysWith: { first, _ in first }
            )

            for consultation in consultations {
                if let record = recordsByID[consultation.id] {
                    record.update(from: consultation)
                } else {
                    let record = ConsultationRecord(consultation)
                    modelContext.insert(record)
                    recordsByID[record.id] = record
                }
            }
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw errorMapper.map(error)
        }
    }
}
