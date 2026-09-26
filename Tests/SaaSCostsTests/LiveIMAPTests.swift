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
}
