//
// Copyright (c) 2026 Enjel Hutasoit
//

import XCTest
import SehatCore
import SehatNetworking

final class RetryingHTTPClientTests: XCTestCase {

    private let policy = RetryPolicy(maxAttempts: 3, baseDelay: 0.5, multiplier: 2, maxDelay: 8)

    func test_send_returnsResponse_withoutRetry_onFirstSuccess() async throws {
        let (sut, stub, recorder) = makeSUT(results: [.success(makeResponse())])

        let response = try await sut.send(makeRequest())

        XCTAssertEqual(response, makeResponse())
        let calls = await stub.sentRequests.count
        let waits = await recorder.delays
        XCTAssertEqual(calls, 1)
        XCTAssertEqual(waits, [])
    }

    func test_send_retriesRetryableError_thenSucceeds() async throws {
        let (sut, stub, recorder) = makeSUT(results: [
            .failure(AppError.offline),
            .success(makeResponse())
        ])

        let response = try await sut.send(makeRequest())

        XCTAssertEqual(response, makeResponse())
        let calls = await stub.sentRequests.count
        let waits = await recorder.delays
        XCTAssertEqual(calls, 2)
        XCTAssertEqual(waits, [0.5])
    }

    func test_send_waitsAccordingToPolicy_andThrowsAfterLastAttempt() async {
        let (sut, stub, recorder) = makeSUT(results: [
            .failure(AppError.offline),
            .failure(AppError.offline),
            .failure(AppError.offline)
        ])

        await assertSendFails(sut, makeRequest(), with: .offline)

        let calls = await stub.sentRequests.count
        let waits = await recorder.delays
        XCTAssertEqual(calls, 3)
        XCTAssertEqual(waits, [0.5, 1])
    }

    func test_send_doesNotRetry_nonRetryableError() async {
        let (sut, stub, recorder) = makeSUT(results: [.failure(AppError.unauthorized)])

        await assertSendFails(sut, makeRequest(), with: .unauthorized)

        let calls = await stub.sentRequests.count
        let waits = await recorder.delays
        XCTAssertEqual(calls, 1)
        XCTAssertEqual(waits, [])
    }

    func test_send_doesNotRetry_nonIdempotentMethod() async {
        let (sut, stub, recorder) = makeSUT(results: [.failure(AppError.offline), .success(makeResponse())])

        await assertSendFails(sut, makeRequest(method: .post), with: .offline)

        let calls = await stub.sentRequests.count
        let waits = await recorder.delays
        XCTAssertEqual(calls, 1)
        XCTAssertEqual(waits, [])
    }

    func test_send_doesNotRetry_whenPolicyAllowsSingleAttempt() async {
        let single = RetryPolicy(maxAttempts: 1, baseDelay: 0.5, maxDelay: 8)
        let (sut, stub, recorder) = makeSUT(results: [.failure(AppError.offline)], policy: single)

        await assertSendFails(sut, makeRequest(), with: .offline)

        let calls = await stub.sentRequests.count
        let waits = await recorder.delays
        XCTAssertEqual(calls, 1)
        XCTAssertEqual(waits, [])
    }

    func test_send_mapsRawErrors_beforeDecidingToRetry() async throws {
        let (sut, stub, recorder) = makeSUT(results: [
            .failure(URLError(.timedOut)),
            .success(makeResponse())
        ])

        let response = try await sut.send(makeRequest())

        XCTAssertEqual(response, makeResponse())
        let calls = await stub.sentRequests.count
        let waits = await recorder.delays
        XCTAssertEqual(calls, 2)
        XCTAssertEqual(waits, [0.5])
    }

    func test_send_throwsCancelled_whenWaitIsCancelled() async {
        let stub = ClientStub(results: [.failure(AppError.offline), .success(makeResponse())])
        let sut = RetryingHTTPClient(base: stub, policy: policy, wait: { _ in throw CancellationError() })

        await assertSendFails(sut, makeRequest(), with: .cancelled)

        let calls = await stub.sentRequests.count
        XCTAssertEqual(calls, 1)
    }

    // MARK: - Helpers

    private func makeSUT(
        results: [Result<HTTPResponse, Error>],
        policy: RetryPolicy? = nil
    ) -> (sut: RetryingHTTPClient, stub: ClientStub, recorder: WaitRecorder) {
        let stub = ClientStub(results: results)
        let recorder = WaitRecorder()
        let sut = RetryingHTTPClient(
            base: stub,
            policy: policy ?? self.policy,
            wait: { delay in await recorder.record(delay) }
        )
        return (sut, stub, recorder)
    }
}
