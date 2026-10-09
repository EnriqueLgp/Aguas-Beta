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

    override func viewDidLoad() {
        super.viewDidLoad()

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

        let newPassword = newPasswordTextField.text ?? ""
        let confirmPassword = confirmPasswordTextField.text ?? ""

        guard !newPassword.isEmpty,
              !confirmPassword.isEmpty else {

            showAlert(
                title: "Campos incompletos",
                message: "Completa ambos campos de contraseña."
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

        let alert = UIAlertController(
            title: "Contraseña actualizada",
            message: "Flujo de recuperación completado correctamente.",
            preferredStyle: .alert
        )

        alert.addAction(
            UIAlertAction(
                title: "Aceptar",
                style: .default
            ) { _ in
                self.navigationController?.popToRootViewController(animated: true)
            }
        )

        present(alert, animated: true)
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
