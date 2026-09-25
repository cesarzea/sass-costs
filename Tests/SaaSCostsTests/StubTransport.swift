import Foundation
@testable import SaaSCosts

/// Returns a canned body chosen by `respond`, and records every request.
final class StubTransport: HTTPTransport, @unchecked Sendable {
    private let respond: @Sendable (URLRequest) -> String?
    private let lock = NSLock()
    private var recorded: [URLRequest] = []

    init(respond: @escaping @Sendable (URLRequest) -> String?) {
        self.respond = respond
    }

    /// Bodies keyed by the `page` query value; `nil` is the first page.
    convenience init(pages: [String?: String]) {
        self.init { pages[$0.query("page")] }
    }

    var requests: [URLRequest] {
        lock.withLock { recorded }
    }

    func send(_ request: URLRequest) async throws -> Data {
        lock.withLock { recorded.append(request) }
        guard let body = respond(request) else {
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
