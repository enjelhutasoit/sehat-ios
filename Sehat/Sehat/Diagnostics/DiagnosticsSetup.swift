//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import MetricKit
import SehatDiagnostics

/// Starts MetricKit collection. Keeps a strong reference to the subscriber.
@MainActor
enum DiagnosticsSetup {
    private static var subscriber: MetricKitSubscriber?

    /// If the support directory is unavailable nothing is collected (no logging yet).
    static func start() {
        guard subscriber == nil,
              let base = try? FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
              )
        else { return }

        let directory = base.appendingPathComponent("Diagnostics", isDirectory: true)
        let subscriber = MetricKitSubscriber(archive: FileDiagnosticsArchive(directory: directory))
        MXMetricManager.shared.add(subscriber)
        self.subscriber = subscriber
    }
}
