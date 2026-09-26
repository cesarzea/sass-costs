@testable import SaaSCosts
import XCTest

final class IMAPParsingTests: XCTestCase {
    func testLiteralSplitAcrossChunksIsReadByByteCount() {
        var reader = IMAPLineReader()
        reader.append(Data("* 1 FETCH (BODY[] {12}\r\nline1\r\nline".utf8))
        XCTAssertNil(reader.nextLine())

        reader.append(Data("2)\r\n* 2 EXISTS\r\n".utf8))
        let fetch = IMAPLine(text: "* 1 FETCH (BODY[] {12})", literals: [Data("line1\r\nline2".utf8)])
        XCTAssertEqual(reader.nextLine(), fetch)
        XCTAssertEqual(reader.nextLine(), IMAPLine(text: "* 2 EXISTS", literals: []))
        XCTAssertNil(reader.nextLine())
    }

    func testListEntryWithQuotedAndLiteralNames() {
        let line = IMAPLine(text: #"* LIST (\All \HasNoChildren) "/" "[Gmail]/All Mail""#, literals: [])
        let quoted = IMAPListEntry(line)
        XCTAssertEqual(quoted?.flags, ["\\All", "\\HasNoChildren"])
        XCTAssertEqual(quoted?.name, "[Gmail]/All Mail")

        let literal = IMAPListEntry(IMAPLine(text: #"* LIST (\All) "/" {13}"#, literals: [Data("[Gmail]/Todos".utf8)]))
        XCTAssertEqual(literal?.name, "[Gmail]/Todos")

        XCTAssertNil(IMAPListEntry(IMAPLine(text: "* SEARCH 1 2", literals: [])))
    }
}
