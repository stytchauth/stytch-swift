import StytchCore
import UIKit

public enum StytchUIClient {
    public static func presentController(with configuration: Configuration, from controller: UIViewController) {
        let authController = AuthRootViewController(configuration: configuration)
        controller.present(authController, animated: true) // TODO: add callback for when auth is completed
    }
}

public extension StytchUIClient {
    struct Configuration {
        let oauth: OAuth?
        let input: Input?

        enum Input {
            case magicLink(sms: Bool)
            case password(sms: Bool)
            case magicLinkAndPassword(sms: Bool)
            case smsOnly
        }
        struct OAuth {
            let providers: [Provider]

            enum Provider {
                case apple
                case thirdParty(StytchClient.OAuth.ThirdParty.Provider)
            }
        }
    }
}
