//
//  NewPasswordViewController.swift
//  Aguas!Beta
//
//  Created by Enrique Lopez Gallo Perez on 08/10/26.
//

import UIKit

class NewPasswordViewController: UIViewController {

    @IBOutlet weak var newPasswordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var currentPasswordTextField: UITextField!
    @IBOutlet weak var currentPasswordLabel: UILabel!


    var resetToken: String = ""
    var isChangingPassword: Bool = false

    private var isRequestInProgress = false

    override func viewDidLoad() {
        super.viewDidLoad()

        newPasswordTextField.isSecureTextEntry = true
        confirmPasswordTextField.isSecureTextEntry = true
        currentPasswordTextField.isSecureTextEntry = true

        currentPasswordTextField.isHidden = !isChangingPassword
        currentPasswordLabel.isHidden = !isChangingPassword

        if isChangingPassword {
            title = "Cambiar contraseña"
        }

        // Oculta el teclado al tocar fuera de los TextFields
        let tapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(dismissKeyboard)
        )

        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    @IBAction func savePasswordButtonTapped(_ sender: UIButton) {

        guard !isRequestInProgress else {
            return
        }

        let newPassword = newPasswordTextField.text ?? ""
        let confirmPassword = confirmPasswordTextField.text ?? ""
        let currentPassword = currentPasswordTextField.text ?? ""

        guard !newPassword.isEmpty,
              !confirmPassword.isEmpty else {

            showAlert(
                title: "Campos incompletos",
                message: "Completa ambos campos de contraseña."
            )

            return
        }

        guard newPassword.count >= 8 else {

            showAlert(
                title: "Contraseña muy corta",
                message: "La contraseña debe tener al menos 8 caracteres."
            )

            return
        }

        guard newPassword == confirmPassword else {

            showAlert(
                title: "Contraseñas diferentes",
                message: "Las contraseñas no coinciden."
            )

            return
        }

        if isChangingPassword {

            guard !currentPassword.isEmpty else {

                showAlert(
                    title: "Contraseña actual requerida",
                    message: "Ingresa tu contraseña actual."
                )

                return
            }

            guard currentPassword != newPassword else {

                showAlert(
                    title: "Contraseña sin cambios",
                    message: "La nueva contraseña debe ser diferente de la actual."
                )

                return
            }

        } else {

            guard !resetToken.isEmpty else {

                showAlert(
                    title: "Recuperación no disponible",
                    message: "Regresa y solicita un código nuevo."
                )

                return
            }
        }

        view.endEditing(true)
        sender.isEnabled = false
        isRequestInProgress = true
        isModalInPresentation = true

        let completion: (Result<PasswordMessageResponse, Error>) -> Void = { [weak self] result in

            DispatchQueue.main.async {

                sender.isEnabled = true

                guard let self = self else {
                    return
                }

                self.isRequestInProgress = false
                self.isModalInPresentation = false

                guard self.viewIfLoaded?.window != nil else {
                    return
                }

                if let navigationController = self.navigationController,
                   navigationController.topViewController !== self {
                    return
                }

                switch result {

                case .success(let response):

                    self.resetToken = ""
                    self.newPasswordTextField.text = ""
                    self.confirmPasswordTextField.text = ""
                    self.currentPasswordTextField.text = ""

                    let alert = UIAlertController(
                        title: "Contraseña actualizada",
                        message: response.message,
                        preferredStyle: .alert
                    )

                    alert.addAction(
                        UIAlertAction(
                            title: "Aceptar",
                            style: .default
                        ) { _ in

                            if self.isChangingPassword {

                                self.closeScreen()

                            } else if let login = self.navigationController?
                                .viewControllers.first(where: {
                                    $0 is LoginViewController
                                }) {

                                self.navigationController?.popToViewController(
                                    login,
                                    animated: true
                                )

                            } else {

                                self.closeScreen()
                            }
                        }
                    )

                    self.present(alert, animated: true)

                case .failure(let error):

                    self.showAlert(
                        title: "No se pudo actualizar la contraseña",
                        message: error.localizedDescription
                    )
                }
            }
        }

        if isChangingPassword {

            PasswordService.shared.changePassword(
                currentPassword: currentPassword,
                newPassword: newPassword,
                completion: completion
            )

        } else {

            PasswordService.shared.resetPassword(
                resetToken: resetToken,
                password: newPassword,
                completion: completion
            )
        }
    }

    @IBAction func cancelButtonTapped(_ sender: UIButton) {

        guard !isRequestInProgress else {
            return
        }

        view.endEditing(true)
        resetToken = ""
        newPasswordTextField.text = ""
        confirmPasswordTextField.text = ""
        currentPasswordTextField.text = ""

        closeScreen()
    }

    private func closeScreen() {

        if let navigationController = navigationController,
           navigationController.viewControllers.first !== self {

            navigationController.popViewController(
                animated: true
            )

        } else {

            dismiss(animated: true)
        }
    }

    private func showAlert(title: String, message: String) {

        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(
            UIAlertAction(
                title: "Aceptar",
                style: .default
            )
        )

        present(alert, animated: true)
    }
}
