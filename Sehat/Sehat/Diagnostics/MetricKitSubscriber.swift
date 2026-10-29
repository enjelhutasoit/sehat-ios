//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import MetricKit
import SehatDiagnostics

/// Hands MetricKit payloads to the archive. Thin glue, not unit-tested:
/// MetricKit payload types cannot be created in tests.
final class MetricKitSubscriber: NSObject, MXMetricManagerSubscriber {
    private let archive: FileDiagnosticsArchive

    init(archive: FileDiagnosticsArchive) {
        self.archive = archive
    }

    func didReceive(_ payloads: [MXMetricPayload]) {
        store(payloads.map { $0.jsonRepresentation() }, kind: .metrics)
    }

    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        store(payloads.map { $0.jsonRepresentation() }, kind: .diagnostics)
    }

    private func store(_ documents: [Data], kind: DiagnosticKind) {
        let archive = self.archive
        Task {
            for document in documents {
                // No logging yet: a failed write is dropped.
                _ = try? await archive.save(document, kind: kind)
            }
        }
    }
}
