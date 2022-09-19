// Generated using Sourcery 1.8.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
import Combine
import Foundation

public extension StytchClient.Sessions {
    /// Wraps Stytch's [authenticate](https://stytch.com/docs/api/session-auth) Session endpoint and validates that the session issued to the user is still valid, returning both an opaque sessionToken and sessionJwt for this session. The sessionJwt will have a fixed lifetime of five minutes regardless of the underlying session duration, though it will be refreshed automatically in the background after a successful authentication.
    func authenticate(parameters: AuthenticateParameters, completion: @escaping Completion<AuthenticateResponseType>) {
        Task {
            do {
                completion(.success(try await authenticate(parameters: parameters)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Wraps Stytch's [authenticate](https://stytch.com/docs/api/session-auth) Session endpoint and validates that the session issued to the user is still valid, returning both an opaque sessionToken and sessionJwt for this session. The sessionJwt will have a fixed lifetime of five minutes regardless of the underlying session duration, though it will be refreshed automatically in the background after a successful authentication.
    func authenticate(parameters: AuthenticateParameters) -> AnyPublisher<AuthenticateResponseType, Error> {
        return Deferred {
            Future({ promise in
                Task {
                    do {
                        promise(.success(try await authenticate(parameters: parameters)))
                    } catch {
                        promise(.failure(error))
                    }
                }
            })
        }
        .eraseToAnyPublisher()
    }
}
