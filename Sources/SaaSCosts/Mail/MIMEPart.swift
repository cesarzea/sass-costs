import Foundation

/// A parsed RFC 822 / MIME entity. Bytes are handled as ISO-8859-1 strings so they round-trip exactly.
struct MIMEPart {
    let headers: [String: String]
    let body: String

    init(raw: Data) {
        self.init(latin1: String(data: raw, encoding: .isoLatin1) ?? "")
    }

    init(latin1 text: String) {
        let separator = text.range(of: "\r\n\r\n") ?? text.range(of: "\n\n")
        let head = separator.map { String(text[..<$0.lowerBound]) } ?? text
        body = separator.map { String(text[$0.upperBound...]) } ?? ""
        headers = Self.parseHeaders(head)
    }

    var mediaType: String {
        (headers["content-type"] ?? "text/plain").split(separator: ";").first
            .map { $0.trimmingCharacters(in: .whitespaces).lowercased() } ?? "text/plain"
    }

    func parameter(_ name: String) -> String? {
        guard let header = headers["content-type"] else {
            return nil
        }
        for item in header.split(separator: ";").dropFirst() {
            let pair = item.split(separator: "=", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            if pair.count == 2, pair[0].lowercased() == name {
                return pair[1].trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            }
        }
        return nil
    }

    /// Child entities of a multipart body.
    var parts: [MIMEPart] {
        guard mediaType.hasPrefix("multipart/"), let boundary = parameter("boundary") else {
            return []
        }
        return body.components(separatedBy: "--\(boundary)")
            .dropFirst()
            .filter { !$0.hasPrefix("--") }
            .map { MIMEPart(latin1: $0.droppingLeadingNewlines()) }
    }

    private static func parseHeaders(_ head: String) -> [String: String] {
        let unfolded = head.replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\n ", with: " ")
            .replacingOccurrences(of: "\n\t", with: " ")
        var headers: [String: String] = [:]
        for line in unfolded.split(separator: "\n") {
            let pair = line.split(separator: ":", maxSplits: 1)
            if pair.count == 2 {
                headers[pair[0].lowercased()] = pair[1].trimmingCharacters(in: .whitespaces)
            }
        }
        return headers
    }
}

private extension String {
    func droppingLeadingNewlines() -> String {
        String(drop(while: \.isNewline))
    }
}
