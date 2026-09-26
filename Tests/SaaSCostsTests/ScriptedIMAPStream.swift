import Foundation
@testable import SaaSCosts

/// Fake IMAP server: replies to each command with a canned response (`TAG` is replaced by the
/// command's tag) and hands bytes back in small chunks to exercise buffering.
final class ScriptedIMAPStream: IMAPStream {
    private var replies: [String: String]
    private var pending = Data()
    private(set) var commands: [String] = []
    private(set) var closed = false

    init(greeting: String = "* OK Gimap ready\r\n", replies: [String: String]) {
        self.replies = replies
        pending = Data(greeting.utf8)
    }

    func write(_ data: Data) async throws {
        let line = (String(bytes: data, encoding: .utf8) ?? "").trimmingCharacters(in: .newlines)
        let parts = line.split(separator: " ", maxSplits: 1).map(String.init)
        commands.append(parts[1])
        let key = replies.keys.first { parts[1].hasPrefix($0) } ?? ""
        let reply = replies[key] ?? "TAG BAD unknown command\r\n"
        pending.append(Data(reply.replacingOccurrences(of: "TAG", with: parts[0]).utf8))
    }

    func read() async throws -> Data {
        guard !pending.isEmpty else {
            throw IMAPError.connectionClosed
        }
        let chunk = pending.prefix(7)
        pending = Data(pending.dropFirst(chunk.count))
        return Data(chunk)
    }

    func close() {
        closed = true
    }
}
