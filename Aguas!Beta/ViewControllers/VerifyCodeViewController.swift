//
//  VerifyCodeViewController.swift
//  Aguas!Beta
//
//  Created by Enrique Lopez Gallo Perez on 08/10/26.
//

import UIKit

class VerifyCodeViewController: UIViewController {

    @IBOutlet weak var codeTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Oculta el teclado al tocar fuera del TextField
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

    @IBAction func verifyCodeButtonTapped(_ sender: UIButton) {

        let code = codeTextField.text?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        // Verifica que el usuario haya escrito un código
        guard !code.isEmpty else {

            showAlert(
                title: "Código requerido",
                message: "Ingresa el código de verificación."
            )

            return
        }

        // Cuando conectemos el backend, aquí se verificará si el código es correcto

        performSegue(
            withIdentifier: "goToNewPassword",
            sender: self
        )
    }

    @IBAction func resendCodeButtonTapped(_ sender: UIButton) {

        // Esta acción se conectará al backend cuando exista el endpoint para reenviar el código
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
