//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import SehatDomain

/// Sends one outbox entry to the server.
///
/// Contract: send `entry.id` as the idempotency key; throw `AppError` only.
public protocol OutboxSender: Sendable {
    func send(_ entry: OutboxEntry) async throws
}

/// Source of consultations from the server.
///
/// May return a full snapshot or a page. The sync engine never deletes local
/// data because a record is missing from the result.
/// Contract: throws `AppError` only.
public protocol ConsultationRemote: Sendable {
    func fetchConsultations() async throws -> [Consultation]
}

/// Local write access used by the sync engine. `ConsultationStore` conforms.
///
/// Contract: throws `AppError` only.
public protocol ConsultationWriting: Sendable {
    func upsert(_ consultations: [Consultation]) async throws
}
