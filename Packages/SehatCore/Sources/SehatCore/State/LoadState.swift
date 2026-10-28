//
// Copyright (c) 2026 Enjel Hutasoit
//

/// State of a screen that loads one value. UI-free, so features can share it.
public enum LoadState<Value: Sendable & Equatable>: Sendable, Equatable {
    case idle
    case loading
    case loaded(Value)
    case failed(AppError)

    public var value: Value? {
        if case .loaded(let value) = self { return value }
        return nil
    }

    /// State to show while a load runs. Existing content stays visible.
    public func startingLoad() -> LoadState {
        value == nil ? .loading : self
    }

    /// State after a failed load. Cancellation is not an error: the state
    /// from before the load is restored.
    public static func afterFailure(_ error: Error, restoring previous: LoadState) -> LoadState {
        let appError = DefaultErrorMapper().map(error)
        return appError == .cancelled ? previous : .failed(appError)
    }
}
