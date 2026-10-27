//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

/// Describes how often a failed operation may be attempted and how long to
/// wait before each retry.
///
/// Pure value type: it only computes delays. Sleeping, error classification
/// and jitter belong to the caller.
public struct RetryPolicy: Sendable, Equatable {
    /// Maximum number of total attempts, including the first one.
    public let maxAttempts: Int
    /// Delay before the first retry, in seconds.
    public let baseDelay: TimeInterval
    /// Growth factor applied after every failure. Always >= 1.
    public let multiplier: Double
    /// Upper bound for any delay, in seconds. Always >= `baseDelay`.
    public let maxDelay: TimeInterval

    /// Invalid input is normalized instead of trapping: negative or
    /// non-finite delays become 0, `multiplier` is at least 1, `maxDelay` is
    /// at least `baseDelay`, and `maxAttempts` is at least 0.
    public init(
        maxAttempts: Int,
        baseDelay: TimeInterval,
        multiplier: Double = 2,
        maxDelay: TimeInterval
    ) {
        let sanitizedBase = Self.nonNegativeFinite(baseDelay)
        self.maxAttempts = max(0, maxAttempts)
        self.baseDelay = sanitizedBase
        self.multiplier = multiplier.isFinite ? max(1, multiplier) : 1
        self.maxDelay = max(sanitizedBase, Self.nonNegativeFinite(maxDelay))
    }

    /// Delay to wait before the next attempt after `failureCount` failures
    /// (1-based), or `nil` when no further attempt is allowed.
    public func delay(afterFailureCount failureCount: Int) -> TimeInterval? {
        guard failureCount >= 1, failureCount < maxAttempts else { return nil }
        guard baseDelay > 0 else { return 0 }

        let raw = baseDelay * pow(multiplier, Double(failureCount - 1))
        return raw.isFinite ? min(raw, maxDelay) : maxDelay
    }

    private static func nonNegativeFinite(_ value: TimeInterval) -> TimeInterval {
        value.isFinite ? max(0, value) : 0
    }
}
