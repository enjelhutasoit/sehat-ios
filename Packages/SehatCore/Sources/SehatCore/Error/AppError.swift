//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

/// App-wide error taxonomy, shaped by what the app does in response,
/// not by where the error came from.
///
/// The original error is intentionally not stored: log it at the mapping
/// site. This keeps `AppError` `Equatable` and `Sendable`.
public enum AppError: Error, Sendable, Equatable {
    /// No usable connection. Candidate for the offline outbox.
    case offline
    case timedOut
    /// Non-success HTTP status not covered by a more specific case.
    case server(statusCode: Int)
    case unauthorized
    case notFound
    case decoding
    case storage
    /// Usually not shown to the user.
    case cancelled
    case unknown

    /// `true` when the failure is transient and trying again later can succeed.
    public var isRetryable: Bool {
        switch self {
        case .offline, .timedOut:
            return true
        case .server(let statusCode):
            return statusCode == 408
                || statusCode == 429
                || (500...599).contains(statusCode)
        case .unauthorized, .notFound, .decoding, .storage, .cancelled, .unknown:
            return false
        }
    }

    /// Key for the string catalog. The core package stays language-agnostic.
    public var localizationKey: String {
        switch self {
        case .offline: return "error.offline"
        case .timedOut: return "error.timed_out"
        case .server: return "error.server"
        case .unauthorized: return "error.unauthorized"
        case .notFound: return "error.not_found"
        case .decoding: return "error.decoding"
        case .storage: return "error.storage"
        case .cancelled: return "error.cancelled"
        case .unknown: return "error.unknown"
        }
    }
}
