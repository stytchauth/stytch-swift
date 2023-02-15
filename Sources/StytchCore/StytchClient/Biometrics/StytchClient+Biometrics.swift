import Foundation

public extension StytchClient {
    /// Biometric authentication enables your users to leverage their devices' built-in biometric authenticators such as FaceID and TouchID for quick and seamless login experiences.
    struct Biometrics {
        let router: NetworkingRouter<BiometricsRoute>

        /// Indicates if there is an existing biometric registration on device.
        public var registrationAvailable: Bool {
            Current.keychainClient.valueExistsForItem(.privateKeyRegistration)
        }

        // sourcery: AsyncVariants, (NOTE: - must use /// doc comment styling)
        /// Removes the current device's existing biometric registration from both the device itself and from the server.
        public func removeRegistration() async throws {
            guard let queryResult: KeychainClient.QueryResult = try? Current.keychainClient.get(.privateKeyRegistration).first else {
                return
            }

            // Delete registration from backend
            if let registration = try queryResult.generic.map({ try Current.jsonDecoder.decode(KeychainClient.KeyRegistration.self, from: $0) }) {
                _ = try await StytchClient.user.deleteFactor(.biometricRegistration(id: registration.registrationId))
            }

            // Remove local registration
            try Current.keychainClient.removeItem(.privateKeyRegistration)
        }

        // sourcery: AsyncVariants, (NOTE: - must use /// doc comment styling)
        /// When a valid/active session exists, this method will add a biometric registration for the current user. The user will later be able to start a new session with biometrics or use biometrics as an additional authentication factor.
        ///
        /// NOTE: - You should ensure the `accessPolicy` parameters match your particular needs, defaults to `deviceOwnerWithBiometrics`.
        public func register(parameters: RegisterParameters) async throws -> RegisterCompleteResponse {
            // Early out if not authenticated
            guard Current.sessionStorage.activeSessionExists else {
                throw StytchError.noCurrentSession
            }

            let (privateKey, publicKey) = Current.cryptoClient.generateKeyPair()

            let startResponse: RegisterStartResponse = try await router.post(
                to: .register(.start),
                parameters: RegisterStartParameters(publicKey: publicKey)
            )

            let finishResponse: Response<RegisterCompleteResponseData> = try await router.post(
                to: .register(.complete),
                parameters: RegisterFinishParameters(
                    biometricRegistrationId: startResponse.biometricRegistrationId,
                    signature: Current.cryptoClient.signChallengeWithPrivateKey(
                        startResponse.challenge,
                        privateKey
                    ),
                    sessionDuration: parameters.sessionDuration
                )
            )

            let registration: KeychainClient.KeyRegistration = .init(
                userId: finishResponse.user.id,
                userLabel: parameters.identifier,
                registrationId: finishResponse.biometricRegistrationId
            )

            try Current.keychainClient.set(
                key: privateKey,
                registration: registration,
                accessPolicy: parameters.accessPolicy.keychainValue
            )

            return finishResponse
        }

        // sourcery: AsyncVariants, (NOTE: - must use /// doc comment styling)
        /// If a valid biometric registration exists, this method confirms the current device owner via the device's built-in biometric reader and returns an updated session object by either starting a new session or adding a the biometric factor to an existing session.
        public func authenticate(parameters: AuthenticateParameters) async throws -> AuthenticateResponse {
            guard let queryResult: KeychainClient.QueryResult = try Current.keychainClient.get(.privateKeyRegistration).first else {
                throw StytchError.noBiometricRegistrationsAvailable
            }

            let privateKey = queryResult.data
            let publicKey = try Current.cryptoClient.publicKeyForPrivateKey(privateKey)

            let startResponse: AuthenticateStartResponse = try await router.post(
                to: .authenticate(.start),
                parameters: AuthenticateStartParameters(publicKey: publicKey)
            )

            // NOTE: - We could return separate concrete type which deserializes/contains biometric_registration_id, but this doesn't currently add much value
            return try await router.post(
                to: .authenticate(.complete),
                parameters: AuthenticateCompleteParameters(
                    signature: Current.cryptoClient.signChallengeWithPrivateKey(startResponse.challenge, privateKey),
                    biometricRegistrationId: startResponse.biometricRegistrationId,
                    sessionDurationMinutes: parameters.sessionDuration
                )
            )
        }
    }
}

