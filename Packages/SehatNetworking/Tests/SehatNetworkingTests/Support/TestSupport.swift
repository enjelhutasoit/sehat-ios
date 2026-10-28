//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import XCTest
import SehatCore
import SehatNetworking

let testURL = URL(string: "https://example.com/api")!

func makeRequest(method: HTTPMethod = .get) -> HTTPRequest {
    HTTPRequest(url: testURL, method: method)
}

func makeResponse(status: Int = 200) -> HTTPResponse {
    HTTPResponse(statusCode: status)
}

func makeHTTPURLResponse(status: Int, headers: [String: String] = [:]) -> HTTPURLResponse {
    guard let response = HTTPURLResponse(
        url: testURL,
        statusCode: status,
        httpVersion: "HTTP/1.1",
        headerFields: headers
    ) else {
        preconditionFailure("Invalid test fixture")
    }
    return response
}

func assertSendFails(
    _ sut: some HTTPClient,
    _ request: HTTPRequest,
    with expected: AppError,
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    do {
        _ = try await sut.send(request)
        XCTFail("Expected \(expected) but send succeeded", file: file, line: line)
    } catch {
        XCTAssertEqual(error as? AppError, expected, file: file, line: line)
    }
}

/// Replays queued results and records every request it receives.
actor ClientStub: HTTPClient {
    private var results: [Result<HTTPResponse, Error>]
    private(set) var sentRequests: [HTTPRequest] = []

    init(results: [Result<HTTPResponse, Error>]) {
        self.results = results
    }

    func send(_ request: HTTPRequest) async throws -> HTTPResponse {
        sentRequests.append(request)
        guard !results.isEmpty else { throw AppError.unknown }
        return try results.removeFirst().get()
    }
}

actor WaitRecorder {
    private(set) var delays: [TimeInterval] = []

    func record(_ delay: TimeInterval) {
        delays.append(delay)
    }
}

actor RequestRecorder {
    private(set) var requests: [URLRequest] = []

    func record(_ request: URLRequest) {
        requests.append(request)
    }
}

struct TransportStub: HTTPTransport {
    let handler: @Sendable (URLRequest) async throws -> (Data, URLResponse)

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await handler(request)
    }
}

/// Yields until `condition` holds. Uses no wall-clock time; the iteration
/// bound only protects against a hang when the condition can never be met.
func eventually(
    _ condition: @Sendable () async -> Bool,
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    for _ in 0..<100_000 {
        if await condition() { return }
        await Task.yield()
    }
    XCTFail("Condition was not met", file: file, line: line)
}

func assertFailure(
    _ result: Result<HTTPResponse, Error>,
    equals expected: AppError,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    switch result {
    case .success:
        XCTFail("Expected \(expected) but got success", file: file, line: line)
    case .failure(let error):
        XCTAssertEqual(error as? AppError, expected, file: file, line: line)
    }
}
