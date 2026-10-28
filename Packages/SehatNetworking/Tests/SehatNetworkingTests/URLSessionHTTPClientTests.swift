//
// Copyright (c) 2026 Enjel Hutasoit
//

import XCTest
import SehatCore
import SehatNetworking

final class URLSessionHTTPClientTests: XCTestCase {

    func test_send_returnsResponse_forSuccessStatus() async throws {
        let body = Data("ok".utf8)
        let sut = URLSessionHTTPClient(transport: TransportStub { _ in
            (body, makeHTTPURLResponse(status: 200, headers: ["Content-Type": "application/json"]))
        })

        let response = try await sut.send(makeRequest())

        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(response.data, body)
        XCTAssertEqual(response.header("content-type"), "application/json")
    }

    func test_send_buildsURLRequest_fromHTTPRequest() async throws {
        let recorder = RequestRecorder()
        let sut = URLSessionHTTPClient(transport: TransportStub { request in
            await recorder.record(request)
            return (Data(), makeHTTPURLResponse(status: 200))
        })
        let body = Data("payload".utf8)
        let request = HTTPRequest(
            url: testURL,
            method: .post,
            headers: ["X-Test": "1"],
            body: body,
            timeout: 12
        )

        _ = try await sut.send(request)

        let sent = await recorder.requests
        let urlRequest = try XCTUnwrap(sent.first)
        XCTAssertEqual(sent.count, 1)
        XCTAssertEqual(urlRequest.url, testURL)
        XCTAssertEqual(urlRequest.httpMethod, "POST")
        XCTAssertEqual(urlRequest.value(forHTTPHeaderField: "X-Test"), "1")
        XCTAssertEqual(urlRequest.httpBody, body)
        XCTAssertEqual(urlRequest.timeoutInterval, 12)
    }

    func test_send_throwsMappedError_forNonSuccessStatus() async {
        let expectations: [(status: Int, error: AppError)] = [
            (400, .server(statusCode: 400)),
            (401, .unauthorized),
            (404, .notFound),
            (500, .server(statusCode: 500)),
            (304, .server(statusCode: 304))
        ]

        for expectation in expectations {
            let sut = URLSessionHTTPClient(transport: TransportStub { _ in
                (Data(), makeHTTPURLResponse(status: expectation.status))
            })

            await assertSendFails(sut, makeRequest(), with: expectation.error)
        }
    }

    func test_send_throwsMappedError_whenTransportFails() async {
        let sut = URLSessionHTTPClient(transport: TransportStub { _ in
            throw URLError(.notConnectedToInternet)
        })

        await assertSendFails(sut, makeRequest(), with: .offline)
    }

    func test_send_throwsUnknown_whenResponseIsNotHTTP() async {
        let sut = URLSessionHTTPClient(transport: TransportStub { _ in
            (Data(), URLResponse(url: testURL, mimeType: nil, expectedContentLength: 0, textEncodingName: nil))
        })

        await assertSendFails(sut, makeRequest(), with: .unknown)
    }
}
