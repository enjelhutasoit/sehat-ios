//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

public enum DiagnosticKind: String, Sendable, CaseIterable {
    /// Aggregated performance metrics.
    case metrics
    /// Crash, hang and similar diagnostics.
    case diagnostics
}

/// One archived payload. Created only by `FileDiagnosticsArchive`.
public struct DiagnosticRecord: Sendable, Equatable, Identifiable {
    /// File name inside the archive directory.
    public let id: String
    public let kind: DiagnosticKind
    /// When the payload was archived, in whole seconds.
    public let receivedAt: Date
}
