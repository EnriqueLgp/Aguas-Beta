//
//  HomeViewController.swift
//  Aguas!Beta
//
//  Created by Enrique Lopez Gallo Perez on 19/09/26.
//

import UIKit

class HomeViewController: UIViewController {

    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var notificationsButton: UIButton!

    private let notificationDot = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()

        if let nombre = UserDefaults.standard.string(forKey: "userName"),
           !nombre.isEmpty {

            welcomeLabel.text = "Bienvenid@, \(nombre)"

        } else {

            welcomeLabel.text = "Bienvenid@"
        }

        setupNotificationDot()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        updateNotificationDot()
    }

    private func setupNotificationDot() {

        notificationDot.backgroundColor = .systemRed
        notificationDot.layer.cornerRadius = 5
        notificationDot.isHidden = true
        notificationDot.isUserInteractionEnabled = false

        notificationsButton.addSubview(notificationDot)

        notificationDot.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            notificationDot.widthAnchor.constraint(equalToConstant: 10),
            notificationDot.heightAnchor.constraint(equalToConstant: 10),
            notificationDot.topAnchor.constraint(
                equalTo: notificationsButton.topAnchor,
                constant: 2
            ),
            notificationDot.trailingAnchor.constraint(
                equalTo: notificationsButton.trailingAnchor,
                constant: -2
            )
        ])
    }

    private func updateNotificationDot() {

        NotificationService.shared.getMyNotifications { result in

            DispatchQueue.main.async {

                switch result {

                case .success(let notifications):

                    let hasUnread = notifications.contains {
                        !$0.leida
                    }

                    self.notificationDot.isHidden = !hasUnread

                case .failure:

                    self.notificationDot.isHidden = true
                }
            }
        }
    }

    @IBAction func notificationsTapped(_ sender: UIButton) {
        performSegue(
            withIdentifier: "goToNotifications",
            sender: self
        )
    }
}
