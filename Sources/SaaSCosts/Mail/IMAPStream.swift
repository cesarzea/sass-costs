import Foundation

enum IMAPError: LocalizedError, Equatable {
    case connectionClosed
    case unexpectedGreeting
    case commandFailed(String)
    case invalidArgument
    case missingAllMailFolder

    var errorDescription: String? {
        switch self {
        case .connectionClosed:
            return "IMAP connection closed"
        case .unexpectedGreeting:
            return "Unexpected IMAP greeting"
        case .commandFailed(let status):
            return "IMAP: \(status)"
        case .invalidArgument:
            return "Invalid IMAP argument"
        case .missingAllMailFolder:
            return "Gmail 'All Mail' folder not found"
        }
    }
}

protocol IMAPStream: AnyObject {
    func write(_ data: Data) async throws
    /// The next chunk of bytes from the server; throws `connectionClosed` at end of stream.
    func read() async throws -> Data
    func close()
}

/// TLS connection to an IMAP server (implicit TLS, e.g. port 993).
final class TLSIMAPStream: IMAPStream {
    private let task: URLSessionStreamTask
    private let timeout: TimeInterval = 30

    init(host: String, port: Int = 993) {
        task = URLSession.shared.streamTask(withHostName: host, port: port)
        task.startSecureConnection()
        task.resume()
    }

    func write(_ data: Data) async throws {
        try await task.write(data, timeout: timeout)
    }

    func read() async throws -> Data {
        let (data, _) = try await task.readData(ofMinLength: 1, maxLength: 65_536, timeout: timeout)
        guard let data, !data.isEmpty else {
            throw IMAPError.connectionClosed
        }
        return data
    }

    func close() {
        task.cancel()
    }
}