#if !os(tvOS) && !os(watchOS)
public extension StytchClient {
    /// The interface for interacting with biometrics products.
    static var biometrics: Biometrics { .init(router: router.scopedRouter { $0.biometrics }) }
}
#endif

public extension StytchClient.Biometrics {
    typealias RegisterCompleteResponse = Response<RegisterCompleteResponseData>

    /// A dedicated parameters type for biometrics `authenticate` calls.
    struct AuthenticateParameters {
        let sessionDuration: Minutes

        /// Initializes the parameters struct
        /// - Parameter sessionDuration: The duration, in minutes, for the requested session. Defaults to 30 minutes.
        public init(sessionDuration: Minutes = .defaultSessionDuration) {
            self.sessionDuration = sessionDuration
        }
    }

    /// A dedicated parameters type for biometrics `register` calls.
    struct RegisterParameters {
        let identifier: String
        let accessPolicy: AccessPolicy
        let sessionDuration: Minutes

        /// Initializes the parameters struct
        /// - Parameters:
        ///   - identifier: An id used to easily identify the account associated with the biometric registration, generally an email or phone number.
        ///   - accessPolicy: Defines the policy as to how the user must confirm their ownership.
        ///   - sessionDuration: The duration, in minutes, for the requested session. Defaults to 30 minutes.
        public init(
            identifier: String,
            accessPolicy: StytchClient.Biometrics.RegisterParameters.AccessPolicy = .deviceOwnerAuthenticationWithBiometrics,
            sessionDuration: Minutes = .defaultSessionDuration
        ) {
            self.identifier = identifier
            self.accessPolicy = accessPolicy
            self.sessionDuration = sessionDuration
        }
    }

    struct RegisterCompleteResponseData: Codable, AuthenticateResponseDataType {
        let biometricRegistrationId: User.BiometricRegistration.ID
        let user: User
        let session: Session
        let sessionToken: String
        let sessionJwt: String
    }
}

public extension StytchClient.Biometrics.RegisterParameters {
    /// Defines the policy as to how the user must confirm their device ownership.
    enum AccessPolicy {
        /// The device will first try to confirm access rights via biometrics and will fall back to device passcode.
        case deviceOwnerAuthentication
        /// The device will try to confirm access rights via biometrics.
        case deviceOwnerAuthenticationWithBiometrics
        #if os(macOS)
        /// The device will, in parallel, try to confirm access rights via biometrics or an associated Apple Watch.
        case deviceOwnerAuthenticationWithBiometricsOrWatch // swiftlint:disable:this identifier_name
        #endif

        var keychainValue: KeychainClient.Item.AccessPolicy {
            switch self {
            case .deviceOwnerAuthentication:
                return .deviceOwnerAuthentication
            case .deviceOwnerAuthenticationWithBiometrics:
                return .deviceOwnerAuthenticationWithBiometrics
            #if os(macOS)
            case .deviceOwnerAuthenticationWithBiometricsOrWatch:
                return .deviceOwnerAuthenticationWithBiometricsOrWatch
            #endif
            }
        }
    }
}

// Internal/private parameters and keys
extension StytchClient.Biometrics {
    struct AuthenticateStartParameters: Encodable {
        let publicKey: Data
    }

    struct AuthenticateStartResponse: Codable {
        let challenge: Data
        let biometricRegistrationId: User.BiometricRegistration.ID
    }

    struct AuthenticateCompleteParameters: Codable {
        let signature: Data
        let biometricRegistrationId: User.BiometricRegistration.ID
        let sessionDurationMinutes: Minutes
    }

    private struct RegisterStartParameters: Encodable {
        let publicKey: Data
    }

    struct RegisterStartResponse: Codable {
        let biometricRegistrationId: User.BiometricRegistration.ID
        let challenge: Data
    }

    private struct RegisterFinishParameters: Encodable {
        private enum CodingKeys: String, CodingKey {
            case biometricRegistrationId, signature, sessionDuration = "session_duration_minutes"
        }

        let biometricRegistrationId: User.BiometricRegistration.ID
        let signature: Data
        let sessionDuration: Minutes
    }
}
