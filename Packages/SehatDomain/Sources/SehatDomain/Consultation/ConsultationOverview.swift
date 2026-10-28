//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

/// Consultations split for the list screen.
public struct ConsultationOverview: Sendable, Equatable {
    /// Active consultations, soonest first.
    public let upcoming: [Consultation]
    /// Finished or cancelled consultations, most recent first.
    public let history: [Consultation]

    public var isEmpty: Bool {
        upcoming.isEmpty && history.isEmpty
    }

    public init(upcoming: [Consultation], history: [Consultation]) {
        self.upcoming = upcoming
        self.history = history
    }
}
