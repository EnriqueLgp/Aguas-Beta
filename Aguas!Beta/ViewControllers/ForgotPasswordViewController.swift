//
//  ForgotPasswordViewController.swift
//  Aguas!Beta
//
//  Created by Enrique Lopez Gallo Perez on 05/10/26.
//

import UIKit

class ForgotPasswordViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Oculta el teclado al tocar fuera del TextField.
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

    @IBAction func sendCodeButtonTapped(_ sender: UIButton) {

        let email = emailTextField.text?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        // Verifica que el campo no esté vacío.
        guard !email.isEmpty else {

            showAlert(
                title: "Correo requerido",
                message: "Ingresa tu correo electrónico."
            )

            return
        }

        // Verifica un formato básico de correo.
        guard isValidEmail(email) else {

            showAlert(
                title: "Correo inválido",
                message: "Ingresa un correo electrónico válido."
            )

            return
        }

        // Cuando conectemos el backend, aquí se verificará que exista una cuenta con este correo
        // Solo si el backend confirma que el correo existe,se deberá ejecutar este segue

        performSegue(
            withIdentifier: "goToVerifyCode",
            sender: self
        )
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
