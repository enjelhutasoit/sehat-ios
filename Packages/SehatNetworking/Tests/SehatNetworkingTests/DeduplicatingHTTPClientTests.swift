//
// Copyright (c) 2026 Enjel Hutasoit
//

import XCTest
import SehatCore
@testable import SehatNetworking

final class DeduplicatingHTTPClientTests: XCTestCase {

    // MARK: - Sharing

    func test_send_sharesSingleCall_forConcurrentIdenticalGETs() async throws {
        let (sut, stub) = makeSUT()
        let request = makeRequest()

        let tasks = (0..<3).map { _ in startSend(sut, request) }
        await eventually { await sut.waiterCount(for: request) == 3 }
        await eventually { await stub.pendingCount == 1 }
        await stub.complete(with: makeResponse())

        for task in tasks {
            let response = try await task.value
            XCTAssertEqual(response, makeResponse())
        }
        let calls = await stub.callCount
        XCTAssertEqual(calls, 1)
    }

    func test_send_doesNotShare_differentRequests() async throws {
        let (sut, stub) = makeSUT()

        let first = startSend(sut, HTTPRequest(url: URL(string: "https://example.com/a")!))
        let second = startSend(sut, HTTPRequest(url: URL(string: "https://example.com/b")!))
        await eventually { await stub.pendingCount == 2 }
        await stub.complete(with: makeResponse())

        _ = try await first.value
        _ = try await second.value
        let calls = await stub.callCount
        XCTAssertEqual(calls, 2)
    }

    func test_send_doesNotShare_nonGETRequests() async throws {
        let (sut, stub) = makeSUT()
        let request = makeRequest(method: .post)

        let first = startSend(sut, request)
        let second = startSend(sut, request)
        await eventually { await stub.pendingCount == 2 }
        await stub.complete(with: makeResponse())

        _ = try await first.value
        _ = try await second.value
        let calls = await stub.callCount
        XCTAssertEqual(calls, 2)
    }

    func test_send_startsNewCall_afterPreviousCallCompleted() async throws {
        let (sut, stub) = makeSUT()
        let request = makeRequest()

        let first = startSend(sut, request)
        await eventually { await stub.pendingCount == 1 }
        await stub.complete(with: makeResponse())
        _ = try await first.value

        let second = startSend(sut, request)
        await eventually { await stub.pendingCount == 1 }
        await stub.complete(with: makeResponse())
        _ = try await second.value

        let calls = await stub.callCount
        XCTAssertEqual(calls, 2)
    }

    // MARK: - Errors

    func test_send_deliversMappedError_toAllWaiters() async {
        let (sut, stub) = makeSUT()
        let request = makeRequest()

        let tasks = (0..<2).map { _ in startSend(sut, request) }
        await eventually { await sut.waiterCount(for: request) == 2 }
        await eventually { await stub.pendingCount == 1 }
        await stub.fail(with: URLError(.timedOut))

        for task in tasks {
            let result = await task.result
            assertFailure(result, equals: .timedOut)
        }
    }

    // MARK: - Cancellation

    func test_cancel_oneWaiter_doesNotAffectOtherWaiters() async throws {
        let (sut, stub) = makeSUT()
        let request = makeRequest()

        let cancelled = startSend(sut, request)
        let survivor = startSend(sut, request)
        await eventually { await sut.waiterCount(for: request) == 2 }
        await eventually { await stub.pendingCount == 1 }

        cancelled.cancel()
        let cancelledResult = await cancelled.result
        assertFailure(cancelledResult, equals: .cancelled)

        await stub.complete(with: makeResponse())
        let response = try await survivor.value
        XCTAssertEqual(response, makeResponse())
        let cancelledCalls = await stub.cancelledCallCount
        XCTAssertEqual(cancelledCalls, 0)
    }

    func test_cancel_allWaiters_cancelsUnderlyingCall() async {
        let (sut, stub) = makeSUT()
        let request = makeRequest()

        let first = startSend(sut, request)
        let second = startSend(sut, request)
        await eventually { await sut.waiterCount(for: request) == 2 }

        first.cancel()
        second.cancel()
        let firstResult = await first.result
        let secondResult = await second.result
        assertFailure(firstResult, equals: .cancelled)
        assertFailure(secondResult, equals: .cancelled)

        await eventually { await stub.cancelledCallCount == 1 }
        await eventually { await sut.waiterCount(for: request) == 0 }
        let calls = await stub.callCount
        XCTAssertEqual(calls, 1)
    }

    func test_cancel_beforeSend_throwsCancelled_withoutCallingBase() async {
        let (sut, stub) = makeSUT()
        let request = makeRequest()

        let task = Task { () async throws -> HTTPResponse in
            while !Task.isCancelled { await Task.yield() }
            return try await sut.send(request)
        }
        task.cancel()

        let result = await task.result
        assertFailure(result, equals: .cancelled)
        let calls = await stub.callCount
        XCTAssertEqual(calls, 0)
    }

    func test_send_startsFreshCall_afterAllWaitersCancelled() async throws {
        let (sut, stub) = makeSUT()
        let request = makeRequest()

        let first = startSend(sut, request)
        await eventually { await sut.waiterCount(for: request) == 1 }
        await eventually { await stub.pendingCount == 1 }
        first.cancel()
        _ = await first.result
        await eventually { await stub.cancelledCallCount == 1 }

        let second = startSend(sut, request)
        await eventually { await stub.pendingCount == 1 }
        await stub.complete(with: makeResponse())

        let response = try await second.value
        XCTAssertEqual(response, makeResponse())
        let calls = await stub.callCount
        XCTAssertEqual(calls, 2)
    }

    // MARK: - Helpers

    private func makeSUT() -> (sut: DeduplicatingHTTPClient, stub: GatedClient) {
        let stub = GatedClient()
        return (DeduplicatingHTTPClient(base: stub), stub)
    }

    private func startSend(
        _ sut: DeduplicatingHTTPClient,
        _ request: HTTPRequest
    ) -> Task<HTTPResponse, Error> {
        Task { try await sut.send(request) }
    }
}
