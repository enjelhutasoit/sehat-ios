//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
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
        let container = try makeContainer()
        cachedContainer = container
        return container
    }

    private func makeContainer() throws -> ModelContainer {
        let configuration = LaunchConfiguration()
        guard configuration.isUITesting else {
            return try PersistenceStack.makeContainer()
        }

        // UI tests get their own store. A reset can only ever delete this one,
        // never the real store, because it is the only URL the reset receives.
        let storeURL = try Self.uiTestingStoreURL()
        if configuration.resetsUITestingData {
            try PersistenceStack.removeStoreFiles(at: storeURL)
        }
        return try PersistenceStack.makeContainer(storeURL: storeURL)
    }

    private static func uiTestingStoreURL() throws -> URL {
        let base = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = base.appendingPathComponent("UITesting", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("store.sqlite")
    }
}
