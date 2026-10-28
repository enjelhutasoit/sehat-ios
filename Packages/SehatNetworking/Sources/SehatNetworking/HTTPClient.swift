//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

/// Sends an HTTP request and returns the response.
///
/// Contract: implementations throw `AppError` only.
public protocol HTTPClient: Sendable {
    func send(_ request: HTTPRequest) async throws -> HTTPResponse
}
