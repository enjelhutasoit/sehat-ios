//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

/// Thin seam over `URLSession` so the HTTP client can be tested without a network.
public protocol HTTPTransport: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

/// Production transport. Pure pass-through; intentionally has no logic.
public struct URLSessionTransport: HTTPTransport {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }
}
