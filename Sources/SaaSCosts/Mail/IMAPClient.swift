import Foundation

/// Minimal read-only IMAP client for Gmail: mailboxes are opened with EXAMINE and bodies fetched
/// with BODY.PEEK so messages keep their unread state.
final class IMAPClient {
    private let stream: IMAPStream
    private var reader = IMAPLineReader()
    private var tagCounter = 0

    init(stream: IMAPStream) {
        self.stream = stream
    }

    func open() async throws {
        guard try await nextLine().text.hasPrefix("* OK") else {
            throw IMAPError.unexpectedGreeting
        }
    }

    func login(user: String, password: String) async throws {
        _ = try await run("LOGIN \(try Self.quoted(user)) \(try Self.quoted(password))")
    }

    /// Gmail's localized "All Mail" folder, found through its `\All` special-use flag.
    func allMailFolder() async throws -> String {
        let entries = try await run("LIST \"\" \"*\"").compactMap(IMAPListEntry.init)
        guard let folder = entries.first(where: { $0.flags.contains("\\All") }) else {
            throw IMAPError.missingAllMailFolder
        }
        return folder.name
    }

    func examine(_ mailbox: String) async throws {
        _ = try await run("EXAMINE \(try Self.quoted(mailbox))")
    }

    /// UIDs of messages matching a Gmail search query (X-GM-RAW).
    func search(gmailQuery: String) async throws -> [Int] {
        let lines = try await run("UID SEARCH X-GM-RAW \(try Self.quoted(gmailQuery))")
        return lines
            .filter { $0.text.hasPrefix("* SEARCH") }
            .flatMap { $0.text.split(separator: " ").dropFirst(2).compactMap { Int($0) } }
    }

    func fetchMessage(uid: Int) async throws -> Data {
        let lines = try await run("UID FETCH \(uid) BODY.PEEK[]")
        guard let message = lines.first(where: { $0.text.contains("FETCH") })?.literals.first else {
            throw IMAPError.commandFailed("message \(uid) not returned")
        }
        return message
    }

    func logout() async {
        _ = try? await run("LOGOUT")
        stream.close()
    }

    /// Sends a tagged command and returns its untagged responses; throws on NO/BAD.
    private func run(_ command: String) async throws -> [IMAPLine] {
        tagCounter += 1
        let tag = "a\(tagCounter)"
        try await stream.write(Data("\(tag) \(command)\r\n".utf8))

        var untagged: [IMAPLine] = []
        while true {
            let line = try await nextLine()
            guard line.text.hasPrefix("\(tag) ") else {
                untagged.append(line)
                continue
            }
            let status = String(line.text.dropFirst(tag.count + 1))
            guard status.hasPrefix("OK") else {
                throw IMAPError.commandFailed(status)
            }
            return untagged
        }
    }

    private func nextLine() async throws -> IMAPLine {
        while true {
            if let line = reader.nextLine() {
                return line
            }
            reader.append(try await stream.read())
        }
    }

    static func quoted(_ value: String) throws -> String {
        guard !value.contains(where: \.isNewline) else {
            throw IMAPError.invalidArgument
        }
        let escaped = value.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
        return "\"\(escaped)\""
    }
}
