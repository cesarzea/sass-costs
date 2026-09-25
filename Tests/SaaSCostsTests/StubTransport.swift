import Foundation
@testable import SaaSCosts

/// Returns a canned body per `page` query value (`nil` key = first page) and records requests.
final class StubTransport: HTTPTransport, @unchecked Sendable {
    private let pages: [String?: String]
    private let lock = NSLock()
    private var recorded: [URLRequest] = []

    init(pages: [String?: String]) {
        self.pages = pages
    }

    var requests: [URLRequest] {
        lock.withLock { recorded }
    }

    func send(_ request: URLRequest) async throws -> Data {
        lock.withLock { recorded.append(request) }
        let page = request.query("page")
        guard let body = pages[page] else {
            throw HTTPError.status(404)
        }
        return Data(body.utf8)
    }
}

extension URLRequest {
    func query(_ name: String) -> String? {
        guard let url, let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        return components.queryItems?.first { $0.name == name }?.value
    }
}
