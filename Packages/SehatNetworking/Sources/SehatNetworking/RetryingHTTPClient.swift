//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import SehatCore

/// Decorator that retries transient failures of idempotent requests,
/// following a `RetryPolicy`.
public struct RetryingHTTPClient: HTTPClient {
    public typealias Wait = @Sendable (TimeInterval) async throws -> Void

    private let base: any HTTPClient
    private let policy: RetryPolicy
    private let errorMapper: any ErrorMapping
    private let wait: Wait

    public init(
        base: any HTTPClient,
        policy: RetryPolicy,
        errorMapper: any ErrorMapping = DefaultErrorMapper(),
        wait: @escaping Wait = RetryingHTTPClient.liveWait
    ) {
        self.base = base
        self.policy = policy
        self.errorMapper = errorMapper
        self.wait = wait
    }

    public func send(_ request: HTTPRequest) async throws -> HTTPResponse {
        var failureCount = 0
        while true {
            do {
                return try await base.send(request)
            } catch {
                let appError = errorMapper.map(error)
                failureCount += 1

                guard request.method.isIdempotent,
                      appError.isRetryable,
                      let delay = policy.delay(afterFailureCount: failureCount)
                else {
                    throw appError
                }
                try await pause(for: delay)
            }
        }
    }

    private func pause(for delay: TimeInterval) async throws {
        do {
            try await wait(delay)
        } catch {
            throw errorMapper.map(error)
        }
    }

    /// Real-time wait. Capped at one hour so the nanosecond conversion cannot overflow.
    public static let liveWait: Wait = { seconds in
        let clamped = min(max(seconds, 0), 3_600)
        try await Task.sleep(nanoseconds: UInt64(clamped * 1_000_000_000))
    }
}
