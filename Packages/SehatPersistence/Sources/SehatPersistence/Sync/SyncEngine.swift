//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import SehatCore

/// Sends pending writes, then merges server data into local storage.
///
/// Stateless. Callers should not run `sync()` concurrently: idempotency keys
/// make a duplicate send harmless, but the work is wasted.
/// Contract: throws `AppError` only.
public struct SyncEngine: Sendable {
    private let outbox: any OutboxQueue
    private let sender: any OutboxSender
    private let remote: any ConsultationRemote
    private let local: any ConsultationWriting
    private let conflictPolicy: any ConflictPolicy
    private let errorMapper: any ErrorMapping

    public init(
        outbox: any OutboxQueue,
        sender: any OutboxSender,
        remote: any ConsultationRemote,
        local: any ConsultationWriting,
        conflictPolicy: any ConflictPolicy = LocalPendingWinsPolicy(),
        errorMapper: any ErrorMapping = DefaultErrorMapper()
    ) {
        self.outbox = outbox
        self.sender = sender
        self.remote = remote
        self.local = local
        self.conflictPolicy = conflictPolicy
        self.errorMapper = errorMapper
    }

    /// Pushes, then pulls. The pull is skipped when the push stopped early,
    /// because the cause is usually connectivity or authentication.
    public func sync() async throws -> SyncReport {
        let push = try await pushPending()
        guard push.stoppedBy == nil else {
            return SyncReport(push: push, pulledCount: nil)
        }
        return SyncReport(push: push, pulledCount: try await pull())
    }

    /// Sends entries oldest first.
    /// - Retryable failures and `.unauthorized` stop the run; the rest stays queued.
    /// - Other failures reject only that entry and the run continues.
    /// - Cancellation throws `AppError.cancelled` and keeps the entry queued.
    public func pushPending() async throws -> PushReport {
        let entries = try await mapped { try await outbox.pending() }
        var sent: [UUID] = []
        var rejections: [PushReport.Rejection] = []

        for entry in entries {
            if let failure = await attemptSend(entry) {
                if failure == .cancelled { throw AppError.cancelled }
                if Self.shouldStop(after: failure) {
                    return PushReport(sentEntryIDs: sent, rejections: rejections, stoppedBy: failure)
                }
                rejections.append(PushReport.Rejection(entry: entry, error: failure))
            } else {
                sent.append(entry.id)
            }
            try await mapped { try await outbox.remove(id: entry.id) }
        }
        return PushReport(sentEntryIDs: sent, rejections: rejections, stoppedBy: nil)
    }

    /// Fetches remote consultations and writes those the conflict policy allows.
    /// Pending entries are read after the fetch to keep the race window small.
    /// - Returns: the number of consultations written.
    public func pull() async throws -> Int {
        let remoteItems = try await mapped { try await remote.fetchConsultations() }
        let pending = try await mapped { try await outbox.pending() }

        let accepted = conflictPolicy.resolve(
            remote: remoteItems,
            pendingEntityIDs: Set(pending.map(\.entityID))
        )
        try await mapped { try await local.upsert(accepted) }
        return accepted.count
    }

    // MARK: - Private

    private func attemptSend(_ entry: OutboxEntry) async -> AppError? {
        do {
            try await sender.send(entry)
            return nil
        } catch {
            return errorMapper.map(error)
        }
    }

    private func mapped<T>(_ operation: () async throws -> T) async throws -> T {
        do {
            return try await operation()
        } catch {
            throw errorMapper.map(error)
        }
    }

    private static func shouldStop(after error: AppError) -> Bool {
        error.isRetryable || error == .unauthorized
    }
}
