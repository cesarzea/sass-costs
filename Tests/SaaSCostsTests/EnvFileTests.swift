@testable import SaaSCosts
import XCTest

final class EnvFileTests: XCTestCase {
    func testParsesKeysIgnoringCommentsBlanksAndQuotes() {
        let text = """
        # comment
        OPENAI_ADMIN_KEY=sk-admin-1

        export ANTHROPIC_ADMIN_KEY = "sk-ant-admin-2"
        SINGLE='x=y'
        EMPTY=
        not a pair
        """

        let values = EnvFile.parse(text)

        XCTAssertEqual(values["OPENAI_ADMIN_KEY"], "sk-admin-1")
        XCTAssertEqual(values["ANTHROPIC_ADMIN_KEY"], "sk-ant-admin-2")
        XCTAssertEqual(values["SINGLE"], "x=y")
        XCTAssertEqual(values["EMPTY"], "")
        XCTAssertEqual(values.count, 4)
    }
}
