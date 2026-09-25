import Foundation

enum HTTPError: LocalizedError, Equatable {
    case invalidURL
    case status(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid request URL"
        case .status(let code):
            return "HTTP \(code)"
        }
    }
}

protocol HTTPTransport: Sendable {
    func send(_ request: URLRequest) async throws -> Data
}

struct URLSessionTransport: HTTPTransport {
    func send(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(for: request)
        let code = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(code) else {
            throw HTTPError.status(code)
        }
        return data
    }
}

extension URLRequest {
    init(_ components: URLComponents, method: String = "GET", headers: [String: String], body: Data? = nil) throws {
        guard let url = components.url else {
            throw HTTPError.invalidURL
        }
        self.init(url: url, timeoutInterval: 30)
        httpMethod = method
        httpBody = body
        headers.forEach { setValue($1, forHTTPHeaderField: $0) }
    }
}
