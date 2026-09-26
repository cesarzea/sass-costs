import Foundation

/// A `* LIST (flags) "delimiter" name` response.
struct IMAPListEntry: Equatable {
    let flags: [String]
    let name: String

    init?(_ line: IMAPLine) {
        guard line.text.hasPrefix("* LIST ("), let close = line.text.firstIndex(of: ")") else {
            return nil
        }
        let flagsStart = line.text.index(line.text.startIndex, offsetBy: "* LIST (".count)
        flags = line.text[flagsStart..<close].split(separator: " ").map(String.init)

        var rest = Substring(line.text[line.text.index(after: close)...]).drop { $0 == " " }
        guard Self.consumeToken(&rest) != nil else {
            return nil
        }
        rest = rest.drop { $0 == " " }
        if let literal = line.literals.first, rest.hasPrefix("{") {
            name = String(bytes: literal, encoding: .utf8) ?? String(bytes: literal, encoding: .isoLatin1) ?? ""
        } else if let token = Self.consumeToken(&rest) {
            name = token
        } else {
            return nil
        }
    }

    /// Reads a quoted string or an atom (e.g. NIL) from the front of `text`.
    private static func consumeToken(_ text: inout Substring) -> String? {
        guard let first = text.first else {
            return nil
        }
        guard first == "\"" else {
            let atom = text.prefix { $0 != " " }
            text = text.dropFirst(atom.count)
            return String(atom)
        }
        var value = ""
        var index = text.index(after: text.startIndex)
        while index < text.endIndex, text[index] != "\"" {
            if text[index] == "\\" {
                index = text.index(after: index)
            }
            if index < text.endIndex {
                value.append(text[index])
                index = text.index(after: index)
            }
        }
        text = index < text.endIndex ? text[text.index(after: index)...] : ""
        return value
    }
}
