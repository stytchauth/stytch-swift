import Foundation

struct KeychainClient {
    let get: (Item) throws -> [QueryResult]

    let setValueForItem: (Item.Value, Item) throws -> Void

    let removeItem: (Item) throws -> Void

    init(
        get: @escaping (Item) throws -> [QueryResult],
        setValueForItem: @escaping (Item.Value, Item) throws -> Void,
        removeItem: @escaping (Item) throws -> Void
    ) {
        self.get = get
        self.setValueForItem = setValueForItem
        self.removeItem = removeItem
    }
}

// String convenience methods
extension KeychainClient {
    func get(_ item: Item) throws -> String? {
        try get(item)
            .first
            .flatMap { String(data: $0.data, encoding: .utf8) }
    }

    func set(_ value: String, for item: Item) throws {
        try setValueForItem(
            .init(data: .init(value.utf8), account: nil, label: nil, generic: nil, accessPolicy: nil, syncingBehavior: .disabled),
            item
        )
    }
}

extension KeychainClient {
    struct QueryResult {
        let data: Data
        let createdAt: Date
        let modifiedAt: Date
        let label: String?
        let account: String
        let generic: Data?
    }

    enum KeychainError: Swift.Error {
        case resultMissingAccount
        case resultMissingDates
        case resultNotArray
        case resultNotData
        case unhandledError(status: OSStatus)
    }
}
