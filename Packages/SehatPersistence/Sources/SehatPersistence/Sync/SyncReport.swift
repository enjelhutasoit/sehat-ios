//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import SehatCore

/// Outcome of sending the outbox.
public struct PushReport: Sendable, Equatable {
    public struct Rejection: Sendable, Equatable {
        public let entry: OutboxEntry
        public let error: AppError

        public init(entry: OutboxEntry, error: AppError) {
            self.entry = entry
            self.error = error
        }
    }

    /// Entries the server accepted; already removed from the queue.
    public let sentEntryIDs: [UUID]
    /// Entries the server refused permanently. They are removed from the
    /// queue and are not stored anywhere else: the caller must handle them.
    public let rejections: [Rejection]
    /// Set when sending stopped early; the remaining entries stay queued.
    public let stoppedBy: AppError?

    public init(sentEntryIDs: [UUID], rejections: [Rejection], stoppedBy: AppError?) {
        self.sentEntryIDs = sentEntryIDs
        self.rejections = rejections
        self.stoppedBy = stoppedBy
    }
}

public struct SyncReport: Sendable, Equatable {
    public let push: PushReport
    /// Number of consultations written by the pull; `nil` when the pull was skipped.
    public let pulledCount: Int?

    public init(push: PushReport, pulledCount: Int?) {
        self.push = push
        self.pulledCount = pulledCount
    }
}
