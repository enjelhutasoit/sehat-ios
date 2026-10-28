//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

/// A write the user made while offline, waiting to be sent to the server.
public struct OutboxEntry: Sendable, Equatable, Identifiable {
    /// Unique per entry. Send it as the idempotency key so a repeated send
    /// has no extra effect.
    public let id: UUID
    /// The record this entry changes. Used to protect it during a pull.
    public let entityID: UUID
    /// Operation name, namespaced by entity (for example "consultation.cancel").
    public let kind: String
    public let payload: Data

    public init(id: UUID, entityID: UUID, kind: String, payload: Data) {
        self.id = id
        self.entityID = entityID
        self.kind = kind
        self.payload = payload
    }
}
