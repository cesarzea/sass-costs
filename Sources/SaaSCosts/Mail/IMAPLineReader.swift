import Foundation

/// One IMAP response line. Literal payloads (`{n}` + n bytes) are kept out of `text`, in order.
struct IMAPLine: Equatable {
    var text: String
    var literals: [Data]
}

/// Splits a byte stream into IMAP response lines, reading literals by byte count.
struct IMAPLineReader {
    private var buffer = Data()

    mutating func append(_ data: Data) {
        buffer.append(data)
    }

    /// The next complete line, or `nil` when more bytes are needed.
    mutating func nextLine() -> IMAPLine? {
        var line = IMAPLine(text: "", literals: [])
        var cursor = buffer.startIndex
        let crlf = Data("\r\n".utf8)

        while let lineEnd = buffer.range(of: crlf, in: cursor..<buffer.endIndex) {
            let segment = String(bytes: buffer[cursor..<lineEnd.lowerBound], encoding: .isoLatin1) ?? ""
            line.text += segment
            guard let size = Self.literalSize(endingSegment: segment) else {
                buffer = Data(buffer[lineEnd.upperBound...])
                return line
            }
            guard buffer.distance(from: lineEnd.upperBound, to: buffer.endIndex) >= size else {
                return nil
            }
            let literalEnd = buffer.index(lineEnd.upperBound, offsetBy: size)
            line.literals.append(Data(buffer[lineEnd.upperBound..<literalEnd]))
            cursor = literalEnd
        }
        return nil
    }

    private static func literalSize(endingSegment segment: String) -> Int? {
        guard segment.hasSuffix("}"), let open = segment.lastIndex(of: "{") else {
            return nil
        }
        let digits = segment[segment.index(after: open)..<segment.index(before: segment.endIndex)]
        return Int(digits.hasSuffix("+") ? digits.dropLast() : digits)
    }
}
