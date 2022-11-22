import XCTest
@testable import StytchCore

// swiftlint:disable implicitly_unwrapped_optional

final class OAuthTestCase: BaseTestCase {
    func testApple() async throws {
        var request: URLRequest!
        Current.networkingClient = try .success(verifyingRequest: { request = $0 }, AuthenticateResponse.mock)
        Current.appleOAuthClient = .init { _, _ in .init(idToken: "id_token_123", name: .init(firstName: "user", lastName: nil)) }
        Current.timer = { _, _, _ in .init() }
        _ = try await StytchClient.oauth.apple.start(parameters: .init())

        XCTAssertEqual(
            request.httpBody,
            Data("{\"session_duration_minutes\":30,\"nonce\":\"e0683c9c02bf554ab9c731a1767bc940d71321a40fdbeac62824e7b6495a8741\",\"id_token\":\"id_token_123\",\"name\":{\"first_name\":\"user\"}}".utf8)
        )
    }

    func testAuthenticate() async throws {
        var request: URLRequest!
        Current.networkingClient = try .success(verifyingRequest: { request = $0 }, AuthenticateResponse.mock)
        Current.timer = { _, _, _ in .init() }

        await XCTAssertThrowsError(_ = try await StytchClient.oauth.authenticate(parameters: .init(token: "i-am-token", sessionDuration: 12)))
        _ = try StytchClient.generateAndStorePKCE(keychainItem: .oauthPKCECodeVerifier)
        _ = try await StytchClient.oauth.authenticate(parameters: .init(token: "i-am-token", sessionDuration: 12))

        XCTAssertEqual(
            request.httpBody,
            .init("{\"token\":\"i-am-token\",\"session_duration_minutes\":12,\"code_verifier\":\"e0683c9c02bf554ab9c731a1767bc940d71321a40fdbeac62824e7b6495a8741\"}".utf8)
        )
    }
}

#if !os(watchOS)
extension OAuthTestCase {
    func testThirdParty() throws {
        var url: URL!
        Current.openUrl = { url = $0 }

        let startParameters: StytchClient.OAuth.ThirdParty.StartParameters = .init(
            loginRedirectUrl: try XCTUnwrap(.init(string: "i-am-url://auth")),
            customScopes: ["scope:1", "scope:2"]
        )

        XCTAssertNil(try Current.keychainClient.get(.oauthPKCECodeVerifier))

        try StytchClient.OAuth.ThirdParty.Provider.allCases.forEach { provider in
            try provider.interface.start(parameters: startParameters)

            XCTAssertEqual(
                url.absoluteString,
                "https://api.stytch.com/v1/public/oauth/\(provider.rawValue)/start?code_challenge=V9dLhNVhiUv_9m8cwFSzLGR9l-q6NAeLskiVZ7WsjA8&public_token=xyz&login_redirect_url=i-am-url://auth&custom_scopes=scope:1%20scope:2"
            )
        }

        XCTAssertNotNil(try Current.keychainClient.get(.oauthPKCECodeVerifier))
    }
}

private extension StytchClient.OAuth.ThirdParty.Provider {
    var interface: StytchClient.OAuth.ThirdParty {
        switch self {
        case .amazon:
            return StytchClient.oauth.amazon
        case .bitbucket:
            return StytchClient.oauth.bitbucket
        case .coinbase:
            return StytchClient.oauth.coinbase
        case .discord:
            return StytchClient.oauth.discord
        case .facebook:
            return StytchClient.oauth.facebook
        case .figma:
            return StytchClient.oauth.figma
        case .github:
            return StytchClient.oauth.github
        case .gitlab:
            return StytchClient.oauth.gitlab
        case .google:
            return StytchClient.oauth.google
        case .linkedin:
            return StytchClient.oauth.linkedin
        case .microsoft:
            return StytchClient.oauth.microsoft
        case .slack:
            return StytchClient.oauth.slack
        case .snapchat:
            return StytchClient.oauth.snapchat
        case .spotify:
            return StytchClient.oauth.spotify
        case .tiktok:
            return StytchClient.oauth.tiktok
        case .twitch:
            return StytchClient.oauth.twitch
        case .twitter:
            return StytchClient.oauth.twitter
        }
    }
}
#endif
