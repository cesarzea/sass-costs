import Foundation

struct EnvLoader {
    private static let envFile = ".env.local"

    static func load() -> [String: String] {
        let fileManager = FileManager.default
        let currentDir = fileManager.currentDirectoryPath
        let envPath = "\(currentDir)/\(envFile)"

        guard let content = try? String(contentsOfFile: envPath, encoding: .utf8) else {
            print("Warning: \(envFile) not found at \(envPath)")
            return [:]
        }

        var env: [String: String] = [:]

        content.split(separator: "\n", omittingEmptySubsequences: true).forEach { line in
            let trimmed = String(line).trimmingCharacters(in: .whitespaces)

            guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { return }
            guard let equalIndex = trimmed.firstIndex(of: "=") else { return }

            let key = String(trimmed[..<equalIndex]).trimmingCharacters(in: .whitespaces)
            let value = String(trimmed[trimmed.index(after: equalIndex)...]).trimmingCharacters(in: .whitespaces)

            env[key] = value
        }

        return env
    }
}
