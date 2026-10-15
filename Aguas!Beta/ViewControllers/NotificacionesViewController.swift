//
//  NotificacionesViewController.swift
//  Aguas!Beta
//
//  Created by Enrique Lopez Gallo Perez on 13/10/26.
//

import UIKit

class NotificacionesViewController: UIViewController,
                                    UITableViewDataSource,
                                    UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyStateStack: UIStackView!

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        tableView.delegate = self

        // Ajusta la altura de las celdas según su contenido
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 130

        // Por ahora se muestra el estado vacío hasta conectar el backend
        emptyStateStack.isHidden = false
        tableView.isHidden = true
    }

    @IBAction func closeTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }

    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {

        return 0
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "NotificationCell",
            for: indexPath
        ) as? NotificationTableViewCell else {
            return UITableViewCell()
        }

        return cell
    }
}
