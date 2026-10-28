//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import SehatDomain

/// Decides which remote consultations may overwrite local data.
public protocol ConflictPolicy: Sendable {
    func resolve(
        remote: [Consultation],
        pendingEntityIDs: Set<Consultation.ID>
    ) -> [Consultation]
}

/// Local changes that are not sent yet are protected; otherwise the server wins.
///
/// Chosen because last-write-wins needs server timestamps or versions that
/// the data model does not have yet.
public struct LocalPendingWinsPolicy: ConflictPolicy {
    public init() {}

    public func resolve(
        remote: [Consultation],
        pendingEntityIDs: Set<Consultation.ID>
    ) -> [Consultation] {
        remote.filter { !pendingEntityIDs.contains($0.id) }
    }
}
