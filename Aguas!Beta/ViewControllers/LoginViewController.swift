//
//  LoginViewController.swift
//  Aguas!Beta
//
//  Created by Enrique Lopez Gallo Perez on 16/09/26.
//

import UIKit

class LoginViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var formStackView: UIStackView!
    @IBOutlet weak var enterButton: UIButton!

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Aumenta el espacio entre el botón Entrar
        // y el bloque "¿No tienes cuenta? / Crear cuenta"
        formStackView.setCustomSpacing(80, after: enterButton)

        // Oculta el teclado mientras arrastras el Scroll View.
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

    @IBAction func loginButtonTapped(_ sender: UIButton) {

        let correo = emailTextField.text?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        let password = passwordTextField.text ?? ""

        // Verifica que ambos campos tengan información.
        guard !correo.isEmpty,
              !password.isEmpty else {

            showAlert(
                title: "Campos incompletos",
                message: "Ingresa tu correo electrónico y contraseña."
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

        // Evita que se presione varias veces mientras responde el servidor
        sender.isEnabled = false

        AuthService.shared.login(
            correo: correo,
            password: password
        ) { result in

            DispatchQueue.main.async {

                sender.isEnabled = true

                switch result {

                case .success(let response):

                    // Guarda los tokens para utilizarlos después en las peticiones protegidas del backend
                    UserDefaults.standard.set(
                        response.accessToken,
                        forKey: "accessToken"
                    )

                    UserDefaults.standard.set(
                        response.refreshToken,
                        forKey: "refreshToken"
                    )

                    // Guarda el nombre del usuario para mostrarlo después en la pantalla de inicio
                    UserDefaults.standard.set(
                        response.nombre,
                        forKey: "userName"
                    )

                    // El login fue correcto, Ahora sí entra al Tab Bar Controller
                    self.performSegue(
                        withIdentifier: "goToHome",
                        sender: self
                    )

                case .failure(let error):

                    self.showAlert(
                        title: "No se pudo iniciar sesión",
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
