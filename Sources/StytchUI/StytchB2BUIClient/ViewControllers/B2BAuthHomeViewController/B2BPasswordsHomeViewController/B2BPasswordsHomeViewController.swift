import AuthenticationServices
import StytchCore
import UIKit

protocol B2BPasswordsHomeViewControllerDelegate: AnyObject {
    func didAuthenticateWithPassword()
    func didSendEmailMagicLink()
}

final class B2BPasswordsHomeViewController: BaseViewController<B2BPasswordsState, B2BPasswordsViewModel> {
    weak var delegate: B2BPasswordsHomeViewControllerDelegate?

    private let emailInputLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryText
        label.text = NSLocalizedString("stytch.emailInputLabel", value: "Email", comment: "")
        return label
    }()

    private lazy var emailInput: EmailInput = .init()

    private let passwordInputLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryText
        label.text = NSLocalizedString("stytch.passwordInputLabel", value: "Password", comment: "")
        return label
    }()

    private lazy var passwordInput: SecureTextInput = {
        let input: SecureTextInput = .init(frame: .zero)
        input.textInput.textContentType = .password
        input.textInput.rightView = secureEntryToggleButton
        input.textInput.rightViewMode = .always
        return input
    }()

    private lazy var secureEntryToggleButton: UIButton = {
        let button = UIButton(type: .custom)
        button.adjustsImageWhenHighlighted = false
        button.setImage(UIImage(systemName: "eye"), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.tintColor = .secondaryText
        button.addTarget(self, action: #selector(toggleSecureEntry(sender:)), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([button.heightAnchor.constraint(equalToConstant: 12.5)])
        return button
    }()

    private lazy var continueButton: Button = .primary(
        title: NSLocalizedString("stytch.pwContinueTitle", value: "Continue", comment: "")
    ) { [weak self] in
        self?.submit()
    }

    init(state: B2BPasswordsState, delegate: B2BPasswordsHomeViewControllerDelegate?) {
        super.init(viewModel: B2BPasswordsViewModel(state: state))
        self.delegate = delegate
        viewModel.delegate = self
    }

    override func configureView() {
        super.configureView()

        view.layoutMargins = .zero

        stackView.spacing = .spacingRegular

        stackView.addArrangedSubview(emailInputLabel)
        stackView.addArrangedSubview(emailInput)
        stackView.addArrangedSubview(passwordInputLabel)
        stackView.addArrangedSubview(passwordInput)
        stackView.addArrangedSubview(continueButton)

        attachStackView(within: view)

        NSLayoutConstraint.activate(
            stackView.arrangedSubviews.map { $0.widthAnchor.constraint(equalTo: stackView.widthAnchor) }
        )
    }

    @objc private func toggleSecureEntry(sender _: UIButton) {
        passwordInput.textInput.isSecureTextEntry.toggle()
    }

    private func submit() {
        guard let emailAddress = emailInput.text, let password = passwordInput.text else {
            // show error
            return
        }
        viewModel.authenticateWithPasswordIfPossible(emailAddress: emailAddress, password: password)
    }
}

extension B2BPasswordsHomeViewController: B2BPasswordsViewModelDelegate {
    func didAuthenticateWithPassword() {
        delegate?.didAuthenticateWithPassword()
    }

    func didSendEmailMagicLink() {
        delegate?.didSendEmailMagicLink()
    }

    func didError(error: any Error) {
        presentErrorAlert(error: error)
    }
}