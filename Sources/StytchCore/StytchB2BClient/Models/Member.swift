import Foundation

public struct Member: Codable {
    public typealias ID = Identifier<Self, String>

    public var id: ID { memberId }
    public let organizationId: Organization.ID
    public let emailAddress: String
    public let status: Status
    public let name: String
    public let ssoRegistrations: [SSORegistration]
    public let trustedMetadata: JSON
    public let untrustedMetadata: JSON

    let memberId: ID

    public enum Status: String, Codable {
        case pending
        case active
        case deleted
        case unknown

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(String.self)
            self = .init(rawValue: rawValue) ?? .unknown
        }
    }
}

public struct SSORegistration: Codable {
    public typealias ID = Identifier<Self, String>

    public var id: ID { registrationId }
    public let connectionId: String
    public let externalId: String
    public let ssoAttributes: JSON

    let registrationId: ID
}
