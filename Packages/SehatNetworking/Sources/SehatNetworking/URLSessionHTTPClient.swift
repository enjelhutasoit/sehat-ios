//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import SehatCore

/// Adapts an `HTTPTransport` (normally `URLSession`) to `HTTPClient`.
/// Maps status codes and thrown errors to `AppError`.
public struct URLSessionHTTPClient: HTTPClient {
    private let transport: any HTTPTransport
    private let errorMapper: any ErrorMapping

    public init(
        transport: any HTTPTransport = URLSessionTransport(),
        errorMapper: any ErrorMapping = DefaultErrorMapper()
    ) {
        self.transport = transport
        self.errorMapper = errorMapper
    }

    public func send(_ request: HTTPRequest) async throws -> HTTPResponse {
        let (data, response) = try await perform(Self.makeURLRequest(from: request))

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.unknown
        }
        try Self.validate(statusCode: httpResponse.statusCode)

        return HTTPResponse(
            statusCode: httpResponse.statusCode,
            headers: Self.headers(from: httpResponse),
            data: data
        )
    }

    private func perform(_ urlRequest: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await transport.data(for: urlRequest)
        } catch {
            throw errorMapper.map(error)
        }
    }

    private static func makeURLRequest(from request: HTTPRequest) -> URLRequest {
        var urlRequest = URLRequest(url: request.url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.timeoutInterval = request.timeout
        urlRequest.httpBody = request.body
        for (name, value) in request.headers {
            urlRequest.setValue(value, forHTTPHeaderField: name)
        }
        return urlRequest
    }

    private static func validate(statusCode: Int) throws {
        switch statusCode {
        case 200...299: return
        case 401: throw AppError.unauthorized
        case 404: throw AppError.notFound
        default: throw AppError.server(statusCode: statusCode)
        }
    }

    private static func headers(from response: HTTPURLResponse) -> [String: String] {
        var headers: [String: String] = [:]
        for (key, value) in response.allHeaderFields {
            if let key = key as? String, let value = value as? String {
                headers[key] = value
            }
        }
        return headers
    }
}
