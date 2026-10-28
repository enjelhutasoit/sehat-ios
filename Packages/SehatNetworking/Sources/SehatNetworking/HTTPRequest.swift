//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

public enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"

    /// Safe to repeat without changing the outcome. Only these methods are
    /// retried automatically.
    public var isIdempotent: Bool {
        switch self {
        case .get, .put, .delete: return true
        case .post, .patch: return false
        }
    }
}

public struct HTTPRequest: Sendable, Hashable {
    public var url: URL
    public var method: HTTPMethod
    public var headers: [String: String]
    public var body: Data?
    /// Seconds. Defaults to 30 (the `URLRequest` default is 60).
    public var timeout: TimeInterval

    public init(
        url: URL,
        method: HTTPMethod = .get,
        headers: [String: String] = [:],
        body: Data? = nil,
        timeout: TimeInterval = 30
    ) {
        self.url = url
        self.method = method
        self.headers = headers
        self.body = body
        self.timeout = timeout
    }
}
