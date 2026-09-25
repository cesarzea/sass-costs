import Foundation

enum EnvFile {
    /// Searched in order; the first existing file wins.
    static var searchPaths: [URL] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        return [
            home.appendingPathComponent(".config/sass-costs/.env"),
            cwd.appendingPathComponent(".env.local")
        ]
    }

    static func load() -> [String: String] {
        for url in searchPaths {
            if let text = try? String(contentsOf: url, encoding: .utf8) {
                return parse(text)
            }
        }
        return [:]
    }

    static func parse(_ text: String) -> [String: String] {
        var values: [String: String] = [:]
        for rawLine in text.split(whereSeparator: \.isNewline) {
            var line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix("#") {
                continue
            }
            if line.hasPrefix("export ") {
                line = String(line.dropFirst("export ".count))
            }
            guard let separator = line.firstIndex(of: "=") else {
                continue
            }
            let key = line[..<separator].trimmingCharacters(in: .whitespaces)
            let value = line[line.index(after: separator)...].trimmingCharacters(in: .whitespaces)
            values[key] = unquoted(value)
        }
        return values
    }

    private static func unquoted(_ value: String) -> String {
        for quote in ["\"", "'"] where value.count >= 2 && value.hasPrefix(quote) && value.hasSuffix(quote) {
            return String(value.dropFirst().dropLast())
        }
        return value
    }
}
