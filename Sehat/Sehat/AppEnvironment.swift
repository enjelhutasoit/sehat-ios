//
// Copyright (c) 2026 Enjel Hutasoit
//

import SehatPersistence
import SwiftData

/// Builds shared dependencies once. Reachable without any UI, because the
/// system can launch the app in the background, with no scene and no views.
actor AppEnvironment {
    static let shared = AppEnvironment()

    private var cachedContainer: ModelContainer?

    /// A failed attempt is not cached; the next call tries again.
    func container() throws -> ModelContainer {
        if let cachedContainer { return cachedContainer }
        let container = try PersistenceStack.makeContainer()
        cachedContainer = container
        return container
    }
}
