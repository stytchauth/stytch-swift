import StytchCore
import UIKit

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        StytchClient.configure(publicToken: "public-token-test-728f8b82-2a20-4926-b077-a8ca7d67e1b2")
    }

    @IBAction func sendAndAuthenticateOTPTapped(_: Any) {
        Task {
            do {
                guard let phoneNumber = try await presentTextFieldAlertWithTitle(alertTitle: "Enter Your Phone Number In The Format xxxxxxxxxx", keyboardType: .numberPad) else {
                    throw TextFieldAlertError.emptyString
                }
                let loginOrCreateResponse = try await StytchClient.otps.loginOrCreate(parameters: .init(deliveryMethod: .sms(phoneNumber: "+1\(phoneNumber)", enableAutofill: false)))

                guard let code = try await presentTextFieldAlertWithTitle(alertTitle: "Enter The OTP Code", keyboardType: .numberPad) else {
                    throw TextFieldAlertError.emptyString
                }
                let authenticateResponse = try await StytchClient.otps.authenticate(parameters: .init(code: code, methodId: loginOrCreateResponse.methodId))
                presentAlertWithTitle(alertTitle: "Authetication Success!")
                logBiometricRegistrations(user: authenticateResponse.user, identifier: "otps.authenticate")
            } catch {
                print(error.errorInfo)
            }
        }
    }

    @IBAction func registerBiometoricsTapped(_: Any) {
        Task {
            do {
                _ = try await StytchClient.biometrics.register(parameters:
                    .init(
                        identifier: "foo@stytch.com",
                        accessPolicy: .deviceOwnerAuthentication
                    )
                )
                presentAlertWithTitle(alertTitle: "Register Biometrics Success!")
                logBiometricRegistrations(user: StytchClient.user.getSync(), identifier: "biometrics.register")
            } catch {
                print(error.errorInfo)
            }
        }
    }

    @IBAction func unregisterBiometoricsTapped(_: Any) {
        Task {
            do {
                try await StytchClient.biometrics.removeRegistration()
                presentAlertWithTitle(alertTitle: "Remove Biometrics Registration Success!")
                logBiometricRegistrations(user: StytchClient.user.getSync(), identifier: "biometrics.removeRegistration")
            } catch {
                print(error.errorInfo)
            }
        }
    }

    @IBAction func autheticateBiometoricsTapped(_: Any) {
        Task {
            do {
                let response = try await StytchClient.biometrics.authenticate(parameters: .init())
                presentAlertWithTitle(alertTitle: "Authenticate Biometrics Success!")
                logBiometricRegistrations(user: response.user, identifier: "biometrics.authenticate")
            } catch {
                print(error.errorInfo)
            }
        }
    }

    @IBAction func deleteRegistrationsTapped(_: Any) {
        clearAllBiometricRegistrations(user: StytchClient.user.getSync())
        Task {
            do {
                let user = try await StytchClient.user.get().wrapped
                logBiometricRegistrations(user: user, identifier: "delete registrations")
            } catch {
                print(error.errorInfo)
            }
        }
    }

    func clearAllBiometricRegistrations(user: User?) {
        guard let user else { return }
        Task {
            do {
                for registration in user.biometricRegistrations {
                    _ = try await StytchClient.user.deleteFactor(.biometricRegistration(id: registration.id))
                }
            } catch {
                print(error.errorInfo)
            }
        }
    }

    func logBiometricRegistrations(user: User?, identifier: String) {
        print(
            """
            -------------------------------------------------------------------------
            \(identifier)
            biometricRegistrations.count: \(user?.biometricRegistrations.count ?? 0)
            biometricRegistrations: \(user?.biometricRegistrations.compactMap(\.id.rawValue).joined(separator: ", ") ?? "")
            -------------------------------------------------------------------------
            """
        )
    }
}
