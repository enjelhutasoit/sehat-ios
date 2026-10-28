//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import SehatCore
import SwiftData

/// SwiftData-backed `OutboxQueue`. All access is confined to this actor.
///
/// Contract: throws `AppError` only.
public actor OutboxStore: ModelActor, OutboxQueue {
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

    public func enqueue(_ entry: OutboxEntry) async throws {
        do {
            let targetID = entry.id
            var existing = FetchDescriptor<OutboxRecord>(
                predicate: #Predicate<OutboxRecord> { $0.id == targetID }
            )
            existing.fetchLimit = 1
            guard try modelContext.fetch(existing).isEmpty else { return }

            var latest = FetchDescriptor<OutboxRecord>(
                sortBy: [SortDescriptor(\OutboxRecord.sequence, order: .reverse)]
            )
            latest.fetchLimit = 1
            let nextSequence = (try modelContext.fetch(latest).first?.sequence ?? 0) + 1

            modelContext.insert(OutboxRecord(entry, sequence: nextSequence))
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw errorMapper.map(error)
        }
    }

    public func pending() async throws -> [OutboxEntry] {
        do {
            let descriptor = FetchDescriptor<OutboxRecord>(
                sortBy: [SortDescriptor(\OutboxRecord.sequence)]
            )
            return try modelContext.fetch(descriptor).map { $0.toEntry() }
        } catch {
            throw errorMapper.map(error)
        }
    }

    public func remove(id: UUID) async throws {
        do {
            let targetID = id
            let matches = try modelContext.fetch(
                FetchDescriptor<OutboxRecord>(
                    predicate: #Predicate<OutboxRecord> { $0.id == targetID }
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
