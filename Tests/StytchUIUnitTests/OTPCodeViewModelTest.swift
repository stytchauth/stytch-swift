import XCTest
@testable import StytchCore
@testable import StytchUI

final class OTPCodeViewModelTest: BaseTestCase {
    var calledMethod: CalledMethod? = nil
    func calledMethodCallback(method: CalledMethod) {
        calledMethod = method
    }

    override func setUp() async throws {
        calledMethod = nil
        StytchUIClient.onAuthCallback = nil
    }

    func testResendCodeCallsLoginOrCreateAndUpdatesState() async throws {
        let state: OTPCodeState = .init(
            config: .init(
                publicToken: "",
                products: .init()
            ),
            phoneNumberE164: "",
            formattedPhoneNumber: "",
            methodId: "",
            codeExpiry: Date()
        )
        let spy = OTPSpy(callback: calledMethodCallback)
        let vm: OTPCodeViewModel = .init(state: state, otpClient: spy)
        _ = try await vm.resendCode(phone: "1234567890")
        XCTAssert(calledMethod == .otpLoginOrCreate)
        XCTAssert(vm.state.phoneNumberE164 == "1234567890")
        XCTAssert(vm.state.methodId == "otp-method-id")
    }

    func testEnterCodeCallsAuthenticateAndReportsToUICallback() async throws {
        let state: OTPCodeState = .init(
            config: .init(
                publicToken: "",
                products: .init()
            ),
            phoneNumberE164: "",
            formattedPhoneNumber: "",
            methodId: "",
            codeExpiry: Date()
        )
        let spy = OTPSpy(callback: calledMethodCallback)
        let vm: OTPCodeViewModel = .init(state: state, otpClient: spy)
        var didCallUICallback = false
        StytchUIClient.onAuthCallback = { _ in
            didCallUICallback = true
        }
        _ = try await vm.enterCode(code: "123456", methodId: "")
        XCTAssert(calledMethod == .otpAuthenticate)
        XCTAssert(didCallUICallback)
    }
}