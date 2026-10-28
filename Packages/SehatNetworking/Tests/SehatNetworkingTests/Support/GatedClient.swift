//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import SehatNetworking

/// Test double whose calls stay suspended until the test completes, fails
/// or cancels them. Lets tests control timing without sleeping.
actor GatedClient: HTTPClient {
    private(set) var callCount = 0
    private(set) var cancelledCallCount = 0
    private var pending: [UUID: CheckedContinuation<HTTPResponse, Error>] = [:]

    var pendingCount: Int { pending.count }

    func send(_ request: HTTPRequest) async throws -> HTTPResponse {
        callCount += 1
        let id = UUID()
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                pending[id] = continuation
            }
        } onCancel: {
            Task { await self.cancel(id) }
        }
    }

    func complete(with response: HTTPResponse) {
        let all = pending
        pending = [:]
        for continuation in all.values {
            continuation.resume(returning: response)
        }
    }

    func fail(with error: Error) {
        let all = pending
        pending = [:]
        for continuation in all.values {
            continuation.resume(throwing: error)
        }
    }

    private func cancel(_ id: UUID) {
        guard let continuation = pending.removeValue(forKey: id) else { return }
        cancelledCallCount += 1
        continuation.resume(throwing: CancellationError())
    }
}
