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

    private var notifications: [AppNotification] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        tableView.delegate = self

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 130

        loadNotifications()
    }

    @IBAction func closeTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }

    private func loadNotifications() {

        NotificationService.shared.getMyNotifications { result in

            DispatchQueue.main.async {

                switch result {

                case .success(let notifications):

                    self.notifications = notifications
                    self.tableView.reloadData()

                    self.emptyStateStack.isHidden = !notifications.isEmpty
                    self.tableView.isHidden = notifications.isEmpty

                case .failure(let error):

                    self.showAlert(
                        title: "No se pudieron cargar las notificaciones",
                        message: error.localizedDescription
                    )
                }
            }
        }
    }

    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {

        return notifications.count
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

        let notification = notifications[indexPath.row]

        cell.titleLabel.text = notification.titulo
        cell.messageLabel.text = notification.mensaje

        if notification.leida {
            cell.titleLabel.font = .systemFont(
                ofSize: 17,
                weight: .regular
            )
        } else {
            cell.titleLabel.font = .systemFont(
                ofSize: 17,
                weight: .semibold
            )
        }

        if let motivo = notification.motivo,
           !motivo.isEmpty {

            cell.reasonLabel.text = "Motivo: \(motivo)"
            cell.reasonLabel.isHidden = false

        } else {

            cell.reasonLabel.text = nil
            cell.reasonLabel.isHidden = true
        }

        cell.dateLabel.text = formatDate(notification.fechaNotificacion)

        return cell
    }

    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {

        tableView.deselectRow(
            at: indexPath,
            animated: true
        )

        let notification = notifications[indexPath.row]

        if notification.leida {
            return
        }

        NotificationService.shared.markAsRead(
            idNotification: notification.idNotificacion
        ) { result in

            DispatchQueue.main.async {

                switch result {

                case .success(let updatedNotification):

                    self.notifications[indexPath.row] = updatedNotification

                    self.tableView.reloadRows(
                        at: [indexPath],
                        with: .none
                    )

                case .failure(let error):

                    self.showAlert(
                        title: "No se pudo actualizar la notificación",
                        message: error.localizedDescription
                    )
                }
            }
        }
    }

    private func formatDate(_ dateString: String) -> String {

        let inputFormatter = ISO8601DateFormatter()

        guard let date = inputFormatter.date(
            from: dateString
        ) else {
            return dateString
        }

        let outputFormatter = DateFormatter()

        outputFormatter.locale = Locale(
            identifier: "es_MX"
        )

        outputFormatter.dateStyle = .medium
        outputFormatter.timeStyle = .short

        return outputFormatter.string(
            from: date
        )
    }

    private func showAlert(
        title: String,
        message: String
    ) {

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

        present(
            alert,
            animated: true
        )
    }
}
