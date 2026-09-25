# SaaS Costs

macOS menu bar app that shows month-to-date spend on AI providers.

The status item shows the total. The menu lists each provider:

- **amount** — spend since the 1st of the month (UTC), read from the provider's billing API
- **Error** — the request failed (hover for the reason); a `⚠︎` is added to the total
- **Needs …_ADMIN_KEY** / **No cost API** — a key exists but spend cannot be read with it

Costs refresh on launch, every hour, and on *Refresh Now* (⌘R).

## Provider support

| Provider | Spend | Requirement |
|----------|-------|-------------|
| Anthropic | ✅ `GET /v1/organizations/cost_report` | Admin key (`ANTHROPIC_ADMIN_KEY`) |
| OpenAI | ✅ `GET /v1/organization/costs` | Admin key (`OPENAI_ADMIN_KEY`) |
| xAI | ✅ `POST management-api.x.ai/v1/billing/teams/{team}/usage` | Management key with BillingRead (`XAI_MANAGEMENT_KEY`); team id is looked up from the key unless `XAI_TEAM_ID` is set |
| Google Gemini | — | Billing lives in Google Cloud; not readable with an API key |
| Groq, Cerebras, Soniox | — | No public spend API found |
| ElevenLabs | — | Subscription based; API reports characters, not spend |

## Configuration

Keys are read from the first file found:

1. `~/.config/sass-costs/.env` — for the installed app
2. `./.env.local` in the working directory — for `make run` from the repository

See [`.env.local.example`](.env.local.example). Keys are only sent to their own provider.

## Build and run

Requires macOS 12+, Xcode 15+ and [SwiftLint](https://github.com/realm/SwiftLint).

```bash
make check   # swiftlint --strict, warning-free build, tests
make run     # builds .build/SaaSCosts.app and launches it from the repo
make stop
```

To install, copy `.build/SaaSCosts.app` to `/Applications` and put the keys in `~/.config/sass-costs/.env`.

## Layout

```
Sources/SaaSCosts/
├── App.swift                  entry point and app delegate
├── Core/                      CostFetcher protocol, billing period, parallel collection, HTTP
├── Providers/                 one file per provider
├── Config/                    .env parsing and provider selection
└── UI/                        status item, menu, formatting
Tests/SaaSCostsTests/          parsing, pagination, ordering, formatting
```

## Adding a provider

1. Add `Sources/SaaSCosts/Providers/<Name>CostFetcher.swift` implementing `CostFetcher`
   (`name` and `cost(for:) async throws -> Double` in USD). Use `HTTPGetting` for requests so it can be tested with a stub.
2. Register it in `Config/ProviderCatalog.swift` and document its key in `.env.local.example`.
3. Add a test with a recorded response, then run `make check`.

## License

MIT
