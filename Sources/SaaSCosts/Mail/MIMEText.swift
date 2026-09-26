import Foundation

extension MIMEPart {
    /// Decoded text of the first inline text/plain part, else the first text/html part with markup removed.
    var text: String? {
        if let plain = firstInlinePart(ofType: "text/plain") {
            return plain.decodedBody
        }
        return firstInlinePart(ofType: "text/html").map { HTMLText.plain($0.decodedBody) }
    }

    var decodedBody: String {
        let bytes: Data
        switch headers["content-transfer-encoding"]?.lowercased() {
        case "quoted-printable":
            bytes = QuotedPrintable.decode(body)
        case "base64":
            bytes = Data(base64Encoded: body.filter { !$0.isWhitespace }) ?? Data()
        default:
            bytes = body.data(using: .isoLatin1) ?? Data()
        }
        return String(bytes: bytes, encoding: charset) ?? String(bytes: bytes, encoding: .isoLatin1) ?? ""
    }

    private var charset: String.Encoding {
        switch parameter("charset")?.lowercased() {
        case "iso-8859-1", "latin1":
            return .isoLatin1
        case "windows-1252":
            return .windowsCP1252
        default:
            return .utf8
        }
    }

    private func firstInlinePart(ofType type: String) -> MIMEPart? {
        let isAttachment = headers["content-disposition"]?.lowercased().hasPrefix("attachment") ?? false
        if mediaType == type, !isAttachment {
            return self
        }
        return parts.lazy.compactMap { $0.firstInlinePart(ofType: type) }.first
    }
}

enum QuotedPrintable {
    /// Decodes a quoted-printable body given as an ISO-8859-1 string (one character per byte).
    static func decode(_ text: String) -> Data {
        let bytes = Array(text.data(using: .isoLatin1) ?? Data())
        var output = Data()
        var index = 0
        while index < bytes.count {
            guard bytes[index] == UInt8(ascii: "=") else {
                output.append(bytes[index])
                index += 1
                continue
            }
            let rest = bytes[(index + 1)...].prefix(2)
            if rest.first == UInt8(ascii: "\n") || Array(rest) == [0x0D, 0x0A] {
                index += 1 + (rest.first == UInt8(ascii: "\n") ? 1 : 2)
            } else if let byte = hexByte(rest) {
                output.append(byte)
                index += 3
            } else {
                output.append(bytes[index])
                index += 1
            }
        }
        return output
    }

    private static func hexByte(_ pair: ArraySlice<UInt8>) -> UInt8? {
        guard pair.count == 2, let hex = String(bytes: pair, encoding: .ascii) else {
            return nil
        }
        return UInt8(hex, radix: 16)
    }
}

enum HTMLText {
    static func plain(_ html: String) -> String {
        var text = html
        for pattern in ["<style[\\s\\S]*?</style>", "<script[\\s\\S]*?</script>", "<[^>]+>"] {
            text = text.replacingOccurrences(of: pattern, with: " ", options: [.regularExpression, .caseInsensitive])
        }
        let entities = [
            "&nbsp;": " ", "&amp;": "&", "&lt;": "<", "&gt;": ">", "&quot;": "\"", "&#39;": "'", "&euro;": "€"
        ]
        for (entity, value) in entities {
            text = text.replacingOccurrences(of: entity, with: value)
        }
        return text
    }
}
