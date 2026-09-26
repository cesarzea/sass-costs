@testable import SaaSCosts
import XCTest

final class IMAPClientTests: XCTestCase {
    private let message = "Subject: Receipt\r\n\r\nAmount paid \u{20AC}180.00\r\n"

    private func gmailServer() -> ScriptedIMAPStream {
        ScriptedIMAPStream(replies: [
            "LOGIN": "TAG OK user authenticated\r\n",
            "LIST": """
                * LIST (\\HasNoChildren) "/" "INBOX"\r
                * LIST (\\All \\HasNoChildren) "/" "[Gmail]/Todos"\r
                TAG OK Success\r

                """,
            "EXAMINE": "* 42 EXISTS\r\nTAG OK [READ-ONLY] examined\r\n",
            "UID SEARCH": "* SEARCH 101 205\r\nTAG OK SEARCH completed\r\n",
            "UID FETCH": "* 7 FETCH (UID 205 BODY[] {\(message.utf8.count)}\r\n\(message))\r\nTAG OK Success\r\n",
            "LOGOUT": "* BYE\r\nTAG OK bye\r\n"
        ])
    }

    func testReadOnlySessionFindsAllMailAndFetchesLiteralBody() async throws {
        let server = gmailServer()
        let client = IMAPClient(stream: server)

        try await client.open()
        try await client.login(user: "me@example.com", password: "app pass")
        let folder = try await client.allMailFolder()
        try await client.examine(folder)
        let uids = try await client.search(gmailQuery: "from:billing@example.com after:2026/08/01")
        let body = try await client.fetchMessage(uid: 205)
        await client.logout()

        XCTAssertEqual(folder, "[Gmail]/Todos")
        XCTAssertEqual(uids, [101, 205])
        XCTAssertEqual(String(bytes: body, encoding: .utf8), message)
        XCTAssertEqual(server.commands, [
            #"LOGIN "me@example.com" "app pass""#,
            #"LIST "" "*""#,
            #"EXAMINE "[Gmail]/Todos""#,
            #"UID SEARCH X-GM-RAW "from:billing@example.com after:2026/08/01""#,
            "UID FETCH 205 BODY.PEEK[]",
            "LOGOUT"
        ])
        XCTAssertTrue(server.closed)
    }

    func testRejectedLoginSurfacesServerStatus() async throws {
        let server = ScriptedIMAPStream(replies: ["LOGIN": "TAG NO [AUTHENTICATIONFAILED] Invalid credentials\r\n"])
        let client = IMAPClient(stream: server)
        try await client.open()

        do {
            try await client.login(user: "me@example.com", password: "wrong")
            XCTFail("Expected login failure")
        } catch {
            XCTAssertEqual(error as? IMAPError, .commandFailed("NO [AUTHENTICATIONFAILED] Invalid credentials"))
        }
    }

    func testQuotingEscapesAndRejectsLineBreaks() throws {
        XCTAssertEqual(try IMAPClient.quoted(#"a"b\c"#), #""a\"b\\c""#)
        XCTAssertThrowsError(try IMAPClient.quoted("a\r\nb"))
    }
}
