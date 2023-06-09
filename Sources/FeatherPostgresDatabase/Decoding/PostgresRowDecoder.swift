import Foundation
import PostgresNIO

struct PostgresRowDecoder {

    enum KeyDecodingStrategy {
        case useDefaultKeys
        case convertFromSnakeCase
        case custom(([CodingKey]) -> CodingKey)
    }

    var prefix: String?
    var keyDecodingStrategy: KeyDecodingStrategy

    init(
        prefix: String? = nil,
        keyDecodingStrategy: KeyDecodingStrategy = .useDefaultKeys
    ) {
        self.prefix = prefix
        self.keyDecodingStrategy = keyDecodingStrategy
    }

    func decode<T: Decodable>(
        _ type: T.Type,
        from row: PostgresRandomAccessRow
    ) throws -> T {
        try T.init(from: RowDecoder(row: row, options: options))
    }

    private var options: RowDecoderOptions {
        .init(
            prefix: prefix,
            keyDecodingStrategy: keyDecodingStrategy
        )
    }
}

private enum RowDecoderError: Error {
    case nesting
    case unkeyedContainer
    case singleValueContainer
}

private struct RowDecoderOptions {
    let prefix: String?
    let keyDecodingStrategy: PostgresRowDecoder.KeyDecodingStrategy
}

private struct RowDecoder: Decoder {

    let options: RowDecoderOptions
    let row: PostgresRandomAccessRow
    var codingPath: [CodingKey] = []
    var userInfo: [CodingUserInfoKey: Any] { [:] }

    init(
        row: PostgresRandomAccessRow,
        codingPath: [CodingKey] = [],
        options: RowDecoderOptions
    ) {
        self.options = options
        self.row = row
        self.codingPath = codingPath
    }

    func container<Key: CodingKey>(
        keyedBy type: Key.Type
    ) throws -> KeyedDecodingContainer<Key> {
        .init(
            KeyedRowDecoder(
                referencing: self,
                row: row,
                codingPath: codingPath
            )
        )
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        throw RowDecoderError.unkeyedContainer
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer {
        throw RowDecoderError.singleValueContainer
    }
}

private struct KeyedRowDecoder<Key: CodingKey>: KeyedDecodingContainerProtocol {

    let decoder: RowDecoder
    let row: PostgresRandomAccessRow
    var codingPath: [CodingKey] = []
    var allKeys: [Key] {
        row.compactMap {
            Key.init(stringValue: $0.columnName)
        }
    }

    init(
        referencing decoder: RowDecoder,
        row: PostgresRandomAccessRow,
        codingPath: [CodingKey] = []
    ) {
        self.decoder = decoder
        self.row = row
    }

    func column(for key: Key) -> String {
        var decodedKey = key.stringValue
        switch decoder.options.keyDecodingStrategy {
        case .useDefaultKeys:
            break
        case .convertFromSnakeCase:
            decodedKey = _convertFromSnakeCase(decodedKey)
        case .custom(let customKeyDecodingFunc):
            decodedKey = customKeyDecodingFunc([key]).stringValue
        }

        if let prefix = decoder.options.prefix {
            return prefix + decodedKey
        }
        return decodedKey
    }

    func contains(_ key: Key) -> Bool {
        row.contains(column(for: key))
    }

    func decodeNil(forKey key: Key) throws -> Bool {
        !contains(key) || row[key.stringValue].bytes == nil
    }

    func decode<T: Decodable>(_ type: T.Type, forKey key: Key) throws -> T {
        let data = row[data: key.stringValue]
        let dec = PostgresDataDecoder()
        return try dec.decode(T.self, from: data)
    }

    func nestedContainer<NestedKey: CodingKey>(
        keyedBy type: NestedKey.Type,
        forKey key: Key
    ) throws -> KeyedDecodingContainer<NestedKey> {
        throw RowDecoderError.nesting
    }

    func nestedUnkeyedContainer(
        forKey key: Key
    ) throws -> UnkeyedDecodingContainer {
        throw RowDecoderError.nesting
    }

    func superDecoder() throws -> Decoder {
        RowDecoder(
            row: row,
            codingPath: codingPath,
            options: decoder.options
        )
    }

    func superDecoder(forKey key: Key) throws -> Decoder {
        throw RowDecoderError.nesting
    }

    func _convertFromSnakeCase(_ stringKey: String) -> String {
        guard !stringKey.isEmpty else { return stringKey }

        var words: [Range<String.Index>] = []
        var wordStart = stringKey.startIndex
        var searchRange = stringKey.index(after: wordStart)..<stringKey.endIndex

        while let upperCaseRange = stringKey.rangeOfCharacter(
            from: CharacterSet.uppercaseLetters,
            options: [],
            range: searchRange
        ) {
            let untilUpperCase = wordStart..<upperCaseRange.lowerBound
            words.append(untilUpperCase)

            searchRange = upperCaseRange.lowerBound..<searchRange.upperBound
            guard
                let lowerCaseRange = stringKey.rangeOfCharacter(
                    from: CharacterSet.lowercaseLetters,
                    options: [],
                    range: searchRange
                )
            else {
                wordStart = searchRange.lowerBound
                break
            }
            let nextCharacterAfterCapital = stringKey.index(
                after: upperCaseRange.lowerBound
            )
            if lowerCaseRange.lowerBound == nextCharacterAfterCapital {
                wordStart = upperCaseRange.lowerBound
            }
            else {
                let beforeLowerIndex = stringKey.index(
                    before: lowerCaseRange.lowerBound
                )
                words.append(upperCaseRange.lowerBound..<beforeLowerIndex)
                wordStart = beforeLowerIndex
            }
            searchRange = lowerCaseRange.upperBound..<searchRange.upperBound
        }
        words.append(wordStart..<searchRange.upperBound)
        let result =
            words
            .map { stringKey[$0].lowercased() }
            .joined(separator: "_")
        return result
    }
}
