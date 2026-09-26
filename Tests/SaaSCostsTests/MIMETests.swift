@testable import SaaSCosts
import XCTest

final class MIMETests: XCTestCase {
    private static let multipartReceipt = """
        From: Billing <billing@example.com>\r
        Content-Type: multipart/mixed; boundary="outer"\r
        \r
        --outer\r
        Content-Type: multipart/alternative;\r
         boundary=inner\r
        \r
        --inner\r
        Content-Type: text/plain; charset=utf-8\r
        Content-Transfer-Encoding: quoted-printable\r
        \r
        Amount paid =E2=82=AC180.00 for Max plan - 20x, a very long line that is =\r
        soft-wrapped\r
        --inner\r
        Content-Type: text/html; charset=utf-8\r
        \r
        <p>ignored</p>\r
        --inner--\r
        --outer\r
        Content-Type: text/plain; name="notes.txt"\r
        Content-Disposition: attachment; filename="notes.txt"\r
        \r
        attachment text\r
        --outer--\r

        """

    func testPrefersInlinePlainTextAndDecodesQuotedPrintableUTF8() {
        let message = MIMEPart(raw: Data(Self.multipartReceipt.utf8))

        XCTAssertEqual(message.headers["from"], "Billing <billing@example.com>")
        XCTAssertEqual(
            message.text?.trimmingCharacters(in: .newlines),
            "Amount paid €180.00 for Max plan - 20x, a very long line that is soft-wrapped"
        )
    }

    func testFallsBackToHTMLAndDecodesBase64() {
        let html = Data("<html><style>p{}</style><p>Total&nbsp;&euro;90.00</p></html>".utf8).base64EncodedString()
        let raw = "Content-Type: text/html; charset=utf-8\r\nContent-Transfer-Encoding: base64\r\n\r\n\(html)\r\n"

        let text = MIMEPart(raw: Data(raw.utf8)).text

        XCTAssertEqual(text?.split(whereSeparator: \.isWhitespace).joined(separator: " "), "Total €90.00")
    }

    func testQuotedPrintableKeepsInvalidEscapesLiterally() {
        XCTAssertEqual(String(bytes: QuotedPrintable.decode("a=3Db=ZZ=\nc"), encoding: .utf8), "a=b=ZZc")
    }
}
