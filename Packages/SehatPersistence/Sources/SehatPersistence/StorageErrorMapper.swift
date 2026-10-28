//
// Copyright (c) 2026 Enjel Hutasoit
//

import SehatCore

/// Maps errors thrown by the storage layer to `AppError`.
public struct StorageErrorMapper: ErrorMapping {
    public init() {}

    public func map(_ error: Error) -> AppError {
        switch error {
        case let appError as AppError:
            return appError
        case is CancellationError:
            return .cancelled
        default:
            return .storage
        }
    }
}
