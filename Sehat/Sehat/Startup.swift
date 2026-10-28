//
// Copyright (c) 2026 Enjel Hutasoit
//

import SehatConsultation
import SehatPersistence
import SwiftData

/// Composition root: builds storage and the coordinator.
/// If storage cannot be opened it reports `.failed` and deletes nothing.
/// There is no logging yet, so the cause is not recorded.
@MainActor
enum Startup {
    case loading
    case ready(ConsultationCoordinator)
    case failed

    static func make() async -> Startup {
        do {
            let container = try PersistenceStack.makeContainer()
            let store = ConsultationStore(modelContainer: container)
            try await store.upsert(SampleData.consultations())
            return .ready(ConsultationCoordinator(repository: store))
        } catch {
            return .failed
        }
    }
}
