//
//  HomeViewController.swift
//  Aguas!Beta
//
//  Created by Enrique Lopez Gallo Perez on 19/09/26.
//

import UIKit

class HomeViewController: UIViewController {

    @IBOutlet weak var welcomeLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        if let nombre = UserDefaults.standard.string(forKey: "userName"),
           !nombre.isEmpty {

            welcomeLabel.text = "Bienvenid@, \(nombre)"

        } else {

            welcomeLabel.text = "Bienvenid@"
        }
    }
}
