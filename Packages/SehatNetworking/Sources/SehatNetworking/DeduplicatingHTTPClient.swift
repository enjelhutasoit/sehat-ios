//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import SehatCore

/// Decorator that shares one in-flight GET among identical concurrent
/// callers. Not a cache: nothing is kept after the call completes.
///
/// Cancellation is reference counted: a cancelled caller returns
/// immediately with `AppError.cancelled`, and the shared call is cancelled
/// only when no caller is left waiting.
public actor DeduplicatingHTTPClient: HTTPClient {
    private struct Entry {
        let id: UUID
        let task: Task<Void, Never>
        var waiters: [UUID: CheckedContinuation<HTTPResponse, Error>]
    }

    private let base: any HTTPClient
    private let errorMapper: any ErrorMapping
    private var entries: [HTTPRequest: Entry] = [:]

    public init(
        base: any HTTPClient,
        errorMapper: any ErrorMapping = DefaultErrorMapper()
    ) {
        self.base = base
        self.errorMapper = errorMapper
    }

    public func send(_ request: HTTPRequest) async throws -> HTTPResponse {
        guard request.method == .get else {
            return try await base.send(request)
        }
        guard !Task.isCancelled else {
            throw AppError.cancelled
        }

        let waiterID = UUID()
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                register(request, waiterID: waiterID, continuation: continuation)
            }
        } onCancel: {
            Task { await self.cancelWaiter(for: request, waiterID: waiterID) }
        }
    }

    /// Test hook: number of callers currently waiting on `request`.
    func waiterCount(for request: HTTPRequest) -> Int {
        entries[request]?.waiters.count ?? 0
    }

    // MARK: - State changes (synchronous on purpose: no suspension points)

    private func register(
        _ request: HTTPRequest,
        waiterID: UUID,
        continuation: CheckedContinuation<HTTPResponse, Error>
    ) {
        if var entry = entries[request] {
            entry.waiters[waiterID] = continuation
            entries[request] = entry
            return
        }

        let entryID = UUID()
        let task = Task { await self.execute(request, entryID: entryID) }
        entries[request] = Entry(id: entryID, task: task, waiters: [waiterID: continuation])
    }

    private func cancelWaiter(for request: HTTPRequest, waiterID: UUID) {
        guard var entry = entries[request],
              let continuation = entry.waiters.removeValue(forKey: waiterID)
        else { return }

        continuation.resume(throwing: AppError.cancelled)

        if entry.waiters.isEmpty {
            entries[request] = nil
            entry.task.cancel()
        } else {
            entries[request] = entry
        }
    }

    private func finish(
        _ request: HTTPRequest,
        entryID: UUID,
        result: Result<HTTPResponse, Error>
    ) {
        // Ignore a stale call whose entry was already cancelled or replaced.
        guard let entry = entries[request], entry.id == entryID else { return }

        entries[request] = nil
        for continuation in entry.waiters.values {
            continuation.resume(with: result)
        }
    }

    private func execute(_ request: HTTPRequest, entryID: UUID) async {
        let result: Result<HTTPResponse, Error>
        do {
            result = .success(try await base.send(request))
        } catch {
            result = .failure(errorMapper.map(error))
        }
        finish(request, entryID: entryID, result: result)
    }
}
