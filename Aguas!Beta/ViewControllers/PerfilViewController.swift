//
//  PerfilViewController.swift
//  Aguas!Beta
//
//  Created by Enrique Lopez Gallo Perez on 09/10/26.
//

import UIKit

class PerfilViewController: UIViewController {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        loadUserInformation()
    }

    private func loadUserInformation() {

        nameLabel.text =
            UserDefaults.standard.string(forKey: "userName")
            ?? "Usuario"

        emailLabel.text =
            UserDefaults.standard.string(forKey: "userEmail")
            ?? "Correo no disponible"
    }

    @IBAction func changePasswordTapped(_ sender: UIButton) {
        // Se conectará cuando esté disponible el endpoint
        // para cambiar la contraseña de un usuario autenticado.
    }

    @IBAction func privacyTapped(_ sender: UIButton) {
        // Aquí se conectará posteriormente la pantalla
        // correspondiente al aviso de privacidad.
    }

    @IBAction func logoutTapped(_ sender: UIButton) {

        let alert = UIAlertController(
            title: "Cerrar sesión",
            message: "¿Seguro que quieres cerrar tu sesión?",
            preferredStyle: .alert
        )

        alert.addAction(
            UIAlertAction(
                title: "Cancelar",
                style: .cancel
            )
        )

        alert.addAction(
            UIAlertAction(
                title: "Cerrar sesión",
                style: .destructive,
                handler: { [weak self] _ in
                    self?.logout()
                }
            )
        )

        present(alert, animated: true)
    }

    private func logout() {

        APIClient.borrarSesion()

        dismiss(animated: true)
    }
}
