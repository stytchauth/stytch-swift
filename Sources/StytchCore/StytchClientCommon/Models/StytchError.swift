import Foundation

/// Base class representing an error within the Stytch ecosystem.
public class StytchError: Error {
    public var name: String
    public var description: String
    public var url: URL?
    
    init(
        name: String,
        description: String,
        url: URL? = nil
    ) {
        self.name = name
        self.description = description
        self.url = url
    }
}

/// Error class representing an error within the Stytch API.
public class StytchAPIError: StytchError, Decodable {
    public let statusCode: Int
    public let requestId: String?
    
    private enum CodingKeys: CodingKey {
        case name
        case description
        case url
        case statusCode
        case requestId
    }
    
    init(
        name: String,
        description: String,
        url: URL? = nil,
        statusCode: Int,
        requestId: String? = nil
    ) {
        self.statusCode = statusCode
        self.requestId = requestId
        super.init(name: name, description: description, url: url)
    }
        
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        statusCode = try container.decode(Int.self, forKey: .statusCode)
        requestId = try? container.decode(String.self, forKey: .requestId)
        
        let name = try container.decode(String.self, forKey: .name)
        let description = try container.decode(String.self, forKey: .description)
        let url = try? container.decode(URL.self, forKey: .url)
        
        super.init(name: name, description: description, url: url)
    }
}

/// Error class representing when the Stytch SDK cannot reach the Stytch API.
public class StytchAPIUnreachableError: StytchError {
    init(description: String, url: URL? = nil) {
        super.init(name: "StytchAPIUnreachableError", description: description, url: url)
    }
}

/// Error class representing a schema error within the Stytch API.
public class StytchAPISchemaError: StytchError {
    init(description: String, url: URL? = nil) {
        super.init(name: "StytchAPISchemaError", description: description, url: url)
    }
}

/// Error class representing an error within the Stytch SDK.
public class StytchSDKError: StytchError {}

/// Error class representing invalid input within the Stytch SDK.
public class StytchSDKUsageError: StytchError {}

public class StytchSDKNotConfiguredError: StytchSDKError {
    let clientName: String
    
    init(clientName: String) {
        self.clientName = clientName
        super.init(
            name: "sdk_not_configured",
            description: "\(clientName) not yet configured. Must include a `StytchConfiguration.plist` in your main bundle or call `\(clientName).configure(publicToken:hostUrl:)` prior to other \(clientName) calls.",
            url: .readmeUrl(withFragment: "configuration")
        )
    }
}

public class StytchDeeplinkError: StytchSDKError {}

public extension StytchSDKError {
    static let consumerSDKNotConfigured = StytchSDKNotConfiguredError(clientName: "StytchClient")
    static let B2BSDKNotConfigured = StytchSDKNotConfiguredError(clientName: "StytchB2BClient")
    static let missingPKCE = StytchSDKError(
        name: "missing_pkce",
        description: "The PKCE code challenge or code verifier is missing. Make sure this flow is completed on the same device on which it was started."
    )
    static let deeplinkUnknownTokenType = StytchDeeplinkError(
        name: "deeplink_unknown_token_type",
        description: "The deeplink received has an unknown token type."
    )
    static let deeplinkMissingToken = StytchDeeplinkError(
        name: "deeplink_missing_token",
        description: "The deeplink received has a missing token value."
    )
    static let noCurrentSession = StytchSDKError(
        name: "no_current_session",
        description: "There is no session currently available. Make sure the user is authenticated with a valid session."
    )
    static let noBiometricRegistration = StytchSDKError(
        name: "no_biometric_registration",
        description: "There is no biometric registration available. Authenticate with another method and add a new biometric registration first."
    )
    static let invalidAuthorizationCredential = StytchSDKError(
        name: "invalid_authorization_credential",
        description: "The authorization credential is invalid. Verify that OAuth is set up correctly in the developer console, and call the start flow method."
    )
    static let missingAuthorizationCredentialIDToken = StytchSDKError(
        name: "missing_authorization_credential_id_token",
        description: "The authorization credential is missing an ID token."
    )
    static let passkeysUnsupported = StytchSDKError(
        name: "passkeys_unsupported",
        description: "Passkeys are unsupported on this device"
    )
    static let randomNumberGenerationFailed = StytchSDKError(
        name: "random_number_generation_failed",
        description: "System unable to generate a random data. Typically used for PKCE."
    )
    // Currently only available on iOS
    static let oauthInvalidStartUrl = StytchSDKError(
        name: "oauth_generic_invalid_start_url",
        description: "The start url was invalid or improperly formatted."
    )
    static let oauthInvalidRedirectScheme = StytchSDKError(
        name: "oauth_generic_invalid_redirect_scheme",
        description: "The scheme from the given redirect urls was invalid. Possible reasons include: nil scheme, non-custom scheme (using http or https), or differing schemes for login/signup urls."
    )
    static let oauthASWebAuthMissingUrl = StytchSDKError(
        name: "oauth_generic_aswebauth_missing_url",
        description: "The underlying ASWebAuthenticationSession failed to return a URL"
    )
    
    static let passkeysInvalidPublicKeyCredentialType = StytchSDKError(
        name: "passkeys_invalid_credential_type",
        description: "The public key credential type was not of the expected type."
    )
    static let passkeysMissingAttestationObject = StytchSDKError(
        name: "passkeys_missing_attestation_object",
        description: "The public key credential is missing the attestation object."
    )
    static let jsonDataNotConvertibleToString = StytchSDKError(
        name: "json_data_not_convertible_to_string",
        description: "JSON data unable to be converted to String type."
    )
}

private extension URL {
    static func readmeUrl(withFragment fragment: String) -> Self? {
        guard var urlComponents = URLComponents(string: "https://github.com/stytchauth/stytch-ios") else {
            return nil
        }
        urlComponents.fragment = fragment
        return urlComponents.url
    }
}
