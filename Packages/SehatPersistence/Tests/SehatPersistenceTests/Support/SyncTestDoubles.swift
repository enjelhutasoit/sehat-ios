//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import SehatCore
import SehatDomain
import SehatPersistence

actor OutboxFake: OutboxQueue {
    private(set) var entries: [OutboxEntry]
    private let failure: AppError?

    init(entries: [OutboxEntry] = [], failure: AppError? = nil) {
        self.entries = entries
        self.failure = failure
    }

    func enqueue(_ entry: OutboxEntry) async throws {
        try failIfNeeded()
        entries.append(entry)
    }

    func pending() async throws -> [OutboxEntry] {
        try failIfNeeded()
        return entries
    }

    func remove(id: UUID) async throws {
        try failIfNeeded()
        entries.removeAll { $0.id == id }
    }

    private func failIfNeeded() throws {
        if let failure { throw failure }
    }
}

actor SenderStub: OutboxSender {
    private let failures: [UUID: Error]
    private(set) var attemptedIDs: [UUID] = []

    init(failures: [UUID: Error] = [:]) {
        self.failures = failures
    }

    func send(_ entry: OutboxEntry) async throws {
        attemptedIDs.append(entry.id)
        if let error = failures[entry.id] { throw error }
    }
}

struct RemoteStub: ConsultationRemote {
    let result: Result<[Consultation], Error>

    func fetchConsultations() async throws -> [Consultation] {
        try result.get()
    }
}

actor LocalSpy: ConsultationWriting {
    private let failure: Error?
    private(set) var upserts: [[Consultation]] = []

    init(failure: Error? = nil) {
        self.failure = failure
    }

    func upsert(_ consultations: [Consultation]) async throws {
        if let failure { throw failure }
        upserts.append(consultations)
    }
}

struct FirstOnlyPolicy: ConflictPolicy {
    func resolve(
        remote: [Consultation],
        pendingEntityIDs: Set<Consultation.ID>
    ) -> [Consultation] {
        Array(remote.prefix(1))
    }
}
