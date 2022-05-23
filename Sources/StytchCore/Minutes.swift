/// A dedicated type which represents the minutes unit of time.
public struct Minutes: Encodable {
    let rawValue: UInt

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        try container.encode(rawValue)
    }
}

extension Minutes: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: UInt) {
        rawValue = value
    }
}

public extension Minutes {
    /// 30
    static let defaultSessionDuration: Self = 30
}