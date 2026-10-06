//
//  ImagePreviewViewController.swift
//  Aguas!Beta
//
//  Created by Enrique Lopez Gallo Perez on 04/10/26.
//

import UIKit

class ImagePreviewViewController: UIViewController {

    var image: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black

        let imageView = UIImageView()
        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        navigationItem.title = "Evidencia"
    }
}
