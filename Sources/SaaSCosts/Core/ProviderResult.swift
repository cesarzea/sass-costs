import Foundation

struct ProviderResult: Equatable, Sendable {
    enum Status: Equatable, Sendable {
        case cost(Double)
        case failed(String)
        case unavailable(String)
    }

    let name: String
    let status: Status
}
