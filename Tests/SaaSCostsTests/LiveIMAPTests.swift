@testable import SaaSCosts
import XCTest

/// Talks to the real Gmail IMAP server. Opt-in: `SASS_COSTS_LIVE=1 swift test --filter LiveIMAPTests`.
final class LiveIMAPTests: XCTestCase {
    override func setUpWithError() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["SASS_COSTS_LIVE"] == "1", "live test disabled")
    }

    func testGmailGreetingOverTLS() async throws {
        let client = IMAPClient(stream: TLSIMAPStream(host: "imap.gmail.com"))

        try await client.open()
        await client.logout()
    }

    /// Writes the extracted text of recent billing mails to `SASS_COSTS_DUMP` (a path outside the repo),
    /// for every account listed in `IMAP_ACCOUNTS`, using the Keychain app passwords.
    func testDumpReceiptTexts() async throws {
        let environment = ProcessInfo.processInfo.environment
        let output = try XCTUnwrap(environment["SASS_COSTS_DUMP"], "set SASS_COSTS_DUMP to an output file")
        let accounts = (EnvFile.load()["IMAP_ACCOUNTS"] ?? "").split(separator: ",").map(String.init)
        let query = "from:(invoice+statements@mail.anthropic.com OR openai.com) newer_than:120d"

        var dump = ""
        for account in accounts {
            let client = IMAPClient(stream: TLSIMAPStream(host: "imap.gmail.com"))
            try await client.open()
            try await client.login(user: account, password: Keychain.password(account: account))
            try await client.examine(client.allMailFolder())
            for uid in try await client.search(gmailQuery: query) {
                let message = MIMEPart(raw: try await client.fetchMessage(uid: uid))
                let from = message.headers["from"] ?? ""
                dump += "=== \(account) uid \(uid) | \(from) | \(message.headers["subject"] ?? "")\n"
                dump += (message.text ?? "<no text part>") + "\n\n"
            }
            await client.logout()
        }
        try dump.write(toFile: output, atomically: true, encoding: .utf8)
    }
}
