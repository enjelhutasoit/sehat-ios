//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

/// Converts any thrown error into an `AppError`.
///
/// Layers with their own error types (for example persistence) provide
/// their own conformance instead of changing the default mapper.
public protocol ErrorMapping: Sendable {
    func map(_ error: Error) -> AppError
}

/// Maps common Foundation and Swift errors. Anything unrecognized becomes
/// `.unknown`; it never guesses.
public struct DefaultErrorMapper: ErrorMapping {
    public init() {}

    public func map(_ error: Error) -> AppError {
        switch error {
        case let appError as AppError:
            return appError
        case is CancellationError:
            return .cancelled
        case let urlError as URLError:
            return Self.mapURLError(urlError)
        case is DecodingError:
            return .decoding
        default:
            return .unknown
        }
    }

    private static func mapURLError(_ error: URLError) -> AppError {
        switch error.code {
        case .notConnectedToInternet,
             .networkConnectionLost,
             .dataNotAllowed,
             .internationalRoamingOff:
            return .offline
        case .timedOut:
            return .timedOut
        case .cancelled:
            return .cancelled
        default:
            return .unknown
        }
    }
}
