//
//  VerifyCodeViewController.swift
//  Aguas!Beta
//
//  Created by Enrique Lopez Gallo Perez on 08/10/26.
//

import UIKit

class VerifyCodeViewController: UIViewController {

    @IBOutlet weak var codeTextField: UITextField!

    var correo: String = ""

    private var isRequestInProgress = false

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

        guard !isRequestInProgress else {
            return
        }

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

        guard code.range(
            of: #"^[0-9]{6}$"#,
            options: .regularExpression
        ) != nil else {

            showAlert(
                title: "Código inválido",
                message: "El código debe contener exactamente 6 dígitos."
            )

            return
        }

        guard !correo.isEmpty else {

            showAlert(
                title: "Correo no disponible",
                message: "Regresa a la pantalla anterior y solicita un código."
            )

            return
        }

        view.endEditing(true)
        isRequestInProgress = true
        sender.isEnabled = false

        PasswordService.shared.verifyResetCode(
            correo: correo,
            codigo: code
        ) { [weak self] result in

            DispatchQueue.main.async {

                sender.isEnabled = true

                guard let self = self else {
                    return
                }

                self.isRequestInProgress = false

                guard self.viewIfLoaded?.window != nil,
                      self.navigationController?.topViewController === self else {
                    return
                }

                switch result {

                case .success(let response):

                    self.codeTextField.text = ""

                    self.performSegue(
                        withIdentifier: "goToNewPassword",
                        sender: response.resetToken
                    )

                case .failure(let error):

                    self.showAlert(
                        title: "No se pudo validar el código",
                        message: error.localizedDescription
                    )
                }
            }
        }
    }

    @IBAction func resendCodeButtonTapped(_ sender: UIButton) {

        guard !isRequestInProgress else {
            return
        }

        guard !correo.isEmpty else {

            showAlert(
                title: "Correo no disponible",
                message: "Regresa a la pantalla anterior y solicita un código."
            )

            return
        }

        view.endEditing(true)
        isRequestInProgress = true
        sender.isEnabled = false

        PasswordService.shared.resendResetCode(
            correo: correo
        ) { [weak self] result in

            DispatchQueue.main.async {

                sender.isEnabled = true

                guard let self = self else {
                    return
                }

                self.isRequestInProgress = false

                guard self.viewIfLoaded?.window != nil,
                      self.navigationController?.topViewController === self else {
                    return
                }

                switch result {

                case .success(let response):

                    self.codeTextField.text = ""

                    self.showAlert(
                        title: "Solicitud recibida",
                        message: response.message
                    )

                case .failure(let error):

                    self.showAlert(
                        title: "No se pudo reenviar el código",
                        message: error.localizedDescription
                    )
                }
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if segue.identifier == "goToNewPassword",
           let destination = segue.destination as? NewPasswordViewController,
           let resetToken = sender as? String {

            destination.resetToken = resetToken
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
