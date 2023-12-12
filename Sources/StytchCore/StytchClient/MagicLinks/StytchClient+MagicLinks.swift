public extension StytchClient {
    /// Magic links can be sent via email and allow for a quick and seamless login experience.
    struct MagicLinks {
        let router: NetworkingRouter<MagicLinksRoute>

        @Dependency(\.keychainClient) private var keychainClient

        // sourcery: AsyncVariants, (NOTE: - must use /// doc comment styling)
        /// Wraps the magic link [authenticate](https://stytch.com/docs/api/authenticate-magic-link) API endpoint which validates the magic link token passed in. If this method succeeds, the user will be logged in, granted an active session, and the session cookies will be minted and stored in `HTTPCookieStorage.shared`.
        public func authenticate(parameters: AuthenticateParameters) async throws -> AuthenticateResponse {
            guard let codeVerifier: String = try? keychainClient.get(.codeVerifierPKCE) else { throw StytchSDKError.pckeNotAvailable }

            return try await router.post(
                to: .authenticate,
                parameters: CodeVerifierParameters(codeVerifier: codeVerifier, wrapped: parameters)
            )
        }
    }
}

public extension StytchClient {
    /// The interface for interacting with magic-links products.
    static var magicLinks: MagicLinks { .init(router: router.scopedRouter { $0.magicLinks }) }
}

public extension StytchClient.MagicLinks {
    /// A dedicated parameters type for magic links `authenticate` calls.
    struct AuthenticateParameters: Encodable {
        private enum CodingKeys: String, CodingKey {
            case token
            case sessionDuration = "sessionDurationMinutes"
        }

        let token: String
        let sessionDuration: Minutes

        /**
         Initializes the parameters struct
         - Parameters:
           - token: The token extracted from the magic link.
           - sessionDuration: The duration, in minutes, for the requested session. Defaults to 30 minutes.
         */
        public init(token: String, sessionDuration: Minutes = .defaultSessionDuration) {
            self.token = token
            self.sessionDuration = sessionDuration
        }
    }
}
