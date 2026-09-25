@testable import SaaSCosts
import XCTest

final class ProviderCatalogTests: XCTestCase {
    func testAdminKeysEnableFetchers() {
        let setup = ProviderCatalog.setup(from: [
            "ANTHROPIC_ADMIN_KEY": "a",
            "OPENAI_ADMIN_KEY": "b",
            "XAI_MANAGEMENT_KEY": "c",
            "ELEVEN_LABS_KEY": "d"
        ])

        XCTAssertEqual(setup.fetchers.map(\.name), ["Anthropic", "OpenAI", "xAI", "ElevenLabs"])
        XCTAssertTrue(setup.unavailable.isEmpty)
    }

    func testRegularKeysAreReportedAsUnavailable() {
        let setup = ProviderCatalog.setup(from: [
            "ANTHROPIC_API_KEY": "a",
            "OPENAI_API_KEY": "b",
            "GROK_API_KEY": "inference key only",
            "GROQ_API_KEY": "c",
            "CEREBRAS_API_KEY": ""
        ])

        XCTAssertTrue(setup.fetchers.isEmpty)
        XCTAssertEqual(setup.unavailable, [
            ProviderResult(name: "Anthropic", status: .unavailable("Needs ANTHROPIC_ADMIN_KEY")),
            ProviderResult(name: "OpenAI", status: .unavailable("Needs OPENAI_ADMIN_KEY")),
            ProviderResult(name: "xAI", status: .unavailable("Needs XAI_MANAGEMENT_KEY")),
            ProviderResult(name: "Groq", status: .unavailable("No cost API"))
        ])
    }
}
