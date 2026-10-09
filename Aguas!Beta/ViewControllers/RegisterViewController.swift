//
//  RegisterViewController.swift
//  Aguas!Beta
//
//  Created by Enrique Lopez Gallo Perez on 16/09/26.
//

import UIKit

class RegisterViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!

    @IBOutlet weak var privacyButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Estado inicial del checkbox de privacidad
        privacyButton.isSelected = false
        privacyButton.setImage(
            UIImage(systemName: "square"),
            for: .normal
        )

        // Oculta el teclado mientras arrastras el Scroll View
        scrollView.keyboardDismissMode = .interactive

        // Oculta el teclado al tocar fuera de los TextFields
        let tapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(dismissKeyboard)
        )

        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)

        // Detecta cuando aparece el teclado
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )

        // Detecta cuando desaparece el teclado
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc func keyboardWillShow(notification: Notification) {

        guard let keyboardFrame = notification.userInfo?[
            UIResponder.keyboardFrameEndUserInfoKey
        ] as? CGRect else {
            return
        }

        let keyboardFrameInView = view.convert(
            keyboardFrame,
            from: nil
        )

        let keyboardOverlap = max(
            0,
            view.bounds.maxY - keyboardFrameInView.minY
        )

        scrollView.contentInset.bottom = keyboardOverlap
        scrollView.verticalScrollIndicatorInsets.bottom = keyboardOverlap
    }

    @objc func keyboardWillHide(notification: Notification) {
        scrollView.contentInset.bottom = 0
        scrollView.verticalScrollIndicatorInsets.bottom = 0
    }

    @IBAction func privacyButtonTapped(_ sender: UIButton) {

        sender.isSelected.toggle()

        let imageName = sender.isSelected
            ? "checkmark.square.fill"
            : "square"

        sender.setImage(
            UIImage(systemName: imageName),
            for: .normal
        )
    }

    @IBAction func createAccountButtonTapped(_ sender: UIButton) {

        let nombre = nameTextField.text?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        let apellido = lastNameTextField.text?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        let correo = emailTextField.text?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        let password = passwordTextField.text ?? ""
        let confirmPassword = confirmPasswordTextField.text ?? ""

        // Verifica que todos los campos estén llenos
        guard !nombre.isEmpty,
              !apellido.isEmpty,
              !correo.isEmpty,
              !password.isEmpty,
              !confirmPassword.isEmpty else {

            showAlert(
                title: "Campos incompletos",
                message: "Completa todos los campos."
            )

            return
        }

        // Verifica que el correo tenga un formato válido
        guard isValidEmail(correo) else {

            showAlert(
                title: "Correo inválido",
                message: "Ingresa un correo electrónico válido."
            )

            return
        }

        // Verifica que la contraseña cumpla con los requisitos
        guard isValidPassword(password) else {

            showAlert(
                title: "Contraseña inválida",
                message: "La contraseña debe tener mínimo 8 caracteres, al menos una letra mayúscula y al menos un número."
            )

            return
        }

        // Verifica que ambas contraseñas sean iguales
        guard password == confirmPassword else {

            showAlert(
                title: "Contraseñas diferentes",
                message: "Las contraseñas no coinciden."
            )

            return
        }

        //Verifica que se haya aceptado el aviso de privacidad
        guard privacyButton.isSelected else {

            showAlert(
                title: "Aviso de privacidad",
                message: "Debes aceptar el aviso de privacidad."
            )

            return
        }

        // Desactiva temporalmente el botón para evitar múltiples registros
        sender.isEnabled = false

        // Envía los datos al backend
        AuthService.shared.register(
            nombre: nombre,
            apellido: apellido,
            correo: correo,
            password: password,
            telefono: nil
        ) { result in

            DispatchQueue.main.async {

                sender.isEnabled = true

                switch result {

                case .success:

                    let alert = UIAlertController(
                        title: "Cuenta creada",
                        message: "Tu cuenta fue creada correctamente.",
                        preferredStyle: .alert
                    )

                    alert.addAction(
                        UIAlertAction(
                            title: "Aceptar",
                            style: .default
                        ) { _ in
                            self.navigationController?
                                .popViewController(animated: true)
                        }
                    )

                    self.present(alert, animated: true)

                case .failure(let error):

                    self.showAlert(
                        title: "Error",
                        message: error.localizedDescription
                    )
                }
            }
        }
    }

    private func isValidEmail(_ email: String) -> Bool {

        let emailPattern =
            #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#

        return email.range(
            of: emailPattern,
            options: .regularExpression
        ) != nil
    }

    private func isValidPassword(_ password: String) -> Bool {

        let hasMinimumLength = password.count >= 8

        let hasUppercase = password.range(
            of: "[A-Z]",
            options: .regularExpression
        ) != nil

        let hasNumber = password.range(
            of: "[0-9]",
            options: .regularExpression
        ) != nil

        return hasMinimumLength && hasUppercase && hasNumber
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
