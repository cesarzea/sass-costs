import Foundation

struct ElevenLabsProvider: CostFetcher {
    let providerName = "ElevenLabs"
    let apiKey: String?

    init(apiKey: String? = nil) {
        self.apiKey = apiKey ?? ProcessInfo.processInfo.environment["ELEVEN_LABS_KEY"]
    }

    func fetchCost() async throws -> Double {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw ProviderError.missingAPIKey
        }

        let url = URL(string: "https://api.elevenlabs.io/v1/user")!

        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ProviderError.invalidResponse
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let user = try decoder.decode(ElevenLabsUser.self, from: data)
        return user.subscription.billedAmount
    }
}

private struct ElevenLabsUser: Codable {
    let subscription: ElevenLabsSubscription
}

private struct ElevenLabsSubscription: Codable {
    let billedAmount: Double

    enum CodingKeys: String, CodingKey {
        case billedAmount = "billed_amount"
    }
}
